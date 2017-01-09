#!/opt/local/bin/perl

use strict;
use warnings;
use JSON;
use Data::Dumper;
use File::HomeDir;
use IO::Pipe;
use Getopt::Long;


my $DEFAULT_CONFIG_DIR = File::HomeDir->my_home . "/.stalwart";
my $DEFAULT_CONFIG_FILE = "$DEFAULT_CONFIG_DIR/stalwart.config";

my $config_file = $DEFAULT_CONFIG_FILE;

GetOptions( "config=s" => \$config_file );


my $json_config = slurp( $config_file ) || die "Could not open config: $config_file";


my $config = decode_json( $json_config );

my $files  = $config->{files};
my $host   = $config->{host};


my $port     = exists $host->{port} ? " -p $host->{port}" : "";
my $identity = exists $host->{key}  ? " -i $host->{key}"  : "";
my $ssh      = "";

my $exclude  = "";
if ( exists $config->{exclude} )
{
  for ( @{$config->{exclude}} )
  {
    $exclude .= "--exclude=\"$_\" ";
  }
  $exclude =~ s/\s$//;
}

my $filelist = "";
for ( @$files )
{
  $filelist .= "$_ ";
}
$filelist =~ s/\s$//;

$ssh = "-e \"ssh$port$identity\" " if ( $port || $identity );

my $cmd = "rsync -av $ssh$exclude $filelist $host->{user}\@$host->{hostname}:$host->{destination}";

#print $cmd, "\n";
#exit(0);

my $pipe = IO::Pipe->new();

$pipe->reader( $cmd );

while( <$pipe> )
{
  print $_;
}



sub slurp
{
  my $filename = shift;
  local $/;
  open( my $fh, '<', $filename ) || die $!;
  my $text   = <$fh>;
  return $text;
}




__END__

date=`date "+%Y-%m-%dT%H_%M_%S"`
TARGET=/Users/sludin/tmp/rsync/protocol-acme
HOST=home2
USER=sludin

rsync -azP --delete  --delete-excluded \
  --exclude-from=$HOME/.rsync/exclude \
  --link-dest=../current \
  $TARGET $USER@$HOST:Backups/incomplete_back-$date \
  && ssh $USER@$HOST \
  "mv Backups/incomplete_back-$date Backups/back-$date \
  && rm -f Backups/current \
  && ln -s back-$date Backups/current"
