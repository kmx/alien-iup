use strict;
use warnings;
use Module::Build;

use lib 'inc';

my %platforms =(
  # Unix = default, thus not listing all UNIX like systems
  MSWin32 => 'Windows',
  cygwin => 'Unix',
);
my $package = 'My::Builder::' . ($platforms{$^O} || 'Unix');
print "Gonna use '$package' class ...\n";
eval "require $package" or die "###ERROR### Require '$package' failed: $@\n";

my $builder = $package->new(
  module_name        => 'Alien::IUP',
  dist_version_from  => 'lib/Alien/IUP.pm',
  dist_author        => 'KMX, kmx@cpan.org',
  license            => 'mit',
  requires => {
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
  },
  configure_requires => {
    'File::Spec'        => 0,
    'File::Temp'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'File::Fetch'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
    'Text::Patch'       => 0,
    'IPC::Run3'         => 0,
  },
  build_requires => {
    'Test::More'        => 0,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Temp'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'File::Fetch'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
    'Text::Patch'       => 0,
    'IPC::Run3'         => 0,
  },
  share_dir          => 'sharedir',
  add_to_cleanup     => [ 'Alien-IUP-*', 'build_done' ],
  create_readme      => 1,
  meta_merge => {
    resources  => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-IUP',
      repository => 'http://github.com/kmx/alien-iup',
    }
  }
);

$builder->create_build_script();

if ($builder->check_installed_lib()) {
  my $ans = $builder->prompt("IUP detected, wanna use IUP already installed on your system?", 'y');
  $builder->notes('already_installed_lib', undef) unless (lc($ans) eq 'y');
}

# delete build marker (= force rebuild after running Build.PL)
unlink 'build_done';

# set what tarballs we are gonna use
$builder->notes('iup_url', 'http://download.sf.net/iup/iup-3.2_Sources.tar.gz');
$builder->notes('iup_sha1', 'ca27b5a51d24e6292dc761081d1f8d497be43114');
$builder->notes('iup_patches', [ 'patches/iup.diff' ] );

$builder->notes('im_url', 'http://download.sf.net/imtoolkit/im-3.6.2_Sources.tar.gz');
$builder->notes('im_sha1', 'a805043af8af9703ded9049ecce1d4c48fc4f224');
$builder->notes('im_patches', [ 'patches/im.diff' ] );

$builder->notes('cd_url', 'http://download.sf.net/canvasdraw/cd-5.4_Sources.tar.gz');
$builder->notes('cd_sha1', '6d1d1c6a6348be19c8cba1a0b7368c64b4532911');
$builder->notes('cd_patches', [ 'patches/cd.diff' ] );
