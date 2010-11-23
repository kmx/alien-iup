use 5.008;
use strict;
use warnings;
use Module::Build;

use lib 'inc';

my %platforms =(
  # Unix = default, thus not listing all UNIX like systems
  MSWin32 => 'Windows',
  cygwin  => 'Cygwin',
  linux   => 'Unix',
);
my $package = 'My::Builder::' . ($platforms{$^O} || 'Unix');
print STDERR "Gonna use '$package' class ...\n";
eval "require $package" or die "###ERROR### Require '$package' failed: $@\n";

my $builder = $package->new(
  module_name        => 'Alien::IUP',
  dist_version_from  => 'lib/Alien/IUP.pm',
  dist_author        => 'KMX, kmx@cpan.org',
  license            => 'mit',
  requires => {
    'perl'              => 5.008,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
  },
  configure_requires => {
    'perl'              => 5.008,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Path'        => 0,
    'File::Temp'        => 0,
    'File::Find'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'File::Fetch'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
    'Text::Patch'       => 0,
    'IPC::Run3'         => 0.041, # we need return_if_system_error
  },
  build_requires => {
    'perl'              => 5.008,
    'Test::More'        => 0,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Path'        => 0,
    'File::Temp'        => 0,
    'File::Find'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'File::Fetch'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
    'Text::Patch'       => 0,
    'IPC::Run3'         => 0.041, # we need return_if_system_error
  },
  share_dir          => 'sharedir',
  add_to_cleanup     => [ 'Alien-IUP-*' ],
  #create_makefile_pl => 'small', # creating Makefile.PL to satisfy old CPAN clients (does not work well with our style of M::B use)
  create_readme      => 1,
  meta_merge => {
    resources  => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-IUP',
      repository => 'http://github.com/kmx/alien-iup',
    }
  },
);

unlink 'build_done'; # delete build marker (= force rebuild after running Build.PL)
$builder->add_to_cleanup("sharedir/" . $builder->{properties}->{dist_version}); # catfile() would be better
$builder->add_to_cleanup('build_done');
$builder->add_to_cleanup('build_src');
      
if ($builder->check_installed_lib()) {
  my $ans = $builder->prompt("\nIUP detected, wanna use IUP already installed on your system (y/n)?", 'y');
  $builder->notes('already_installed_lib', undef) unless (lc($ans) eq 'y');  
}

$builder->notes('build_debug_info', lc($builder->prompt("\nWanna see more debug info during build (y/n)?", 'y')) eq 'y' ? 1 : 0);

# set what tarballs we are gonna use

$builder->notes('iup_url', 'http://strawberryperl.com/package/kmx/testing/iup-cvs-101123.tar.gz');
$builder->notes('iup_sha1', 'd26ee919ef57d4b7bcc2d909bb450309093ccf41');
#$builder->notes('iup_patches', [ ] );

$builder->notes('im_url', 'http://strawberryperl.com/package/kmx/testing/im-cvs-101123.tar.gz');
$builder->notes('im_sha1', 'e29e026ad8d353d90b8b299778e4bc5512281b35');
#$builder->notes('im_patches', [ 'patches/im-dragonfly.diff' ] );

$builder->notes('cd_url', 'http://strawberryperl.com/package/kmx/testing/cd-cvs-101123.tar.gz');
$builder->notes('cd_sha1', 'ecea482eaf365df8805a6971704445b056c0893e');
#$builder->notes('cd_patches', [ 'patches/cd-dragonfly.diff' ] );

# check if we have GNU make otherwise 'exit 0' - cpan testers will report "N/A"
my $m = $builder->get_make;
exit 0 unless $m;
$builder->notes('gnu_make', $m);

$builder->create_build_script();
