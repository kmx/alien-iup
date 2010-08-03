package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use lib "inc";
use File::Spec::Functions qw(catfile);
use ExtUtils::Command;
use File::Fetch;
use File::Temp qw(tempdir tempfile);
use Digest::SHA qw(sha1_hex);
use Archive::Extract;
use Config;
use ExtUtils::Liblist;
use Text::Patch;
use IPC::Run3;

sub ACTION_code {
  my $self = shift;

  unless (-e 'build_done') {
    $self->add_to_cleanup('build_done');
    my $inst = $self->notes('already_installed_lib');
    if (defined $inst) {
      $self->config_data('config', { LIBS   => $inst->{lflags},
                                     INC    => $inst->{cflags},
                                   });
    }
    else {
      # important directories
      my $download = 'download';
      my $patches = 'patches';
      my $build_src = 'build_src';
      # we are deriving the subdir name from VERSION as we want to prevent
      # troubles when user reinstalls the newer version of Alien package
      my $build_out = catfile('sharedir', $self->{properties}->{dist_version});
      $self->add_to_cleanup($build_out);
      $self->add_to_cleanup($build_src);

      # store info into CofigData
      $self->config_data('iup_url', $self->notes('iup_url'));
      $self->config_data('im_url', $self->notes('im_url'));
      $self->config_data('cd_url', $self->notes('cd_url'));

      # prepare sources
      my $unpack;
      $unpack = (-d "$build_src/iup") ? $self->prompt("Dir '$build_src/iup' exists, wanna replace with clean sources?", "n") : 'y';
      if (lc($unpack) eq 'y') {
        $self->prepare_sources($self->notes('iup_url'), $self->notes('iup_sha1'), $download, $build_src);
        if ($self->notes('iup_patches')) {
          $self->apply_patch("$build_src/iup", $_)  foreach (@{$self->notes('iup_patches')});
        }
      }

      $unpack = (-d "$build_src/im") ? $self->prompt("Dir '$build_src/im'  exists, wanna replace with clean sources?", "n") : 'y';
      if (lc($unpack) eq 'y') {
        $self->prepare_sources($self->notes('im_url'), $self->notes('im_sha1'), $download, $build_src);
        if ($self->notes('im_patches')) {
          $self->apply_patch("$build_src/im", $_)  foreach (@{$self->notes('im_patches')});
        }
      }

      $unpack = (-d "$build_src/cd") ? $self->prompt("Dir '$build_src/cd'  exists, wanna replace with clean sources?", "n") : 'y';
      if (lc($unpack) eq 'y') {
        $self->prepare_sources($self->notes('cd_url'), $self->notes('cd_sha1'), $download, $build_src);
        if ($self->notes('cd_patches')) {
          $self->apply_patch("$build_src/cd", $_)  foreach (@{$self->notes('cd_patches')});
        }
      }

      # go for build
      $self->build_binaries($build_out, $build_src);

      # store info about build to ConfigData
      $self->config_data('share_subdir', $self->{properties}->{dist_version});
      $self->config_data('config', { PREFIX => '@PrEfIx@',
                                     LIBS   => '-L' . $self->quote_literal('@PrEfIx@/lib') .
                                               ' -l' . join(' -l', @{$self->config_data('linker_libs')}) .
                                               ' ' . $self->config_data('extra_lflags'),
                                     INC    => '-I' . $self->quote_literal('@PrEfIx@/include') .
                                               ' ' . $self->config_data('extra_cflags'),
                                   });
    }
    # mark sucessfully finished build
    local @ARGV = ('build_done');
    ExtUtils::Command::touch();
  }
  $self->SUPER::ACTION_code;
}

sub prepare_sources {
  my ($self, $url, $sha1, $download, $build_src) = @_;
  $self->fetch_file($url, $sha1, $download);
   my $archive = catfile($download, File::Fetch->new(uri => $url)->file);
   my $ae = Archive::Extract->new( archive => $archive );
   die "###ERROR### Cannot extract tarball ", $ae->error unless $ae->extract(to => $build_src);
}

sub fetch_file {
  my ($self, $url, $sha1sum, $download) = @_;
  die "###ERROR### fetch_file() undefined url\n" unless $url;
  die "###ERROR### fetch_file() undefined sha1sum\n" unless $sha1sum;
  my $ff = File::Fetch->new(uri => $url);
  my $fn = catfile($download, $ff->file);
  if (-e $fn) {
    print "Checking checksum for already existing '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    unlink $fn; #exists but wrong checksum
  }
  print "Fetching '$url'...\n";
  my $fullpath = $ff->fetch(to => $download);
  die "###ERROR### Unable to fetch '$url'" unless $fullpath;
  if (-e $fn) {
    print "Checking checksum for '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    die "###ERROR### Checksum failed '$fn'";
  }
  die "###ERROR### fetch_file() failed '$fn'";
}

sub check_sha1sum {
  my ($self, $file, $sha1sum) = @_;
  my $sha1 = Digest::SHA->new;
  my $fh;
  open($fh, $file) or die "###ERROR## Cannot check checksum for '$file'\n";
  binmode($fh);
  $sha1->addfile($fh);
  close($fh);
  return ($sha1->hexdigest eq $sha1sum) ? 1 : 0;
}

sub build_binaries {
  die "###ERROR### My::Builder is not able to build, use rather My::Builder::<platform>";
}

sub quote_literal {
  # this needs to be overriden in My::Builder::<platform>
  my ($self, $path) = @_;
  return $path;
}

sub check_installed_lib {
  my ($self) = @_;
  my $idir = $ENV{IUP_DIR} || '';
  my @candidates;
  push(@candidates, { L => "$idir/lib", I => "$idir/include" }) if -d $idir;
  push(@candidates, { L => '', I => '' });
  push(@candidates, { L => '', I => $Config{usrinc} }) if -d $Config{usrinc};
  push(@candidates, { L => '/usr/local/lib', I => '/usr/local/include' }) if -d '/usr/local/lib' && -d '/usr/local/include';
  push(@candidates, { L => '/usr/lib', I => '/usr/include' }) if -d '/usr/lib' && -d '/usr/include';

  print "Gonna detect iup+im+cd already installed on your system:\n";
  foreach my $i (@candidates) {
    my $lflags = $i->{L} ? '-L'.$self->quote_literal($i->{L}) : '';
    my $cflags = $i->{I} ? '-I'.$self->quote_literal($i->{I}) : '';
    #xxx does not work with MSVC compiler
    #xxx $lflags = ExtUtils::Liblist->ext($lflags) if($Config{make} =~ /nmake/ && $Config{cc} =~ /cl/); # MSVC compiler hack
    print "- testing: $cflags $lflags\n";
    my $rv1 = $self->check_header( [ 'iup.h', 'im.h', 'cd.h' ], $cflags);
    #xxx maybe we need to link with more libs
    if ($self->check_lib( [ 'iup', 'im', 'cd' ], $cflags, $lflags)){
      print "- iup+im+cd FOUND!\n";
      $self->notes('already_installed_lib', { lflags => "$lflags -liup -lim -lcd", cflags => $cflags } );
      return 1;
    }
    elsif ($self->check_lib( [ 'iupwin', 'im', 'cdwin' ], $cflags, $lflags)) {
      print "- iupwin+im+cdwin FOUND!\n";
      $self->notes('already_installed_lib', { lflags => "$lflags -liupwin -lim -lcdwin", cflags => $cflags } );
      return 1;
    }
    elsif ($self->check_lib( [ 'iupgtk', 'im', 'cdgdk' ], $cflags, $lflags)) {
      print "- iupgtk+im+cdgdk FOUND!\n";
      $self->notes('already_installed_lib', { lflags => "$lflags -liupgtk -lim -lcdgdk", cflags => $cflags } );
      return 1;
    }
    elsif ($self->check_lib( [ 'iupmot', 'im', 'cdx11' ], $cflags, $lflags)) {
      print "- iupmot+im+cdx11 FOUND!\n";
      $self->notes('already_installed_lib', { lflags => "$lflags -liupmot -lim -lcdx11", cflags => $cflags } );
      return 1;
    }
  }
  print "- iup+im+cd not found (we have to build it from sources)!\n";
  return 0;
}

# check presence of header(s) specified as params
sub check_header {
  my ($self, $h, $cflags) = @_;
  $cflags ||= '';
  my @header = ref($h) ? @$h : ( $h );

  my ($fs, $src) = File::Temp->tempfile('tmpfileXXXXXXaa', SUFFIX => '.c', UNLINK => 1);
  my ($fo, $obj) = File::Temp->tempfile('tmpfileXXXXXXaa', SUFFIX => '.o', UNLINK => 1);
  my $inc = '';
  $inc .= "#include <$_>\n" foreach @header;
  syswrite($fs, <<MARKER); # write test source code
$inc
int demofunc(void) { return 0; }

MARKER
  close($fs);
  local *OLDERR;
  open OLDERR, ">&", STDERR;
  open STDERR, ">", File::Spec->devnull();
  $src = $self->quote_literal($src);
  $obj = $self->quote_literal($obj);
  #Note: $Config{cc} might contain e.g. 'ccache cc' (FreeBSD 8.0)
  my $rv = system("$Config{cc} -c -o $obj $src $cflags");
  open(STDERR, ">&", OLDERR);
  return ($rv == 0) ? 1 : 0;
}

# check presence of lib(s) specified as params
sub check_lib {
  my ($self, $l, $cflags, $lflags) = @_;
  $cflags ||= '';
  $lflags ||= '';
  $cflags =~ s/[\r\n]//g;
  $lflags =~ s/[\r\n]//g;
  my @libs = ref($l) ? @$l : ( $l );

  my ($fs, $src) = File::Temp->tempfile('tmpfileXXXXXXaa', SUFFIX => '.c', UNLINK => 1);
  my ($fo, $obj) = File::Temp->tempfile('tmpfileXXXXXXaa', SUFFIX => '.o', UNLINK => 1);
  my ($fe, $exe) = File::Temp->tempfile('tmpfileXXXXXXaa', SUFFIX => '.out', UNLINK => 1);
  syswrite($fs, <<MARKER); # write test source code
int main() { return 0; }

MARKER
  close($fs);
  local *OLDERR;
  open OLDERR, ">&", STDERR;
  open STDERR, ">", File::Spec->devnull();
  $src = $self->quote_literal($src);
  $obj = $self->quote_literal($obj);
  $exe = $self->quote_literal($exe);
  #Note: $Config{cc} might contain e.g. 'ccache cc' (FreeBSD 8.0)
  my $rv1 = system("$Config{cc} -c -o $obj $src $cflags");
  my $liblist = scalar(@libs) ? '-l' . join(' -l', @libs) : '';
  my $rv2 = ($rv1 == 0) ? system("$Config{ld} $obj -o $exe $lflags $liblist") : -1;
  open(STDERR, ">&", OLDERR);
  return ($rv2 == 0) ? 1 : 0;
}

# pude perl implementation of patch functionality
sub apply_patch {
  my ($self, $dir_to_be_patched, $patch_file) = @_;
  my ($src, $diff);

  undef local $/;
  open(DAT, $patch_file) or die "###ERROR### Cannot open file: '$patch_file'\n";
  $diff = <DAT>;
  close(DAT);
  $diff =~ s/\r\n/\n/g; #normalise newlines
  $diff =~ s/\ndiff /\nSpLiTmArKeRdiff /g;
  my @patches = split('SpLiTmArKeR', $diff);

  foreach my $p (@patches) {
    my ($k) = map{$_ =~ /\n---\s*([\S]+)/} $p;
    # doing the same like -p1 for 'patch'
    $k =~ s|\\|/|g;
    $k =~ s|^[^/]*/(.*)$|$1|;
    $k = catfile($dir_to_be_patched, $k);
    print "Gonna patch file '$k'\n";

    open(SRC, $k) or die "###ERROR### Cannot open file: '$k'\n";
    $src  = <SRC>;
    close(SRC);
    $src =~ s/\r\n/\n/g; #normalise newlines

    my $out = eval { Text::Patch::patch( $src, $p, { STYLE => "Unified" } ) };
    if ($out) {
      open(OUT, ">", $k) or die "###ERROR### Cannot open file for writing: '$k'\n";
      print(OUT $out);
      close(OUT);
    }
    else {
      warn "###WARN### Patching '$k' failed: $@";
    }
  }
}

sub do_system_output_tail {
  my ($self, $limit, @cmd) = @_;
  my $output;
  print "CMD: " . join(' ',@cmd) . "\n";
  print "Running (stdout+stderr redirected)...\n";
  my $rv = run3 \@cmd, \undef, \$output, \$output;
  $output = substr $output, -$limit if defined $limit; # we want just last N chars
  print ( (defined $limit) ? "OUTPUT: (only last $limit chars)\n" : "OUTPUT:\n");
  print $output, "\n";
  return $rv;
}

1;
