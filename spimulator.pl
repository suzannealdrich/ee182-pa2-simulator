#!/usr/bin/perl

##############################################################
#  ____  ____ ___ __  __ _   _ _        _  _____ ___  ____   #
# / ___||  _ \_ _|  \/  | | | | |      / \|_   _/ _ \|  _ \  #
# \___ \| |_) | || |\/| | | | | |     / _ \ | || | | | |_) | #
#  ___) |  __/| || |  | | |_| | |___ / ___ \| || |_| |  _ <  #
# |____/|_|  |___|_|  |_|\___/|_____/_/   \_\_| \___/|_| \_\ #
# v. 1.01                                                    #
##############################################################
# Automatically convert MIPS assembly to int for reading by  #
# the simulator.s program.                                   #
# by Eric Silverberg - esilver@leland                        #
##############################################################

# instruction hash
%inst = (
    addi=>8,
    lw=>35,
    sw=>43,
    andi=>12,
    slti=>10,
    lui=>15,
    beq=>4,
    bne=>5,     

    jal=>3,

    add=>32,
    sub=>34,
    and=>36,
    sll=>0,
    slt=>42,
    jr=>8
);

# register hash
%reg = (
    "\$zero"=>0,
    "\$at"=>1,
    "\$v0"=>2,
    "\$v1"=>3,
    "\$a0"=>4,
    "\$a1"=>5,
    "\$a2"=>6,
    "\$a3"=>7,
    "\$t0"=>8,
    "\$t1"=>9,
    "\$t2"=>10,
    "\$t3"=>11,
    "\$t4"=>12,
    "\$t5"=>13,
    "\$t6"=>14,
    "\$t7"=>15,
    "\$s0"=>16,
    "\$s1"=>17,
"\$s2"=>18,
"\$s3"=>19,
"\$s4"=>20,
"\$s5"=>21,
"\$s6"=>22,
"\$s7"=>23,
"\$t8"=>24,
"\$t9"=>25,
"\$k0"=>26,
"\$k1"=>27,
"\$gp"=>28,
"\$sp"=>29,
"\$fp"=>30,
"\$ra"=>31
);

$inc = 0;
$currenti = 0;
%blocks;


# get the file
if ($ARGV[0] ne undef) { 
    $infile = $ARGV[0];
} else {
    print "File? ";
    $infile = <STDIN>;
    chop($infile);
}

open(FILE,"$infile");
while(<FILE>) {
    $cmd = $_;
    chop($cmd);

    # if it's not a commented line & it can find a word char
    if ($_ !~ /^(\s*)\#/ && $_ =~ /\w/) {

	$inc++;

	# if it finds a block, then make sure there is text on the line
	# before it increments $inc
	if ($cmd =~ /^(\s*)(\w+)\:/) {
	    
	    # if find a block then add it to our list. 
	    $blocks{$2} = $inc;

	    # if this line is just a block statement then we don't count
	    # it as a new instruction
	    if ($_ !~ /\:(\s*)\w/) {
		$inc-- ;

	    } 

	}
    }
    

}
close (FILE);


# Debug
# foreach (keys %blocks) { 
#    print $_ . " is a key for " . $blocks{$_} . "\n";
#}



open(FILE,"$infile");
while(<FILE>) {
    $cmd = $_;
    chop($cmd);
    $parsed = &ParseCmd($cmd);
    print  $parsed . "\n" if ($parsed ne "");
}
close (FILE);

exit();



# function that parses mips command

sub ParseCmd($) {
    my $cmd = $_[0];

    # don't parse comments
    if ($cmd =~ m/^(\s*?)\#/) {
	return "";
    }
    
    $cmd =~ s/(.*)?\#.*/$1/; # no comments
    $cmd =~ s/.*?\:(.*)/$1/; # no blocks
    
    $cmd =~ s/^\s*(.*)/$1/; # no leading spaces

    my @cmda = split /[\s,]+/, $cmd; # split into array based on , and space

# debug
#    foreach (@cmda) {
#	print "$_ is cmd\n";
#    }

    # better find some words in the cmd after removing comments
    return unless ($cmd =~ /\w/);

    $currenti++; # inc inst. count

    if (&isItype($cmda[0])) {
	my $op = $inst{$cmda[0]} << 26;

	# sign checking
	if ($op >= 2147483648) { 
	    $op -= 2147483648; 
	    $op -= 2147483648; 
	}
	
	# lw and sw parameters

	if ($cmda[2] =~ /(.*?)\((.*)\)/) {
	    $cmda[2] = $2;
	    $cmda[3] = $1;
	}

#	print "cmd1 is " . $cmda[1];
#	print "rs is " . $cmda[2] . " - ". $reg{$cmda[2]}, "\n";
#	print "rt is " . $cmda[1] . " - ". $reg{$cmda[1]}, "\n";
#	print "three is " . $cmda[3]."\n";

	my ($rs,$rt,$addr);
	
	# if it's a branch, we do it differently
	if ($cmda[0] =~ /^b/) {
	     $rs = $reg{$cmda[2]} << 16;
	     $rt = $reg{$cmda[1]} << 21;
	     $addr = $cmda[3];

	# lui is different too
	} elsif ($cmda[0] =~ /^lui/) {

	    if ($cmda[2] =~ /^(0x.*)/) {
		$cmda[2] = hex($1);
	    }

	    $rs = 0;
	    $rt = $reg{$cmda[1]} << 16;


	    $addr = $cmda[2];

	# normal i type
	} else {
	     $rs = $reg{$cmda[2]} << 21;
	     $rt = $reg{$cmda[1]} << 16;
	     $addr = $cmda[3];

	}


	# translate blocks into relative addresses
	if ($addr =~ /[a-zA-Z]/) {
	    $addr = ($blocks{$addr} - ($currenti + 1));
	    
	}
	
	$addr = $addr & 65535; # take only first 16 bits


	return $op + $rs + $rt + $addr;

    # process j type
    } elsif (&isJtype($cmda[0])) {

	my $op = $inst{$cmda[0]} << 26;
	my $addr = $cmda[1];

	# translate block into exact address
	if ($addr =~ /[a-zA-Z]/) {
	    $addr = $blocks{$cmda[1]} - 1;
	}

	return $op + $addr;

    # r type
    } else {
	
	# get funct code
	my $funct = $inst{$cmda[0]};

	my $rs = $reg{$cmda[2]} << 21;
	my $rt = $reg{$cmda[3]} << 16;
	my $rd = $reg{$cmda[1]} << 11;

	
	# special cases for sll, jr
	if ($cmda[0] =~ /^sll$/i) {
	    my $shamt = $cmda[3] << 6;
	    $rt = $reg{$cmda[2]} << 16;
	    return $rt + $rd + $shamt + $funct;
	} elsif ($cmda[0] =~ /^jr$/i) {
	    $rt = $reg{$cmda[1]} << 21;
	    return $rt + $funct;
	} else {
	    # normal case
	    return $rs + $rt + $rd + $funct;
	}
    }
}

# detect if it's an i-type
sub isItype($) {
    return $_[0] =~ m/(addi|lw|sw|andi|slti|lui|beq|bne)/i;
}

# detect if it's a j-type
sub isJtype($) {
    return $_[0] =~ m/jal/i;
}

