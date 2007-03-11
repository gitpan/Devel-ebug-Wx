package Devel::ebug::Wx;

use Wx;

use strict;
use warnings;
use base qw(Wx::Frame Class::Accessor::Fast);

our $VERSION = '0.03';

use Wx qw(:aui);
use Wx::Event qw(EVT_CLOSE);

use Devel::ebug::Wx::Publisher;
use Devel::ebug::Wx::ServiceManager;

__PACKAGE__->mk_ro_accessors( qw(ebug service_manager) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( undef, -1, 'wxebug', [-1, -1], [-1, 500] );

    EVT_CLOSE( $self, \&_on_close );

    $self->{ebug} = Devel::ebug::Wx::Publisher->new;
    $self->{service_manager} = Devel::ebug::Wx::ServiceManager->new;

    $self->ebug->add_subscriber( 'load_program', sub { $self->_pgm_load( @_ ) } );
    $self->service_manager->initialize( $self );
    $self->service_manager->load_state;

    $self->SetMenuBar( $self->command_manager_service->get_menu_bar );

    $self->ebug->load_program( $args->{argv} );

    return $self;
}

sub get_service { $_[0]->service_manager->get_service( $_[0], $_[1] ) }

sub _on_close {
    my( $self ) = @_;

    $self->service_manager->finalize( $self );
    $self->Destroy;
}

sub _pgm_load {
    my( $self, $ebug, $event, %params ) = @_;

    $self->SetTitle( $params{filename} );
}

# remap ->xxx_yy_service to ->get_service( 'xxx_yy' )
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    return if $AUTOLOAD =~ /::DESTROY$/;
    ( my $sub = $AUTOLOAD ) =~ s/.*::(\w+)_service$/$1/;
    return $self->get_service( $1 );
}

1;

__END__

=head1 NAME

Devel::ebug::Wx - GUI interface for your (d)ebugging needs

=head1 SYNOPSIS

  # it's easier to use the 'ebug_wx' script
  my $app = Wx::SimpleApp->new;
  my $wx = Devel::ebug::Wx->new( { argv => \@ARGV } );
  $wx->Show;
  $app->MainLoop;

=head1 DESCRIPTION

L<Devel::ebug::Wx> is a GUI front end to L<Devel::ebug>.

The core is a publisher/subscriber wrapper around L<Devel::ebug>
(L<Devel::ebug::Wx::Publisher>) plus a plugin system for defining menu
commands and keyboard bindings (L<Devel::ebug::Wx::Command::*>) and
views (L<Devel::ebug::Wx::View::*>).

The wxWidgets Advanced User Interface (AUI) is used, so it is possible
to dock/undock and arrange views.

=head1 TODO

=over 4

=item * make a saner interface for plugins

what do commands do; better registration interface
views have gui state that needs saving,
global state of the debugger gui
allow generic plugins to be views/commands/services at the same time?

=item * define a service interface

for example for code-viewing, configuration, gui management, view management
allow enabling/dispabling services, commands, views

=item * add more views (package browser)

=item * configuration interface

=item * notebooks

better editing interface
better debugging, edge cases still present, esp. at load time
views must ba able to serialize themselves (neetds a proper format)
composite for notebooks (common base for notebook and viewmanager?)

=item * allow saving debugger state between session

=item * handle the cases when the debugged program is terminated

=item * break on subroutine, undo, watchpoints

=item * show pad, show package variables, show packages

=item * see the FIXMEs

=back

=head1 SEE ALSO

L<Devel::ebug>, L<ebug_wx>, L<Wx>, L<ebug>

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.