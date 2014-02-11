package Mojar::Config;
use Mojo::Base -base;

our $VERSION = 0.002;
# Adapted from Mojolicious::Plugin::Config (3.57)

use Mojo::Util qw(decode slurp);

# Private function

sub croak { require Carp; goto &Carp::croak; }

# Public methods

sub load {
  my ($self, $file, $log) = @_;
  $log->debug(sprintf 'Reading config file (%s)', $file) if defined $log;
  my $content = decode 'UTF-8', slurp $file;
  return $self->parse(\$content, $log);
}

sub parse {
  my ($self, $content_ref, $log) = @_;

  # Run Perl code
  my $config = eval sprintf '%s%s%s', 'package Mojar::Config::Sandbox;',
      'use strict;', $$content_ref;
  croak qq{Failed to load configuration from file: $@} if not $config and $@;
  croak qq{Config file did not return a hash reference.\n}
    unless ref $config eq 'HASH';
  $log->debug('Config content successfully read') if defined $log;

  return $config;
}

1;
__END__

=head1 NAME

Mojar::Config - Perl-ish configuration utility for standalone code

=head1 SYNOPSIS

  use Mojar::Config;
  my $config = Mojar::Config->load('cfg/defaults.conf');
  say $config->{redis}{ip};

=head1 DESCRIPTION

A simple configuration file reader for a configuration written as a perl hash.

=head1 USAGE

  # cfg/defaults.conf
  {
    debug => undef,
    expiration => 60 * 60 * 10,
    secrets => [qw(where wild things roam)],
    redis => {
      ip => '192.168.1.1',
      port => 6379
    }
  }

The contents are evaluated, so compuatations are valid.

=head1 METHODS

=head2 load

  $hashref = Mojar::Config->load('path/to/file.conf');
  $hashref = Mojar::Config->load('path/to/file.conf', $log);

Loads a perl-ish configuration from the given file path.  In normal usage, this
is the only method required.  The result is a plain (unblessed) hashref.

=head2 parse

  $content = '{ testing => 2 * 2 }';
  $config = Mojar::Config->parse(\$content);
  say $config->{testing};

Does the actual parsing of the configuration, being passed a ref to the
configuration text.

=head1 DEBUGGING

Both methods accept a Mojar::Log/Mojo::Log object as their final argument.  If
passed a debug-level logger, some debugging statements become available.

  my $log = Mojar::Log->new(level => 'debug', path => '/tmp/stuff.log');
  my $config = Mojar::Config->new->load('/etc/stuff.conf', $log);

=head1 SEE ALSO

This is a fork of L<Mojolicious::Plugin::Config> (v3.57) that can be used
independently of having a Mojolicious app.  So if your code is for a Mojolicious
app, it makes sense to use the upstream module instead.

=cut
