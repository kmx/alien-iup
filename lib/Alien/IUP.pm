package Alien::IUP;

use warnings;
use strict;

use Alien::IUP::ConfigData;
use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catdir catfile rel2abs);

=head1 NAME

Alien::IUP - Building, finding and using iup + related libraries - L<http://www.tecgraf.puc-rio.br/iup/>

=cut

# following http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/
our $VERSION = "0.024";
$VERSION = eval $VERSION;

=head1 VERSION

Version 0.024 of Alien::IUP is based on the following:

=over

=item * I<iup> library 3.2 - see L<http://www.tecgraf.puc-rio.br/iup/>

=item * I<im> library 3.6.2 - see L<http://www.tecgraf.puc-rio.br/im/>

=item * I<cd> library 5.4 - see L<http://www.tecgraf.puc-rio.br/cd/>

=back

=head1 SYNOPSIS

B<IMPORTANT:> This module is not a perl binding for I<iup + related> libraries; it is just
a helper module. The real perl binding is implemented by L<IUP|http://github.com/kmx/perl-iup> module,
which is using Alien::IUP to locate I<iup + related> libraries on your system (or build it from source codes).

Alien::IUP tries (in given order) during its installation:

=over

=item * Locate an already installed I<iup> and related libraries  + ask user whether
to use the already installed I<iup> or whether to build I<iup> from sources

=item * Via env variable IUP_DIR you can specify where the build script should look
for the already installed I<iup> and related libs (directories $ENV{IUP_DIR}/lib and 
$ENV{IUP_DIR}/include are expected to exist)

=item * When not using the already installed libraries build process continues with
the following steps

=item * Download I<iup> & co. source code tarballs

=item * Build I<iup> & co. binaries from source codes (note: static libraries are build in this case)

=item * Install libs and dev files (*.h, *.a) into I<share> directory of Alien::IUP
distribution - I<share> directory is usually something like this: /usr/lib/perl5/site_perl/5.10/auto/share/dist/Alien-IUP

=back

Later on you can use Alien::IUP in your module that needs to link with
I<iup> and/or related libs like this:

 # Sample Makefile.pl
 use ExtUtils::MakeMaker;
 use Alien::IUP;
 
 WriteMakefile(
   NAME         => 'Any::IUP::Module',
   VERSION_FROM => 'lib/Any/IUP/Module.pm',
   LIBS         => Alien::IUP->config('LIBS'),
   INC          => Alien::IUP->config('INC'),
   # + additional params
 );

B<IMPORTANT:> As Alien::IUP builds static libraries the modules using Alien::IUP (e.g. L<IUP|http://github.com/kmx/perl-iup>)
need to have Alien::IUP just for building, not for later use. In other words Alien:IUP is just
"build dependency" not "run-time dependency".

=head1 METHODS

=head2 config()

This function is the main public interface to this module.

 Alien::IUP->config('LIBS');

Returns a string like: '-L/path/to/iupdir/lib -liup -lim -lcd'

 Alien::IUP->config('INC');

Returns a string like: '-I/path/to/iupdir/include'

 Alien::IUP->config('PREFIX');

Returns a string like: '/path/to/iupdir' (note: if using the already installed
I<iup> config('PREFIX') returns undef)

=head1 AUTHOR

KMX, E<lt>kmx at cpan.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-iup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-IUP>.

=head1 LICENSE AND COPYRIGHT

Libraries I<iup>, I<im> and I<cd>: Copyright (C) 1994-2010 Tecgraf, PUC-Rio.
L<http://www.tecgraf.puc-rio.br>

Alien::IUP module: Copyright (C) 2010 KMX.

This program is distributed under the MIT License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

sub config
{
  my ($package, $param) = @_;
  return unless ($param =~ /[a-z0-9_]*/i);
  my $subdir = Alien::IUP::ConfigData->config('share_subdir');
  unless ($subdir) {
    #we are using lib already installed on your system not compiled by Alien
    #therefore no additinal magic needed
    return Alien::IUP::ConfigData->config('config')->{$param};
  }
  my $share_dir = dist_dir('Alien-IUP');
  my $real_prefix = catdir($share_dir, $subdir);
  my $val = Alien::IUP::ConfigData->config('config')->{$param};
  return unless $val;
  $val =~ s/\@PrEfIx\@/$real_prefix/g; # handle @PrEfIx@ replacement
  return $val;
}

1; # End of Alien::IUP
