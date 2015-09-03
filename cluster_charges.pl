#!/usr/bin/perl -w 

use FileHandle;

%rates = (
	"all.q" => .03,
	"long.q" => .025,
	"express.q" => .05,
	"gen.q" => .0225,
	"commonj.q" => .0225,
	"commonp.q" => .0225,
);

sub init_usermap {
	open (USERLIST, "UserList.txt") || die "Can't open UserList.txt: $!";
	while (defined ($user = <USERLIST>)) {
		chomp($user);
		($userid, $user_name, $p_i_name, $fas_account) = split(/:/,$user);
		$usermap{$userid} = [$user_name, $p_i_name, $fas_account];
	}
	close (USERLIST) || die "Couldn't close UserList.txt: $!";
}

format STDOUT = 
@<<<<<<<<<<<<  @####.#  @>>>>>>>>     $@####.##   @<<<<<<
$userid, $hours, $queue, $charge, $fasnumber
.
format STDOUT_TOP = 
$%
         ELLIPSE Cluster Usage Summary

Userid         Hours     Queue        Charge      Acct
---------      -------   ---------    ---------   ------
.

# FIX :  Change to argv
$BEGINTIME="0711270000";
$ENDTIME="0712262359";
@ACCOUNTING_USERS = (`qacct -b $BEGINTIME -e $ENDTIME -o`); 

init_usermap();
my $PI_bill = ();
my $newtotal = ();
 
foreach $usageline (@ACCOUNTING_USERS){
	 $userid = (split /\s+/, $usageline)[0];
         next if $userid =~ m/^===/;
         next if $userid =~ m/^OWN/;
	@account_usage = `qacct -b $BEGINTIME -e $ENDTIME -o $userid -q`;
	@PI_namefield = (split /,/, $usermap{$userid}[1]);
	$PI_name = $PI_namefield[0];
	$PI_fullname = join ' ', $PI_namefield[1], $PI_namefield[0];
	$PI_fasnumber{$PI_name} = $usermap{$userid}[2];
	$PI_firstlast{$PI_name} = $PI_fullname;
	$total = 0;
	foreach $line (@account_usage){
		($queue,$wallclock) = (split /\s+/, $line)[0,2];
         	next if $line =~ m/^===/;
         	next if $line =~ m/^CLU/;
		$hours = $wallclock/3600;
		$charge = $hours * $rates{$queue};
		$fasnumber = $usermap{$userid}[2];
		@account_array = $billed_account{$fasnumber};
		push (@account_array, [$userid, $hours, $queue, $charge]); 
		$billed_account{$fasnumber} = @account_array;
		write;
		$total += $charge;
	}
	$PI_bill{$PI_name} = 0 unless exists $PI_bill{$PI_name};
	$newtotal = $total + $PI_bill{$PI_name};
	$PI_bill{$PI_name}= $newtotal;
} 

print "\n\nAccounts To Be Billed:\n";
print "----------------------\n\n";

foreach $key ( sort keys %PI_bill){
	next if $PI_fasnumber{$key} =~ m/0-00000/;
	printf "%s (%s) has \$%.2f in total cluster usages charges. \n", $PI_firstlast{$key}, $PI_fasnumber{$key}, $PI_bill{$key};
}

print "\n";

# END
