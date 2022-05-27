#!/usr/bin/perl

$notes = "usage: $0 lib ...

check load name of libs and fix if needed

";

die $notes if !@ARGV;

use File::Basename;

for my $lib ( @ARGV ) {
    $lib =~ s/\/$//;

    die "$lib doesn't appear to be a dylib (should be named .dylib)\n" if $lib !~ /\.dylib/;

    
    my $f = $lib;

    die "$f does not exist\n" if !-e $f;

    print "$f\n";

    ## otool analysis
    my $cmds;

    $f =~ s/\.app$//;
    die "$f does not exist\n" if !-e $f;
    
    my @deps = `otool -L $f | sed 1,2d | awk '{ print \$1 }'`;
    grep chomp, @deps; 

    for ( my $i = 0; $i < @deps; ++$i ) {

        my $d = $deps[$i];

        if ( $d =~ /^\/System\/Library\/Frameworks/ ) {
            next;
        }
        if ( $d =~ /^\/usr\/lib\// ) {
            next;
        }
        if ( $d =~ /^\@rpath\/(Qt|qwt\.|lib\/)/ ) {
            next;
        }

        print "$ba dep $d\n";

        if ( $d =~ /\.framework/ ) {
            $cmds .= "install_name_tool -change $d \@rpath/$d $f\n";
            next;
        }

        if ( $d =~ /^(\/opt|lib)/ ) {
            my $bd = basename( $d );
            $cmds .= "install_name_tool -change $d \@rpath/lib/$bd $f\n";
            next;
        }

        die "don't know what to do\n";
    }

    $cmds .= "codesign -fs - $f\n";
    print $cmds;
    print `$cmds`;
}