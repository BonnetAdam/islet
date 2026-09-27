# Runs IsletMediaBridge inside /usr/bin/perl, which macOS allows to read what is playing.
# Usage: /usr/bin/perl media-bridge.pl /path/to/libIsletMediaBridge.dylib
use strict;
use warnings;
use DynaLoader;

my $library = shift @ARGV or die "usage: media-bridge.pl LIBRARY\n";
my $handle = DynaLoader::dl_load_file($library, 0) or die DynaLoader::dl_error();
my $symbol = DynaLoader::dl_find_symbol($handle, "islet_media_run") or die DynaLoader::dl_error();
DynaLoader::dl_install_xsub("main::islet_media_run", $symbol);
islet_media_run();
