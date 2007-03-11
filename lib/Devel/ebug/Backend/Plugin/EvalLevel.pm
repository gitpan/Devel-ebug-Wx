package Devel::ebug::Backend::Plugin::EvalLevel;

use strict;

sub register_commands {
    return ( eval_level => { sub => \&DB::eval_level, record => 1 },
             );
}

package DB;

*_project = \&Devel::ebug::Backend::Plugin::EvalLevel::project;

# FIXME use Devel::ebug's eval
# FIXME distinguish success and exception thrown
sub eval_level {
    my( $req, $context ) = @_;
    my $eval = $req->{eval};
    local $SIG{__WARN__} = sub {};

    my $v = eval "package $context->{package}; $eval";
    if( $@ ) {
        return { eval => $@, exception => 1 };
    } else {
        return { eval => _project( $v, $req->{level} ) };
    }
}

package Devel::ebug::Backend::Plugin::EvalLevel;

sub _cc {
    my( $v ) = @_;

    return ref( $v ) eq 'ARRAY' ? scalar( @$v ) :
           ref( $v ) eq 'HASH'  ? scalar( keys %$v ) : -1;
}

sub _ck {
    my( $v ) = @_;

    return ref( $v ) eq 'ARRAY' ? [ 0 .. $#$v ] :
           ref( $v ) eq 'HASH'  ? [ sort keys %$v ] : [];
}

sub _cv {
    my( $v ) = @_;

    return ref( $v ) eq 'ARRAY' ? [ @$v ] :
           ref( $v ) eq 'HASH'  ? [ map $v->{$_}, sort keys %$v ] : $v;
}

sub _g {
    my( $v, $i ) = @_;

    return ref( $v ) eq 'ARRAY' ? ( $i < @$v, $v->[$i] ) :
           ref( $v ) eq 'HASH'  ? ( exists $v->{$i}, $v->{$i} ) : die;
}

sub _ckv {
    my( $c ) = @_;
    my( $k, $v ) = ( _ck( $c ), _cv( $c ) );
    my $r = [];

    while( @$k ) {
        push @$r, [ shift @$k, shift @$v ];
    }

    return $r;
}

sub project {
    my( $v, $l ) = @_;
    my $r = { type   => ref $v,
              string => "$v",
              };

    if( _cc( $v ) >= 0 ) {
        $r->{keys} = [];
        foreach my $kv ( @{_ckv( $v )} ) {
            push @{$r->{keys}}, [ $kv->[0], project( $kv->[1], $l - 1 ) ];
        }
    } else {
        $r->{value} = $v;
    }

    return $r;
}

1;