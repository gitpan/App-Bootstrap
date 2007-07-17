package App::Bootstrap;

use warnings;
use strict;

use Cwd;
use File::Path qw(mkpath);
use File::ShareDir qw(module_dir);
use Text::Template;

=head1 NAME

App::Bootstrap - Bootstrap, stub, or install applications

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our %files;
our @delimiters = ('{{{', '}}}');

=head1 SYNOPSIS

In YourApp::Install:

    use base qw(App::Bootstrap);

=head1 WARNING

This is experimental and subject to change.  It's not even guaranteed to
really work at all.  You have been warned.

=head1 DESCRIPTION

This is easiest to do by analogy.  Have you ever used any of the
following?

    module-starter
    catalyst.pl
    kwiki-install
    minimvc-install

Each of these scripts comes packaged with its respective distro
(Module::Starter, Catalyst::Helper, Kwiki, and MasonX::MiniMVC
respectively) and is used to create a framework, stub, or starting point
for some software.

If you're not familiar with any of those modules and their installers,
imagine a theoretical module Foo::Bar, which comes with a foo-install
script.  When you run foo-install, it creates a directory structure like
this:

    foo.cgi
    lib/
    lib/Foo/Local.pm
    t/
    t/foo_local.t

You can then adapt foo.cgi and the other provided files to suit your
specific needs.

Well, App::Bootstrap is a generic tool for creating installers like
those described above.

=head2 Using App::Bootstrap

App::Bootstrap is used by subclassing it.  In YourApp::Install, you'll
put:

    package YourApp::Install;
    use base qw(App::Bootstrap);

Next, specify the files you'll want to populate:

    YourApp::Install->files(
        identifier  => 'relative/file/location',
        second_file => 'some/other/location',
    );

File locations are relative to the base directory the user's installing
into.  Using the Foo::Bar example given above, you might have:

    Foo::Bar::Install->files(
        foo_cgi.tmpl    => 'foo.cgi',
        local_pm.tmpl   => 'lib/Foo/Local.pm',
        local_test.tmpl => 't/foo_local.t',
    );

You need to include your input template files in the C<share> directory
of your module distribution.  If you're using Module::Build, this
typically means creating a directory called C<share/> at the top level
of your distro, and everything will be magically installed in the right
place.  App::Bootstrap uses File::ShareDir to determine the location of
your app's share directory after it's installed.

If you wish data to be interpolated into your inline files -- and you
probably do -- this is done using Text::Template.  In its simplest form,
simply put anything you wish to have interpolated in triple curly braces:

    package {{{$app_name}}};

The delimiters -- C<{{{> and C<}}}> have been chosen for their
unlikelihood of showing up in real Perl code.  If for some reason this
doesn't suit you, you can change the delimiters in YourApp::Install as
follows:

    YourApp::Install->delimiters($start, $end);

To actually create an installer script, simply write something like:

    use YourApp::Install;

    # pick up options from the command line or elsewhere, if desired
    # eg. the application name, email, etc.

    YourApp::Install->install(
        template_dir => $template_dir,
        install_dir  => $install_dir,
        data => \%data,
    );

The template directory defaults to your distribution's C<share>
directory (see L<Module::ShareDir>).

The installation directory defaults to the current working directory.

The data hashref will be passed to Text::Template for interpolation into
the files.

=head1 PUBLIC METHODS

=head2 files()

Set a list of files to install.

=cut

sub files {
    my ($class, %files) = @_;
    %App::Bootstrap::files = %files;
}

=head2 delimiters()

Change the delimiters used by the templating system.

=cut

sub delimiters {
    my ($class, $start, $end) = @_;
    @App::Bootstrap::delimiters = ($start, $end);
}

=head2 install()

Do it!

=cut

sub install {
    my ($class, %options) = @_;
    _check_empty_dir($options{install_dir} || getcwd());
    $class->_write_files(%options);
}

sub _check_empty_dir {
    my ($dir) = @_;

    opendir DIR, $dir or die "Can't open current directory to check if it's empty: $!\n";
    my @files = grep !/^\.+$/, readdir(DIR);
    closedir DIR;

    if (@files) {
        die "Directory isn't empty.  Remove files and try again.\n";
    }
}

sub _write_files {
    my ($class, %options) = @_;

    my $install_dir  = $options{install_dir};
    my $template_dir = $options{template_dir} || module_dir($class);
    my $data         = $options{data};

    my %files = %App::Bootstrap::files;

    print "Running install from $class...\n";
    print "Creating file structure...\n";

    $DB::single = 1;

    foreach my $file ( sort { $files{$a} cmp $files{$b} } keys %files) {

        my $template = "$template_dir/$file";
        open my $ifh, '<', $template
            or warn "Can't open input file $template: $!\n";
        $/ = undef;
        my $content = <$ifh>;
        close $ifh;

        if ($content) {
            $DB::single = 1;
            my $template = Text::Template->new(
                TYPE       => 'STRING',
                SOURCE     => $content,
                DELIMITERS => \@App::Bootstrap::delimiters,
            );

            $content = $template->fill_in(HASH => $data);

            my $outfile = "$install_dir/$files{$file}";

            my $subdir = $outfile;
            $subdir =~ s/[^\/]+$//; # strip trailing filename
            unless (-e $subdir) {
                unless (mkpath $subdir) {
                    warn "Can't make subdirectory $subdir: $!\n";
                }
            }

            if (open my $ofh, '>', $outfile) {
                print $ofh $content;
                close $ofh;
                print "  $outfile\n";
            } else {
                warn "Couldn't open $files{$file} to write: $!\n";
            }

        } else {
            warn "Couldn't get content for file $files{$file}\n";
        }
    }
}

=head1 AUTHOR

Kirrily "Skud" Robert, C<< <skud at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-bootstrap at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Bootstrap>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Bootstrap

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Bootstrap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Bootstrap>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Bootstrap>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Bootstrap>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Kirrily "Skud" Robert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
