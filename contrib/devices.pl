#!/usr/bin/perl
#
# This script builds grep'able text files to allow users 
# to look up device information quickly from the command
# line
# 
#
use strict;
use lib "/usr/local/netdot/lib";
use Netdot::UI;
use Data::Dumper;

my $ui = Netdot::UI->new();

my $DIR = "/usr/local/netdot/export";

my $DEBUG = 0;

my %tree = ( 
	     Switch => {
			file => "$DIR/switches.txt"
			},
	     Hub    => {
			file => "$DIR/10baseThubs.txt"
			},
	     'Access Point'    => {
			file => "$DIR/wireless.txt"
			},
	     'Console Server'    => {
			file => "$DIR/consoles.txt"
			},
	    );

foreach my $dt (keys %tree){
    my ($type, @products, @devices);
    open (FILE, ">$tree{$dt}{file}") 
	or die "Couldn't open $tree{$dt}{file}: $!\n";
    select (FILE);
    unless ($type = (ProductType->search (name => "$dt"))[0]){
	warn "Couldn't find object for ProductType $dt\n)";
	next;
    }
    unless ( @products = $type->products ){
	warn "Couldn't find any products of type $dt\n)";
	next;
    }
    foreach my $product ( @products ){
	my $name = $product->name;
	if ( my @devs = $product->devices ){
	    warn "Found ", scalar @devs, " $name devices\n" if $DEBUG;
	    push @devices, @devs;
	}else{
	    warn "No $name devices found in DB\n" if $DEBUG;
	}
    }
    unless ( scalar @devices ){
	warn "No $dt devices found\n";
    }
    print "            ****        THIS FILE WAS GENERATED FROM A DATABASE         ****\n";
    print "            ****           ANY CHANGES YOU MAKE WILL BE LOST            ****\n";
    print "\n  Generated by $0 on ", scalar(localtime), "\n\n\n";
    
    
    foreach my $o ( sort { $a->name->name cmp $b->name->name } @devices ){
	my $name = $o->name->name;
	print $name, " -- Building: ", $o->site->name, "\n";
	print $name, " -- Room:", $ui->getobjlabel($o->room, ", "), "\n" if ( $o->room );
	print $name, " -- Rack:", $o->rack, "\n" if ( $o->rack );
	if ( $o->productname ){
	    print $name, " -- Model: ", $o->productname->name, "\n";
	    if ( $o->productname->manufacturer ){
		print $name, " -- Manufacturer: ", $o->productname->manufacturer->name, "\n";
	    }
	}
	print $name, " -- s/n: ", $o->serialnumber, "\n" if ( $o->serialnumber );
	my $info = $o->info;
	$info  =~ s/\n/\n$name -- Info: /g;
	$info  =~ s/\r//g;  
	print "$name -- Info: $info\n";
	
	foreach my $p ( sort { $a->number <=> $b->number } $o->interfaces ){
	    my $descr = $p->description;
	    $descr  =~ s/\n//g;
	    my $link;
	    if ( my $parentdep = ($p->parents)[0] ){
		if ( $parentdep->parent->device && $parentdep->parent->device->name 
		     && $parentdep->parent->device->name->name ){
		    my $port = $parentdep->parent->number;
		    $link = $parentdep->parent->device->name->name . ".[$port]";
		}
	    }elsif ( my $childdep = ($p->children)[0] ){
		if ( $childdep->child->device && $childdep->child->device->name
		     && $childdep->child->device->name->name ){
		    my $port = $childdep->child->number;
		    $link = $childdep->child->device->name->name . ".[$port]";
		}
	    }
	    print $name, ", port ", $p->number, ", ", $p->name, ", ", $p->room_char, ", ", $p->jack_char, ", $descr",
	          ", ", $link, "\n";
	}
	print "\n";
    }
    close (FILE);
}
