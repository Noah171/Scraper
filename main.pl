#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Tiny;
use JSON; # Imports json making functions
use Data::Dumper qw(Dumper);
use List::Util qw(first); # Import 'first' from core library List::Util which
use Encode;

# perl syntax is weird, so this is the only way to initialize the hash %validArgs;
my @options = ("-s", "-a", "-l");
my @funcs = (\&searchSites, \&saveSite, \&listSites);
my %validArgs;
@validArgs{@options} = @funcs;

my @sites = [];


#####################################################################################
#
# TODO
# o improve searchSites functionality.
# 
#####################################################################################


my $rootFolder = $ENV{HOME} . "/.local/site-searcher/"; # The HOME (~) folder of user
my $jsonFile = "sites.json";

sub main{
    my $option = "";
    my $func = undef;
    my $cmdLineArg = "";

    # Get the option the user is trying to invoke, always at position 0, check if
    # it is an accepted argument.
    # If the length of $option is zero, the string is empty
    $option = $ARGV[0];
    if (!defined($option) || unsortedSearch($option, \@options) == -1){
	print ("Error! That is not a valid option.\n");
	exit 1;
    }
    
    # Get the $option's associated function and assign it to $func
    $func = \&{$validArgs{$option}};
    # Get the argument to the option the person is trying to invoke
    if(defined($ARGV[1])){
	$cmdLineArg = $ARGV[1];
    } else {
	$cmdLineArg = "";
    }
    # Invoke function (This is how you invoke a function who has been assigne to a
    # scalar
    $func->($cmdLineArg);
    
}

sub makeDirectory{
    my ($directory) = @_;

    # -d checks to see if this is a valid directory path. If it is not, then make the
    # directory.
    if(!(-d $directory)){
	mkdir($rootFolder);
    }
}

# Downloads site information and returns the site's html
sub getHTML{

    my $url = $_[0];
    my $http = HTTP::Tiny->new(); # This is an object which acts as a nexus to get
    # html from some sites
    my %response; # HTTP GET response
    %response = %{$http->request("GET", $url)};
    return %response{content};
}

# Writes a single site into the JSON folder containing the list of sites,
# $rootFolder/site-list
sub saveSite{
    
    my $url = $_[0];

    my $json = undef;
    my $fh = undef;
    my $path = "";
    
    $path = $rootFolder . $jsonFile;
    
    makeDirectory($rootFolder);
    createFile($path);
    
    
    if(alreadySaved($url, $path) == -1){
	$json = encode_json($url);
	open($fh, ">>:encoding(utf-8)", $path) or die $!;
	$fh->write($json . "\n");
	close($fh);
    } else {
	print("The site $url has previously been added to the database!\n");
    }
}

# Checks to see if the object $obj has already been saved to the file $path in JSON
# format.
sub alreadySaved{

    my ($obj, $path) = @_;
    
    my $saved = 0; # flag for whether or not the object is already saved
    my @objects = ();
    @objects = unserializeJson($path);
    $saved = unsortedSearch($obj, \@objects);
    return $saved;
}

# Makes a file after checking to see if the file exists.
sub createFile{
    my ($path) = @_;

    unless (-e $path){               # Checks if the file at the path exists
	my $fh = undef;
	open ($fh, ">:encoding(utf-8)", $path) or die $!;   
	$fh->write("");
	close($fh);
    }
}

# determine if $arg is a memeber of @arr return -1 if failed
sub unsortedSearch{
    # $arg is what we are trying to determine to be a member of @arr
    my ($arg, @arr) = ($_[0], @{$_[1]});
    for (my $i=0; $i < scalar(@arr); ++$i){
	# If this passes, then $arg is a member of $arr, so return 1
	if ($arr[$i] eq $arg){ # eq is string equals
	    return $i;
	}
    }   
    return -1;
}

# Search sites listed in /.local/site-searcher/sites.json For the keyword which will
# be sent
sub searchSites{
    
    my ($keyword) = @_;
    my @urls = ();
    my @hitUrls = ();
    my @matches = ();

    my $path = "";
    $path = $rootFolder . $jsonFile;
    # Get a list of urls 
    @urls = unserializeJson($path);
    # Get the html from these websites.
    for my $site (@urls){
	my $html = getHTML($site);
	my $tempMatch = "";
	# Brackets around the regex and lvalue returns the keyword match as a
	# variable
	if (($tempMatch) = $html =~ /($keyword)/i){
	    push(@hitUrls, $site);
	    push(@matches, $tempMatch);
	}
    }
    print ("Sites with the desired keyword:\n");
    for(my $i = 0; $i < scalar(@hitUrls); ++$i){
	print( "[" . ($i+1) . "] - ", $hitUrls[$i]," " , $matches[$i] ,"\n");
    }
}

# Reads the entirety of a json file into an array, each element is a separate entry
# into the file
sub unserializeJson{
    my ($path) = @_;
   
    my $fh = undef;
    my $tempObj = ""; # One object from the json file,
    my @objects = ();
    
    open($fh, "<:encoding(utf-8)", $path) or die $!; # :encoding(UTF-8)
    
    while($tempObj = readline($fh)){
	$tempObj = decode_json($tempObj);
	push(@objects, $tempObj);
    }
    close ($fh);

    return @objects;
}

sub listSites{

    my $path = "";
    $path = $rootFolder . $jsonFile;
    
    my @sites = unserializeJson($path);
    for(my $i = 0; $i < scalar(@sites); ++$i){
	print("[", $i+1, "] ", $sites[$i], "\n");
    }
}

# Prints proper usage and exits program
sub printUsage{
    	print("\tError! The proper arguments: <option> <optional argument> <url>.\n\tValid options include:\n\t-s <argument>: search sites for argument.\n\t-a: to add sites to database.\n\t-l: list sites that are in search database.");
        exit 1;
}

main();
