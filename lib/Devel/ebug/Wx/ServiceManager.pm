package Devel::ebug::Wx::ServiceManager;

use strict;
use base qw(Class::Accessor::Fast);

=head1 NAME

Devel::ebug::Wx::Service::ServiceManager - manage services

=head1 SYNOPSIS

  my $sm = $wxebug->service_manager; # or find it elsewhere
  my $service = $sm->get_service( $service_name );
  # use the $service

  # alternate ways of getting a service
  my $srv = $wxebug->service_manager->get_service( 'foo_frobnicate' );
  my $srv = $wxebug->foo_frobnicate_service;

=head1 DESCRIPTION

The service manager is responsible for finding, initializing and
terminating services.  Users of the service usually need just to call
C<get_service> to retrieve a service instance.

=head1 METHODS

=cut

use Module::Pluggable
      sub_name    => '_services',
      search_path => 'Devel::ebug::Wx::Service',
      require     => 1;

__PACKAGE__->mk_ro_accessors( qw(_active_services _wxebug) );

=head2 services

  my @service_classes = Devel::ebug::Wx::ServiceManager->services;

Returns a list of service classes known to the service manager.

=head2 active_services

  my @services = $sm->active_services;

Returns a list of services currently registered with the service manager.

=cut

sub active_services { @{$_[0]->_active_services} }
sub services { grep !$_->abstract, $_[0]->_services }

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new;
    my @services = map $_->new, $self->services;

    $self->{_active_services} = \@services;

    return $self;
}

=head2 initialize

  $sm->initialze( $wxebug );

Calls C<initialize> on all service instances and sets their
C<initialized> property to true.

=cut

sub initialize {
    my( $self, $wxebug ) = @_;

    foreach my $service ( $self->active_services ) {
        next if $service->initialized;
        $service->initialize( $wxebug );
        $service->initialized( 1 );
    }
}

=head2 load_state

  $sm->load_state;

Calls C<load_state> on all service instances.

=cut

sub load_state {
    my( $self ) = @_;

    $_->load_state foreach $self->active_services;
}

=head2 finalize

  $sm->finalize( $wxebug );

Calls C<save_state> on all service instances, then calls C<finalize>
on them and sets their C<finalized> property to true.

Important: the C<initialized> property is still true even after
C<finalize> has been called..

=cut

sub finalize {
    my( $self, $wxebug ) = @_;

    # distinguish between explicit and implicit state saving?
    $_->save_state foreach $self->active_services;
    foreach my $service ( $self->active_services ) {
        next if $service->finalized;
        $service->finalize;
        $service->finalized( 1 );
    }
}

=head2 get_service

  my $service_instance = $sm->get_service( 'service_name' );

Returns an active service with the given name, or C<undef> if none is
found.  If the service has not been initialized, calls C<inititialize>
as well, but not C<load_state>.

=cut

sub get_service {
    my( $self, $wxebug, $name ) = @_;
    my( $service, @rest ) = grep $_->service_name eq $name,
                                 $self->active_services;

    # FIXME what if more than one?
    unless( $service->initialized ) {
        $service->initialize( $wxebug );
        $service->initialized( 1 );
        # FIXME should call load_state, too?
    }
    return $service;
}

=head1 SEE ALSO

L<Devel::ebug::Wx::Service::Base>

=cut

1;