use strict;
use warnings;
use Data::Dumper;
use Template;

my $input = 'build-dllw4.log';

my %flags1 = ();
my $flags2 = {};

my %fixtarget = ( 
    ftgl => 'cd_ftgl',
    freetype6 => 'cd_freetype',
    zlib1 => 'cd_zlib',
    pdflib => 'cd_pdflib',
);

my @targets = ();

my @curlist = ();
my $curtarget = '';
my $curmakefile = '';
my $curlname = '';
my $curlf = '';
my $curlobjs = [];

sub flush_target {
  my %srcdir = (
    iupwin => 'src',
    iup => 'src',
    iupcd => 'srccd',
    xx => 'srcconsole',
    iupcontrols => 'srccontrols',
    iupgl => 'srcgl',
    iupim => 'srcim',
    iupimglib => 'srcimglib',
    iupole => 'srcole',
    iup_pplot => 'srcpplot', 
    iup_mglplot => 'srcmglplot',
    iuptuio => 'srctuio',
    iupweb => 'srcweb',
  );
  my %extralf = (
    iupwin => '',
    iupcd => '-L../cd/lib/$(BUILDNICK)',
    iupcontrols => '-L../cd/lib/$(BUILDNICK)',
    iupgl => '',
    iupim => '-L../im/lib/$(BUILDNICK)',
    iupimglib => '',
    iup_pplot => '-L../cd/lib/$(BUILDNICK)', 
  );
  return unless (scalar(@curlist) > 0);
  print STDERR "Flushing " . scalar(@curlist) . " " . scalar(@{$curlobjs}) . "\n";
  #print STDERR ">>> curtarget=$curtarget curlf=$curlf curmakefile=$curmakefile\n";
  if (scalar(@curlist) != scalar(@{$curlobjs})) {
    warn "###ERROR### objcount mismatch";
#    die Dumper(\@curlist);
  }    
  my @keeplist = @curlist;
  my $cf = (keys %{$flags1{$curtarget}})[0];
  if ($curmakefile eq 'iup') {
    $cf =~ s/-I([a-zA-Z])/-I$srcdir{$curtarget}\/$1/g;
    $cf =~ s/-I\.\.\//-I/g;
    $cf =~ s/-I. /-I$srcdir{$curtarget} /g;
    $curlf = "$extralf{$curtarget} $curlf" if $extralf{$curtarget};
  }
  (my $cfms = $cf) =~ s/-Wall//g;
  $cfms =~ s/-DHAVE_UNISTD_H -DHAVE_STDINT_H -DJAS_TYPES/-DJAS_WIN_MSVC_BUILD -DWIN32 -DJAS_TYPES/;
  $cfms .= " -DWIN32";
  
  push (@targets, { NAME  => $curtarget,
		CF    => $cf,
		CFMS    => $cfms,
 		LF    => $curlf,
		LNAME => $curlname,
		OBJS  => \@keeplist,
		LOBJS => join(' ', @{$curlobjs}),
         	SRC_PRE=> ($curmakefile eq 'iup') ? $srcdir{$curtarget} : '.',
	      });     
  @curlist = ();
}

sub flush_makefile {
  return unless $curtarget;
  print STDERR "Flushing Makefile for $curmakefile\n";
  my $cf = (keys %{$flags2})[0] || '';
  $cf =~ s/-DTEC_UNAME=[a-z0-9]+/-DTEC_UNAME=gcc4/;
  (my $cfms = $cf) =~ s/-DTEC_UNAME=[a-z0-9]+/-DTEC_UNAME=vc9/;
    my %data = (
      targets => \@targets,
      global => {
        COMPILER => "mingw",
        VER_OBJ => "version.o",
        VER_RC => "version.rc",
        CF => $cf,
	CFMS => $cfms,
        LF => '',
	LIB_PRE=> ($curmakefile eq 'iup') ? './lib' : '../lib',
	OBJ_PRE=> ($curmakefile eq 'iup') ? './obj' : '../obj',
	INC_PRE=> ($curmakefile eq 'iup') ? './' : '../',
	PRE_PRE=> ($curmakefile eq 'iup') ? '../' : '../../',
      },
    );
    $data{global}->{CF} =~ s/-DWin32=[0-9]\.[0-9]/-DWin\$(BUILDBITS)=5\.1/;
    $data{global}->{CF} =~ s/-DTEC_32/-DTEC_\$(BUILDBITS)/;
    $data{global}->{CF} =~ s/-DTEC_SYSNAME=Win32/-DTEC_SYSNAME=Win\$(BUILDBITS)/;    
    my $tt = Template->new();
    $tt->process('mingw.tt', \%data, "Makefile_$curmakefile.mingw");
    $tt->process('nmake.tt', \%data, "Makefile_$curmakefile.nmake");
}

open DAT, "<", $input;
while (<DAT>) {
  chomp;
  if ( /^curdir=(.*?)([^\/]*)(\/src)?$/) {
    my $tmp = $curtarget;
    my $newmakefile = $2;
    flush_target();
    flush_makefile();
    $curmakefile = $newmakefile;
    @targets = ();
    %flags1 = ();
    $flags2 = {};
    print STDERR "New makefile=$curmakefile\n";
  }
  elsif (/^Tecmake: Starting \[ ([^:]*)/) {
    flush_target();
    $curtarget = $fixtarget{$1} || $1;
    $curlname = $1;    
    $curlobjs = [];
    $curlf = '';    
    print STDERR "New target=$curtarget\n";
  }
  elsif (/^[^ ]*?ar rv ([^ ]*) (.*)$/) {
    $curlname = $1;
    $curlname =~ s|^.*/lib||;
    $curlname =~ s|(\.dll)?\.a$||;
    my @o = split / /, $2;
    $curlobjs = \@o;
  }
  #elsif (/^(gcc|g\+\+) (-shared).*? -o .*?([^\/]*?)\.dll .*?\.a * (.*?)( *-L[^ ]*)* (-l.*)$/) {
  elsif (/^[^ ]*?(gcc|g\+\+) (.*?) -o .*?([^\/]*?)\.dll .*?\.a * (.*?)(-L[^ ]*)* (-l.*)$/) {
    $curlf = $6;
    $curlname = $3;
    warn "l=$curlname";
    my @tmp = grep {/^[^-].*?\.o$/} split(' ', $4); 
    my @o = map { s|^(.*?/obj/).*?([^/]*)$|$2|; $_ } @tmp;
#    warn "###$curlf\n";
#    warn "###count=".scalar(@tmp).",".scalar(@o)."\n";
#    warn "###". Dumper(\@o);
    $curlobjs = \@o;
  }
  elsif (/^[^ ]*?(gcc|g\+\+) (.*?) (-DTEC.*?) -o ([^ ]*) ([^ ]*)$/) {
    $flags1{$curtarget}->{$2}++;
    $flags2->{$3}++;
    my $item = { COMPILER => $1, SRC => $5, OBJ_orig => $4 };  
    (my $o = $4) =~ s|^(.*?/obj/).*?([^/]*)$|$2|;
    $item->{OBJ} = $o; #extension .o
    $item->{OBJMS} = $o . "bj"; #extension .obj
    push( @curlist, $item);
  }
  elsif (/^g/ && !/^gdiplus/) {
    warn "LINE:$_";
  }
  elsif (/^ar (.*)$/) {
  }
}
flush_target();
flush_makefile();
