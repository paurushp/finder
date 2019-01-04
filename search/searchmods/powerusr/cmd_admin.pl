#!/usr/bin/perl --
use strict;
$::VERSION = '2.0.0.0073';
my $usage = <<"EOM";

Usage:

	cmd_admin.pl Password=MyPassword listrules
	cmd_admin.pl Password=MyPassword setrule "crawler: rogue" 1

	cmd_admin.pl Password=MyPassword listrealms

	cmd_admin.pl Password=MyPassword rebuild "My Realm 1"
	cmd_admin.pl Password=MyPassword rebuild "All"

	cmd_admin.pl Password=MyPassword add_url "My Realm 1" http://xav.com/
	cmd_admin.pl Password=MyPassword add_site "My Realm 1" http://xav.com/

	cmd_admin.pl Password=MyPassword create_realm
		"name=My Ream 2" file=file.txt type=1 base_url=x base_dir=y

	cmd_admin.pl Password=MyPassword delete_realm "My Realm 1"

Parameters wrapped for readability in final example.  Parameters must be
submitted in order.

This script is a general example of how to use FDSE as an API.

The Password parameter will be URL-decoded.  If your password contains a
literal '+' or '%' character, replace it with '%2B' or '%25' respectively.

Any parameter that contains an embedded space should be double-quoted.

To simulate the "Revisit Old" command instead of "rebuild", just add a
DaysPast parameter, i.e.:

	cmd_admin.pl Password=MyPassword rebuild "All" DaysPast=30

Realm types are:

type=1	open realm
type=2	file-fed realm; requires base_url
type=3	website realm, crawler; requires base_url
type=4	website realm, file system; requires both base params
type=5	runtime realm; requires both base params

In general, to index an entire web site, use the "create_realm" command and
follow it with a "rebuild" command.  The "add_site" command is an alternative
that can be used with open realms under very special circumstances.

EOM

my $FOLDER_CONTAINING_SEARCH = '../..';
my @POSSIBLE_FDSE_SCRIPT_NAMES = ( 'search.pl', 'search.cgi' );



# Step 1. general preparation:

	if ($ENV{'SERVER_SOFTWARE'}) {
		print "Warning: You have ENV SERVER_SOFTWARE defined. Unset it.\n";
		print "Content-Type: text/html\n\n";
		print "This script can only be called from the command-line.\n";
		exit;
		}
	unless ((@ARGV) and ($ARGV[0] =~ m!^Password=.+$!) and ($ARGV[1])) {
		print $usage;
		exit;
		}

	delete $ENV{'REMOTE_ADDR'};
	delete $ENV{'SERVER_SOFTWARE'};
	delete $ENV{'SCRIPT_NAME'};
	delete $ENV{'HTTP_HOST'}; # all needed to set $b_is_api


# Step 1a. force a chdir to the folder holding this script:

if ($0 =~ m!^(.*)(\\|/)!) {
	my $dir = $1;
	print "Local folder is '$dir'; attempting to chdir()\n";
	unless (chdir($dir)) {
		die "unable to chdir to local dir '$dir' - $!\n";
		}
	}

# Step 1b. force a chdir up two levels
unless (chdir($FOLDER_CONTAINING_SEARCH)) {
	die "unable to chdir to '$FOLDER_CONTAINING_SEARCH' - $!\n";
	}



# Step 2. define code to be executed inside of FDSE admin module:

use vars qw! $FDSE_CALLBACK_SUB !;



$FDSE_CALLBACK_SUB = <<'EOC';

	$::const{'is_cmd'} = 1;
	my $b_has_realm = 0;

	my $action = $ARGV[1] || '';

	if ($action eq 'listrealms') {
		my $p_realm_data = ();
		foreach $p_realm_data ($::realms->listrealms('all')) {
			print "Realm: $$p_realm_data{'name'}\n";
			$b_has_realm = 1;
			}
		unless ($b_has_realm) {
			print "No realms defined.\n";
			}

		}
	elsif ($action eq 'rebuild') {

		$::FORM{'Action'} = 'rebuild';
		if (lc($ARGV[2]) eq 'all') {

			my $p_realm_data = ();
			foreach $p_realm_data ($::realms->listrealms('all')) {
				delete $::FORM{'LimitSite'};
				delete $::FORM{'StartTime'};
				$::FORM{'Realm'} = $$p_realm_data{'name'};
				&ui_Rebuild();
				$b_has_realm = 1;
				}
			unless ($b_has_realm) {
				print "No realms defined.\n";
				}
			}
		else {
			$::FORM{'Realm'} = $ARGV[2];
			&ui_Rebuild();
			}

		}
	elsif ($action eq 'listrules') {

		foreach (sort keys %::Rules) {
			print "$_: $::Rules{$_}\n\n";
			}

		}
	elsif ($action eq 'setrule') {

		$err = &WriteRule( $ARGV[2], $ARGV[3] );
		next Err if ($err);
		}
	elsif ($action eq 'create_realm') {
		$::FORM{'is_update'} = 0;
		$::FORM{'Action'} = 'ManageRealms';
		$::FORM{'subaction'} = 'Create';
		$::FORM{'Write'} = 1;
		$::FORM{'orig_name'} = '';

		if ($ARGV[5] =~ m!^base_url=(.*)$!i) {
			$::FORM{'base_url' . $::FORM{'type'} } = $1;
			}
		if ($ARGV[6] =~ m!^base_dir=(.*)$!i) {
			$::FORM{'base_dir' . $::FORM{'type'} } = $1;
			}


		$err = &ui_ManageRealms();
		next Err if ($err);
		last Err;
		}
	elsif ($action eq 'delete_realm') {
		$::FORM{'Action'} = 'ManageRealms';
		$::FORM{'subaction'} = 'DeleteRealm';
		$::FORM{'Delete'} = $ARGV[2];
		$err = &ui_ManageRealms();
		next Err if ($err);
		last Err;
		}
	elsif ($action eq 'add_url') {
		&s_AddURL(0, $ARGV[2], $ARGV[3]);
		}
	elsif ($action eq 'add_site') {


		$::FORM{'Realm'} = $ARGV[2];
		$::FORM{'URL'} = $ARGV[3];

		$::FORM{'LimitSite'} = &get_web_folder( $::FORM{'URL'} );
		$::FORM{'StartTime'} = $::private{'script_start_time'} - 5;
		$::FORM{'Action'} = 'CrawlEntireSite';

		&s_AddURL(0, $::FORM{'Realm'}, $::FORM{'URL'} );

		my $b_is_complete = 0;
		while (1) {
			($err, $b_is_complete) = &s_CrawlEntireSite($::FORM{'Realm'});
			next Err if ($err);
			last if ($b_is_complete);
			}
		}
	else {
		$err = "action '$action' not recognized";
		next Err;
		}

EOC


# Step 3. Call FDSE as an API; FDSE will initialize and then execute the code in $FDSE_CALLBACK_SUB

push(@ARGV,'Mode=Admin');
$ENV{'FDSE_NO_EXEC'} = 1;
$0 = '';
Found: {
	foreach (@POSSIBLE_FDSE_SCRIPT_NAMES) {
		next unless (-e $_);
		require $_;
		last Found;
		}
	print "Error: unable to find FDSE script in $FOLDER_CONTAINING_SEARCH\n";
	print "Checked for " . join(',',@POSSIBLE_FDSE_SCRIPT_NAMES);
	}

