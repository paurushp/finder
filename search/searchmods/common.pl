#use strict;#if-debug
sub version_c {
	return '2.0.0.0073';
	}

=head1 HEAD

Copyright 1997-2005 by Zoltan Milosevic, All Rights Reserved
See http://www.xav.com/scripts/search/ for more information.

If you edit the source code, you'll find it useful to restore the function comments and #&Assert checks:

	cd "search/searchmods/powerusr/"
	hacksubs.pl build_map
	hacksubs.pl restore_comments
	hacksubs.pl assert_on

This library, common.pl, contains simple standalone functions which are shared among all modes.

=cut





sub highlighter_new {
	my %params = @_;
	my $self = bless({
		'str_original' => '',
		'str_reduced' => '', # a growing "reduced" string
		'has_trailing_space' => 0, # Boolean for whether str_reduced has a trailing space
		'p_opos_by_rpos' => {}, # pointer to a hash that maintains the original string position by the reduced string position
		});
	return $self;
	}



sub highlighter_scan {
	my ($self, $str) = @_;

	$self->{'str_original'} = " $str ";

	my $const_str = $self->{'str_original'};
	my $const_len = length( $const_str );

	my $p_charmap = $::private{'p_single_char_map'};

	my $i = 0;
	while ($i < $const_len) {

		my $orig_pos = $i;

		my $ch = substr( $const_str, $i, 1 );
		$i++;

		my $virtual_ch = $ch;

		if ($ch eq '<') {
			# the beginning of an HTML string; scan to the closing bracket

			my $expr;
			if ($const_str =~ m!^.{$i}(.*?)\>!s) {
				$expr = $ch . $1 . '>';
				}
			else {
				# no closing bracket... we should scan to the end and quit
				$expr = $ch . substr( $const_str, $i );
				}

			my $jumplen = length( $expr ) - 1;
			$i += $jumplen;

			$virtual_ch = ($expr =~ m!^$::private{'inline_elements'}!is) ? '' : ' ';
			}
		elsif ($ch eq '&') {
			# possibly the beginning of an HTML entity

			if ($const_str =~ m!^.{$i}((\#\d+|\#x[0-9a-f]+|\w{2,8})\;?)!is) {
				my $len = 0;
				my $test_ch = &entity_decode( $ch . $1, 1, \$len );

				if ($len) {
					$i += $len - 1; # advanced for the length of the entity, minus the leading '&' we already recorded...
					$virtual_ch = $test_ch;
					}

				}
			}

		my $reduced_string = $$p_charmap[ord($virtual_ch)];

		# now that we've determine what the reduced string is, append it to the
		# private reduced copy:

		next if ($reduced_string eq '');

		if ($reduced_string eq ' ') {
			next if ($self->{'has_trailing_space'});
			$self->{'has_trailing_space'} = 1;
			}
		else {
			$self->{'has_trailing_space'} = 0;
			}

		my $rpos = length( $self->{'str_reduced'} );
		$self->{'str_reduced'} .= $reduced_string;

		# this code uses a loop, instead of a simple assignment, because of the case
		# "für" => "fuer".  In this case, "ue" is pushed as the reduced char; both
		# 'u' and 'e' must point back to the original 'ü'.  This mapping would be needed
		# if, for example, something matched on substring 'er' and we had to position the
		# beginning.

		my $i = 0;
		while (1) {
			$self->{'p_opos_by_rpos'}->{$rpos + $i} = $orig_pos;
			$i++;
			last if ($i >= length($reduced_string));
			}
		}
	$self->{'p_opos_by_rpos'}->{ length($self->{'str_reduced'}) } = length($self->{'str_original'}); # add final buffer mapping
	}

sub highlight {
	my ($self, $p_keywords, $type) = @_;

	foreach (@$p_keywords) {
		s!^ h\=\.\*\?\((.+)\)\.\*\?l\= $!$1!s; # make "text:keyword" attribute searches act like "keyword" base searches
		s!^\\ ! !s; # makes '\ foo \ ' be just ' foo '
		s!\\ $! !s; #
		}

	my %highlight_by_rpos = ();


	my %priority_by_kw_index = ();

	# priority is: shortest keyword highest priority, otherwise alpha
	# lenght is measure against the reduced-pattern, i.e. 'foo' or 'f\S{0,4}o'.

	my %priority_by_keyword = ();

	my $pri = 0; # baseline priority, no highlighting done

	my $kw;
	foreach $kw (sort { length($b) <=> length($a) || $a cmp $b } @$p_keywords) {

		next unless length($kw); #changed 0070

		$pri++;
#		print "Prisort: $pri $kw\n";
		$priority_by_keyword{ $kw } = $pri;

		my $this_priority = $pri;


		# okay, we've decided on a priority.  Now find where there are matches:

		my $temp_str = $self->{'str_reduced'};

		my $offset = 0;
		while ((length($temp_str)) and ($temp_str =~ m!^(.*?)($kw)!s)) { #changed 0070

			# what matched?  where was it, how long was it?
			my $rel_start_rpos = length($1);

			my $kw_match = $2;
			my $length = length($kw_match);

			# if the kw_match ended with a space, don't advance the pointer over the space
			# spaces can be 'shared' among adjacent keywords
			if ($kw_match =~ m! $!s) {
				$length--;
				}

			my $advance = $rel_start_rpos + $length;
			if ($advance < 1) {
				# we may be stuck in an inifinte loop if we allow this to stand; skip to the end:
				$advance = length($temp_str);
				}

			# advance the pointer to the remaining text:
			$temp_str = substr( $temp_str, $advance );

			my $abs_start_rpos = $offset + $rel_start_rpos;
			$offset += $rel_start_rpos + $length;

			# if this is a ' kw ' pattern with leading spaces, adjust the match
			# so that only the interior is highlighted (after the first space)

			if ($kw =~ m!^ !s) {
				$abs_start_rpos++;
				$length--;
				}

			my $i = 0;
			while ($i < $length) {

				my $abs_rpos = $abs_start_rpos + $i;
				$highlight_by_rpos{ $abs_rpos } = $this_priority;
#				print "Position $abs_rpos = $this_priority\n";
				$i++;
				}

			}
		}

	my $start_pos = -1;


	my @high_no_overlap = ();

	my $last_rpos = -2;
	my $state = 0;

	#debug:
#	my $i;
#	foreach $i (sort { $a <=> $b } keys %highlight_by_rpos) {
#		print "\$hbr{$i}: $highlight_by_rpos{$i}\n";
#		}
	#/debug

	my $i;
	foreach $i (sort { $a <=> $b } keys %highlight_by_rpos) {

		my $this_state = $highlight_by_rpos{$i};

		next if (($this_state == $state) and ($i == $last_rpos + 1));

		# state change; record...
		if (($state == 0) or ($i != $last_rpos + 1)) {

			if (($start_pos > -1) and ($state > 0)) {
				#print "$i # recording highlight kw$state span $start_pos thru $i-1\n";
				push( @high_no_overlap, [
					$self->{'p_opos_by_rpos'}->{ $start_pos },
					$self->{'p_opos_by_rpos'}->{ $last_rpos + 1 } - 1,
					$state,
					],
					);
				}

			#print "$i # we're leaving a dead area and starting a highlight\n";
			$state = $this_state;
			$start_pos = $i;
			}
		elsif ($this_state == 0) {
			#print "$i # we're leaving a live area and stopping a highlight\n";
			push( @high_no_overlap, [
				$self->{'p_opos_by_rpos'}->{ $start_pos },
				$self->{'p_opos_by_rpos'}->{ $i } - 1,
				$state,
				],
				);
			$start_pos = -1;
			$state = $this_state;
			}
		else {
			#print "$i # we're switching from one highlight-string to another\n";
			push( @high_no_overlap, [
				$self->{'p_opos_by_rpos'}->{ $start_pos },
				$self->{'p_opos_by_rpos'}->{ $last_rpos + 1 } - 1,
				$state,
				],
				);
			$start_pos = $i;
			$state = $this_state;
			}

		}
	continue {
		$last_rpos = $i;
		}

	if ($state) {
		#print "$i # closing final span state $state [ $start_pos - $last_rpos-1 ]\n";
		push( @high_no_overlap, [
			$self->{'p_opos_by_rpos'}->{ $start_pos },
			$self->{'p_opos_by_rpos'}->{ $last_rpos + 1 } - 1,
			$state,
			],
			);
		}

	my $fresh_str = '';


	my $last_pos = 0;

	my $record;
	foreach $record (@high_no_overlap) {

		my ($start, $end, $kw_index) = @$record;
		#print "Start;end $start $end\n\n";


		my $start_tag = qq!<span class="fdse_hi$kw_index">!;
		my $end_tag = qq!</span>!;

		if ($type == 0) {
			$start_tag = qq!<b class="hl1">!;
			$end_tag = qq!</b>!;
			}
		elsif ($type == 1) {
			$start_tag = qq!<b class="hl2">!;
			$end_tag = qq!</b>!;
			}


		# read in the lead-up text

		my $len = $start - $last_pos;
		$fresh_str .= substr( $self->{'str_original'}, $last_pos, $len );

		# start the highlighted block:
		$fresh_str .= $start_tag;

		# embed the text-to-be-highlighted:
		$len = $end - $start + 1;
		my $embed = substr( $self->{'str_original'}, $start, $len );

		# walk char-by-char.  respan the highlight tag on each part that is broken by an HTML tag.
		# BUT: don't blindy insert null spans between side-by-side HTML tags, and don't blindly
		# insert them into tags which only have whitespace between them.  doing so might cause
		# HTML validation errors...

		if ($embed =~ m!\<!s) {
			# special

			$embed =~ s!^([^\<]*)\<!$1$end_tag\<!s; # </span> against the first <
			$embed =~ s!\>([^\>]*)$!\>$start_tag$1!s; # <span> in from of the last >

			# now all we need to worry about are internal ">.*<" things.
			# the rule is: throw in a <span> if .* contains non-whitespace characters (it can also contain any other chars)

			$embed =~ s!\>([^\<]*?[^\<\s]+[^\<]*)\<!\>$start_tag$1$end_tag\<!sg;

			# a bug in the above code is that the string:
			#		<foo> bar < xyz </foo>
			# will match ' bar ' as the viewable string and treat '< xyz </foo>' as a tag.
			# The code sample above is not valid HTML, but it will render in Internet Explorer 6.0,
			# which suggests that some sites will use this code.  IE6 treats is as ' bar < xyz ' viewable.
			#
			# The more common counter-example, <foo> bar > xyz </foo>, will work as the user expected,
			# because the pattern above seeks to the next "<" and will read over any un-escaped ">"
			# characters.  The ">" bareword is probably much more common.
			#
			# no fix is planned for the <foo> bar < xyz </foo> problem.  It will simply be yet another
			# negative consequence of using incorrect HTML.

			$fresh_str .= $embed;
			}
		else {
			# shortcut -- no embedded HTML tags to worry about
			$fresh_str .= $embed;
			}


		# finish it:
		$fresh_str .= $end_tag;

		# update the counter:
		$last_pos = $end + 1;
		}
	$fresh_str .= substr( $self->{'str_original'}, $last_pos );
	$fresh_str =~ s!^ !!s;
	$fresh_str =~ s! $!!s;
	return $fresh_str;
	}





sub choose_interface_lang {
	my ($b_is_admin_rq, $browser_lang) = @_;
	my $options = '';
	my $lang = $::Rules{'language'};
	my $err = '';
	Err: {

		my %valid;
		($err, $options, %valid) = &get_valid_langs();
		next Err if ($err);

		last Err if ($b_is_admin_rq);

		my $uls = $::Rules{'user language selection'};

		if (($uls == 1) or ($uls == 3)) {
			# detect lang based on browser

			my $browser = substr( &query_env('HTTP_ACCEPT_LANGUAGE'), 0, 2 );

			# only map non-2-char entries; others pass through
			my %fdse_name_map = (
				'en' => 'english',
				'pt' => 'portuguese',
				'fr' => 'french',
				'it' => 'italian',
				'nl' => 'dutch',
				'de' => 'german',
				'es' => 'spanish',
				);

			$browser = $fdse_name_map{$browser} || $browser;

			if ($valid{$browser}) {
				$lang = $browser;
				}

			}
		if (($uls == 2) or ($uls == 3)) {
			# detect lang from form settings

			if (exists($::FORM{'set:lang'})) {
				$::FORM{'p:lang'} = $::FORM{'set:lang'};
				delete $::FORM{'set:lang'};
				}
			if ((exists($::FORM{'p:lang'})) and ($::FORM{'p:lang'} =~ m!^(\w+)$!s) and ($valid{$1})) {
				$lang = $1;
				}

			}

		last Err;
		}
	return ($err, $options, $lang);
	}





sub get_valid_langs {
	my %valid = ();
	my $err = '';
	Err: {
		my $cache_string = '';
		my $template_time = (stat('templates'))[9];
		my $cache = 'valid_languages_cache.txt';
		if ((-e $cache) and (-f $cache)) {
			($err, $cache_string) = &ReadFileL( $cache );
			next Err if ($err);

			my ($cache_version, $cache_build_time, $cache_template_time, %cache_valid) = split(m!\$!s, $cache_string);

			if (
					($cache_version ne $::VERSION)
					or
					(($::private{'script_start_time'} - $cache_build_time) > 86400)
					or
					($cache_template_time != $template_time)
				) {
				# discard cache
				}
			else {
				%valid = %cache_valid;
				last Err;
				}
			}

		# query file system, either because no cache present, or because it has been discarded:

		if (opendir(DIR, 'templates')) {
			my @folders = sort readdir(DIR);
			closedir(DIR);
			foreach (@folders) {
				next unless (-e "templates/$_/strings.txt");
				unless (open(FILE, "<templates/$_/strings.txt" )) {
					#$err = "unable to open file '$_/strings.txt' - $!"; next Err;
					next;
					}
				my ($ver, $selfname) = (<FILE>, <FILE>);
				close(FILE);
				if ($ver =~ m!^VERSION $::VERSION!s) {
					# ok
					$selfname =~ s!\r|\n|\015|\012!!sg;
					$valid{$_} = $selfname;
					}
				}
			}

		# save cache if possible:

		$cache_string = join( '$', $::VERSION, $::private{'script_start_time'}, $template_time, %valid );
		if (open(FILE, ">$cache")) {
			binmode(FILE);
			print FILE $cache_string;
			close(FILE);
			chmod($::private{'file_mask'},$cache);
			}
		last Err;
		}
	my $options = '';
	foreach (sort keys %valid) {
		$options .= qq!<option value="$_">$valid{$_}</option>!;
		}
	return ($err, $options, %valid);
	}





sub rewrite_url {
	my ($level, $url) = @_;
	my $key = "rewrite_url_" . $level;

	return $url unless (exists $::Rules{$key});

	# format is b_enabled,p1,p2,comment,b_verbose,
	if (not exists $::private{$key}) {
		# create a cache copy
		my @rules = ();
		my $rule;
		foreach $rule (split(m!\&!s, $::Rules{$key})) {
			my @fields = split(m!\=!s, $rule);
			next unless ($fields[0]);
			my @rule = ( &ud($fields[1],$fields[2]), $fields[4] );
			push(@rules, \@rule);
			}
		$::private{$key} = \@rules;
		}
	my $p_rules = $::private{$key}; # pointer to an array of arrays
	my $p_rule;
	foreach $p_rule (@$p_rules) {
		my $init = $url;
		my ($p1, $p2, $b_verbose) = @$p_rule;
		#changed 0056; Brian Renken's contrib; rewrite rules now support $1, $2, uc/lc($1)
		my @backref = ($url =~ m!$p1!is);
		my $count = ($url =~ s!$p1!$p2!isg);
		my $i = 0;
		my $ref;
		foreach $ref (@backref) {
			$i++;
			$url =~ s!lc\(\$$i\)!lc($ref)!iesg;
			$url =~ s!uc\(\$$i\)!uc($ref)!iesg;
			$url =~ s!\$$i!$ref!sg;
			}
		if (($count) and ($b_verbose)) {
			my $h_init = &he($init);
			print "<p><b>Status:</b> URL rewrite feature has converted $h_init to " . &he($url) . ".</p>\n";
			}
		}
	return $url;
	}





sub check_regex {
	my ($pattern) = @_;
	my $err = '';
	Err: {
		if ($pattern =~ m!\?\{!s) {
			$err = &pstr(50,&he($pattern));
			next Err;
			}
		eval '"foo" =~ m!$pattern!s;';
		if ($@) {
			$err = &pstr(51,&he($pattern,$@));
			undef($@);
			next Err;
			}
		}
	return $err;
	}





sub pstr {
	local $_ = $::str[$_[0]];
	my $x = 0;
	foreach $x (1..((scalar @_) - 1)) {
		my $c = (s!\$s$x!$_[$x]!sg);
		#&Assert($c != 0);
		}
	#&Assert( $_ !~ m!\$s\d!s );
	return $_;
	}





sub ppstr {
	local $_ = $::str[$_[0]];
	#&Assert(defined($_));
	my $x = 0;
	foreach $x (1..((scalar @_) - 1)) {
		#&Assert(defined($_[$x]));
		my $c = (s!\$s$x!$_[$x]!sg);
		#&Assert($c != 0);
		}
	#&Assert( $_ !~ m!\$s\d!s );
	print;
	}





sub pppstr {
	local $_ = $::str[$_[0]];
	my $x = 0;
	foreach $x (1..((scalar @_) - 1)) {
		my $c = (s!\$s$x!$_[$x]!sg);
		#&Assert($c != 0);
		}
	#&Assert( $_ !~ m!\$s\d!s );

	if ($::const{'is_cmd'}) {
		print "\n$_\n";
		}
	else {
		print "<p>" . $_ . "</p>\n";
		}
	}





sub CompressStrip {
	local $_ = defined($_[0]) ? $_[0] : '';
	$_ = &RawTranslate(" $_ ");
	s'\s+'  'og;
	eval($::private{'code_strip_ignored_words'});
	die $@ if $@;
	s'\s+' 'og;
	s'^ '';
	s' $'';
	return " $_ ";
	}





sub entity_decode {
	my ($string, $b_return_only_ch, $p_ilen) = @_;

	my $elen = 0; # initialize; assume no entity match

	# decimal:
	if (($string =~ m!^\&\#(\d+)\;?$!s) and ($1 < 256)) {
		$elen = length($string);
		$string = chr($1);
		}

	# hexidecimal:
	elsif (($string =~ m!^\&\#x([0-9a-f]+)\;?$!s) and (hex($1) < 256)) {
		$elen = length($string);
		$string = chr(hex($1));
		}

	# named entity, with explicit closing semicolon:
	elsif (($string =~ m!^\&(\w{2,8})\;$!s) and (exists $::private{'p_entity_value_by_name'}->{$1})) {
		$elen = length($string);
		$string = $::private{'p_entity_value_by_name'}->{$1};
		}

	# named entity, but without closing semicolon.
	# try to match longest possible string
	elsif ($string =~ m!^\&(\w{2,8})$!s) {
		my $test = $1;
		my $len = length($test);
		while ($len > 1) {
			if (exists($::private{'p_entity_value_by_name'}->{ substr($test,0,$len) })) {
				$elen = 1 + $len;
				$string = $::private{'p_entity_value_by_name'}->{ substr($test,0,$len) };
				$string .= substr($test, $len) unless ($b_return_only_ch);
				last;
				}
			$len--;
			}
		}
	if ($b_return_only_ch) {
		$$p_ilen = $elen;
		}
	return $string;
	}





sub create_conversion_code {
	my ($b_verbose) = @_;
	my $code = '';

	# Format of %charset is { char_number => [ @values, $name ] }
	# where @values represents what the character should be converted to under 4 circumstances
	# -1 means "strip, is non-word"
	#  0 means "leave as is"
	# any other string value is the value to be converted to


	my %base_charset = (

		  9 => [   -1,   -1,   -1,   -1, 'Horizontal tab'],
		 10 => [   -1,   -1,   -1,   -1, 'Line feed'],

		 13 => [   -1,   -1,   -1,   -1, 'Carriage Return'],

		 32 => [   -1,   -1,   -1,   -1, 'Space'],
		 33 => [   -1,   -1,   -1,   -1, 'Exclamation mark'],
		 34 => [   -1,   -1,   -1,   -1, 'Quotation mark'],
		 35 => [   -1,   -1,   -1,   -1, 'Number sign'],
		 36 => [   -1,   -1,   -1,   -1, 'Dollar sign'],
		 37 => [   -1,   -1,   -1,   -1, 'Percent sign'],
		 38 => [   -1,   -1,   -1,   -1, 'Ampersand'],
		 39 => [   -1,   -1,   -1,   -1, 'Apostrophe'],
		 40 => [   -1,   -1,   -1,   -1, 'Left parenthesis'],
		 41 => [   -1,   -1,   -1,   -1, 'Right parenthesis'],
		 42 => [   -1,   -1,   -1,   -1, 'Asterisk'],
		 43 => [   -1,   -1,   -1,   -1, 'Plus sign'],
		 44 => [   -1,   -1,   -1,   -1, 'Comma'],
		 45 => [   -1,   -1,   -1,   -1, 'Hyphen'],
		 46 => [   -1,   -1,   -1,   -1, 'Period (fullstop)'],
		 47 => [   -1,   -1,   -1,   -1, 'Solidus (slash)'],
		 48 => [    0,    0,    0,    0, 'Digit 0'],
		 49 => [    0,    0,    0,    0, 'Digit 1'],
		 50 => [    0,    0,    0,    0, 'Digit 2'],
		 51 => [    0,    0,    0,    0, 'Digit 3'],
		 52 => [    0,    0,    0,    0, 'Digit 4'],
		 53 => [    0,    0,    0,    0, 'Digit 5'],
		 54 => [    0,    0,    0,    0, 'Digit 6'],
		 55 => [    0,    0,    0,    0, 'Digit 7'],
		 56 => [    0,    0,    0,    0, 'Digit 8'],
		 57 => [    0,    0,    0,    0, 'Digit 9'],
		 58 => [   -1,   -1,   -1,   -1, 'Colon'],
		 59 => [   -1,   -1,   -1,   -1, 'Semicolon'],
		 60 => [   -1,   -1,   -1,   -1, 'Less than'],
		 61 => [   -1,   -1,   -1,   -1, 'Equals sign'],
		 62 => [   -1,   -1,   -1,   -1, 'Greater than'],
		 63 => [   -1,   -1,   -1,   -1, 'Question mark'],
		 64 => [   -1,   -1,   -1,   -1, 'Commercial at'],
		 65 => [  'a',    0,  'a',    0, 'Capital A'],
		 66 => [  'b',    0,  'b',    0, 'Capital B'],
		 67 => [  'c',    0,  'c',    0, 'Capital C'],
		 68 => [  'd',    0,  'd',    0, 'Capital D'],
		 69 => [  'e',    0,  'e',    0, 'Capital E'],
		 70 => [  'f',    0,  'f',    0, 'Capital F'],
		 71 => [  'g',    0,  'g',    0, 'Capital G'],
		 72 => [  'h',    0,  'h',    0, 'Capital H'],
		 73 => [  'i',    0,  'i',    0, 'Capital I'],
		 74 => [  'j',    0,  'j',    0, 'Capital J'],
		 75 => [  'k',    0,  'k',    0, 'Capital K'],
		 76 => [  'l',    0,  'l',    0, 'Capital L'],
		 77 => [  'm',    0,  'm',    0, 'Capital M'],
		 78 => [  'n',    0,  'n',    0, 'Capital N'],
		 79 => [  'o',    0,  'o',    0, 'Capital O'],
		 80 => [  'p',    0,  'p',    0, 'Capital P'],
		 81 => [  'q',    0,  'q',    0, 'Capital Q'],
		 82 => [  'r',    0,  'r',    0, 'Capital R'],
		 83 => [  's',    0,  's',    0, 'Capital S'],
		 84 => [  't',    0,  't',    0, 'Capital T'],
		 85 => [  'u',    0,  'u',    0, 'Capital U'],
		 86 => [  'v',    0,  'v',    0, 'Capital V'],
		 87 => [  'w',    0,  'w',    0, 'Capital W'],
		 88 => [  'x',    0,  'x',    0, 'Capital X'],
		 89 => [  'y',    0,  'y',    0, 'Capital Y'],
		 90 => [  'z',    0,  'z',    0, 'Capital Z'],
		 91 => [   -1,   -1,   -1,   -1, 'Left square bracket'],
		 92 => [   -1,   -1,   -1,   -1, 'Reverse solidus (backslash)'],
		 93 => [   -1,   -1,   -1,   -1, 'Right square bracket'],
		 94 => [   -1,   -1,   -1,   -1, 'Caret'],
		 95 => [   -1,   -1,   -1,   -1, 'Horizontal bar (underscore)'],
		 96 => [   -1,   -1,   -1,   -1, 'Acute accent'],
		 97 => [    0,    0,    0,    0, 'Small a'],
		 98 => [    0,    0,    0,    0, 'Small b'],
		 99 => [    0,    0,    0,    0, 'Small c'],
		100 => [    0,    0,    0,    0, 'Small d'],
		101 => [    0,    0,    0,    0, 'Small e'],
		102 => [    0,    0,    0,    0, 'Small f'],
		103 => [    0,    0,    0,    0, 'Small g'],
		104 => [    0,    0,    0,    0, 'Small h'],
		105 => [    0,    0,    0,    0, 'Small i'],
		106 => [    0,    0,    0,    0, 'Small j'],
		107 => [    0,    0,    0,    0, 'Small k'],
		108 => [    0,    0,    0,    0, 'Small l'],
		109 => [    0,    0,    0,    0, 'Small m'],
		110 => [    0,    0,    0,    0, 'Small n'],
		111 => [    0,    0,    0,    0, 'Small o'],
		112 => [    0,    0,    0,    0, 'Small p'],
		113 => [    0,    0,    0,    0, 'Small q'],
		114 => [    0,    0,    0,    0, 'Small r'],
		115 => [    0,    0,    0,    0, 'Small s'],
		116 => [    0,    0,    0,    0, 'Small t'],
		117 => [    0,    0,    0,    0, 'Small u'],
		118 => [    0,    0,    0,    0, 'Small v'],
		119 => [    0,    0,    0,    0, 'Small w'],
		120 => [    0,    0,    0,    0, 'Small x'],
		121 => [    0,    0,    0,    0, 'Small y'],
		122 => [    0,    0,    0,    0, 'Small z'],
		123 => [   -1,   -1,   -1,   -1, 'Left curly brace'],
		124 => [   -1,   -1,   -1,   -1, 'Vertical bar'],
		125 => [   -1,   -1,   -1,   -1, 'Right curly brace'],
		126 => [   -1,   -1,   -1,   -1, 'Tilde'],
		);

	my %extended_charset = (


		138 => [  's',  'S', chr(154),    0, 'Scaron'],

		140 => [ 'oe', 'OE', chr(156),    0, 'OE ligature'],

		142 => [  'z',  'Z', chr(158),    0, ''],

		154 => [  's',  's',    0,    0, 'scaron'],

		156 => [ 'oe', 'oe',    0,    0, 'oe ligature'],

		158 => [  'z',  'z',    0,    0, ''],
		159 => [  'y',  'Y', chr(255),    0, ''],
		160 => [   -1,   -1,   -1,   -1, 'Nonbreaking space'],
		161 => [   -1,   -1,   -1,   -1, 'Inverted exclamation'],
		162 => [   -1,   -1,   -1,   -1, 'Cent sign'],
		163 => [   -1,   -1,   -1,   -1, 'Pound sterling'],
		164 => [   -1,   -1,   -1,   -1, 'General currency sign'],
		165 => [   -1,   -1,   -1,   -1, 'Yen sign'],
		166 => [   -1,   -1,   -1,   -1, 'Broken vertical bar'],
		167 => [   -1,   -1,   -1,   -1, 'Section sign'],
		168 => [   -1,   -1,   -1,   -1, 'Diæresis / Umlaut'],
		169 => [   -1,   -1,   -1,   -1, 'Copyright'],
		170 => [   -1,   -1,   -1,   -1, 'Feminine ordinal'],
		171 => [   -1,   -1,   -1,   -1, 'Left angle quote, guillemet left'],
		172 => [   -1,   -1,   -1,   -1, 'Not sign'],
		173 => [   -1,   -1,   -1,   -1, 'Soft hyphen'],
		174 => [   -1,   -1,   -1,   -1, 'Registered trademark'],
		175 => [   -1,   -1,   -1,   -1, 'Macron accent'],
		176 => [   -1,   -1,   -1,   -1, 'Degree sign'],
		177 => [   -1,   -1,   -1,   -1, 'Plus or minus'],
		178 => [   -1,   -1,   -1,   -1, 'Superscript 2'],
		179 => [   -1,   -1,   -1,   -1, 'Superscript 3'],
		180 => [   -1,   -1,   -1,   -1, 'Acute accent'],
		181 => [   -1,   -1,   -1,   -1, 'Micro sign'],
		182 => [   -1,   -1,   -1,   -1, 'Paragraph sign'],
		183 => [   -1,   -1,   -1,   -1, 'Middle dot'],
		184 => [   -1,   -1,   -1,   -1, 'Cedilla'],
		185 => [   -1,   -1,   -1,   -1, 'Superscript 1'],
		186 => [   -1,   -1,   -1,   -1, 'Masculine ordinal'],
		187 => [   -1,   -1,   -1,   -1, 'Right angle quote, guillemet right'],
		188 => [   -1,   -1,   -1,   -1, 'Fraction one-fourth'],
		189 => [   -1,   -1,   -1,   -1, 'Fraction one-half'],
		190 => [   -1,   -1,   -1,   -1, 'Fraction three-fourths'],
		191 => [   -1,   -1,   -1,   -1, 'Inverted question mark'],
		192 => [  'a',  'A', chr(224),    0, 'Capital A, grave accent'],
		193 => [  'a',  'A', chr(225),    0, 'Capital A, acute accent'],
		194 => [  'a',  'A', chr(226),    0, 'Capital A, circumflex'],
		195 => [  'a',  'A', chr(227),    0, 'Capital A, tilde'],
		196 => [ 'ae', 'Ae', chr(228),    0, 'Capital A, diaeresis / umlaut'],
		197 => [  'a',  'A', chr(229),    0, 'Capital A, ring'],
		198 => [ 'ae', 'AE', chr(230),    0, 'Capital AE ligature'],
		199 => [  'c',  'c', chr(231),    0, 'Capital C, cedilla'],
		200 => [  'e',  'E', chr(232),    0, 'Capital E, grave accent'],
		201 => [  'e',  'E', chr(233),    0, 'Capital E, acute accent'],
		202 => [  'e',  'E', chr(234),    0, 'Capital E, circumflex'],
		203 => [  'e',  'E', chr(235),    0, 'Capital E, diaeresis / umlaut'],
		204 => [  'i',  'I', chr(236),    0, 'Capital I, grave accent'],
		205 => [  'i',  'I', chr(237),    0, 'Capital I, acute accent'],
		206 => [  'i',  'I', chr(238),    0, 'Capital I, circumflex'],
		207 => [  'i',  'I', chr(239),    0, 'Capital I, diaeresis / umlaut'],
		208 => [  'd',  'D', chr(240),    0, 'Capital Eth, Icelandic'],
		209 => [  'n',  'N', chr(241),    0, 'Capital N, tilde'],
		210 => [  'o',  'O', chr(242),    0, 'Capital O, grave accent'],
		211 => [  'o',  'O', chr(243),    0, 'Capital O, acute accent'],
		212 => [  'o',  'O', chr(244),    0, 'Capital O, circumflex'],
		213 => [  'o',  'O', chr(245),    0, 'Capital O, tilde'],
		214 => [ 'oe', 'Oe', chr(246),    0, 'Capital O, diaeresis / umlaut'],
		215 => [   -1,   -1,   -1,   -1, 'Multiply sign'],
		216 => [  'o',  'O', chr(248),    0, 'Capital O, slash'],
		217 => [  'u',  'U', chr(249),    0, 'Capital U, grave accent'],
		218 => [  'u',  'U', chr(250),    0, 'Capital U, acute accent'],
		219 => [  'u',  'U', chr(251),    0, 'Capital U, circumflex'],
		220 => [ 'ue', 'Ue', chr(252),    0, 'Capital U, diaeresis / umlaut'],
		221 => [  'y',  'Y', chr(253),    0, 'Capital Y, acute accent'],
		222 => [  'p',  'P', chr(254),    0, 'Capital Thorn, Icelandic'],
		223 => [ 'ss', 'ss',    0,    0, 'Small sharp s, German sz'],
		224 => [  'a',  'a',    0,    0, 'Small a, grave accent'],
		225 => [  'a',  'a',    0,    0, 'Small a, acute accent'],
		226 => [  'a',  'a',    0,    0, 'Small a, circumflex'],
		227 => [  'a',  'a',    0,    0, 'Small a, tilde'],
		228 => [ 'ae', 'ae',    0,    0, 'Small a, diaeresis / umlaut'],
		229 => [  'a',  'a',    0,    0, 'Small a, ring'],
		230 => [ 'ae', 'ae',    0,    0, 'Small ae ligature'],
		231 => [  'c',  'c',    0,    0, 'Small c, cedilla'],
		232 => [  'e',  'e',    0,    0, 'Small e, grave accent'],
		233 => [  'e',  'e',    0,    0, 'Small e, acute accent'],
		234 => [  'e',  'e',    0,    0, 'Small e, circumflex'],
		235 => [  'e',  'e',    0,    0, 'Small e, diaeresis / umlaut'],
		236 => [  'i',  'i',    0,    0, 'Small i, grave accent'],
		237 => [  'i',  'i',    0,    0, 'Small i, acute accent'],
		238 => [  'i',  'i',    0,    0, 'Small i, circumflex'],
		239 => [  'i',  'i',    0,    0, 'Small i, diaeresis / umlaut'],
		240 => [  'o',  'o',    0,    0, 'Small eth, Icelandic'],
		241 => [  'n',  'n',    0,    0, 'Small n, tilde'],
		242 => [  'o',  'o',    0,    0, 'Small o, grave accent'],
		243 => [  'o',  'o',    0,    0, 'Small o, acute accent'],
		244 => [  'o',  'o',    0,    0, 'Small o, circumflex'],
		245 => [  'o',  'o',    0,    0, 'Small o, tilde'],
		246 => [ 'oe', 'oe',    0,    0, 'Small o, diaeresis / umlaut'],
		247 => [   -1,   -1,   -1,   -1, 'Division sign'],
		248 => [  'o',  'o',    0,    0, 'Small o, slash'],
		249 => [  'u',  'u',    0,    0, 'Small u, grave accent'],
		250 => [  'u',  'u',    0,    0, 'Small u, acute accent'],
		251 => [  'u',  'u',    0,    0, 'Small u, circumflex'],
		252 => [ 'ue', 'ue',    0,    0, 'Small u, diaeresis / umlaut'],
		253 => [  'y',  'y',    0,    0, 'Small y, acute accent'],
		254 => [  'p',  'p',    0,    0, 'Small thorn, Icelandic'],
		255 => [  'y',  'y',    0,    0, 'Small y, diaeresis / umlaut'],
		);





=item reserved

	The %reserved hash contains the Latin character index of characters that FDSE uses internally to delimit data, including newlines, whitespace, and the equals sign.  These characters are *always* stripped from incoming data regardless of locale settings.

=cut

	my %reserved = (
		34 => 1,
		38 => 1,
		60 => 1,
		62 => 1,
		9 => 1,
		95 => 1,
		10 => 1,
		13 => 1,
		32 => 1,
		61 => 1,
		);






=item named_entities

	The %named_entities hash maps HTML entities to their Latin character index.

	Numeric formats like "#ddd" and "xHH" are programmatically added to the hash -- there is no need to manually add them.

	Named entities which do not map to alphanumeric "word" characters, like "amp", are omitted as an optimization, since those characters are never included in the index.

=cut

	my %named_entities = (
		'#338' => 140,
		'#339' => 156,
		'#352' => 138,
		'#353' => 154,
		'AElig' => 198,
		'Aacute' => 193,
		'Acirc' => 194,
		'Agrave' => 192,
		'Aring' => 197,
		'Atilde' => 195,
		'Auml' => 196,
		'Ccedil' => 199,
		'ETH' => 208,
		'Eacute' => 201,
		'Ecirc' => 202,
		'Egrave' => 200,
		'Euml' => 203,
		'Iacute' => 205,
		'Icirc' => 206,
		'Igrave' => 204,
		'Iuml' => 207,
		'Ntilde' => 209,
		'OElig' => 140,
		'Oacute' => 211,
		'Ocirc' => 212,
		'Ograve' => 210,
		'Oslash' => 216,
		'Otilde' => 213,
		'Ouml' => 214,
		'Scaron' => 138,
		'THORN' => 222,
		'Uacute' => 218,
		'Ucirc' => 219,
		'Ugrave' => 217,
		'Uuml' => 220,
		'Yacute' => 221,
		'aacute' => 225,
		'acirc' => 226,
		'aelig' => 230,
		'agrave' => 224,
		'aring' => 229,
		'atilde' => 227,
		'auml' => 228,
		'ccedil' => 231,
		'eacute' => 233,
		'ecirc' => 234,
		'egrave' => 232,
		'eth' => 240,
		'euml' => 235,
		'iacute' => 237,
		'icirc' => 238,
		'igrave' => 236,
		'iquest' => 191,
		'iuml' => 239,
		'ntilde' => 241,
		'oacute' => 243,
		'ocirc' => 244,
		'oelig' => 156,
		'ograve' => 242,
		'oslash' => 248,
		'otilde' => 245,
		'ouml' => 246,
		'scaron' => 154,
		'sup1' => 185,
		'sup2' => 178,
		'sup3' => 179,
		'szlig' => 223,
		'thorn' => 254,
		'uacute' => 250,
		'ucirc' => 251,
		'ugrave' => 249,
		'uuml' => 252,
		'yacute' => 253,
		'yuml' => 255,
		);

my @non_word_entities = qw!
Alpha
Beta
Chi
Dagger
Delta
Epsilon
Eta
Gamma
Iota
Kappa
Lambda
Mu
Nu
OElig
Omega
Omicron
Phi
Pi
Prime
Psi
Rho
Scaron
Sigma
Tau
Theta
Upsilon
Xi
Yuml
Zeta
acute
alefsym
alpha
amp
and
ang
apos
asymp
bdquo
beta
brvbar
bull
cap
cedil
cent
chi
circ
clubs
cong
copy
crarr
cup
curren
dArr
dagger
darr
deg
delta
diams
divide
empty
emsp
ensp
epsilon
equiv
eta
euro
exist
fnof
forall
frac12
frac14
frac34
frasl
gamma
ge
gt
hArr
harr
hearts
hellip
iexcl
image
infin
int
iota
iquest
isin
kappa
lArr
lambda
lang
laquo
larr
lceil
ldquo
le
lfloor
lowast
loz
lrm
lsaquo
lsquo
lt
macr
mdash
micro
middot
minus
mu
nabla
nbsp
ndash
ne
ni
not
notin
nsub
nu
oelig
oline
omega
omicron
oplus
or
ordf
ordm
otimes
para
part
permil
perp
phi
pi
piv
plusmn
pound
prime
prod
prop
psi
quot
rArr
radic
rang
raquo
rarr
rceil
rdquo
real
reg
rfloor
rho
rlm
rsaquo
rsquo
sbquo
scaron
sdot
sect
shy
sigma
sigmaf
sim
spades
sube
sum
sup
sup1
sup2
sup3
supe
tau
there4
theta
thetasym
thinsp
tilde
times
trade
uArr
uarr
uml
upsih
upsilon
weierp
xi
yen
zeta
zwj
zwnj
sub
!;


	$::private{'p_entity_value_by_name'} = {};

	foreach (@non_word_entities) {
		$::private{'p_entity_value_by_name'}->{ $_ } = ' ';
		}


	my %entity_name_by_num = ();

	my ($name, $number) = ('', 0);
	while (($name, $number) = each %named_entities) {
		$entity_name_by_num{ $number } .= "$name ";
		$::private{'p_entity_value_by_name'}->{ $name } = chr( $number );
		}


	$::private{'p_single_char_map'} = [];

	my %ac_map_cs = ();
	my @nonword = ();
	my $focus = (2 + (-2 * $::Rules{'character conversion: accent insensitive'})) + (1 + (-1 * $::Rules{'character conversion: case insensitive'}));

	my $chx = 0;

	if (not $b_verbose) {
		for (my $chx = 255; $chx > 0; $chx--) {
			my $ch = chr($chx);
			my $value = -1;
			if (defined($base_charset{$chx})) {
				$value = $base_charset{$chx}[$focus];
				}
			elsif (defined($extended_charset{$chx})) {
				$value = $extended_charset{$chx}[$focus];
				}
			if ($value eq '-1') {
				$nonword[$chx] = 1;
				$::private{'p_single_char_map'}->[$chx] = ' ';
				}
			elsif ($value ne '0') {
				$ac_map_cs{$value} .= $ch;
				$::private{'p_single_char_map'}->[$chx] = $value;
				}
			else {
				$::private{'p_single_char_map'}->[$chx] = $ch;
				}
			}
		}
	else {

print <<"EOM";

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th>$::str[62]</th>
	<th>$::str[45]</th>
	<th>$::str[61]</th>
	<th>$::str[60]</th>
	<th>$::str[59]<br />$::str[57]</th>
	<th>$::str[59]<br />$::str[56]</th>
	<th>$::str[58]<br />$::str[57]</th>
	<th>$::str[58]<br />$::str[56]</th>
</tr>

EOM
		for (my $chx = 255; $chx > 0; $chx--) {
			my $ch = chr($chx);
			my @data = (-1, -1, -1, -1, 'Unused'); #default
			if (defined($base_charset{$chx})) {
				for (0..4) {
					$data[$_] = $base_charset{$chx}[$_];
					}
				}
			elsif (defined($extended_charset{$chx})) {
				for (0..4) {
					$data[$_] = $extended_charset{$chx}[$_];
					}
				}
			print qq!<tr><td align="center"><tt>! . substr(1000 + $chx, 1, 3) . qq!</tt></td><td align="center">$data[4]<br /></td><td nowrap="nowrap"><tt>!;

			if ($entity_name_by_num{$chx}) {
				my @list = split(m!\s+!s, $entity_name_by_num{$chx});
				my $en;
				foreach $en (@list) {
					next unless ($en);
					print '&' . "amp;$en; - &$en;<br />";
					}
				}
			else {
				print "<br />";
				}
			print qq!</tt></td><td class="fdtan" align="center"><b>! . &he($ch) . "<br /></b></td>";
			my $zz = 0;
			for $zz (0..3) {
				if ($zz == $focus) {
					if ($data[$zz] eq '-1') {
						print qq!<td align="center" bgcolor="#cccccc">---</td>\n!;
						$nonword[$chx] = 1;
						}
					elsif ($data[$zz] eq '0') {
						print qq!<td class="fdtan" align="center"><b>$ch</b></td>\n!;
						}
					else {
						print qq!<td class="fdtan" align="center"><b>$data[$zz]</b></td>\n!;
						# format {dest} = {orig orig orig}
						$ac_map_cs{$data[$zz]} .= $ch;
						}
					}
				else {
					if ($data[$zz] eq '-1') {
						print qq!<td align="center"><br /></td>\n!;
						}
					elsif ($data[$zz] eq '0') {
						print qq!<td align="center">$ch</td>\n!;
						}
					else {
						print qq!<td align="center">$data[$zz]</td>\n!;
						}
					}
				}
			print "</tr>\n";
			next;
			}
		print '</table>';
		}



	# build the code to strip spans of non-word characters:

	my @kill = ();
	foreach (1..255) {
		next unless ($nonword[$_]);
		push(@kill,quotemeta(chr($_)));
		}
	my $frag = join("|",@kill);

	my $cnw = '';
	if ($frag) {
		$cnw = "s'($frag)+' 'og;\n";
		}





	my $ccc = '';

	foreach (keys %ac_map_cs) {

		my $ch = ();
		my @chars = ();
		foreach $ch (split(m!!s, $ac_map_cs{$_})) {
			push(@chars, quotemeta($ch));
			}

		my $in = join('|',@chars);
		if (1 == length($in)) {
			$ccc .= "s!$in!$_!sog;\n";
			}
		elsif ($in) {
			$ccc .= "s!($in)!$_!sog;\n";
			}
		}

	@kill = ();
	foreach (keys %reserved) {
		push(@kill, quotemeta(chr($_)));
		}
	$frag = join('|', @kill);
	my $csr = '';
	if ($frag) {
		$csr = "s!($frag)+! !sog;\n";
		}

	#changed 0056 - map %20 to ' ' as very special case to avoid "foo%20bar" from mapping to "foo 20bar"
	$code = <<'EOM';

s!\%20! !sg;

my $temp = 0;
s!(\&(\#\d+|\#x[0-9a-f]+|\w{2,8})\;?)!&entity_decode($1)!seig;

EOM

	$code .= $csr;
	$code .= $ccc;
	$code .= $cnw;

	return $code;
	}

=item foo_sub

=cut

sub foo_sub {
	return;
	}





sub RawTranslate {
	local $_ = defined($_[0]) ? $_[0] : '';
	if (not exists($::private{'conversion_code'})) {
		$::private{'conversion_code'} = &create_conversion_code(0);
		}
	eval $::private{'conversion_code'};
	return $_;
	}





sub SelectAdEx {
	my @Ads = ('','','','');

	my $err = '';
	Err: {

		last Err if ($::private{'is_freeware'});

		my $text = '';
		($err, $text) = &ReadFileL('ads.xml');
		next Err if ($err);

		my $ads_ver = 1;
		if ($text =~ m! version=\"(\d)!s) {
			$ads_ver = $1;
			}

		last Err unless ($text =~ m!<FDSE:Ads placement="(.*?)">(.+)</FDSE:Ads>!s);
		my ($master_pos_str, $ads) = ($1, $2);
		next unless ($master_pos_str);

		#changed 0068

		my $b_query_has_keywords = 0;

		my @patterns = ();
		if (exists $::private{'search_term_patterns'}) {
			@patterns = @{ $::private{'search_term_patterns'} };
			$b_query_has_keywords = 1;
			}
		if (exists $::FORM{'Realm'}) {
			push( @patterns, ' realm ' . &Trim(&CompressStrip($::FORM{'Realm'})) . ' ' );
			$b_query_has_keywords = 1;
			}

		my $term_pattern = '(' . join( '|', @patterns ) . ')';

		my @match_ads = ();
		my @all_ads = ();
		foreach (split(m!<FDSE:Ad !s, $ads)) {
			next unless (m!(.*?)>(.*)</FDSE:Ad>!s);
			my %adinfo = ();
			$adinfo{'text'} = $2;
			my $attributes = $1;
			while ($attributes =~ m!^\s*(\S+)\=\"(.*?)\"(.*)$!s) {
				$adinfo{$1} = $2;
				$attributes = $3;
				}
			if ($ads_ver > 1) {
				foreach (keys %adinfo) {
					$adinfo{$_} = &ud($adinfo{$_});
					}
				}
			push(@all_ads, \%adinfo);
			}


		# for each of 4 positions, select an ad:
		my $i = 1;
		for ($i = 1; $i < 5; $i++) {

			# skip if we've globally decided not to put ads in this position
			next unless ($master_pos_str =~ m!$i!s);

			my ($matchweight, $weight) = (0, 0);
			my (@my_ads, @match_ads) = ();

			# Select an ad for position $i
			my $p_data = ();
			foreach $p_data (@all_ads) {

				# skip this ad if we've decided to to show it at position $i:
				next unless ($$p_data{'placement'} =~ m!$i!s);

				# ok, do we have search words to work with, and are there keywords with this ad?
				my $is_keyword_match = 0;
				if (($b_query_has_keywords) and ($$p_data{'keywords'})) {

					$$p_data{'keywords'} = &CompressStrip( $$p_data{'keywords'} );

					# Is there a keyword match?
					if (" $$p_data{'keywords'} " =~ m!$term_pattern!is) {
						$matchweight += $$p_data{'weight'};
						push(@match_ads, $p_data);
						$is_keyword_match = 1;
						}
					}

				# have they decided that this ad *only* appears for keyword matches?
				if (($$p_data{'kw'}) and (not $is_keyword_match)) {
					# sorry maybe next time:
					next;
					}

				$weight += $$p_data{'weight'};
				push(@my_ads, $p_data);
				}
			if ($matchweight) {
				$weight = $matchweight;
				@my_ads = @match_ads;
				}

			my $num = int($weight * rand());

			foreach $p_data (@my_ads) {
				$num -= $$p_data{'weight'};
				next if ($num > 0);

				# Increment the logfile
				my $logfile = "ads_hitcount_$$p_data{'ident'}.txt";
				my $hits = 0;
				if ((not (-e $logfile)) and (open(FILE, ">$logfile" ))) {
					print FILE 0;
					close(FILE);
					}
				if (open(FILE, "+<$logfile")) {
					$hits = <FILE>;
					seek(FILE, 0, 0);
					print FILE ++$hits;
					close(FILE);
					}
				$Ads[$i-1] = $$p_data{'text'};
				last;
				}
			}
		}
	return @Ads;
	}





sub PrintTemplate {
	my ($b_return_as_string, $file, $language, $p_replace, $p_visited, $p_cache) = @_;
	my $return_text = '';

	my $err = '';
	Err: {

		# Initialize:
		unless ($p_replace) {
			my %hash = ();
			$p_replace = \%hash;
			}
		$$p_replace{'version'} = $::VERSION;

		unless ($p_visited) {
			my %hash = ();
			$p_visited = \%hash;
			}

		my $text = '';
		if (($p_cache) and ('HASH' eq ref($p_cache)) and (exists($$p_cache{$file}))) {
			$text = $$p_cache{$file};
			}
		else {
			my $fullfile = '';
			my $base = "templates/$language/";
			my $max_parents = 12;
			for (0..$max_parents) {
				$fullfile = $base . ('../' x $_) . $file;
				$fullfile =~ s!/+!/!sg;
				last if (-e $fullfile);
				}
			unless (-e $fullfile) {
				$err = "unable to find file '$file'";
				next Err;
				}
			if ($fullfile =~ m!([^\\|/]+)$!s) {
				$$p_visited{$1}++;
				}
			($err, $text) = &ReadFileL($fullfile);
			next Err if ($err);

			if (($p_cache) and ('HASH' eq ref($p_cache))) {
				$$p_cache{$file} = $text;
				}
			}



		#conditionals
		foreach (reverse sort keys %$p_replace) {
			next unless (defined($_));
			$$p_replace{$_} = '' if (not defined($$p_replace{$_}));
			if ($$p_replace{$_}) {
				# true
				$text =~ s!<%\s*if\s+$_\s*%\>(.*?)<%\s*end\s*if\s*%>!$1!isg;
				$text =~ s!<%\s*(if\s+not|unless)\s+$_\s*%>.*?<%\s*end\s*if\s*%>!!isg;
				}
			else {
				# false
				$text =~ s!<%\s*if\s+$_\s*%>.*?<%\s*end\s*if\s*%>!!isg;
				$text =~ s!<%\s*(if\s+not|unless)\s+$_\s*%>(.*?)<%\s*end\s*if\s*%>!$2!isg;
				}
			}



		foreach (reverse sort keys %$p_replace) {
			#revcompat
			$text =~ s!\$$_!$$p_replace{$_}!isg;
			$text =~ s!\_\_$_\_\_!$$p_replace{$_}!isg;
			#/revcompat
			$text =~ s!\%$_\%!$$p_replace{$_}!isg;
			}

		my $pattern = '<!--#(include file|include virtual|echo var)=\"(.*?)\" -->';

		while ($text =~ m!^(.*?)$pattern(.*)$!is) {
			my ($start, $c1, $incfile, $end) = ($1, lc($2), $3, $4);

			if ($b_return_as_string) {
				$return_text .= $start;
				}
			else {
				print $start;
				}

			if ($c1 eq 'echo var') {
				my $var = uc($incfile);
				my $vardata = '';
				if ($var eq 'DATE_GMT') {
					$vardata = scalar gmtime();
					}
				elsif ($var eq 'DATE_LOCAL') {
					$vardata = scalar localtime();
					}
				elsif ($var eq 'DOCUMENT_NAME') {
					$vardata = $1 if ($0 =~ m!([^\\|/]+)$!s);
					}
				elsif ($var eq 'DOCUMENT_URI') {
					$vardata = &query_env('SCRIPT_NAME');
					}
				elsif ($var eq 'LAST_MODIFIED') {
					$vardata = scalar localtime( (stat($0))[9] );
					}
				elsif (defined($ENV{$var})) {
					$vardata = &query_env($var);
					}

				if ($b_return_as_string) {
					$return_text .= $vardata;
					}
				else {
					print $vardata;
					}

				}
			else {

				my $basefile = $incfile;
				if ($incfile =~ m!.*(\\|/)(.*?)$!s) {
					$basefile = $2;
					}

				my $outstr = '';

				# Do we have a file extension?
				if ($basefile !~ m!\.(txt|htm|html|shtml|stm|inc)$!is) {
					$outstr = "<!-- FDSE: not including file '$incfile' because does not have a text/html file extension -->";
					}
				elsif ($$p_visited{$basefile}) {
					$outstr = "<!-- FDSE: loop avoidance: already parsed file '$basefile' -->";
					}
				else {
					$$p_visited{$basefile}++;
					$outstr .= &PrintTemplate( $b_return_as_string, $incfile, $language, $p_replace, $p_visited );
					}

				if ($b_return_as_string) {
					$return_text .= $outstr;
					}
				else {
					print $outstr;
					}

				}


			$text = $end;
			}

		if ($b_return_as_string) {
			$return_text .= $text;
			}
		else {
			print $text;
			}

		last Err;
		}
	continue {
		if ($b_return_as_string) {
			$return_text .= &pstr(29,$err);
			}
		else {
			&ppstr(29,$err);
			}
		}
	return $return_text;
	}





sub ReadInput {
	# Initialize:
	%::FORM = ();
	my @Pairs = @ARGV;
	if (($ARGV[0]) and ($ARGV[0] eq 'is_shell_include=1')) {
		# use argv
		}
	elsif (&query_env('REQUEST_METHOD') eq 'POST') {
		my $buffer = '';
		read(STDIN, $buffer, &query_env('CONTENT_LENGTH',0));
		&untaintme(\$buffer);
		@Pairs = split(m!\&!s, $buffer);
		}
	elsif ($ENV{'QUERY_STRING'}) {
		@Pairs = split(m!\&!s, &query_env('QUERY_STRING'));
		}
	#changed 0054 - support for multi-select
	my ($name, $value);
	foreach (@Pairs) {
		next unless (m!^(.*?)=(.*)$!s);
		($name, $value) = &ud($1,$2);
		if (exists($::FORM{$name})) {
			# multi
			$::FORM{$name} .= ",$value";
			}
		else {
			$::FORM{$name} = $value;
			}
		}
	#changed 0053 - support for undefined-alt-value
	foreach (keys %::FORM) {
		next unless (m!^(.*)_udav$!s);
		next if (exists($::FORM{$1}));
		$::FORM{$1} = $::FORM{$_};
		}
	$::FORM{'Mode'} = '' if (not (exists($::FORM{'Mode'})));
	}





sub Trim {
	local $_ = defined($_[0]) ? $_[0] : '';
	s!^[\r\n\s]+!!so;
	s![\r\n\s]+$!!so;
	return $_;
	}





sub ue {
	my @out = @_;
	local $_;
	foreach (@out) {
		$_ = '' if (not defined($_));
		s!([^a-zA-Z0-9_.-])!uc(sprintf("%%%02x", ord($1)))!seg;
		}
	if ((wantarray) or ($#out > 0)) {
		return @out;
		}
	else {
		return $out[0];
		}
	}



sub ud {
	my @out = @_;
	local $_;
	foreach (@out) {
		next unless (defined($_));
		tr!+! !;
		s!\%([a-fA-F0-9][a-fA-F0-9])!pack('C', hex($1))!seg;
		}
	if ((wantarray) or ($#out > 0)) {
		return @out;
		}
	else {
		return $out[0];
		}
	}





sub ReadFile {
	my ($file) = @_;
	my ($err, $text) = ('', '');
	Err: {
		my ($BytesToRead, $BytesRead, $obj, $p_rhandle) = (-s $file);

		last Err unless ($BytesToRead);

		$obj = &LockFile_new();
		($err, $p_rhandle) = $obj->Read($file);
		next Err if ($err);

		$BytesRead = read($$p_rhandle, $text, $BytesToRead);
		$err = $obj->Close();
		next Err if ($err);

		unless ($BytesRead == $BytesToRead) {
			$err = &pstr(47, $file, $BytesRead, $BytesToRead );
			next Err;
			}
		}
	return ($err, $text);
	}





sub ReadFileL {
	my ($file) = @_;
	my ($err,$text) = ('','');
	Err: {
		unless (open(FILE, "<$file")) {
			$err = &pstr(44,$file,$!);
			next Err;
			}
		unless (binmode(FILE)) {
			$err = &pstr(39,$file,$!);
			next Err;
			}
		$text = join('',<FILE>);
		}
	close(FILE);
	return ($err,$text);
	}





sub log_search {
	my ($realm, $terms, $rank, $documents_found, $documents_searched) = @_;
	my $err = '';
	Err: {
		last unless ($::Rules{'logging: enable'});

		$terms = &he( $terms );

		#changed 0058
		if ($realm eq 'include-by-name') {
			my @realms = ();
			foreach (keys %::FORM) {
				next unless (m!^Realm:(.+)$!s);
				push(@realms, $1);
				}
			$realm = join('|',sort @realms);
			}


		my $host = &query_env('REMOTE_HOST') || $::private{'visitor_ip_addr'} || 'undefined';

		my $time = time();
		my $human_time = &FormatDateTime( $time, 14, 0 );

		my $lang = $::Rules{'language'};
		$lang =~ s!\,|\r|\n|\015|\012!!sg;

		my @fields = ($host,$time,$human_time,$realm,$terms,$rank,$documents_found,$documents_searched,$lang);

		#validate/cleanse all fields so as not to corrupt CSV
		foreach (@fields) {
			s!(\,|\s|\r|\n|\015|\012|\")+! !sg;
			}

		my $logline = join(',', @fields) . ",\n";
		$logline =~ s!^(.+?)\,(.*)!$1 ,$2!s; # insert space before first comma

		unless (open(LOGFILE, ">>search.log.txt")) {
			$err = &pstr(42,'search.log.txt',$!);
			next Err;
			}
		binmode(LOGFILE);
		print LOGFILE $logline;
		close(LOGFILE);
		chmod($::private{'file_mask'},'search.log.txt');


		eval {
			DBMLog: {

				last DBMLog unless ($::Rules{'use dbm routines'});

				if (length($terms) > 64) {# prevent overflow in dbm key-value len
					$terms = substr($terms,0,64);
					}

				my (%str_all, %str_t20) = ();

				last DBMLog unless (dbmopen( %str_all, 'dbm_strlog_all', 0666 ));
				my $total = ++$str_all{$terms};

				#maxval
				if (not defined($str_all{'+++'})) {
					$str_all{'+++'} = $total;
					}
				elsif ($total > $str_all{'+++'}) {
					$str_all{'+++'} = $total;
					}

				$str_all{'++'} = time() unless ($str_all{'++'});
				$str_all{'+'} = $str_all{'+'} || 0; # boundary

				last unless ($total >= $str_all{'+'});

				last DBMLog unless ($::Rules{'logging: display most popular'});
				dbmopen( %str_t20, 'dbm_strlog_top', 0666 ) || die &pstr( 43, 'dbm_strlog_top', $! );

				$str_t20{'++'} = time() unless ($str_t20{'++'});

				$str_t20{$terms} = $total;

				my $maxval = 0;
				my $count = 0;
				foreach (sort { $str_t20{$b} <=> $str_t20{$a} || $a cmp $b } keys %str_t20) {
					next if (m!^\++$!s);
					$count++;
					if ($count > $::Rules{'logging: display most popular'}) {
						delete $str_t20{$_};
						}
					else {
						if ($str_t20{$_} > $maxval) {
							$maxval = $str_t20{$_};
							}
						$str_all{'+'} = $str_t20{$_};
						}
					}
				if ($count < $::Rules{'logging: display most popular'}) {
					$str_all{'+'} = 0;
					}


				#maxval
				if (not defined($str_t20{'+++'})) {
					$str_t20{'+++'} = $maxval;
					}
				elsif ($maxval > $str_t20{'+++'}) {
					$str_t20{'+++'} = $maxval;
					}



				}
			};
		if ($@) {
			&ppstr(53, &pstr(20, &he($@), "$::const{'help_file'}1169.html" ) );
			}



		}
	return $err;
	}





sub FormatNumber {
	my ( $expression, $decimal_places, $include_leading_digit, $use_parens_for_negative, $group_digits, $euro_style ) = @_;

	my $dec_ch = ($euro_style) ? ',' : '.';
	my $tho_ch = ($euro_style) ? '.' : ',';

	my $qm_dec_ch = quotemeta( $dec_ch );

	local $_ = $expression;
	unless (m!^\-?\d*\.?\d*$!s) {
		#print "Warning: arg '$num' isn't numeric.\n";
		$_ = 0;
		}

	my $exp = 1;
	for (1..$decimal_places) {
		$exp *= 10;
		}
	$_ *= $exp;
	$_ = int($_);
	$_ = ($_ / $exp);


	# Add a trailing decimal divider if we don't have one yet
	$_ .= '.' unless (m!\.!s);

	# Pad zero'es if appropriate:
	if ($decimal_places) {
		if (m!^(.*)\.(.*)$!s) {
			$_ .= '0' x ($decimal_places - length($2));
			}
		}

	# Re-write with localized decimal divider:
	s!\.!$dec_ch!so;

	# Group digits:
	if ($group_digits) {
		while (m!(.*)(\d)(\d\d\d)(\,|\.)(.*)!s) {
			$_ = "$1$2$tho_ch$3$4$5";
			}
		}

	if ($include_leading_digit) {
		s!^$qm_dec_ch!0$dec_ch!so;
		}

	# Have we somehow ended up with just a decimal point?  Make it zero then:
	if ("foo$_" eq "foo$dec_ch") {
		$_ = "0";
		}

	# Strip trailing decimal point
	s!$qm_dec_ch$!!so;

	if ($use_parens_for_negative) {
		s!^\-(.*)$!\($1\)!so;
		}

	return $_;
	}





sub FormatDateTime {
	my ($time, $format_type, $b_format_as_gmt) = @_;
	$format_type = 0 unless ($format_type);
	my $date_str = '';

	$time = 0 unless ($time);

	if ($format_type == 13) {

		if ($b_format_as_gmt) {
			$date_str = scalar gmtime( $time );
			}
		else {
			$date_str = scalar localtime( $time );
			}
		}
	else {

		my ($sec, $min, $milhour, $day, $month_index, $year, $weekday_index) = ($b_format_as_gmt) ? gmtime( $time ) : localtime( $time );

		$year += 1900;

		my $ampm = ( $milhour >= 12 ) ? 'PM' : 'AM';
		my $relhour = (($milhour - 1) % 12) + 1;
		my $month = $month_index + 1;

		foreach ($milhour, $relhour, $min, $sec, $month, $day) {
			$_ = "0$_" if (1 == length($_));
			}

		my @MonthNames = (
			$::str[8],
			$::str[9],
			$::str[26],
			$::str[32],
			$::str[40],
			$::str[48],
			$::str[36],
			$::str[34],
			$::str[33],
			$::str[31],
			$::str[30],
			$::str[27],
			);

		my @WeekNames = (
			$::str[25],
			$::str[24],
			$::str[28],
			$::str[7],
			$::str[6],
			$::str[5],
			$::str[22],
			);

		my $full_weekday = $WeekNames[$weekday_index];
		my $short_weekday = substr($full_weekday, 0, 3);

		my $full_monthname = $MonthNames[$month_index];
		my $short_monthname = substr($full_monthname, 0, 3); #localize bug?

		if ($format_type == 0) {
			$date_str = "$month/$day/$year $relhour:$min:$sec $ampm";
			}
		elsif ($format_type == 1) {
			$date_str = "$full_weekday, $full_monthname $day, $year";
			}
		elsif ($format_type == 2) {
			$date_str = "$month/$day/$year";
			}
		elsif ($format_type == 3) {
			$date_str = "$relhour:$min:$sec $ampm";
			}
		elsif ($format_type == 4) {
			$date_str = "$milhour:$min";
			}
		elsif ($format_type == 10) {
			$date_str = "$short_weekday $month/$day/$year $relhour:$min:$sec $ampm";
			}
		elsif ($format_type == 11) {
			$date_str = "$short_weekday, $day $short_monthname $year $milhour:$min:$sec -0000";
			}
		elsif ($format_type == 12) {
			$date_str = "$year-$month-$day $milhour:$min:$sec";
			}
		elsif ($format_type == 14) {
			$date_str = "$month/$day/$year $milhour:$min";
			}
		}
	return $date_str;
	}





sub SetDefaults {
	my ($text, $p_params) = @_;

	# short-circuit:
	if ((ref($p_params) ne 'HASH') or (not (%$p_params))) {
		return $text;
		}


	my @array = split(m!<(INPUT|SELECT|TEXTAREA)([^\>]+?)\>!is, $text);

	my $finaltext = $array[0];

	my $setval;

	my $x = 1;
	for ($x = 1; $x < $#array; $x += 3) {

		my ($uctag, $origtag, $attribs, $trail) = (uc($array[$x]), $array[$x], $array[$x+1] || '', $array[$x+2] || '');

		Tweak: {

			my $tag_name = '';
			if ($attribs =~ m! NAME\s*=\s*\"([^\"]+?)\"!is) {
				$tag_name = $1;
				}
			elsif ($attribs =~ m! NAME\s*=\s*(\S+)!is) {
				$tag_name = $1;
				}
			else {

				# we cannot modify what we do not understand:
				last Tweak;
				}
			last Tweak unless exists $p_params->{$tag_name};
			last Tweak unless defined $p_params->{$tag_name};
			$setval = &he($$p_params{$tag_name});


			if ($uctag eq 'INPUT') {

				# discover VALUE and TYPE
				my $type = 'TEXT';
				if ($attribs =~ m! TYPE\s*=\s*\"([^\"]+?)\"!is) {
					$type = uc($1);
					}
				elsif ($attribs =~ m! TYPE\s*=\s*(\S+)!is) {
					$type = uc($1);
					}

				# discover VALUE and TYPE
				my $value = '';
				if ($attribs =~ m! VALUE\s*=\s*\"([^\"]+?)\"!is) {
					$value = $1;
					}
				elsif ($attribs =~ m! VALUE\s*=\s*(\S+)!is) {
					$value = $1;
					}

				# we can only set values for known types:

				if (($type eq 'RADIO') or ($type eq 'CHECKBOX')) {

					#changed 2001-11-15; strip pre-existing checks
					$attribs =~ s! (checked="checked"|checked)($| )!$2!ois;

					if ($setval eq $value) {
						$attribs = qq! checked="checked"$attribs!;
						}

					}
				elsif (($type eq 'TEXT') or ($type eq 'PASSWORD') or ($type eq 'HIDDEN')) {

					# but only hidden fields if value is null:

					last Tweak if (($type eq 'HIDDEN') and ($value ne ''));

					# replace any existing VALUE tag:
					my $qm_value = quotemeta($value);
					$attribs =~ s! value\s*=\s*\"$qm_value\"! value="$setval"!iso;
					$attribs =~ s! value\s*=\s*$qm_value! value="$setval"!iso;

					# add the tag if it's not present (i.e. if no VALUE was present in original tag)
					my $qm_setval = quotemeta($setval);
					unless ($attribs =~ m! VALUE="$qm_setval"!is) {
						$attribs = " value=\"$setval\"$attribs";
						}

					}
				}
			elsif ($uctag eq 'SELECT') {

# does not support <OPTION>value syntax, only <OPTION VALUE="value">value

				my $lc_set_value = lc($setval);

				my @frags = ();
				foreach (split(m!<option!is, $trail)) {

					#changed 2001-11-15; strip pre-existing "selected"
					$_ =~ s! (selected|selected="selected")($| )!$2!ois;

					if (m!VALUE\s*=\s*\"(.*?)\"!is) {
						if ($lc_set_value eq lc($1)) {
							$_ = ' selected="selected"' . $_;
							}
						}
					elsif (m!VALUE\s*=\s*(\S+)!is) {
						if ($lc_set_value eq lc($1)) {
							$_ = ' selected="selected"' . $_;
							}
						}
					push(@frags, $_);
					}
				$trail = join('<option', @frags);
				}
			elsif ($uctag eq 'TEXTAREA') {
				$trail =~ s!^.*?</(textarea)>!\r\n$setval</$1>!osi;#changed 2005-07-07 inserting leading line break before value
				}
			last Tweak;
			}

		$finaltext .= "<$origtag$attribs>$trail";
		}
	return $finaltext;
	}





sub SearchIndexFile {
	my $err = '';
	Err: {
		local $_;
		my ($file, $search_code, $r_pages_searched, $r_hits) = @_;

		my ($obj, $p_rhandle) = ();

		$obj = &LockFile_new();
		($err, $p_rhandle) = $obj->Read( $file );
		next Err if ($err);
		eval($search_code);
		die $@ if ($@);
		$err = $obj->Close();
		next Err if ($err);
		last Err;
		}
	continue {
		&ppstr(29,$err);
		}
	}





sub leadpad {
	my ($expr, $padch, $padlen) = @_;
	if (length($expr) <= $padlen) {
		return ($padch x ($padlen - length($expr))) . $expr;
		}
	else {
		return substr($expr, length($expr) - $padlen, 6);
		}
	}





sub text_record_from_hash {
	my ($p_pagedata) = @_;
	my ($err, $text_record) = ('', '');

	Err: {
		my @require_fields = ('url', 'promote', 'size', 'title', 'description', 'keywords', 'text', 'links');

		foreach (@require_fields) {
			next if (exists($$p_pagedata{$_}));
			$err = &pstr(21,$_);
			next Err;
			}

		&compress_hash( $p_pagedata );

		$text_record = '';
		foreach ('promote', 'dd', 'mm') {
			$text_record .= &leadpad( $$p_pagedata{$_}, '0', 2 );
			}

		#changed 0053 - not longer forcing size to be 6 digits
		$text_record .= $$p_pagedata{'yyyy'} . $$p_pagedata{'size'};


		foreach ('url', 'title', 'description') {
			$$p_pagedata{$_} =~ s'= '=%20'og;
			}

		$text_record .= ' ' . $$p_pagedata{'lastmodtime'};
		$text_record .= ' ' . $$p_pagedata{'lastindex'};

		$text_record .= ' u= ' . $$p_pagedata{'url'};
		$text_record .= ' t= ' . $$p_pagedata{'title'};
		$text_record .= ' d= ' . $$p_pagedata{'description'};
		$text_record .= ' uM=' . $$p_pagedata{'um'};
		$text_record .= 'uT=' . $$p_pagedata{'ut'};
		$text_record .= 'uD=' . $$p_pagedata{'ud'};
		$text_record .= 'uK=' . $$p_pagedata{'uk'};
		$text_record .= 'h=' . $$p_pagedata{'text'};
		$text_record .= 'l=' . $$p_pagedata{'links'};
		$text_record .= "\n";
		last Err;
		}
	return ($err, $text_record);
	}





sub compress_hash {
	my ($p_pagedata) = @_;

	return if ($$p_pagedata{'compressed'});

	# Solidify time fields:
	foreach ('lastindex', 'lastmodtime') {
		$$p_pagedata{$_} = time() unless ($$p_pagedata{$_});
		}
	unless (($$p_pagedata{'dd'}) and ($$p_pagedata{'mm'}) and ($$p_pagedata{'yyyy'})) {
		($$p_pagedata{'dd'}, $$p_pagedata{'mm'}, $$p_pagedata{'yyyy'}) = (localtime($$p_pagedata{'lastmodtime'}))[3..5];
		$$p_pagedata{'yyyy'} += 1900;
		}
	my %pairs = (
		'um' => 'url',
		'ut' => 'title',
		'ud' => 'description',
		'uk' => 'keywords',
		'text' => 'text',
		'links' => 'links',
		);
	my ($name, $value) = ();
	while (($name, $value) = each %pairs) {
		$$p_pagedata{$name} = &CompressStrip($$p_pagedata{$value});
		}
	$$p_pagedata{'compressed'} = 1;
	}





sub StandardVersion {
	my (%pagedata) = @_;

	local $_;
	foreach ('redirector', 'relevance', 'record_realm', 'context') {
		$pagedata{$_} = '' unless (defined($pagedata{$_}));
		}

	unless ((defined($pagedata{'dd'})) and (defined($pagedata{'mm'})) and (defined($pagedata{'yyyy'}))) {
		if ($pagedata{'lastindex'}) {
			($pagedata{'dd'}, $pagedata{'mm'}, $pagedata{'yyyy'}) = (localtime($pagedata{'lastmodtime'}))[3..5];
			$pagedata{'yyyy'} += 1900;
			}
		}


	$pagedata{'day'} = $pagedata{'dd'};

	$pagedata{'month'} = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$pagedata{'mm'}];
	$pagedata{'year'} = $pagedata{'yyyy'};

	#changed 0056
	$pagedata{'size'} = &FormatNumber( ($pagedata{'size'} + 1023) / 1024, 0, 1, 0, 1, $::Rules{'ui: number format'} ) . 'KB';

	if (exists $::private{'search_term_patterns'}) {

		my $obj = &highlighter_new();
		$obj->highlighter_scan( $pagedata{'description'} );
		$pagedata{'description'} = $obj->highlight( $::private{'search_term_patterns'}, 0 );


		$obj = &highlighter_new();
		$obj->highlighter_scan( $pagedata{'context'} );
		$pagedata{'context'} = $obj->highlight( $::private{'search_term_patterns'}, 1 );
		}


	if ($pagedata{'context'}) {
		$pagedata{'context_line'} = "<br /><b>$::str[35]:</b> $pagedata{'context'}";
		}
	else {
		$pagedata{'context_line'} = '';
		}

	$pagedata{'admin_options'} = '' unless (defined($pagedata{'admin_options'}));

	$pagedata{'url'} = &rewrite_url( 1, $pagedata{'url'} );

	if ($pagedata{'url'} =~ m!^\w+\://([^/]+)!s) {
		$pagedata{'host'} = $1;
		}

	#revcompat - 0033
	$pagedata{'target'} = '';
	#/revcompat

	#changed 0050
	$pagedata{'url_terms'} = &ue($::const{'terms'});
	$pagedata{'url_url'} = &ue($pagedata{'url'});
	$pagedata{'html_url'} = $pagedata{'url'} = &he($pagedata{'url'});

	#changed 0053 - all const avail
	my ($n,$v);
	while (($n,$v) = each %::const) {
		$pagedata{$n} = $::const{$n} unless defined($pagedata{$n});
		}

	$pagedata{'file_type_icon'} = &get_file_type_icon_by_url( $pagedata{'url'} );

	return &PrintTemplate( 1, 'line_listing.txt', $::Rules{'language'}, \%pagedata, 0, \%::const);
	}





sub get_file_type_icon_by_url {
	my ($URL) = @_;

	# 1. determine file extension by URL:
	my $extension = $URL;
	$extension =~ s!\#|\?.*$!!s;
	$extension = ($extension =~ m!\.(\w+)$!s) ? lc($1) : '';

	my %icon_by_ext = (

		'doc'      => 'doc', # special print formats
		'pdf'      => 'pdf',
		'txt'      => 'txt',
		'xls'      => 'xls',
		'pub'      => 'pub',

		'mp3'      => 'audio', # audio formats
		'wav'      => 'audio',

		'mpg'      => 'video', # video formats
		'avi'      => 'video',
		);

	return $icon_by_ext{$extension} || '0';
	}





sub str_jumptext {

	my ( $start_pos, $units_per_page, $maximum, $url, $b_is_exact_count ) = @_;

	$start_pos = 1 if ($start_pos < 1);

	my $end_pos = $start_pos + $units_per_page - 1;


	unless ($b_is_exact_count) {
		$b_is_exact_count = 1 if ($maximum < $end_pos);
		}

	$end_pos = $maximum if ($maximum < $end_pos);

	my ($jump_sum, $jumptext) = ('', '');

	if ($b_is_exact_count) {
		$jump_sum = &pstr(15, $start_pos, $end_pos, $maximum );
		}
	else {
		$jump_sum = &pstr(15, $start_pos, $end_pos, $end_pos . '+' );

		# Okay, we've printed what we know.  Now, for purposes of generating advance links, pretend that there's at least one page beyond this one (we know that if max < curr+units then we would have toggled to b_is_exact_count earlier.  and if max already exceeds this page's worth fo data, then there's no need to tweak it:

		if ($maximum == $end_pos) {
			$maximum++;
			}

		}



	if ($maximum > $units_per_page) {

		# Time for a scrolling thing - "<- Previous 1 2 3 4 5 Next ->"

		$jumptext .= '<p class="fd_results">';
		$jumptext .= $::str[16];
		$jumptext .= ' ';

		if ($start_pos > 1) {
			$jumptext .= " <a href=\"$url" . ($start_pos - $units_per_page) . "\">&lt;&lt; $::str[17]</a> | ";
			}

		my $nlinks = 1 + int(($maximum - 1) / $units_per_page);
		my $thislink = 1 + int($start_pos / $units_per_page);

		my $start = 1;
		if ($thislink > 15) {
			$start = $thislink - 15;
			}

		my @links = ();
		my $x = 0;
		for ($x = $start; $x <= $nlinks; $x++) {
			if ($x == $thislink) {
				push( @links, "<b>$x</b>" );
				}
			else {
				my $start = 1 + (($x - 1) * $units_per_page);
				push( @links, qq!<a href="$url$start">$x</a>! );
				}
			last if ($x > ($start + 18));
			}

		$jumptext .= join( ' | ', @links );

		if ($maximum > $end_pos) {
			$jumptext .= " | <a href=\"$url" . ($start_pos + $units_per_page) . "\">$::str[18] &gt;&gt;</a>";
			}

		$jumptext .= "</p>\n";
		}
	return ('<p class="fd_results">' . $jump_sum . '</p>', $jumptext);#changed 0054 - para
	}





sub Assert {
	return if ($_[0]);
	my ($package, $file, $line) = caller();
	&header_print();
	print "<hr /><h1><pre>Assertion Error:<br />	Package: $package<br />	File: $file<br />	Line: $line</pre></h1><hr />";
	}





sub LoadRules {
	my ($DEFAULT_LANGUAGE) = @_;
	my $err = '';
	Err: {
		%::Rules = ();

		my $FDR = &FD_Rules_new();
		$::Rules{'file'} = $FDR->{'file'};

		my $text = '';
		($err, $text) = &ReadFile($::Rules{'file'});
		next Err if ($err);

		my $line = '';
		foreach $line (split(m!\r|\n!s, $text)) {
			next if ($line =~ m!^\s*\#!s); # skip comments
			next unless ($line =~ m!(.*?)=(.*)!s);
			my ($name, $value) = (lc(&Trim($1)), &Trim($2));
			my ($is_valid, $valid_value) = $FDR->_fdr_validate($name, $value);
			$::Rules{$name} = $valid_value;
			}
		#revcompat pre 0056
		if (((exists($::Rules{'allow index entire site'})) or (exists($::Rules{'allow filtered realms'}))) and (not exists($::Rules{'show advanced commands'}))) {
			$::Rules{'show advanced commands'} = 1;
			}
		#/revcompat


		my $r_defaults = $FDR->{'r_defaults'};
		if (($r_defaults) and ('HASH' eq ref($r_defaults))) {
			my %defhash = %$r_defaults;
			local $_;
			while (defined($_ = each %defhash)) {
				next if exists($::Rules{$_});
				if ($_ eq 'language') {
					$::Rules{$_} = $DEFAULT_LANGUAGE;
					next;
					}
				$::Rules{$_} = $defhash{$_}[0];
				}
			}

		# build derived values:

		if ($::Rules{'admin notify: sendmail program'}) {
			my $b_is_valid = 0;
			foreach (@::sendmail) {
				$b_is_valid = 1 if ($_ eq $::Rules{'admin notify: sendmail program'});
				}
			unless ($b_is_valid) {
				$::Rules{'admin notify: sendmail program'} = '';
				}
			}

		foreach ('wildcard match','ignore words') {
			next unless ($::Rules{$_});
			$::Rules{$_} =~ s!\?\{!!sg; # strip code-exec regex
			}


		my %NewWords = ();
		foreach (split(m!\s+!s, &RawTranslate($::Rules{'ignore words'}))) {
			$NewWords{quotemeta($_)}++;
			}
		my $frag = join('|', sort keys %NewWords);
		$frag =~ s!^\|!!s;
		$frag =~ s!\|$!!s;
		$::private{'code_strip_ignored_words'} = "s! ($frag) ! !sog;";

		my @ignored_extensions = split(m!\s+!s, $::Rules{'crawler: ignore links to'});
		if (@ignored_extensions) {
			my %ig_ext = ();
			foreach (@ignored_extensions) {
				$ig_ext{quotemeta(lc($_))}++;
				}
			$::private{'pattern_is_ignored_extension'} = '\.(' . join('|', sort keys %ig_ext) . ')$';
			}
		else {
			$::private{'pattern_is_ignored_extension'} = '';
			}
		}
	return $err;
	}





sub str_search_form {
	my ($action) = @_;

	my %replace = %::const;
	$replace{'action'} = $action;

	#revcompat - 0032
	$replace{'displayterms'} = '';
	$replace{'selectmatch'} = '<select name="match"><option value="1">All</option><option value="0">Any</option></select>';
	#/revcompat

	$replace{'realm_options'} = '';
	$replace{'selectrealm'} = '<select name="Realm"><option value="All">[ All ]</option>';

	my $p_realm = ();
	foreach $p_realm ($::realms->listrealms('no_error')) {
		$replace{'selectrealm'}.= "\t<option value=\"$$p_realm{'html_name'}\">$$p_realm{'html_name'}</option>\n";
		$replace{'realm_options'} .= "\t<option value=\"$$p_realm{'html_name'}\">$$p_realm{'html_name'}</option>\n";
		}
	$replace{'selectrealm'} .= '</select>';

	my $html = &PrintTemplate( 1, 'searchform.htm', $::Rules{'language'}, \%replace );

	#revcompat - 0072
	if ($html !~ m!<form !is) {
		$html = qq!<form method="get" action="$action">\r\n$html!;
		}
	if ($html !~ m!</form>!is) {
		$html .= '</form>';
		}
	#/revcompat


	my $hidden = '';
	local $_;
	foreach (keys %::FORM) {
		next unless (m!^p:!s);
		my $qm_n = quotemeta($_);
		next if ($html =~ m!$qm_n!s); # if user already has something like "p:pm" in their custom search form, don't risk double-ing up with a hidden field
		my ($n, $v) = &he( $_, $::FORM{$_} );
		$hidden .= qq!<input type="hidden" name="$n" value="$v" />\r\n!;
		}
	$html =~ s!</form>!$hidden</form>!is;

	my %defaults = %::FORM;
	$defaults{'Terms'} = $::FORM{'Terms'} || '';
	$defaults{'p:ssm'} = defined($::FORM{'p:ssm'}) ? $::FORM{'p:ssm'} : $::Rules{'default substring match'};
	if ($defaults{'Terms'} eq '') {
		$defaults{'Terms'} = $::Rules{'default search terms'};
		}
	unless ($defaults{'Realm'}) {
		$defaults{'Realm'} = 'All';
		}
	return &SetDefaults($html,\%defaults);
	}





sub parse_search_terms {
	my ($str_terms, $str_match, $b_substring_match) = @_;
	my ($bTermsExist, $Ignored_Terms, $Important_Terms, $DocSearch, $RealmSearch, $sort_method) = (0, '', '', '', '', 0);


	# use match==2 to force search-as-phrase
	if ($str_match eq '2') {
		$str_terms =~ s!\s+!_!sg;
		}

	my $terms = $str_terms;

	my $IgnoreQuotedTerms = 0;
	unless ($str_match) {
		# if this is a non-special string - without meta characters, but containing a phrase - addx a special phrased version
		# of the terms for better matching:
		if (($terms =~ m! !s) and not ($terms =~ m!(\W|\-|not |and |or )!is)) {
			$terms = "\"$terms\" $terms";
			$IgnoreQuotedTerms = 1;
			}
		}

	$terms = ' '.$terms.' ';
	$terms =~ s'\s+' 'g;

	# changed 0056 - support "title: keyword" w/ space
	$terms =~ s! (url|host|domain|title|text|link)\: (\S)! $1:$2!sig;

	my ($i, $ProcTerms) = (0, '');
	foreach (split(m!\"!s, $terms)) {
		tr! !_! if $i;
		$i = not $i;
		$ProcTerms .= $_;
		}

	$ProcTerms =~ s' not ' -'ig;
#	$ProcTerms =~ s' and ' +'ig; # changed 0066
#	$ProcTerms =~ s' or ' |'ig;

	my ($EvalForbid, $EvalRequired, $EvalOptional, $EvalExtraRequired, $EvalExtraOptional) = ('', '', '', '', '');
	my $tm = $::Rules{'multiplier: title'};
	my $um = $::Rules{'multiplier: url'};
	my $km = $::Rules{'multiplier: keyword'};
	my $dm = $::Rules{'multiplier: description'};

	my (@invalid_terms, @valid_terms) = ();

	my $default_type = ($str_match) ? 3 : 2;

	my $chars_per_context_hit = 36;
	my $str_context_hit_before = '';
	my $str_context_hit_after = '... ';

	$::private{'search_term_patterns'} = [];

	Term: foreach (split(m!\s+!s, $ProcTerms)) {

		# Remove the underscores that are binding the phrases together:
		s!_! !sg;

		next unless ($_);

		my ($type, $is_attrib_search, $str_pattern) = &format_term_ex($_, $default_type, $b_substring_match);
		push( @{ $::private{'search_term_patterns'} }, $str_pattern ) if length($str_pattern);

		if ($type == 0) {
			push(@invalid_terms, $_);
			next;
			}

		# only get the search context if this is *not* an attrib search

		if ($type == 1) {
			$EvalForbid .= "\tlast SearchBlock if (m!$str_pattern!os);\n";
			}
		elsif ($type == 2) {

			if (($::Rules{'show examples: enable'}) and (not ($is_attrib_search))) {

				my @temp;
				my $ignore_blocks = scalar (@temp = ($str_pattern =~ m!\(!osg));

$EvalOptional .= <<"EOM";

	\$delta = scalar (\@WordCount = m!$str_pattern!sog);
	\$WordMatches += \$delta;
	if ((\$n_context_matches) and (\$delta)) {
		\$delta = scalar (\@WordCount = (\$text =~ m!([^\=]{0,$chars_per_context_hit})($str_pattern)([^\=]{0,$chars_per_context_hit})!sog));
		if (\$delta) {
			my \$x = 0;
			while ((\$x + 2 + $ignore_blocks) <= \$#WordCount) {
				my \$full_context = \$WordCount[\$x] . \$WordCount[\$x + 1] . \$WordCount[\$x + 2 + $ignore_blocks];
				\$x += 3 + $ignore_blocks;
				next unless (\$full_context =~ m! (.*) !s);
				\$context_str .= "$str_context_hit_before\$1$str_context_hit_after";
				\$n_context_matches--;
				last unless (\$n_context_matches);
				}
			}
		}

EOM

				}
			else {


$EvalOptional .= <<"EOM";

	\$WordMatches += scalar (\@WordCount = m!$str_pattern!sog);

EOM

				}
			}
		elsif ($type == 3) {

			if (($::Rules{'show examples: enable'}) and (not ($is_attrib_search))) {

				my @temp;
				my $ignore_blocks = scalar (@temp = ($str_pattern =~ m!\(!sog));

$EvalRequired .= <<"EOM";

	\$delta = scalar (\@WordCount = m!$str_pattern!sog);
	last SearchBlock unless (\$delta);
	\$WordMatches += \$delta;
	if (\$n_context_matches) {
		\$delta = scalar (\@WordCount = (\$text =~ m!([^\=]{0,$chars_per_context_hit})($str_pattern)([^\=]{0,$chars_per_context_hit})!sog));
		if (\$delta) {
			my \$x = 0;
			while ((\$x + 2 + $ignore_blocks) <= \$#WordCount) {
				my \$full_context = \$WordCount[\$x] . \$WordCount[\$x + 1] . \$WordCount[\$x + 2 + $ignore_blocks];
				\$x += 3 + $ignore_blocks;
				next unless (\$full_context =~ m! (.*) !s);
				\$context_str .= "$str_context_hit_before\$1$str_context_hit_after";
				\$n_context_matches--;
				last unless (\$n_context_matches);
				}
			}
		}



EOM

				}
			else {


$EvalRequired .= <<"EOM";

	\$delta = scalar (\@WordCount = m!$str_pattern!sog);
	last SearchBlock unless (\$delta);
	\$WordMatches += \$delta;

EOM

				}
			}

		if ($type == 1) {
			push(@invalid_terms, $_);
			}
		else {
			push(@valid_terms, $_);
			$EvalExtraRequired .= "\t\$WordMatches += $um * (\@WordCount = (\$u =~ m!$str_pattern!sog));\n" if $um;
			$EvalExtraRequired .= "\t\$WordMatches += $tm * (\@WordCount = (\$t =~ m!$str_pattern!sog));\n" if $tm;
			$EvalExtraRequired .= "\t\$WordMatches += $dm * (\@WordCount = (\$d =~ m!$str_pattern!sog));\n" if $dm;
			$EvalExtraRequired .= "\t\$WordMatches += $km * (\@WordCount = (\$k =~ m!$str_pattern!sog));\n" if $km;
			$bTermsExist = 1;
			}

		}




	# double-quote terms with embedded spaces:
	@invalid_terms = map { m! !s ? "$_" : $_ } @invalid_terms;

	# double-quote terms with embedded spaces:
	if ($IgnoreQuotedTerms) {
		@valid_terms = map { m! !s ? '' : $_ } @valid_terms;
		}
	else {
		@valid_terms = map { m! !s ? "$_" : $_ } @valid_terms;
		}

	$Ignored_Terms = join(', ', @invalid_terms);
	$Important_Terms = join(', ', @valid_terms);

# extract $text early if we're doing context matching - otherwise wait till later


my $sort_code = '';

$sort_method = $::Rules{'sorting: default sort method'};
if (($::FORM{'sort-method'}) and ($::FORM{'sort-method'} =~ m!^\d+$!s) and (0 < $::FORM{'sort-method'}) and ($::FORM{'sort-method'} < 7)) {
	$sort_method = $::FORM{'sort-method'};
	}


if (($sort_method < 3) and (($::Rules{'sorting: time sensitive'}) or ($::FORM{'p:ts'}))) {



	$sort_code = <<'EOM';

m!^\d+ (\d+)!s;
my $age = $::private{'script_start_time'} - $1;

if ($age < 172800) {
	$WordMatches *= 4;
	}
elsif ($age < 345600) {
	$WordMatches *= 3;
	}
elsif ($age < 691200) {
	$WordMatches *= 2;
	}

EOM
	}


# relevance:
if ($sort_method == 1) {
	$sort_code .= ' $sort_num = 10E6 - ($WordMatches * substr($_,0,2)); ';
	}
# reverse relevance:
elsif ($sort_method == 2) {
	$sort_code .= ' $sort_num = 10E6 + ($WordMatches * substr($_,0,2)); ';
	}
# by lastmod time
elsif ($sort_method == 3) {
$sort_code = <<'EOM';
	m!^\d+ (\d+)!s;
	$sort_num = 2147400000 - $1;
	$sort_num = '0' x (10 - length($sort_num)) . $sort_num;
EOM
	}
elsif ($sort_method == 4) {
$sort_code = <<'EOM';
	m!^\d+ (\d+)!s;
	$sort_num = $1;
	$sort_num = '0' x (10 - length($sort_num)) . $sort_num;
EOM
	}
# by lastindex time
elsif ($sort_method == 5) {
$sort_code = <<'EOM';
	m!^\d+ \d+ (\d+)!s;
	$sort_num = 2147400000 - $1;
	$sort_num = '0' x (10 - length($sort_num)) . $sort_num;
EOM
	}
elsif ($sort_method == 6) {
$sort_code = <<'EOM';
	m!^\d+ \d+ (\d+)!s;
	$sort_num = $1;
	$sort_num = '0' x (10 - length($sort_num)) . $sort_num;
EOM
	}

if ($::Rules{'sorting: randomize equally-relevant search results'}) {
	$sort_code .= ' $sort_num .= 1000 + int(rand(8999)); ';
	}
$sort_code .= ' $sort_num .=  "." . (10E6 - ($WordMatches * substr($_,0,2))); ';


if ($::Rules{'show examples: enable'}) {

$DocSearch = <<"EOM";

	SearchBlock: {
		\$\$r_pages_searched++;
		\$WordMatches = 0;
		\$text = '';
		$EvalForbid

		\$n_context_matches = $::Rules{'show examples: number to display'};
		\$context_str = '';

		unless (m!^(.*?)uM=(.*?)uT=(.*?)uD=(.*?)uK=(.*?)h=(.*)l=!os) { \$\$r_pages_searched--; last SearchBlock; }
		(\$hdr, \$u, \$t, \$d, \$k, \$text) = (\$1, \$2, \$3, \$4, \$5, \$6);
		$EvalRequired
		$EvalOptional
		last SearchBlock unless \$WordMatches;
		$EvalExtraRequired
		$EvalExtraOptional
		$sort_code
		push(\@\$r_hits, \$sort_num . '.' . \$hdr . ' c= ' . \$context_str . ' r= ' . \$::const{'record_realm'});
		}

EOM

	}
elsif (($EvalExtraRequired) or ($EvalExtraOptional)) {

$DocSearch = <<"EOM";

	SearchBlock: {
		\$\$r_pages_searched++;
		\$WordMatches = 0;
		$EvalForbid
		$EvalRequired
		$EvalOptional
		last SearchBlock unless \$WordMatches;
		unless (m!^(.*?)uM=(.*?)uT=(.*?)uD=(.*?)uK=(.*?)h=!os) { \$\$r_pages_searched--; last SearchBlock; }
		(\$hdr, \$u, \$t, \$d, \$k) = (\$1, \$2, \$3, \$4, \$5);
		$EvalExtraRequired
		$EvalExtraOptional
		$sort_code
		push(\@\$r_hits, \$sort_num . '.' . \$hdr . ' c=  r= ' . \$::const{'record_realm'});
		}

EOM

	}
else {
$DocSearch = <<"EOM";

	SearchBlock: {
		\$\$r_pages_searched++;
		\$WordMatches = 0;
		$EvalForbid
		$EvalRequired
		$EvalOptional
		last SearchBlock unless \$WordMatches;
		unless (m!^(.*?)uM=!os) { \$\$r_pages_searched--; last SearchBlock; }
		\$hdr = \$1;
		$sort_code
		push(\@\$r_hits, \$sort_num . '.' . \$hdr . ' c=  r= ' . \$::const{'record_realm'});
		}
EOM

	}


	$RealmSearch = <<"EOM";
my \@WordCount = ();
my (\$WordMatches, \$sort_num, \$u, \$t, \$d, \$k, \$hdr, \$n_context_matches, \$context_str, \$delta, \$text);
Record: while (defined(\$_ = readline(\$\$p_rhandle))) {
$DocSearch
	}

EOM

	return ($bTermsExist, $Ignored_Terms, $Important_Terms, $DocSearch, $RealmSearch);
	}





sub format_term_ex {
	my ($raw_term, $default_type, $b_substring_match) = @_;
	local $_ = defined($raw_term) ? $raw_term : '';
	$default_type = $default_type || 2;

	my $WildCard = 'thewildcardisaveryspecialcharacter';
	my $WildSearch = $::Rules{'wildcard match'};

	my ($type, $is_attrib_search, $lead_pattern, $term_pattern, $trail_pattern) = ($default_type, 0, '', '', '');

	# Ignore wildcard-enhanced terms with less than 3 real characters:
	if ((m!\*!s) and ((length($_) - (s!\*!\*!sg)) < 3)) {
		$type = 0;
		}

	s!\*+!$WildCard!sg;

	if (s!^\-!!os) {
		$type = 1;
		}
	elsif (s!^\|!!so) {
		$type = 2;
		}
	elsif (s!^\+!!so) {
		$type = 3;
		}

	if (m!^(url|host|domain):(.+)!is) {
		$_ = $2;
		$lead_pattern = ' uM=.*?(';
		$trail_pattern = ').*?uT= ';
		$is_attrib_search = 1;
		}
	elsif (m!^title:(.+)!is) {
		$_ = $1;
		$lead_pattern = ' uT=.*?(';
		$trail_pattern = ').*?uD= ';
		$is_attrib_search = 1;
		}
	elsif (m!^text:(.+)!is) {
		$_ = $1;
		$lead_pattern = ' h=.*?(';
		$trail_pattern = ').*?l= ';
		$is_attrib_search = 1;
		}
	elsif (m!^link:(.+)!is) {
		$_ = $1;
		$lead_pattern = ' l=.*?(';
		$trail_pattern = ')';
		$is_attrib_search = 1;
		}
	#end changes
	$term_pattern = &CompressStrip($_);

	if ($b_substring_match) {
		$term_pattern =~ s!^\s!!s;
		$term_pattern =~ s!\s$!!s;
		}

	# What if CompressStrip removed all words as ignored words?
	if ($term_pattern =~ m!^\s*$!s) {
		$type = 0;
		}

	$term_pattern = quotemeta($term_pattern);

	# should we match plurals?
	$term_pattern = &build_plural_pattern($term_pattern) if ($::FORM{'p:pm'});

	$term_pattern =~ s!$WildCard!$WildSearch!sg;
	my $pattern = "$lead_pattern$term_pattern$trail_pattern";
	return ($type, $is_attrib_search, $pattern);
	}





sub build_plural_pattern {
	my ($term) = @_;

	my $endspace = ($term =~ m!\s$!s) ? ' ' : '';

	my @subpatterns = ();
	my $term_pattern;
	foreach $term_pattern (split(m!\s+!s, $term)) {

		my $endchar = '';
		if ($term_pattern =~ m!\\$!s) {
			$term_pattern =~ s!\\$!!s;
			$endchar = "\\";
			}

	# singular to plural conversions:

		# if the word ends in [vowel]o, addx s
		# otherwise add "es" or "s" (varies)

		if ($term_pattern =~ m!^(.+)(a|e|i|o|u)(o)$!is) {
			$term_pattern = "$1$2$3s?";
			}
		elsif ($term_pattern =~ m!^(.+)(o)$!is) {
			$term_pattern = "$1$2(es|s)?";
			}


		# words ending in "f/fe" => "ves"
		# skip this one; false pos on "gif" => "gives"
		# very few nouns of this type


		# words ending in "is" become "es"

		elsif ($term_pattern =~ m!^(.+)(is)$!is) {
			$term_pattern = "$1(i|e)s";
			}

		# words ending in [consonant]y becomes "ies"

		elsif ($term_pattern =~ m!^(.+)([^a|e|i|o|u])(y)$!is) {
			$term_pattern = "$1$2(ies|y)";
			}

	# plural to singular conversions

		# words ending in "ies" => "y|ie"
		elsif ($term_pattern =~ m!^(.+)(ies)$!is) {
			$term_pattern = "$1(y|ie|ies)";
			}
		# words ending in "es" => "''|e|is|es"
		elsif ($term_pattern =~ m!^(.+)(es)$!is) {
			$term_pattern = "$1(|e|is|es)";
			}
		# words ending in "s"; trailing s optional; additional trailing "es" allowed
		elsif ($term_pattern =~ m!^(.+)(s)$!is) {
			$term_pattern = "$1$2?(es)?";
			}

		# hissing sound addx "-es"

		elsif ($term_pattern =~ m!^(.+)(z|x|sh|ch)$!is) {
			$term_pattern = "$1$2(es)?";
			}

		# all others - add optional "s"

		elsif ($term_pattern =~ m!^(..+)$!is) { # must be at least two characters
			$term_pattern = "$1s?";
			}

		$term_pattern .= $endchar;

		push(@subpatterns, $term_pattern);
		}

	return join(' ', @subpatterns) . $endspace;
	}





sub LockFile_new {
	$::private{'global_lockfile_count'}++;
	my $name = $::private{'global_lockfile_count'};

	my $self = {
		'timeout' => 30,
		'create_if_needed' => 0,
		'rname' => '',
		'wname' => '',
		'ename' => '',
		'filename' => '',
		'mode' => -1,
		};
	bless($self);

#changed 0044 - re comp.perl.misc discussion of problems with *GLOB references

my $code = <<"EOM";

	\$self->{'p_rhandle'} = \\*ReadHandle$name;
	\$self->{'p_whandle'} = \\*WriteHandle$name;
	\$self->{'p_ehandle'} = \\*ExclusiveLockHandle$name;

EOM




	eval($code);


	my %params = @_;
	foreach (keys %params) {
		$self->{$_} = $params{$_};
		}
	return $self;
	}





sub FlockEx {
	my ($filehandle_ref, $mode) = @_;
	my $rv = 1;
	if ($::private{'bypass_file_locking'} == 1) {
		# ok
		}
	elsif ($::private{'bypass_file_locking'} == 2) {
		$rv = flock($$filehandle_ref, $mode);
		}
	else {
		eval {
			$rv = flock($$filehandle_ref, $mode);
			};
		if ($@) {
			$rv = 1;
			}
		else {
			$::private{'bypass_file_locking'} = 2;
			}
		}
	return $rv;
	}





sub Read {
	my ($self, $filename) = @_;

	$self->{'rname'} = $filename;
	$self->{'ename'} = "$filename.exclusive_lock_request";
	$self->{'wname'} = "$filename.working_copy";

	my ($p_rhandle, $rname, $p_whandle, $wname, $p_ehandle, $ename) = ($self->{'p_rhandle'}, $self->{'rname'}, $self->{'p_whandle'}, $self->{'wname'}, $self->{'p_ehandle'}, $self->{'ename'});

	my $err = '';
	Err: {
		my $success = 0;

		$err = $self->LockFile_get_read_access();
		next Err if ($err);

		#&Assert('GLOB' eq ref($p_rhandle));

		unless (open($$p_rhandle, "<$rname")) {
			$err = &pstr(44,$rname,$!);
			next Err;
			}
		unless (binmode($$p_rhandle)) {
			$err = &pstr(39,$rname,$!);
			next Err;
			}
		my $attempts = $self->{'timeout'};
		while ($attempts > 0) {
			my $rv = &FlockEx($p_rhandle, 5);
			if ($rv) {
				$success = 1;
				last;
				}
			$attempts--;
			sleep(1);
			}
		unless ($success) {
			$err =  &pstr(41, $rname, $! );
			next Err;
			}
		}
	return ($err,$p_rhandle);
	}





sub Close {
	my ($self) = @_;
	return &freeh($self->{'p_rhandle'},$self->{'rname'});
	}





sub LockFile_get_read_access {
	my ($self) = @_;
	my $err = '';
	Err: {
		my $attempts = $self->{'timeout'};
		while ((-e $self->{'ename'}) and ($attempts > 0)) {
			# If an "exlusive lock request" file exists, wait up to timeout seconds for it to disappear. If it doesn't, and if it's age is
			# also less than timeout seconds, return an error:
			# is she recent?
			my $lastmodt = (stat($self->{'ename'}))[9];
			my $age = time() - $lastmodt;
			last unless ($age < $self->{'timeout'});
			$attempts--;
			sleep(1);
			}
		unless ($attempts > 0) {
			$err = &pstr(44, $self->{'rname'}, &pstr(37, $self->{'timeout'} ) );
			next Err;
			}
		while (($attempts > 0) and (-e $self->{'wname'})) {
			# How old is the write file?
			my $lastmodt = (stat($self->{'wname'}))[9];
			my $age = time() - $lastmodt;
			if ($age > $self->{'timeout'}) {
				# claim it for ourselves - but if the core file doesn't exist, rename this one over to it's spot.
				unless (-e $self->{'rname'}) {
					unless (rename($self->{'wname'}, $self->{'rname'})) {
						$err = &pstr(38,$self->{'wname'},$self->{'rname'},$!);
						next Err;
						}
					}
				last;
				}
			sleep(1);
			$attempts--;
			}

		unless ($attempts > 0) {
			$err = &pstr(44, $self->{'rname'}, &pstr(37, $self->{'timeout'} ) );
			next Err;
			}


		# Okay, by now we've waited for the .exclusive_lock_request file and the .working_copy.  If the orginal target file still doesn't exist, and if we are so directed, create it:

		if (($self->{'create_if_needed'}) and (not (-e $self->{'rname'}))) {
			# okay, it don't exist and we're config'ed to created it...
			unless (open(TEMP, '>' . $self->{'rname'})) {
				$err = &pstr(43, $self->{'rname'}, $! );
				next Err;
				}
			binmode(TEMP);
			print TEMP '';
			close(TEMP);
			chmod($::private{'file_mask'}, $self->{'rname'});
			}

		}
	return $err;
	}





sub FD_Rules_new {
	my $self = {};
	bless($self);

		# name => [default, data_type_number ]

	my %defaults = (
		'wildcard match' => ['\S{0,4}', 5],
		'parse fdse-index-as header' => [1,1],
		'time interval between restarts' => [15,3,10,60],

		'use dbm routines' => [1,1],
		'use socket routines' => [1,1],
		'use standard io' => [1,1],

		'delete index file with realm' => [0,1],

		'mode' => [1,3,0,3],
		'regkey' => ['',5],

		'redirector' => ['', 5],
		'default match' => [0, 3, 0, 2],
		'default search terms' => ['',5],
		'default substring match' => [0, 1],
		'language' => ['english', 5],

		'admin notify: smtp server' => ['', 5],
		'admin notify: email address' => ['', 5],
		'admin notify: sendmail program' => ['',5],

		'ui: number format' => [0,2],
		'ui: date format' => [12,2],

		'ui: search form display' => [2, 3, 0, 3],

		'security: session timeout' => [60, 3, 10, 1000000],

		'show advanced commands' => [0,1],

		'handling url search terms' => [2, 3, 1, 3],

		'sorting: randomize equally-relevant search results' => [0,1],
		'sorting: default sort method' => [1,3,1,6],
		'sorting: time sensitive' => [0,1],

		#changed 0054
		'logging: enable' => [1,1],

		'multi-line add-url form - admin' => [0,1],
		'multi-line add-url form - visitors' => [0,1],


		'user language selection' => [2,3,0,3],
		'logging: display most popular' => [0,3,0,1000],


		'network timeout' => [10,3,0,1000000],

		'refresh time delay' => [10,3,0,10000],

		'allowanonadd: notify admin' => [0, 1],
		'allowanonadd: log' => [0,1],
		'allowanonadd: require user email' => [0, 1],
		'allowanonadd' => [0, 1],
		'require anon approval' => [1, 1],

		'allowanonadd: use form-signature'  => [ '', 5 ],

		'allowanonadd: use rate'            => [ 0, 1 ],
		'allowanonadd: max rate'            => [ 10, 3, 1, 10000 ],
		'allowanonadd: recent submit times' => [ '', 5 ],



		'allowbinaryfiles' => [1, 1],
		'allowsymboliclinks' => [1, 1],

		'character conversion: accent insensitive' => [1, 1],
		'character conversion: case insensitive' => [1, 1],

		'crawler: days til refresh' => [30, 3, 1, 100],
		'crawler: follow offsite links' => [1, 1],
		'crawler: follow query strings' => [1, 1],
		'crawler: ignore links to' => ['gif jpg jpe js css wav ram ra mpeg mpg avi zip exe doc xls pdf gz', 5],
		'crawler: max pages per batch' => [10, 2],
		'crawler: max redirects' => [6, 2],
		'crawler: minimum whitespace' => [0.01, 4],
		'crawler: rogue' => [0, 1],
		'crawler: user agent' => ['Mozilla/4.0 (compatible: FDSE robot)', 5],
		'crawler: use cookies' => [ 1, 1 ],

		'ext' => ['html htm shtml shtm stm mp3', 5],
		'file' => ['', 5],
		'forbid all cap descriptions' => [1, 1],
		'forbid all cap titles' => [1, 1],
		'hits per page' => [10, 3, 1, 99999],
		'sql: enable' => [0, 1],

		'ignore words' => ['your you www with will why who which where when what web we was want w used use two to this they these there then then them their the that than t so site should see s re page our other org or only one on of now not no new net name n my ms mrs mr most more me may like just its it is in if i http how he have has get from for find ed do d com can by but been be b at as are any and an also all after about a ', 5],

		'index alt text' => [1, 1],
		'index links' => [0, 1],

		'max characters: auto description' => [150, 2],
		'max characters: description' => [384, 2],
		'max characters: file' => [64000000, 2],
		'max characters: keywords' => [256, 2],
		'max characters: text' => [64000000, 2],
		'max characters: title' => [96, 2],
		'max characters: url' => [128, 3, 16, 2048],

		'max index file size' => [10000000, 2],
		'minimum page size' => [128, 2],

		'multiplier: description' => [0, 3, 0, 100],
		'multiplier: keyword' => [0, 3, 0, 100],
		'multiplier: title' => [0, 3, 0, 100],
		'multiplier: url' => [0, 3, 0, 100],

		'password' => ['', 5],

		'show examples: enable' => [0, 1],
		'show examples: number to display' => [1, 2],

		'timeout' => [30, 2],
		'trustsymboliclinks' => [0, 1],

		'pics_rasci_enable' => [0, 1],
		'pics_rasci_handle' => [1, 1],

		'pics_ss_enable' => [0, 1],
		'pics_ss_handle' => [1, 1],

		'pics_rasci_n' => [2, 2],
		'pics_rasci_s' => [2, 2],
		'pics_rasci_l' => [2, 2],
		'pics_rasci_v' => [2, 2],

		'pics_ss_000' => [3, 2],
		'pics_ss_001' => [3, 2],
		'pics_ss_002' => [3, 2],
		'pics_ss_003' => [3, 2],
		'pics_ss_004' => [3, 2],
		'pics_ss_005' => [3, 2],
		'pics_ss_006' => [3, 2],
		'pics_ss_007' => [3, 2],
		'pics_ss_008' => [3, 2],
		'pics_ss_009' => [3, 2],
		'pics_ss_00A' => [3, 2],

		);
	$self->{'r_defaults'} = \%defaults;
	$self->{'delim'} = '=';
	$self->{'separ'} = "\015\012";
	$self->{'file'} = 'settings.pl';
	if (-e 'settings.cgi') {
		$self->{'file'} = 'settings.cgi';
		}
	return $self;
	}





sub _fdr_validate {
	my ($self, $name, $value) = @_;
	my ($is_valid, $valid_value) = (1, $value);
	my $r_defaults = $self->{'r_defaults'};
	if (defined($$r_defaults{$name})) {
		my $type = $$r_defaults{$name}[1];
		if ($type == 1) {
			if ((not defined($value)) or ($value eq '')) {
				$valid_value = $value = 0;
				}
			$is_valid = (($value eq '0') or ($value eq '1'));
			}
		elsif ($type == 2) {
			$is_valid = ($value =~ m!^\d+$!s);
			}
		elsif ($type == 3) {
			$is_valid = (($value =~ m!^\d+$!s) and ($value >= $$r_defaults{$name}[2]) and ($value <= $$r_defaults{$name}[3]));
			}
		elsif ($type == 4) {
			$is_valid = ($value =~ m!^\d+\.?\d*$!s); #changed 0053
			}
		unless ($is_valid) {
			$valid_value = $$r_defaults{$name}[0];
			}
		}
	return ($is_valid, $valid_value);
	}





sub fdse_realms_new {
	my $self = {};
	bless($self);

	my (@realms, %realms_by_name, @delete_realm_ids) = ();

	$self->{'realms'} = \@realms;
	$self->{'p_realms_by_name'} = \%realms_by_name;
	$self->{'p_delete_realm_ids'} = \@delete_realm_ids;

	$self->{'need_approval'} = 0;
	$self->{'use_db'} = 0;
	$self->{'file'} = 'search.realms.txt';
	$self->{'last_realm_err'} = '';
	return $self;
	}





sub load {
	my ($self) = @_;
	# clear original list:
	my $ref_realms = $self->{'realms'};
	@$ref_realms = ();

	my $err = '';
	Err: {

		my ($obj, $p_rhandle) = ();

		$obj = &LockFile_new(
			'create_if_needed' => 1,
			);
		($err, $p_rhandle) = $obj->Read( $self->{'file'} );
		next Err if ($err);

		while (defined($_ = readline($$p_rhandle))) {
			my @Fields = split(m!\|!s, &Trim($_));
			next unless ($Fields[0] and $Fields[1]);
			my ($name, $file, $base_dir, $base_url, $exclude, $pagecount, $is_filefed, $type, $limit_pattern) = @Fields;
			my $is_runtime = ($file eq 'RUNTIME') ? 1 : 0;

			#revcompat 0055 and earlier
			if ((not defined($type)) or ($type !~ m!^\d+$!s)) {
				$type = 0;
				}
			if (not defined($limit_pattern)) {
				$limit_pattern = '';
				}
			#/revcompat

			$limit_pattern = &ud($limit_pattern);


			#0054 untaint fields:
			if ($file =~ m!\.\.!s) {
				$err = "realm file name cannot contain '..' substring";
				next Err;
				}
			&untaintme( \$file );
			&untaintme( \$base_dir );

			$self->add(0, $name, 0, $file, $is_runtime, $base_dir, $base_url, $exclude, $pagecount, $is_filefed, $type, $limit_pattern);
			}

		$err = $obj->Close();
		next Err if ($err);

		last Err;
		}
	continue {
		$self->{'last_realm_err'} = $err;
		}
	return $err;
	}





sub hashref {
	my ($self, $name) = @_;
	my ($err, $ref) = ('');
	my $p_realms_by_name = $self->{'p_realms_by_name'};
	unless ($ref = $$p_realms_by_name{$name}) {
		$err = &pstr(55,&he($name));
		}
	return ($err, $ref);
	}





sub listrealms {
	my ($self, $attrib) = @_;
	my @realms = ();
	my %names = ();
	my $ref_realms = $self->{'realms'};
	my $RH;
	foreach $RH (@$ref_realms) {
		next unless ($$RH{$attrib});
		$names{$$RH{'name'}} = $RH;
		}
	foreach (sort keys %names) {
		push(@realms, $names{$_});
		}
	return @realms;
	}





sub realm_count {
	my ($self, $attrib) = @_;
	my $count = 0;
	my $ref_realms = $self->{'realms'};
	my $ref_hash;
	foreach $ref_hash (@$ref_realms) {
		$count++ if $$ref_hash{$attrib};
		}
	return $count;
	}





sub add {
	my ($self, $realm_id, $name, $is_database, $file, $is_runtime, $base_dir, $base_url, $exclude, $pagecount, $is_filefed, $type, $limit_pattern) = @_;
	if (($file) and (open(FILE, "<$file.pagecount"))) {
		binmode(FILE);
		$pagecount = <FILE>;
		$pagecount =~ s!\,|\015|\012!!sg;
		close(FILE);
		}
	$pagecount = 0 unless ($pagecount);

	my $need_approval = ((-e "$file.need_approval") and ((-s "$file.need_approval") > 10)) ? 1: 0;

	# assign file-fed attributes:
	my %RH = (
		'is_runtime'  => $is_runtime,
		'is_database' => $is_database,
		'is_filefed'  => $is_filefed,

		'pagecount' => $pagecount,

		'name' => $name,
		'html_name' => &he($name),
		'url_name' => &ue($name),
		'file' => $file,
		'base_dir' => $base_dir,
		'base_url' => $base_url,
		'exclude' => $exclude,
		'need_approval' => $need_approval,
		'limit_pattern' => $limit_pattern,
		);

	#revcompat pre 0056
	if ($type == 0) { # legacy auto-detect
		if ($base_url eq 'http://filtered:1/') {
			$type = 6;
			}
		elsif ($is_runtime) {
			$type = 5;
			}
		elsif ($is_filefed) {
			$type = 2;
			}
		elsif (($base_dir) and ($base_url)) {
			$type = 4;
			}
		elsif ($base_url) {
			$type = 3;
			}
		else {
			$type = 1;
			}
		}
	#/revcompat

	$RH{'type'} = $type;

	if ($RH{'need_approval'}) {
		$self->{'need_approval'} = 1;
		}

	# cleanse data:
	while (defined($_ = each %RH)) {
		$RH{$_} = &Trim($RH{$_});
		$RH{$_} = '' unless defined($RH{$_});
		$RH{$_} =~ s!\015|\012!!sg;
		$RH{$_} =~ s!\|!!sg unless ($_ eq 'limit_pattern');
		}
	$RH{'base_dir'} =~ s!/$!!s;

	my ($err, $clean_url) = &uri_parse( $RH{'base_url'} );
	unless ($err) {
		$RH{'base_url'} = $clean_url;
		}

	$RH{'is_error'} = 0;
	$RH{'no_error'} = 1;
	$RH{'err'} = '';

	# Try to create a file if we're going to be needing it:
	if (($RH{'file'}) and (not ($RH{'is_runtime'})) and (not (-e $RH{'file'})) and (not (-e "$RH{'file'}.exclusive_lock_request")) and (not (-e "$RH{'file'}.working_copy"))) {
		if (open(FILE, '>>' . $RH{'file'})) {
			binmode(FILE);
			close(FILE);
			}
		else {
			$RH{'is_error'} = 1;
			$RH{'no_error'} = 0;
			$RH{'err'} = &pstr(42, $RH{'file'}, $! );
			}
		}

	# set derived attributes:

	$RH{'all'} = 1;

	$RH{'has_index_data'} = not $RH{'is_runtime'};

	if ($self->{'use_db'}) {
		$RH{'is_database'} = 1;
		$RH{'has_file'} = 0;
		}
	else {
		$RH{'is_database'} = 0;
		$RH{'has_file'} = not $RH{'is_runtime'};
		}

	if ($RH{'base_url'} eq 'http://filtered:1/') {
		$RH{'has_base_url'} = 0;
		$RH{'has_no_base_url'} = 1;
		}
	elsif ($RH{'base_url'}) {
		$RH{'has_base_url'} = 1;
		$RH{'has_no_base_url'} = 0;
		}
	else {
		$RH{'has_base_url'} = 0;
		$RH{'has_no_base_url'} = 1;
		}

	$RH{'is_open_realm'} = ($RH{'type'} == 1) ? 1 : 0;
	$RH{'realm_id'} = $realm_id;

	my $p_realms_by_name = $self->{'p_realms_by_name'};
	$$p_realms_by_name{$name} = \%RH;

	my $p_realms = $self->{'realms'};
	push(@$p_realms, \%RH);
	}





sub freeh {
	my ($p_handle,$name,$b_delete) = @_;
	my $err = '';
	unless (&FlockEx($p_handle,8)) {
		$err = &pstr(49,&he($name),$!);
		}
	unless (close($$p_handle)) {
		$err = &pstr(52,&he($name),$!);
		}
	if ($b_delete) {
		unless (unlink($name)) {
			$err = &pstr(54,&he($name),$!);
			}
		}
	return $err;
	}





sub hd {
	my @out = @_;
	local $_;
	foreach (@out) {
		$_ = '' if (not defined($_));
		s!\&gt;!\>!sg;
		s!\&lt;!\<!sg;
		s!\&amp;!\&!sg;
		s!\&quot;!\"!sg;
		}
	if ((wantarray) or ($#out > 0)) {
		return @out;
		}
	else {
		return $out[0];
		}
	}





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
			while ($path =~ s!([^/]+)/+\.\./+!/!s) {}


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
		$folder =~ s!/([^/]*)$!/!s; # strip anything past the last slash (i.e., a filename)

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


1;
