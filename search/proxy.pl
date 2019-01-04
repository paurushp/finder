#!/usr/bin/perl --
#use strict;#if-debug
use Socket;
$::VERSION = '2.0.0.0073';

# <h1>If you can see this text from a web browser, then there is a problem.
# <a href="http://www.xav.com/scripts/search/help/1089.html">Get help here.</a></h1><xmp>


my $ext = 'pl';
$ext = $1 if (&query_env('SCRIPT_NAME') =~ m!proxy\.(\w+)$!s);

my $overview = <<"EOM";

Overview
========

The proxy.$ext redirect script is a utility to be used with the Fluid Dynamics
Search Engine.

What It Does
============

Visitors who wish to view a search result can request this proxy.$ext script
instead, with the destination URL passed as a parameter.  This proxy script
will request the URL on their behalf, and then display it to the visitor
with all search terms highlighted in bold yellow.  This should help the
visitor find the sought-after information.

More?  See: http://www.xav.com/scripts/search/help/1106.html

How To Enable
=============

First, install FDSE and make sure it works normally for normal search
results.

Next, test the proxy.$ext script by requesting it directly.

Then edit the "line_listing.txt" template.  Add a link below the search
results as follows:

# for *.pl script:

<br /><a href="proxy.pl?terms=%url_terms%&url=%url_url%">
View with Highlighted Search Terms</a>

# for *.cgi script:

<br /><a href="proxy.cgi?terms=%url_terms%&url=%url_url%">
View with Highlighted Search Terms</a>

On some systems, this script will be named proxy.pl, or proxy.cgi, or
proxy.somthing.  On those systems, simply use that alternate filename.

Copyright 2005 by Zoltan Milosevic; distributed under the same terms as FDSE.

EOM


# ~~ read http://www.xav.com/scripts/search/help/1106.html "Security" first ~~
#
# "turn on" the proxy:

my $SECURITY_ENABLE = 0;

# allow retrieval of only URL's on this server:

my $SECURITY_MATCH_SERVER_NAME = 0;

# allow retrieval of only URL's listed in the search.pending.txt file: (recommended)

my $SECURITY_MATCH_PENDING_FILE = 1;

# if network sockets are not allowed on this host, you must set this to zero. You will only be able to use the %maps feature.

my $NETWORK_SOCKETS_OK = 1;

# is a specific hostname must be used to access this system, enter:

my $SECURITY_HOSTNAME = '';

%::FORM = ();
&WebFormL(\%::FORM);
my $hurl = &he($::FORM{'url'});


my $highlight_open = '<span style="font-weight:bold;color:#000000;background-color:#ffff77">';
my $highlight_close = '</span>';

my $header = <<"EOM";

<meta name="robots" content="none" />
<base href="%base_href%" />
<table width="100%" border="1" bgcolor="#ffffff"><tr><td style="color:#000000"><font color="#000000">

	<p>This is a pre-processed version of the web page <a href="%link_href%" style="text-decoration:underline">%base_href%</a>. In this copy, the search terms %str% have been $highlight_open highlighted $highlight_close to make them easier to find. If a search term was not found, then it may exist in the non-visible title, description, keywords or URL fields, or the contents of this document may have changed since it was indexed.</p>

	<p>Some web pages will not display properly in this pre-processor. Visit those pages directly by following <a href="%link_href%" style="text-decoration:underline">this link</a>. Visit the page itself before bookmarking it.</p>

	<p align="center"><small>The search engine that brought you here is not necessarily affiliated with, nor responsible for, the contents of this page.</small></p>

</font></td></tr></table>

EOM


# optional - maps are of the form "url/" => "folder/"
# If proxy.pl intercepts a URL which matches one of these maps entries, it will do a file-request rather than an HTTP request.
# Use forward slashes for Windows paths. Always include trailing slashes.
# caveats:
#	will bypass server logging of visits
#	will bypass username-password and/or SSL protection of file
#	will return source code of file; not appropriate for active content or files that contain includes
# Remove the "#" signs in the %maps entries below to activate:

my %maps = (
	#'http://www.xav.com/' => '/usr/www/users/xav/',
	#'http://nickname.net/tori/' => '/usr/www/users/xav/tori/',
	);

%::private = ();
$::private{'PRINT_HTTP_STATUS_HEADER'} = 0;



my %termcount = ();

my %httpcookie = ();
my $NetStream = '';
my $httpInit = 1;


my $err = '';
Err: {
	local $_;

	unless ($SECURITY_ENABLE) {
		$err = "this proxy script is currently turned off. To turn it on, edit it's source code and set:</P><P><PRE>my \$SECURITY_ENABLE = 1;</PRE>";
		next Err;
		}

	my $ua_host = &query_env('HTTP_HOST');
	if (($ua_host) and ($SECURITY_HOSTNAME) and ($ua_host ne $SECURITY_HOSTNAME)) {
		$err = "this proxy script can only be accessed via hostname $SECURITY_HOSTNAME";
		next Err;
		}


	my $base_href = $hurl;
	my $link_href = $hurl;

	$::FORM{'terms'} = $::FORM{'terms'} || '';
	$::FORM{'terms'} =~ s!\+|\-|\||\"!!sg;
	$::FORM{'terms'} =~ s!&quot;!!sg;
	my @terms = split(m!\s+!s, $::FORM{'terms'});

	unless ($::FORM{'url'}) {
		$err = "must supply a URL parameter";
		next Err;
		}

	#changed 0056 -- override on *.pdf, *.mp3, *.doc, *.xls
	if ($::FORM{'url'} =~ m!\.(pdf|mp3|doc|xls)$!is) {
		&http_redirect( $::FORM{'url'} );
		last Err;
		}


	my $text = '';


	if (($0 =~ m!^(.+)(\\|/)!s) and ($0 !~ m!safeperl\d*$!is)) {
		unless (chdir($1)) {
			$err = "unable to chdir to script folder '$1' - $!";
			next Err;
			}
		}

	my $http_headers = '';

	GetText: {

		my $local_path = '';

		foreach (sort { length($maps{$b}) <=> length($maps{$a}) } keys %maps) { # changed 0056 - length-first search
			# i.e. http://host/cgi-bin/ comes before http://host/
			my $pat = quotemeta($_);
			next unless ($::FORM{'url'} =~ m!^$pat(.*)$!is);
			unless (-d $maps{$_}) {
				$err = "unable to find folder named '$maps{$_}'";
				next Err;
				}
			$local_path = $maps{$_} . &ud($1);

			if ($local_path =~ m!\.\.!s) {
				$err = "path cannot contain '..' string";
				next Err;
				}
			if (not -f $local_path) {
				# error probably due to URL == http://xav/ but FILE == http://xav/index.html
				# or due to URL == http://xav.com/index.html?query
				# not necessarily a critical error; just failover to HTTP request
				$local_path = '';
				}
			last;
			}

		if ($local_path) {
			unless (open(FILE, "<$local_path")) {
				$err = "unable to open file '$local_path' for reading - $!";
				next Err;
				}
			binmode(FILE);
			$text = join('',<FILE>);
			close(FILE);
			$http_headers .= "HTTP/1.0 200 OK\015\012" if ($::private{'PRINT_HTTP_STATUS_HEADER'});
			$http_headers .= "Content-Type: text/html\015\012\015\012";
			last GetText;
			}

		unless ($NETWORK_SOCKETS_OK) {
			&http_redirect( $::FORM{'url'} );
			last Err;
			}


		my ($clean, $host, $port, $path, $query);
		($err, $clean, $host, $port, $path, $query) = &uri_parse( $::FORM{'url'} );
		next Err if ($err);

		my $sn = &query_env('SERVER_NAME');

		#changed 2005-02-12
		$host =~ s!^www\.!!is;
		$sn =~ s!^www\.!!is;

		if (($SECURITY_MATCH_SERVER_NAME) and ($host ne $sn)) {
			$err = "this script has setting \$SECURITY_MATCH_SERVER_NAME = 1 and so it will only query web site http://$sn, not http//" . &he($host);
			next Err;
			}
		if ($SECURITY_MATCH_PENDING_FILE) {

			my $pending_file = 'searchdata/search.pending.txt';

			my $b_found = 0;
			my $qm_url = quotemeta($clean);
			# get pending file...
			unless (open(FILE, "<$pending_file")) {
				$err = "unable to read from file '$pending_file' - $!";
				next Err;
				}
			binmode(FILE);
			while (defined($_ = <FILE>)) {
				next unless (m!^$qm_url !s);
				next unless (m!^$qm_url \S+ (\d+)!s); # do expensive ()-matching only on valid lines
				next unless ($1 > 2); # match only valid points
				$b_found = 1;
				last;
				}
			close(FILE);
			unless ($b_found) {
				$err = "this script has setting \$SECURITY_MATCH_PENDING_FILE = 1 but it was not able to find the URL '" . &he($clean) . "' in the file '$pending_file'.";
				next Err;
				}
			}


		my $Method = 'GET';
		my $RequestBody = '';
		my $AllowRedir = 6;
		my %CustomHeaders = (
			'USER-AGENT' => &query_env('HTTP_USER_AGENT'),
			'REFERER' => &query_env('HTTP_REFERER'),
			);
		if ($CustomHeaders{'REFERER'} =~ m!(Mode=Admin|CP=)!s) {
			delete $CustomHeaders{'REFERER'};
			}
		#fixed 0052 - blank-spaces-in-URL bug
		$::FORM{'url'} =~ s! !%20!gs;
		my ($is_error, $error_msg, $URL, $ResponseBody, $ResponseCode, %Headers) = &http_ex($clean, $Method, $RequestBody, $AllowRedir, %CustomHeaders);
		if ($is_error) {
			$err = $error_msg;
			next Err;
			}
		if ($ResponseCode ne '200') {
			$err = "proxy.pl received HTTP response code '$ResponseCode' rather than '200 OK'";
			next Err;
			}
		$http_headers .= "HTTP/1.0 200 OK\015\012" if ($::private{'PRINT_HTTP_STATUS_HEADER'});
		foreach (keys %Headers) {
			next if (m!^(set-cookie|content-length|connection)$!is);
			$http_headers .= "$_: $Headers{$_}\015\012";
			}
		$http_headers .= "\015\012";
		$text = $ResponseBody;

		$base_href = $URL; # update on redirect


		# override based on content-type
		if (($Headers{'Content-Type'}) and ($Headers{'Content-Type'} !~ m!^text/!s)) {
			&http_redirect( $::FORM{'url'} );
			last Err;
			}


		last GetText;
		}

	#changed 0056 -- override based on document text
	if ($text =~ m!(<frameset.*?</frameset>|fdse-bypass-proxy)!is) {
		&http_redirect( $::FORM{'url'} );
		last Err;
		}

	print $http_headers;


	if ($::FORM{'terms'}) {

		my @parts = split(m!\<(SCRIPT|STYLE|TITLE)!is, $text);

		my $c = 0;

		my $new = &proc( $parts[0], @terms );
		local $_;

		for ($c = 1; $c < $#parts; $c += 2) {
			my $end = quotemeta(uc($parts[$c]));
			if ($parts[$c+1] =~ m!^(.*?)</$end>(.+)$!is) {
				$new .= "<$parts[$c]$1</$end>" . &proc( $2, @terms );
				}
			else {
				$new .= '<' . $parts[$c] . $parts[$c+1];
				}
			}
		$text = $new;
		}

	my $str = '';
	foreach (@terms) {
		my $qmterm = quotemeta($_);
		$str .= $highlight_open . &he($_) . "$highlight_close (" . ($termcount{$qmterm} || 0) . ") ";
		}

	$header =~ s!%base_href%!$base_href!isg;
	$header =~ s!%link_href%!$link_href!isg;
	$header =~ s!%str%!$str!isg;

	print $header;
	print $text;



	last Err;
	}
continue {
	print "HTTP/1.0 200 OK\015\012" if ($::private{'PRINT_HTTP_STATUS_HEADER'});
	print "Content-Type: text/html\015\012\015\012";

print <<"EOM";
<meta name="robots" content="none" />
<p><b>Error:</b> $err.</p>
EOM

	unless ($::FORM{'url'}) {
print <<"EOM";
<hr />
<form method="get" action="$ENV{'SCRIPT_NAME'}">
URL: <input name="url" value="http://" /><br />
Search Terms: <input name="terms" /> <input type="submit" value="Test" /></form>
<hr /><pre>
EOM
		print &he($overview);
		}
	}


sub proc {
	my ($text, @terms) = @_;
	local $_;

	my $new = '';
	foreach (split(m!<!s, $text)) {
		if (m!^(.*?)\>(.+)$!s) {
			$new .= "<$1>" . &replace($2, @terms);
			}
		else {
			$new .= "<$_";
			}
		}
	$new =~ s!^\<!!os;
	return $new;
	}

sub replace {
	my ($text, @terms) = @_;
	local $_;
	foreach (@terms) {
		my $qmterm = quotemeta($_);
		my $pattern = $qmterm;
		$pattern =~ s!\\\*!\\S{0,4}!gs;
		$termcount{$qmterm} += (scalar ($text =~ s!($pattern)!<<$1>>!sig));
		}
	$text =~ s!\<+!$highlight_open!sg;
	$text =~ s!\>\>+!$highlight_close!sg;
	return $text;
	}





=item WebFormL

Usage:
	&WebFormL( \%::FORM );

Returns a by-reference hash of all name-value pairs submitted to the CGI script.

updated: 8/21/2001

Dependencies:
	&query_env

=cut

sub WebFormL {
	my ($p_hash) = @_;
	my @Pairs = ();
	if ('POST' eq &query_env('REQUEST_METHOD')) {
		my $buffer = '';
		my $len = &query_env('CONTENT_LENGTH',0);
		read(STDIN, $buffer, $len);
		@Pairs = split(m!\&!s, $buffer);
		}
	elsif (&query_env('QUERY_STRING')) {
		@Pairs = split(m!\&!s, &query_env('QUERY_STRING'));
		}
	else {
		@Pairs = @ARGV;
		}
	local $_;
	foreach (@Pairs) {
		next unless (m!^(.*?)=(.*)$!s);
		my ($name, $value) = &ud($1,$2);
		if ($$p_hash{$name}) {
			$$p_hash{$name} .= ",$value";
			}
		else {
			$$p_hash{$name} = $value;
			}
		}
	}


=item query_env

Usage:
	my $remote_host = &query_env('REMOTE_HOST');

Abstraction layer for the %ENV hash.  Why abstract?  Here's why:
 1. adds safety for -T taint checks
 2. always returns '' if undef; prevent -w warnings

=cut

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




sub ud {
	my @out = @_;
	local $_;
	foreach (@out) {
		next unless (defined($_));
		tr!+! !;
		s!\%([a-fA-F0-9][a-fA-F0-9])!pack('C', hex($1))!esg;
		}
	if ((wantarray) or ($#out > 0)) {
		return @out;
		}
	else {
		return $out[0];
		}
	}



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


=item http_ex

Usage:
	my ($is_error, $error_msg, $URL, $ResponseBody, $ResponseCode, %Headers) = &http_ex($URL, $Method, $RequestBody, $AllowRedir, %CustomHeaders);

	if ($is_error) {
		print "<P><B>Error:</B> $error_msg.</P>\n";
		}

Error message contains an error fragment, suitable for inclusion as above.

=cut

sub http_ex {
	my ($URL, $Method, $RequestBody, $AllowRedir, %CustomHeaders) = @_;

	my ($is_error, $error_msg) = (0, '');

	my ($ResponseBody, $ResponseCode, %ResponseHeaders) = ('', 0);

	my $trace = '';

	Err: {

		my ($Request, %Headers);
		$Method = uc($_[1] ? $_[1] : 'GET'); # default to GET; force uppercase.
		$RequestBody = '' unless $RequestBody; # init
		$AllowRedir = $_[3] ? $_[3] : 0; # force numeric
		local $_;

		my ($clean, $host, $port, $path, $query);
		($error_msg, $clean, $host, $port, $path, $query) = &uri_parse( $URL );
		next Err if ($error_msg);

		%Headers = (
			'ACCEPT', '*/*',
			'ACCEPT-ENCODING', 'none',
			'ACCEPT-LANGUAGE', 'en-us',
			'CONNECTION', 'close',
			'PRAGMA', 'no-cache',
			'USER-AGENT', 'Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt)',
			);

		foreach (keys %CustomHeaders) {
			$Headers{uc($_)} = $CustomHeaders{$_};
			}


		#changed 0052 security/tracking
		delete $Headers{'COOKIE'};
		$Headers{'X_FORWARDED_FOR'} = &query_env('REMOTE_ADDR');
		$Headers{'VIA'} = &query_env('SERVER_NAME');
		if (&query_env('HTTP_VIA')) {
			$Headers{'VIA'} .= "; " . &query_env('HTTP_VIA');
			}



		# Force HTTP/1.1 compliance:
		$Headers{'HOST'} = $host . (($port == 80) ? '' : ":$port");
		if ($RequestBody) {
			$Headers{'CONTENT-LENGTH'} = length($RequestBody);
			$Headers{'CONTENT-TYPE'} = 'application/x-www-form-urlencoded' unless $Headers{'CONTENT-TYPE'};
			}

		# Cookies?
		unless ($Headers{'COOKIE'}) {
			$Headers{'COOKIE'} = '';
			foreach (keys %httpcookie) {
				$Headers{'COOKIE'} .= "$_=$httpcookie{$_};";
				}
			}

		my $CRLF = "\015\012";

		$Request = "$Method $path$query HTTP/1.0$CRLF";
		foreach (keys %Headers) {
			$Request .= "$_: $Headers{$_}$CRLF" if ($Headers{$_});
			}
		$Request .= "$CRLF";
		$Request .= $RequestBody;


		my $HexIP = inet_aton($host);
		unless ($HexIP) {
			$error_msg = "could not resolve hostname '$host' into an IP address";
			next Err;
			}

		unless (socket(HTTP, PF_INET, SOCK_STREAM, getprotobyname('tcp'))) {
			$error_msg = "could not create socket - $! ($^E)";
			next Err;
			}
		unless (connect(HTTP, sockaddr_in($port, $HexIP))) {
			$error_msg = "could not connect to '$host:$port' - $! ($^E)";
			next Err;
			}
		unless (binmode(HTTP)) {
			$error_msg = "could not set binmode on HTTP socket - $! - $^E";
			next Err;
			}

		select(HTTP);
		$| = 1;
		select(STDOUT);

		$trace = $Request;

		my $ExpectBytes = length($Request);

		my $SentBytes = send(HTTP, $Request, 0);

		if ($SentBytes != $ExpectBytes) {
			$error_msg = "unable to send a full $ExpectBytes - only send $SentBytes - $! ($^E)";
			close(HTTP);
			next Err;
			}

		my $FirstLine = <HTTP>;

		$trace .= $FirstLine;

		# Determine the HTTP version:
		if ($FirstLine =~ m!^HTTP/1.\d (\d+)!s) {
			# Is HTTP 1.x, great.
			$ResponseCode = $1;

			# Get HTTP headers:
			while (defined($_ = <HTTP>)) {
				$trace .= $_;
				last unless m!^(.*?)\:\s+(.*?)\r?$!s;
				$ResponseHeaders{uc($1)} = $2;
				if ((uc($1) eq 'SET-COOKIE') and ($2 =~ m!^(\w+)\=([^\;]+)!s)) {
					$httpcookie{$1} = $2;
					}
				}

			# Get HTTP body:
			if ($ResponseHeaders{'TRANSFER-ENCODING'} and
					($ResponseHeaders{'TRANSFER-ENCODING'} =~ m!^chunked$!is)) {
				my $buffer;
				my $ReadLine;
				while (defined($ReadLine = <HTTP>)) {
					$NetStream .= $ReadLine;
					last unless ($ReadLine =~ m!^(\w+)\r?$!s);
					last unless read(HTTP, $buffer, hex($1));
					$trace .= $buffer;
					$ResponseBody .= $buffer;
					}
				}
			else {
				$ResponseBody = '';
				while (defined($_ = <HTTP>)) {
					$ResponseBody .= $_;
					}
				$trace .= $ResponseBody;
				}
			}
		else {

			# This is an HTTP 0.9 response, which has no headers:

			# Set Code to 200 to satisfy 80% of customers:
			$ResponseCode = 200;

			$ResponseBody = $FirstLine;
			while (defined($_ = <HTTP>)) {
				$trace .= $_;
				$ResponseBody .= $_;
				}
			}
		close(HTTP);
		if ($AllowRedir and ($ResponseCode =~ m!^(301|302)$!s)) {
			$httpInit = 0;
			$AllowRedir--;
			my ($err, $clean) = &uri_merge( $URL, $ResponseHeaders{'LOCATION'} );
			if ($err) {
				$error_msg = $err;
				next Err;
				}
			return &http_ex($clean, 'GET', '', $AllowRedir, %CustomHeaders);
			}
		else {
			$httpInit = 1;
			}
		last Err;
		}
	continue {
		$is_error = 1;
		}
	return ($is_error, $error_msg, $URL, $ResponseBody, $ResponseCode, %ResponseHeaders);
	}




=item Trim

Usage:

	my $word = &Trim("  word  \t\n");

Strips whitespace and line breaks from the beginning and end of the argument.

=cut

sub Trim {
	local $_ = defined($_[0]) ? $_[0] : '';
	s!^[\r\n\s]+!!os;
	s![\r\n\s]+$!!os;
	return $_;
	}





sub http_redirect {
	my ($url) = @_;
	$url =~ s!\s!\%20!sg; # strips vertical whitespace, primary concern here
	print "HTTP/1.0 302 Moved\015\012" if ($::private{'PRINT_HTTP_STATUS_HEADER'});
	print "Status: 302 Moved\015\012";
	print "Location: $url\015\012";
	print "\015\012";
	};

# updated from master Common.pm for release 0073
sub uri_parse {
	my ($str, $b_retain_frag) = @_;
	my ($err, $clean, $host, $port, $path, $query, $frag, $folder) = ('', '', '', 80, '', '', '', '');
	Err: {

		local $_ = $str;

		# basic validation steps:

		if (not defined($_)) {
			my ($package, $filename, $line) = caller();
			$err = "invalid argument.  Sub <code>uri_parse(URL)</code> called with undefined parameter from file $filename line $line";
			next Err;
			}

		my $len = length($_);
		if (($len == 0) or ($_ eq 'http://')) {
			$err = 'invalid argument; URL cannot be blank';
			next Err;
			}

		my $maxlen = 2048;
		if ($len > $maxlen) {
			$err = "URL length $len characters is too long.  This software has a limit of $maxlen characters in a URL string";
			next Err;
			}

		my $hstr = &he($_);

		# free validation - remove leading and trailing whitespace and zero out internal vertical whitespace and tabs
		s!^\s+!!s;
		s!\s+$!!s;
		s!(\r|\n|\015|\012|\t)!!sg;
		s!\s!%20!sg; # for spaces to '%20'

		# format validation:

		unless (m!^(\w+)\:(.*)$!s) {
			$err = "string '$hstr' is not a valid HTTP URL.  Must be of the format 'http://host.tld/path/file.ext'";
			next Err;
			}

		my $protocol = lc($1);
		$_ = $2;
		if ($protocol ne 'http') {
			$err = "string '$hstr' not accepted as HTTP URL.  This software supports only the 'http' protocol, not '$protocol'";
			next Err;
			}

		unless (m!^//(.+)$!s) {
			# punish the f**ing morons who enter http:\\xav.com
			$err = "string '$hstr' is not a valid HTTP URL.  The sequence '//' must follow leading 'http:'";
			next Err;
			}
		$_ = $1;

		# extract the host and port portion - basically, anything up till the next "/" or the end of the string
		if (m!^(.+?)/(.*)$!s) {
			$host = $1;
			$_ = "/$2";
			}
		else {
			$host = $_;
			$_ = '/';
			}

		# perform a URL-decode operation on the server portion; this is allowed because we are free and clear to URL-decode anything we want before the ?
		# user:pass%40host => user:pass@host
		# xav.%63om => xav.com

		# URL-decode the hostname, but don't touch '+' signs; just %HH sequences:
		$host =~ s!\+!\%2B!sg;
		$host = &ud($host);

		#changed 2003-03-17; force lc()!!
		$host = lc($host);

		# is there a user:pass@host format?
		if ($host =~ m!\@!s) {
			$err = "string '$hstr' cannot be parsed as an HTTP URL due to presence of an '\@' character in the hostname substring.  Note that this software does not accept username and password information within the URL string";
			next Err;
			}

		# is there a numeric port?
		if ($host =~ m!^(.+)\:(\d+)$!s) {
			$host = $1;
			$port = 1 * $2; # force as number not string - helps deal with "0080" as port
			}
		if (($port < 1) or ($port > 65536)) {
			$err = "string '$hstr' is not a valid HTTP URL.  Port number $port is outside the allowed range 1-65536";
			next Err;
			}

		# are the hostname characters valid?

	# TODO - what about Windows Netbios names which can contain underscores and non-printable characters?
	# what about the extensions to DNS that allow for localized names? i.e. Unicode DNS, etc.?  (seems to be mostly vaporware for now)
	# what about TLD validation -- there is a known subset of TLD's

		if ($host =~ m![^a-z0-9\.\-]!s) {
			$err = "string '$hstr' is not a valid HTTP URL.  The hostname portion contains characters outside the allowed character set of a-z, 0-9, '.' and '-'";
			next Err;
			}

		my $hlen = length($host);
		my $hmax = 255;
		if ($hlen > $hmax) {
			$err = "string '$hstr' is not a valid HTTP URL.  The hostname substring is $hlen characters, but the maximum allowed length is $hmax characters";
			next Err;
			}

		IsNumberAddr: {

			my $b_invalid = 0;
			my $count = 0;
			foreach (split(m!\.!s, $host)) {
				$count++;
				if (m!^0\d+$!s) { # octal
					$b_invalid = 1;
					next;
					}
				if (m!^\d+$!s) { # decimal, non-octal
					$b_invalid = 1 if ($_ > 255);
					next;
					}
				if (m!^0x[0-9a-f]+$!is) { # hex
					$b_invalid = 1;
					next;
					}
				last IsNumberAddr;
				}

			# if we get here, then *all* components were numeric (octal or decimal) and/or hex 0xAA.0x9B.etc...
			# we accept *only* decimal numeric with all 4 octets separated

			if (($b_invalid) or (4 != $count)) {
				$err = "string '$hstr' not accepted as HTTP URL.  When using a numeric host address (IP address), must use dotted decimal notation such as 255.1.1.1.  This software does not support octal or hex representations, nor octet grouping";
				next Err if ($err);
				}


			}



		# extract the fragment identifier

		if (m!^(.*?)\#(.*)$!s) {
			$_ = $1;
			$frag = '#' . $2 if (length($2));
			}

		# extract the query string

		if (m!^(.*?)\?(.*)$!s) {
			$_ = $1;
			$query = '?' . $2 if (length($2));
			}

		# URL-decode the remaining path portion, but only %HH sequences -- leave '+' as literal
		s!\+!\%2B!sg;
		$path = &ud($_);

		# perform magic on . .. / sequences in the path

			while ($path =~ s!/+\./+!/!s) {} # make foo/./bar become foo/bar

			$path =~ s!/+\.$!/!sg;  # map trailing /. => /

			# nuke all leading "/../" entries (meaningless for us)
			# map /../foo => /foo
			while ($path =~ s!^/+\.\./+!/!s) {}


			# map "folder/../" => "/"
			# map "bar/folder/../" => "bar//"
			while ($path =~ s!([^/]+)/+\.\./+!/!s) {} # BUG - this'll glitch on /foo/./../bar/ => becomes /foo/bar/ but should be /foo/


			# map "/folder/.." => "/"
			$path =~ s!/+([^/]+)/+\.\.$!/!s;

			$path =~ s!/+!/!sg; # collapse chained / characters


		$path =~ s!\%!%25!sg; # 2003-03-17 force required URL-encodings to return
		$path =~ s!\s!%20!sg;
		$path =~ s!\#!%23!sg;


		$clean = 'http://' . $host;
		if ($port != 80) {
			$clean .= ':' . $port;
			}
		$clean .= $path;

		$folder = $clean;
		$folder =~ s!/([^/]*)$!/!; # strip anything past the last slash (i.e., a filename)

		$clean .= $query;
		$clean .= $frag if ($b_retain_frag);

		last Err;
		}
	continue {
		# error response should have all other return values zero'ed
		($clean, $host, $port, $path, $query, $frag, $folder) = ('', '', 80, '', '', '', '');
		}
	return ($err, $clean, $host, $port, $path, $query, $frag, $folder);
	}



sub uri_merge {
	my ($v_base, $str) = @_;
	my $err = '';
	my $clean = '';
	Err: {

		local $_;

		if ('ARRAY' ne ref($v_base)) {
			$v_base = [ &uri_parse( $v_base ) ]; # anonymous array reference to return values
			}

		if ($v_base->[0]) {
			# there was an error in parsing the base URL
			# the $str can be returned as $clean iff it validated on its own

			($err, $clean) = &uri_parse( $str );
			last Err unless ($err);

			# oh.. there was an error - how do we explain this to our end user?

			# don't worry too much about the format of this string.  it is *extremely* rare for us to arrive at a situation where
			# the $base_url is not valid in our context.  the only case would be when parsing an HTML document which contains a <base href=""> tag
			# that is malformed or that uses an unsupported protocol like https://xav.com/
			#
			# we only go critical and print the $err from uri_merge in cases of HTTP redirects, and so the $base_url-is-invalid scenario is
			# unlikely to arise in that context

			$err = qq!unable to merge URL with fragment.  The primary URL failed to validate with:</p><p style="margin-left:20px"><strong>Error:</strong> $v_base->[0].</p><p>Because the primary URL failed, the fragment could only be evaluated as a stand-alone URL.  It failed that evaluation with:</p><p style="margin-left:20px"><strong>Error:</strong> $err!;
			next Err;
			}

		# okay - more general case - base_url valid

		local $_ = $str;

		if (m!^/!s) {
			# absolute link from top-level directory
			$_ = 'http://' . $v_base->[2] . ':' . $v_base->[3] . $_;
			}

		elsif (m!^\#!s) {
			# a relative link on this page.  just strip any current frag and append this one
			$_ = 'http://' . $v_base->[2] . ':' . $v_base->[3] . $v_base->[4] . $v_base->[5] . $_;
			}

		elsif (m!^\w+\:!s) {
			# a protocol link.  this link stands on its own as $_
			}

		else {
			# relative link
			$_ = $v_base->[7] . $_;
			}

		($err, $clean) = &uri_parse( $_ );
		next Err if ($err);
		last Err;
		}
	return ($err, $clean);
	};



1;
