#!/usr/bin/perl

#This script will generate two breeding files a) Nestling raw data b) Breeding Data File ** notes will go in a separate file 
# notes will use a hash consisting of a concatenated box # and elevation (key) + note (value)

####   COMMAND LINE: a) Year for filename b) note file *bnotes.txt c) file for new & old bands d)text files from boxes to read in #######

use strict; use warnings;
use List::Util 'sum';

my $y  = shift @ARGV;		#Here $y will be whatever year this pertains to
my $NO = shift @ARGV;		# This is a text file of new & old ids for birds that we have replaced PIT tags on... format is New\tOld, with a header line
my $nA = shift @ARGV;		# $nA & $nB are the notes files for H & L, I had to assign these to separate scalars
my $nB = shift @ARGV;		# because shifting off from the ARGV array only includes one note file and treats the second one as a box file
my $in = @ARGV;				#should select all files *2016.TXT in the proper directory, these are the individual box files

open (JULDATE, "< JulianDates.txt")		or die "Couldn't open Julian Dates\n";			 #file w/ mm/dd	julian date for non-leap years
open (LEAPJUL, "< LEAPjulianDates.txt") or die "Couldn't open Julian Leap Year Dates\n"; #these are the julian dates for leap years

my %juldates;
my %leapdates;
my %nnot;

#The two following hashes will be used to assign the proper julian date to the 1st egg date in the master breeding file.  
#The hashes use the year to determine if it should match using the leap year dates or non-leap year dates

while (<JULDATE>) {						#So here I am making 2 hashes, they will have mm/dd (key) and julian date (value)
	chomp;								#I will match the proper hash using a conditional b/c one is for regular years
	my @jcol = split ("\t", $_);		#while the other is for leap years 
	$juldates{$jcol[0]} = $jcol[1];
}
close (JULDATE);

while (<LEAPJUL>) {						#This is my leap year hash
	chomp;
	my @lcol = split ("\t", $_);
	$leapdates{$lcol[0]} = $lcol[1];
}
close (LEAPJUL);


#This code will take the Elevation and Year from the title of the note file and concatenate it with the box number to create a 
#unique key that will have NO repeats (to avoid duplicate keys which would get deleted)
#Later I create matching concatenated box_elevation_year IDs that can match with this hash. 
#The values here are simply the note ($nlin[1]). This hash will be used to append the note (here the hash value) to the breeding file

my %olds;

open (NO, "< $NO") or die "Couldn't open NewOld Band file\n";
<NO>;

while (<NO>) {
	chomp;
	my @no_lin = split("\t", $_);
	$olds{$no_lin[1]} = $no_lin[0];
}

close(NO);

my @notes;
push(@notes, $nA, $nB);				# I need to push both note files to an array so I can loop through them and create a hash using both files

foreach my $note (@notes) {										#looping through the elements of the array (here the two note files)
	open (NOTE, "< $note") or die "Couldn't open Notes Files\n";
		$note     =~ m/(\w)_(\d{4})_\S+/;							#This involves using E_YYYY_bnotes.txt eg. L_2017_bnotes.txt
		my $nelev = $1;											#extracting the elevation from the filename & assigning to scalar
		my $nyr	  = $2;											#extracting the year from filename & assigning to scalar 
		
		while (<NOTE>) {										#line by line w/in each note file....
			chomp;
			my @nlin    = split(/\t|\n/, $_);					#splitting each line into its two components (box id & note)
			my $nID     = join ("_", $nlin[0], $nelev, $nyr);	#creating a unique ID, see lines 41-44 for explanation 
			$nnot{$nID} = $nlin[1];								#hash construction where unique ID is the key & the note is the value
		}
		
	close(NOTE);
}



open (BBOUT, "> nestlings$y.txt") or die "Couldn't open nestlings file!\n"; #This will be the nestling file
open (OUT, 	 "> breeding$y.txt" ) or die "Couldn't open breeding file!\n";  #This is the breeding file

print BBOUT "YEAR\tDATE\tELEVATION\tNEST\tNEST.TYPE\tID\tBID\tMASS\tAS.RIGHT\tAS.LEFT\tNOTES\n";		#Here I'm just creating headers for each of my out files
print OUT   "YEAR\tBOX\tELEVATION\tNEST.TYPE\tM.RFID\tF.RFID\tFIRST.EGG\tJ.FIRST.EGG\tCLUTCH\tBROOD\tMEANMASS\tCV\tNOTES\n";  



foreach my $in (@ARGV) {
	open (IN, "< $in") or die "Couldn't open $in\n";
	
	my $box;
	my $nbox;
	my $elev;
	my $year;
	my $condition;
	my $uniqID;
	my @masses;
	my $male;
	my $female;
	my $eggdate;
	my $jdate;
	my $avg;
	my $cv;
	my $not;
	
	
	if ($in =~ m/(\w{1,4}|\w{1,2}\-\w{1,2})_(\w)_(\d{4})_(\S+)\.TXT/) {
		$box       = $1;						#storing elements from filename in scalars
		$elev      = $2;
		$year      = $3;
		$condition = $4;
		$nbox	   = join ("_", $box, $condition);
		$uniqID    = join ("_", $box, $elev, $year, $condition);
		
	} else {
	
		$in =~ m/(\w{1,4}|\w{1,2}\-\w{1,2})_(\w)_(\d{4})\.TXT/;	#Grabbing nest id, elevation, & year from each filename
	
		$nbox 	   = $1;						#storing elements from filename in scalars
		$elev 	   = $2;
		$year 	   = $3;
		$condition = 'INITIAL';
		$uniqID    = join ("_", $nbox, $elev, $year); #This unique ID will be used to match the IDs in the note hash to print out notes
	}
	
	my @lin1 = split(/\s/, <IN>);			#strips the 1st line from each box file
						
	if (exists $olds{$lin1[0]}) {
		$male = $olds{$lin1[0]};	# looking to swap any old IDs with new IDs for males
	} else {
		$male = $lin1[0];		# if the PIT tag hasn't been replaced, assigning Male RFID from 1st line to this scalar
	}
	if (exists $olds{$lin1[1]}) {
		$female = $olds{$lin1[1]};
	} else {
		$female = $lin1[1];		# if PIT tag hasn't been replaced, assigning Female RFID from 1st line to this scalar
	}
	
	my $egg     = $lin1[2];					#assigning First Egg date from 1st line to this scalar (add year to this later)
	my $clutch  = $lin1[3];					#assigning Clutch from 1st line to this scalar
	my $brood   = $lin1[4];					#assigning Brood from 1st line to this scalar
	
	if ($male !~ /(\w{10})/) { 
		die "$male RFID not 10 digits long in $in\n" unless ($male =~ m/(NA)|(UNBANDED)|(SILVER)|(UNKNOWN)/);
	}										#this and the following die statement will help check for type-os in RFIDs
	
	if ($female !~ /(\w{10})/) {
		die "$female RFID not 10 digits long in $in\n" unless ($female =~ m/(NA)|(UNBANDED)|(SILVER)|(UNKNOWN)/);
	}
	
	if ($egg =~ m/(NA)/) {					#this just adds the year to the mm/dd stored in the box file
		$eggdate = "NA";
	} else {
		$eggdate = join("/",$egg,$year);
	}
		
	if ($egg =~ m/(NA)/) {					#here I'm assigning julian dates by matching mm/dd with my julian date hashes
		$jdate = "NA";
	} elsif ((($year % 4 == 0) && ($year % 100 != 0)) or ($year % 400 == 0)) { #this checks to see if the year is a leap year
		$jdate = $leapdates{$egg};
	} else {
		$jdate = $juldates{$egg};
	}
	
	if (exists $nnot{$uniqID}) {			#matching with the note hash here and assigning values to the $not 
			$not = $nnot{$uniqID};
	} else {
		$not = "";							#this ensures that all lines will have the same number of elements
	}
	
	if ($brood =~ m/(NA)/) {				#escapes errors associated with lack of nestling masses, also ensures that only nests with nestlings will be included in nestling file
		$avg = "NA";
		$cv  = "NA";
	} else {									# here we are only dealing with nests that had a brood surviving to D16
		my @lin2 = split(/\s/, <IN>);			#strips the 2nd line from each box file
		my $nband   = join("/",$lin2[0],$year);	#assigning Nestling Band Date to this scalar & adding year
		my $prefix  = $lin2[1];					#assigning Silver Band Prefix to this scalar, I'll cat this with suffix for ID
		
		while (<IN>) { 							#Now that we've assigned all values to our first lines, we are ready to loop through the nestling data
			chomp;
			my $ID;
			my $ASR;		# this for fluctuating asymmetry (AS). Here this is on the right side
			my $ASL;		# Here this is on the left side
			my $fnote;
			
			my @cols = split(/\t|\n/, $_);
			
			if ($cols[0] =~ m/(\w{10})/) {				#this conditional is in place to deal with nests where we started a new silver
				$ID   = $cols[0];						#band string that has a different prefix from the one that we began with
			} else {
				$ID   = join("-", $prefix, $cols[0]);
			}
			
			my $BID   = $cols[1];						#Stores the blood IDs
			my $m     = $cols[2];						#stores masses
			
			if ($year < 2018) {
				$ASR   = "NA";
				$ASL   = "NA";
				$fnote = $cols[4];
			} else {
				$ASR   = $cols[3];
				$ASL   = $cols[4];
				$fnote = $cols[5];
			}
		
			print BBOUT "$year\t$nband\t$elev\t$nbox\t$condition\t$ID\t$BID\t$m\t$ASR\t$ASL\t$fnote\n";

			push (@masses, $m) unless ($m =~ m/(NA)/i);	#so here I'm pushing each mass to an array so I can loop through them in a little bit!
		}
		
		my $length = @masses;					#this returns the number of elements in the array sneaky sneaky
		my $total;
		my $diff;
		my $ctr;

		
		if ($length > 0) {
			$total  = sum @masses;
			$avg    = $total / $length;			#Sweet! I've got mean mass, noice
			$ctr    = 0;						#So I'm going to add stuff to this business
	
			foreach my $i (@masses) {			#Since we are still within the same file, we can loop through the mass array to do these calcs
				$diff = ($i-$avg)**2;
				$ctr += $diff;					#adding up all the ((individual mass)-(mean mass))^2
			}
		}
	
		my $sd;
	
		if ($length <= 1) {						#we can't calculate standard deviation or coefficient of variance with a brood of one
			$sd = "NA";
			$cv = "NA";
		} else {
			$sd = sqrt($ctr/($length-1));		#standard deviation
			$cv = $sd/$avg;						#allegedly this isn't the correct formula for coefficient of variance, but it is what we've been using in the past
		}
	}
	
	print OUT "$year\t$nbox\t$elev\t$condition\t$male\t$female\t$eggdate\t$jdate\t$clutch\t$brood\t$avg\t$cv\t$not\n";
	close(IN);
	
}
	
close (BBOUT);
close (OUT);
