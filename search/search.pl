#!/usr/bin/perl --
#use warnings 'all';#if-debug
#use strict;#if-debug

=head1 copyright

Fluid Dynamics Search Engine

Copyright 1997-2005 by Zoltan Milosevic.  Please adhere to the copyright
notice and conditions of use, described in the attached help file and hosted
at the URL below.  For the latest version and help files, visit:

	http://www.xav.com/scripts/search/

This search engine is managed from the web, and it comes with a password to
keep it secure.  You can set the password when you first visit this script
using the special "Mode=Admin" query string - for example:

	http://my.host.com/search.pl?Mode=Admin

If you edit the source code, you'll find it useful to restore the function comments and #&Assert checks:

	cd "search/searchmods/powerusr/"
	hacksubs.pl build_map
	hacksubs.pl restore_comments
	hacksubs.pl assert_on

<h1>If you can see this text from a web browser, then there is a problem. <a
href="http://www.xav.com/scripts/search/help/1089.html">Get help here.</a></h1><xmp>

=cut

$::VERSION = '2.0.0.0073';
%::FORM = ();

my $all_code = "\n" x 36 . <<'END_OF_FILE';

my $err = '';
Err: {

	# initialize and schedule clean-up for package globals:
	$::realms = undef();
	%::private = %::FORM = %::const = %::Rules = @::str = ();
	@::sendmail = (
		'/usr/sbin/sendmail -t',
		'/usr/bin/sendmail -t',
		'/usr/lib/sendmail -t',
		'/usr/sendmail -t',
		'/bin/sendmail -t',
		);
	END {
		$::VERSION = $::realms = undef();
		%::private = %::FORM = %::const = %::Rules = @::str = @::sendmail = ();
		}

	# clear ENV for -T compatibility
	block: {
		last block if ( #changed 0072 mod_perl compat issue
			(exists $ENV{'GATEWAY_INTERFACE'} and $ENV{'GATEWAY_INTERFACE'} =~ /CGI-Perl/)
			or exists $ENV{'MOD_PERL'} );
		local $_;
		foreach ('IFS','CDPATH','ENV','BASH_ENV','PATH') {
			delete $ENV{$_} if (defined($ENV{$_}));
			}
		}

	binmode(STDOUT);

	#high-explosive hash option
#	tie(%::private,'FDSC::HEH');#if-debug
#	tie(%::Rules,'FDSC::HEH');#if-debug
#	tie(%::const,'FDSC::HEH');#if-debug

	%::private = (
		'antiword utility folder'  => "",
		'pdf utility folder' => "",
		'global_lockfile_count' => 1,
		'script_start_time' => time(),
		'visitor_ip_addr' => &query_env('REMOTE_ADDR'),
		'allow_admin_access_from' => '', # space-separated list of IP addresses or IP patterns
		'file_mask' => 0666,
		'needs_header' => 1,
		'trust_api' => 0,
		'html_footer' => '',
		'inline_elements' => qq!(a|abbr|acronym|applet|b|bdo|big|button|cite|dfn|em|embed|font|i|img|input|ins|kbd|label|noscript|object|q|rt|ruby|samp|select|small|span|strong|tt|u)!,
		'p_nc_cache' => 0,
		'http_headers' => '',
		);

	$::private{'PRINT_HTTP_STATUS_HEADER'} = 0;

	%::const = (
		'is_cmd' => 0,
		'help_file' => 'http://www.xav.com/scripts/search/help/',
		'copyright' => '<p style="text-align:center"><small>Powered by the<br /><a href="http://www.xav.com/scripts/search/">Fluid Dynamics<br />Search Engine</a><br />v' . $::VERSION . '<br />&copy; 2005</small></p>',
		);

	# Give the folder where all data files are located
	# See http://www.xav.com/scripts/search/help/1138.html about changing this value:

	$err = &load_files_ex( '.' );
	next Err if ($err);


	my $terms = '';
	foreach ('Terms','terms','q') {
		next unless exists $::FORM{$_};
		$terms = $::FORM{$_};
		last;
		}
	$::FORM{'Terms'} = $::FORM{'terms'} = $::FORM{'q'} = $terms;
	$::const{'terms'} = &he($::FORM{'Terms'});
	$::const{'terms_url'} = &ue($::FORM{'Terms'});

	# create self-reference string:

	my $sn = &query_env('SCRIPT_NAME');
	$sn =~ s!^.*/(.+?)$!$1!s;

	if (exists $::FORM{'search_url'}) {
		$sn = &he($::FORM{'search_url'});
		}

	$::const{'script_name'} = $::const{'search_url'} = $sn;
	$::const{'admin_url'} = $sn . '?Mode=Admin';
	$::const{'search_url_ex'} = $sn . '?';

	# support persistent fields and secondary queries
	my ($n,$v);
	while (($n,$v) = each %::FORM) {
		next unless ($n =~ m!^p:!s);
		$::const{'search_url_ex'} .= &ue($n) . '=' . &ue($v) . '&amp;';

		if ($n =~ m!^p:t:!s) { $::const{$n} = $v; } # changed 0053 - persistent/template namespace

		next unless ($n =~ m!^p:q(\d+)$!s);

		#changed 0064 - prepend, append

		next unless (length($v));
		if ((exists($::FORM{"p:pq$1"})) and (exists($::FORM{"p:aq$1"}))) {
			$terms .= ' ' . $::FORM{"p:pq$1"} . $v . $::FORM{"p:aq$1"};
			}
		else {
			$terms .= ' ' . $v;
			}
		}


	# are we being called from a PHP/ASP/CFM parent?

	my $b_is_shell_include = ((exists($::FORM{'is_shell_include'})) and ($::FORM{'is_shell_include'} eq '1')) ? 1 : 0;

	my $address_offer = '';
	AddressAsTerm: {
		last unless ($::Rules{'handling url search terms'} > 1);
		last if ($b_is_shell_include);
		last if ($terms =~ m!\s!s);
		my $address = '';
		if ($terms =~ m!^(http|ftp|https|telnet)://(\w+)\.(\w+)(.*)$!s) {
			$address = $terms;
			}
		elsif ($terms =~ m!^www\.(\w+)\.(\w+)(.*)$!is) {
			$address = "http://$terms";
			}
		if ($address) {
			$address_offer = '<p>' . &pstr(23, &he($address, $address) ) . '</p>';
			if ($::Rules{'handling url search terms'} == 3) {
				&header_print( "Location: $address" );
				print $address_offer;
				last Err;
				}
			}
		}



	if (exists($::FORM{'NextLink'})) {
		#changed 0034 - fixes bug where NextLink contains &
		if (&query_env('QUERY_STRING') =~ m!^NextLink=(.*)$!s) {
			$::FORM{'NextLink'} = $1;
			}
		my $html_link = &he($::FORM{'NextLink'});
		# security re-director from admin screen (prevents query-string-based
		# password from showing up in referer logs of remote systems:
		&header_print();
		print qq!<head><meta http-equiv="refresh" content="0;url=$html_link"></head><a href="$html_link">$html_link</a>!;
		last Err;
		}


	# changed 0067
	my $Realm = 'All';
	block: {

		last unless exists $::FORM{'Realm'};

		if ($::FORM{'Realm'} eq '') {
			$Realm = 'All';
			}
		elsif (($::FORM{'Realm'} eq 'All') or ($::FORM{'Realm'} eq 'include-by-name')) {
			# reserved names; ok
			$Realm = $::FORM{'Realm'};
			}
		else {
			# explode if invalid $Realm param is passed, but special-case for All include-by-name and empty
			my $p_realm;
			($err, $p_realm) = $::realms->hashref( $::FORM{'Realm'} );
			next Err if ($err);
			$Realm = $::FORM{'Realm'};
			}

		}


	$::const{'realm'} = &he($Realm);

	if ($::FORM{'Mode'} eq 'Admin') {
		$err = &admin_main();
		next Err if ($err);
		last Err;
		}

	if (($b_is_shell_include) and (not $ARGV[0])) {
		$err = "the 'is_shell_include' parameter can only be set when this script is being called from the command line";
		next Err;
		}

	if ($b_is_shell_include) {
		$::private{'needs_header'} = 0;
		}



	$::const{'copyright'} =~ s!<br />! !sg;

	&header_print();

	#changed 0058 - hard validate
	if ((exists($::FORM{'Match'})) and length($::FORM{'Match'})) {
		if ($::FORM{'Match'} =~ m!^(0|1|2)$!s) {
			# ok
			}
		else {
			my $hval = &he($::FORM{'Match'});
			$err = "parameter 'Match' value '$hval' is invalid. Must be 0, 1 or 2";
			next Err;
			}
		}
	else {
		$::FORM{'Match'} = $::Rules{'default match'};
		}
	if ((exists($::FORM{'maxhits'})) and length($::FORM{'maxhits'})) {
		if (($::FORM{'maxhits'} =~ m!^\d+$!s) and ($::FORM{'maxhits'} > 0)) {
			# ok
			}
		else {
			my $hval = &he($::FORM{'maxhits'});
			$err = "parameter 'maxhits' value '$hval' is invalid. Must be a positive integer";
			next Err;
			}
		}
	else {
		$::FORM{'maxhits'} = $::Rules{'hits per page'};
		}



	#changed 0058
	if (($::Rules{'logging: display most popular'}) and ($::Rules{'use dbm routines'})) {
		eval {
			my %str_t20 = ();

			dbmopen( %str_t20, 'dbm_strlog_top', 0666 ) || die &pstr( 43, 'dbm_strlog_top', $! );

			$::const{'t_since'} = &FormatDateTime( $str_t20{'++'}, $::Rules{'ui: date format'} );
			my $count = 1;
			foreach (sort { $str_t20{$b} <=> $str_t20{$a} || $a cmp $b } keys %str_t20) {
				next if (m!^\++$!s);
				$::const{ 'tu' . $count } = &ue( &hd($_) );
				$::const{ 'th' . $count } = $_;
				$::const{ 'c' . $count } = $str_t20{$_};
				$::const{'c'.$count}++ if ($::const{'terms'} eq $_);#tweakui
				$count++;
				last if ($count > $::Rules{'logging: display most popular'});
				}
			for ($count..$::Rules{'logging: display most popular'}) {
				$::const{ 'tu' . $_ } = '';
				$::const{ 'th' . $_ } = '';
				$::const{ 'c' . $_ } = '';
				}
			};
		if ($@) {
			&ppstr(53, &pstr(20, &he($@), "$::const{'help_file'}1169.html" ) );
			}
		}



	#changed 0046
	if ($::FORM{'Mode'} eq 'SearchForm') {
		print &str_search_form($::const{'search_url'});
		last Err;
		}

	unless ($b_is_shell_include) {
		# build and print header:
		&PrintTemplate(0, 'header.htm', $::Rules{'language'}, \%::const);
		$| = 0;
		}

	# build and queue footer:

	if (($::Rules{'allowanonadd'}) and ($::realms->realm_count('has_no_base_url')) and (not $::private{'is_freeware'})) {
		# print: Search Tips - Add New URL - Main Page
		$::private{'html_footer'} = &PrintTemplate(1, 'linkline2.txt', $::Rules{'language'}, \%::const);
		}
	else {
		# print: Search Tips - Main Page
		$::private{'html_footer'} = &PrintTemplate(1, 'linkline1.txt', $::Rules{'language'}, \%::const);
		}

	unless ($b_is_shell_include) {
		$::private{'html_footer'} .= &PrintTemplate(1, 'footer.htm', $::Rules{'language'}, \%::const);
		}


	if ($::FORM{'Mode'} eq 'AnonAdd') {
		$err = &anonadd_main();
		next Err if ($err);
		last Err;
		}

	if (not ($::FORM{'Terms'})) {
		$::const{'query_example'} = $::str[46];
		$::const{'url_query_example'} = &ue($::const{'query_example'});
		print &str_search_form($::const{'search_url'});
		&PrintTemplate(0, 'tips.htm', $::Rules{'language'}, \%::const);
		last Err;
		}

	print $address_offer;

	my $Rank = 1;
	if (defined($::FORM{'Rank'})) {
		if (($::FORM{'Rank'} =~ m!^\d+$!s) and ($::FORM{'Rank'} > 0)) {
			$Rank = $::FORM{'Rank'}; # fixed 0060
			}
		else {
			my $hval = &he($::FORM{'Rank'});
			$err = "parameter 'Rank' value '$hval' is invalid. Must be a positive integer";
			next Err;
			}
		}
	my $b_substring_match = $::Rules{'default substring match'};
	if (defined($::FORM{'p:ssm'})) {
		if ($::FORM{'p:ssm'} =~ m!^(0|1)$!s) {
			$b_substring_match = $1;
			}
		else {
			my $hval = &he($::FORM{'p:ssm'});
			$err = "parameter 'p:ssm' value '$hval' is invalid. Must be 0 or 1";
			next Err;
			}
		}

	my ($bTermsExist, $Ignored_Terms, $Important_Terms, $DocSearch, $RealmSearch) = &parse_search_terms($terms, $::FORM{'Match'}, $b_substring_match);

	#changed 0042 - persist maxhits
	my $linkhits = $::const{'search_url_ex'} . 'Realm=' . &ue($::FORM{'Realm'}) . "&amp;Match=$::FORM{'Match'}&amp;Terms=" . &ue($::FORM{'Terms'}) . '&amp;';

	if ($::FORM{'sort-method'}) {
		$linkhits .= 'sort-method=' . &ue($::FORM{'sort-method'}) . '&amp;';
		}


	my ($pages_searched, @HITS, $p_realm_data, $DD, $MM, $YYYY, $FBYTES) = (0);

#printf("<h2>Init + prep: user time: %s; system time: %s</h2>", times());

	Search: {
		next Search unless ($bTermsExist);

		#changed 0042 -- added support for include-by-name

		# include runtime realms:
		if ($Realm eq 'include-by-name') {
			foreach $p_realm_data ($::realms->listrealms('is_runtime')) {
				next unless ($::FORM{"Realm:$$p_realm_data{'name'}"});
				$linkhits .= "Realm:$$p_realm_data{'url_name'}=1&amp;";
				$::const{'record_realm'} = $$p_realm_data{'url_name'};
				&SearchRunTime($p_realm_data, $DocSearch, \$pages_searched, \@HITS);
				}
			}
		elsif ($Realm eq 'All') {
			foreach $p_realm_data ($::realms->listrealms('is_runtime')) {
				$::const{'record_realm'} = $$p_realm_data{'url_name'};
				&SearchRunTime($p_realm_data, $DocSearch, \$pages_searched, \@HITS);
				}
			}
		else {
			($err, $p_realm_data) = $::realms->hashref($Realm);
			next Err if ($err);
			if ($$p_realm_data{'is_runtime'}) {
				$::const{'record_realm'} = $$p_realm_data{'url_name'};
				&SearchRunTime($p_realm_data, $DocSearch, \$pages_searched, \@HITS);
				last Search;
				}
			}

		# include indexed realms:

		if ($Realm eq 'include-by-name') {
			foreach $p_realm_data ($::realms->listrealms('has_file')) {
				next unless ($::FORM{"Realm:$$p_realm_data{'name'}"});
				$linkhits .= "Realm:$$p_realm_data{'url_name'}=1&amp;";
				$::const{'record_realm'} = $$p_realm_data{'url_name'};
				&SearchIndexFile($$p_realm_data{'file'}, $RealmSearch, \$pages_searched, \@HITS);
				}
			}
		elsif ($Realm ne 'All') {
			($err, $p_realm_data) = $::realms->hashref($Realm);
			next Err if ($err);
			$::const{'record_realm'} = $$p_realm_data{'url_name'};
			&SearchIndexFile($$p_realm_data{'file'}, $RealmSearch, \$pages_searched, \@HITS);
			}
		else {
			foreach $p_realm_data ($::realms->listrealms('has_file')) {
				$::const{'record_realm'} = $$p_realm_data{'url_name'};
				&SearchIndexFile($$p_realm_data{'file'}, $RealmSearch, \$pages_searched, \@HITS);
				}
			}
		}

#printf("<h2>Search complete: user time: %s; system time: %s</h2>", times());

	my ($HitCount, $PerPage, $Next) = (scalar @HITS, $::FORM{'maxhits'}, 0);
	$linkhits .= 'maxhits=' . $PerPage . '&amp;';
	my $Remaining = $HitCount - $Rank - $PerPage + 1;
	my $RangeUpper = $Rank + $PerPage - 1;

	if ($Remaining >= $PerPage) {
		$Next = $PerPage;
		}
	elsif ($Remaining > 0) {
		$Next = $Remaining;
		}
	else {
		$RangeUpper = $HitCount;
		}

	my @Ads = &SelectAdEx();
	print $Ads[0];

	print &str_search_form($::const{'search_url'}) if ($::Rules{'ui: search form display'} % 2);

	print '<p class="fd_results"><b>' . $::str[10] . '</b><br />';

	if ($Ignored_Terms) {
		&ppstr(11, &he($Ignored_Terms));
		}

	if ($HitCount) {
		&ppstr(12, &he($Important_Terms), $pages_searched);
		}
	else {
		&ppstr(13, &he($Important_Terms), $pages_searched);
		}

	print '<br />';

	print $Ads[1];

	PrintHits: {
		if ($HitCount < 1) {
			# print: No documents found
			print qq!</p><p class="fd_results">$::str[19]</p>\n!;
			last PrintHits;
			}

		# print: Results $Rank-$RangeUpper of $HitCount
		&ppstr(14, $Rank, $RangeUpper, $HitCount );

		print '</p>';

		my ($jump_sum, $jumptext) = &str_jumptext( $Rank, $PerPage, $HitCount, $linkhits . 'Rank=', 1 );
		# $jump_sum = "Documents 1-10 of 15 displayed."
		# $jumptext = "<p><- Previous 1 2 3 4 5 Next -></p>"

		my $i = $Rank;
		foreach ((sort @HITS)[($Rank-1)..($RangeUpper-1)]) {
			next unless (m!^\d+\.(\d+)\.(\d+)\s*\d*\s*\d* u= (.+) t= (.*?) d= (.*?) c= (.*?) r= (.*?)$!s);
			($DD, $MM, $YYYY, $FBYTES) = (unpack('A2A2A2A4A*',$2))[1..4];
			my $relevance = 10E6 - $1;
			print &StandardVersion(
				'relevance' => $relevance,
				'redirector' => $::Rules{'redirector'},
				'rank' => $i,
				'url' => $3,
				'title' => $4,
				'description' => $5,
				'size' => $FBYTES,
				'dd' => $DD,
				'mm' => $MM,
				'yyyy' => $YYYY,
				'context' => $6,
				'record_realm' => &he(&ud($7)),
				);
			$i++;
			}
		print $jump_sum;
		print $jumptext;
		}
	print $Ads[2];
	print &str_search_form($::const{'search_url'}) if ($::Rules{'ui: search form display'} > 1);
	print $Ads[3];
	$err = &log_search( $Realm, $terms, $Rank, $HitCount, $pages_searched );
	next Err if ($err);

#printf("<h2>Display complete: user time: %s; system time: %s</h2>", times());

	last Err;
	}
continue {
	&header_print();
	if ($::str[29]) {
		print &pstr(29,$err);
		}
	else {
		print "<p><b>Error:</b> $err.</p>\n"; # still print meaningful errors when $::str[] fails to load
		}
	}
print $::private{'html_footer'};


sub query_env {
	my ($name,$default) = @_;
	if (($ENV{$name}) and ($ENV{$name} =~ m!^(.*)$!s)) {
		return $1;
		}
	elsif (defined($default)) {
		return $default;
		}
	else {
		return '';
		}
	}


sub untaintme {
	my ($p_val) = @_;
	$$p_val = $1 if ($$p_val =~ m!^(.*)$!s);
	}





sub header_add {
	my ($header) = @_;
	$::private{'http_headers'} .= $header . "\015\012";
	}





sub header_print {
	return unless $::private{'needs_header'};
	return if $::const{'is_cmd'};
	foreach (@_) {
		&header_add( $_ );
		}

	# fine-tune the header response:
	if ($::private{'PRINT_HTTP_STATUS_HEADER'}) {
		my $status = '200 OK';
		if ($::private{'http_headers'} =~ m!(^|\012)Location:!is) {
			$status = '302 Moved';
			&header_add( 'Status: ' . $status ); # duplicate
			}
		$::private{'http_headers'} = "HTTP/1.0 $status\015\012" . $::private{'http_headers'};
		}
	if ($::private{'http_headers'} !~ m!(^|\012)Content-Type:!is) {
		&header_add( "Content-Type: text/html" );
		}

	# prepare and print:
	$::private{'http_headers'} .= "\015\012";
	print $::private{'http_headers'};
	delete $::private{'http_headers'}; #save mem
	$::private{'needs_header'} = 0;
	}





sub load_files_ex {
	($::private{'support_dir'}) = @_;

	my $err = '';
	Err: {

		# This manually sets the current working directory to the directory that
		# contains this script. This is necessary in case people have used a
		# relative path to the $data_files_dir:

		if (($0 =~ m!^(.+)(\\|/)!s) and ($0 !~ m!safeperl\d*$!is)) {
			#changed 0045 - added error check
			unless (chdir($1)) {
				$err = "unable to chdir to folder '$1' - $! ($^E)";
				next Err;
				}
			}

		# force forward slashes:
		$::private{'support_dir'} =~ s!\\!/!sg;
		$::private{'support_dir'} .= "/searchdata";
		$::private{'support_dir'} =~ s!/+searchdata$!/searchdata!s;

		unless (chdir($::private{'support_dir'})) {
			$err = "unable to chdir to folder '$::private{'support_dir'}' - $! ($^E)";
			next Err;
			}

		@INC = ( '../searchmods', @INC );


		#require
		my $lib = 'common.pl';
		delete $INC{$lib};
		require $lib;
		if (&version_c() ne $::VERSION) {
			$err = "the library '$lib' is not version $::VERSION";
			next Err;
			}
		#/require

		&ReadInput();



		if (exists($::FORM{'ApproveRealm'})) {
			$::FORM{'Realm'} = $::FORM{'ApproveRealm'};
			$::FORM{'Mode'} = 'Admin';
			$::FORM{'Action'} = 'FilterRules';
			$::FORM{'subaction'} = 'ShowPending';
			}

		unless ($::FORM{'Mode'}) {
			#revcompat - pre-0010
			if (exists($::FORM{'AddSite'})) {
				$::FORM{'Mode'} = 'AnonAdd';
				$::FORM{'URL'} = $::FORM{'AddSite'};
				delete $::FORM{'AddSite'};
				}
			#/revcompat
			if ('mode=admin' eq lc(&query_env('QUERY_STRING'))) {
				$::FORM{'Mode'} = 'Admin';
				delete $::FORM{'mode'};
				}
			}
		#revcompat 0030
		if ((exists($::FORM{'Action'})) and ($::FORM{'Action'} eq 'ReCrawlRealm')) {
			$::FORM{'Action'} = 'rebuild';
			}
		#/revcompat

		my $is_admin_rq = (($::FORM{'Mode'}) and (($::FORM{'Mode'} eq 'Admin') or ($::FORM{'Mode'} eq 'AnonAdd'))) or (&query_env('FDSE_NO_EXEC'));



		$::private{'bypass_file_locking'} = (-e 'bypass_file_locking.txt') ? 1 : 0;

		# Can we load the rules?

		my $DEFAULT_LANGUAGE = 'english';

		$err = &LoadRules($DEFAULT_LANGUAGE);
		next Err if ($err);


		#0056 - user lang selection algorithm by Ian Dobson

		($err, $::const{'lang_options'}, $::Rules{'language'}) = &choose_interface_lang($is_admin_rq, &query_env('HTTP_ACCEPT_LANGUAGE'));
		next Err if ($err);

		#to hard-code a lang, uncomment this line:
		# $::Rules{'language'} = 'english';

		$::const{'language'} = $::FORM{'set:lang'} = $::Rules{'language'};

		# init err strings
		$::str[44] = 'unable to read from file "$s1" - $s2';

		my $str_file = 'templates/' . $::Rules{'language'} . '/strings.txt';
		my $str_text;
		($err, $str_text) = &ReadFileL($str_file);
		next Err if ($err);
		my $MAX_PUB_STR = 88;
		@::str = (0);
		my $i = 1;
		foreach (split(m!\n!s,$str_text)) {
			s!(\r|\n|\015|\012)!!sg;
			push(@::str,$_);
			unless ($is_admin_rq) {
				last if ($i > $MAX_PUB_STR);
				}
			$i++;
			}
		unless (&Trim($::str[1]) eq "VERSION $::VERSION") {
			$err = "strings file '$str_file' is not version $::VERSION ($::str[1]).</p><p>Loaded $i strings from file; sample: <xmp>" . substr($str_text,0,128) . "</" . "xmp>";
			next Err;
			}

		#changed 0064: quality audit
		foreach ($MAX_PUB_STR,100,200,300,400,500,558) {
			if ($::str[$_] ne "$_-anchor") {
				$::str[29] = '<p><b>Error:</b> $s1.</p>'; # force default value
				$err = qq!strings file "$str_file" is corrupted.  Extra line breaks have been added or removed.  We know this because line $_ does not have expected value "$_-anchor".</p><p>To fix, re-upload the original strings.txt file in ASCII mode!;
				next Err;
				}
			last if ((not $is_admin_rq) and ($_ >= $MAX_PUB_STR));
			}


		$::const{'dir'} = $::str[4];
		$::const{'content_type'} = $::str[3];
		$::const{'language_str'} = $::str[2];



		$::realms = &fdse_realms_new();
		$::realms->load();

		# set mode: demo/trial/registered/freeware == 0/1/2/3
		$::private{'mode'} = $::Rules{'mode'};

		if (-e 'is_demo') {
			$::private{'mode'} = 0;
			}
		elsif (($::private{'mode'} == 2) and (not $::Rules{'regkey'})) {
			$::private{'mode'} = 1;
			}

		$::private{'is_demo'} = ($::private{'mode'} == 0);
		$::private{'is_freeware'} = ($::private{'mode'} == 3);



		#require
		if (($is_admin_rq) or ($::realms->listrealms('is_runtime'))) {
			$lib = 'common_parse_page.pl';
			delete $INC{$lib};
			require $lib;
			if (&version_cpp() ne $::VERSION) {
				$err = "the library '$lib' is not version $::VERSION";
				next Err;
				}
			}
		if ($is_admin_rq) {
			$lib = 'common_admin.pl';
			delete $INC{$lib};
			require $lib;
			if (&version_ca() ne $::VERSION) {
				$err = "the library '$lib' is not version $::VERSION";
				next Err;
				}
			}
		#/require


		last Err;
		}
	return $err;
	}

package FDSC::HEH;
sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }
sub FETCH {
	my ($self, $key) = @_;
	if (exists ($self->{$key})) {
		return $self->{$key};
		}
	else {
		my ($package, $file, $line) = caller();
		my $err = "blind fetch of non-existent hash element '$key' file $file line $line<br />\n";
		foreach (sort keys %$self) {
			$err .= "$_: $self->{$_}<br />\n";
			}
		die $err;
		}
	};

END_OF_FILE

sub he {
	my @out = @_;
	local $_;
	foreach (@out) {
		$_ = '' if (not defined($_));
		s!\&!\&amp;!sg;
		s!\>!\&gt;!sg;
		s!\<!\&lt;!sg;
		s!\"!\&quot;!sg;
		}
	if ((wantarray) or ($#out > 0)) {
		return @out;
		}
	else {
		return $out[0];
		}
	}

undef($@);
eval $all_code;
if ($@) {
	my $errstr = &he($@);
	print "Content-Type: text/html\015\012\015\012";
	print "<hr /><p><b>Perl Execution Error</b> in $0:</p><blockquote><pre>$errstr</pre></blockquote>";
print <<"EOM";

<script>g_loaded=true;</script>
<form method="post" action="http://www.xav.com/bug.pl">
<input type="hidden" name="product" value="search" />
<input type="hidden" name="version" value="$::VERSION" />
<input type="hidden" name="Perl Version" value="$]" />
<input type="hidden" name="Script Path" value="$0" />
<input type="hidden" name="Perl Error" value="$errstr" />
EOM

my ($name, $value) = ();
while (($name, $value) = each %::FORM) {
	next if ($name =~ m!(Password|new_pass_\d)!s);
	($name, $value) = &he($name,$value);
	print qq!<input type="hidden" name="Form: $name" value="$value" />\n!;
	}
print <<"EOM";

<p>Please report this error to the script author:</p>
<blockquote><input type="submit" value="Report Error" /></blockquote>
</form><hr />

EOM
	}
1;

