#use strict;#if-debug
sub version_ca {
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

common_admin.pl contains functions that are only called from the Mode/Admin or Mode/AnonAdd pathways.

=cut





sub ui_Rewrite {
	my $err = '';
	Err: {
		my $sa = $::FORM{'sa'} || '';
		if ($sa eq 'save') {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=FilterRules">$::str[162]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Rewrite">Rewrite</a>
	<span class="gt">&rarr;</span>
	$::str[362]
</div>

EOM

			my $test_str = 'foo bar';


			my $level;
			foreach $level (0,1) {
				my @rules = ();
				foreach (sort keys %::FORM) {
					next unless (m!^$level\.(\d+)$!s);
					my $key = $1;

					my ($p1, $p2) = ($::FORM{$key . '_p1'}, $::FORM{$key . '_p2'});

					next unless ($p1);

					my @fields = ($::FORM{$key . '_enabled'}, $p1, $p2, $::FORM{$key . '_comment'}, $::FORM{$key . '_verbose'} );

					eval '$test_str =~ s!$p1!$p2!isg;';
					if ($@) {
						my ($hp1, $hp2) = &he($p1, $p2);
						$err = "unable to evaluate Perl substitution on '$hp1' and '$hp2' - Perl returned the following error string:</p><p>" . &he($@);
						next Err;
						}


					my $str = join('=', &ue(@fields) );
					push(@rules, $str);
					}

				my $key = 'rewrite_url_' . $level;
				$::Rules{$key} = '' if not exists $::Rules{$key};

				$err = &WriteRule( $key , join('&',@rules) );
				next Err if ($err);
				my $count = scalar @rules;
				print "<p><b>Success:</b> saved <b>$count</b> level-$level rewrite rules.</p>\n";
				}



			last Err;
			}

		my @out = ('', '');

my $template = <<"EOM";

<input type="hidden" name="%level%.%name%" value="1" />

<table border="1">
<tr>
	<th>Enabled</th>
	<th>$::str[309]</th>
	<th>Pattern</th>
	<th>Replace</th>
</tr>
<tr>
	<td align="center"><input type="checkbox" value="1" name="%name%_enabled" /><input type="hidden" value="0" name="%name%_enabled_udav" /></td>
	<td align="center"><input type="checkbox" value="1" name="%name%_verbose" /><input type="hidden" value="0" name="%name%_verbose_udav" /></td>
	<td><input name="%name%_p1" /></td>
	<td><input name="%name%_p2" /></td>
</tr>
<tr class="%class%">
	<td colspan="2" align="right"><b>Comment:</b></td>
	<td colspan="2"><textarea name="%name%_comment" rows="2" cols="40"></textarea></td>
</tr>
</table>

<p><br /></p>

EOM

	# format is b_enabled,p1,p2,comment,b_verbose,

		my $index = 1000;

		my $level;
		foreach $level (0,1) {
			for (0..1) {
				$index++;
				my $frag = $template;
				$frag =~ s!%name%!$index!sg;
				$frag =~ s!%level%!$level!sg;
				$frag =~ s!%class%!newdata!sg;
				my %defaults = (
					$index . '_enabled' => 1,
					$index . '_comment' => 'new rewrite rule',
					);
				$out[$level] .= &SetDefaults($frag, \%defaults);
				}


			my @rules = ();
			my $key = "rewrite_url_" . $level;
			$::Rules{$key} = '' if (not exists $::Rules{$key});

			my $rule;
			foreach $rule (split(m!\&!s, $::Rules{$key})) {
				my @fields = map { &ud($_) } split(m!\=!s, $rule);
				push(@rules, \@fields);
				}


			my $p_rule;
			foreach $p_rule (@rules) {
				$index++;
				my $frag = $template;
				$frag =~ s!%name%!$index!sg;
				$frag =~ s!%level%!$level!sg;
				$frag =~ s!%class%!existingdata!sg;
				my %defaults = (
					$index . '_enabled' => $$p_rule[0],
					$index . '_verbose' => $$p_rule[4],
					$index . '_p1' => $$p_rule[1],
					$index . '_p2' => $$p_rule[2],
					$index . '_comment' => $$p_rule[3],
					);
				$out[$level] .= &SetDefaults($frag, \%defaults);
				}
			for (0..1) {
				$index++;
				my $frag = $template;
				$frag =~ s!%name%!$index!sg;
				$frag =~ s!%level%!$level!sg;
				$frag =~ s!%class%!newdata!sg;
				my %defaults = (
					$index . '_enabled' => 1,
					$index . '_comment' => 'new rewrite rule',
					);
				$out[$level] .= &SetDefaults($frag, \%defaults);
				}
			}


print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=FilterRules">$::str[162]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Rewrite">Rewrite</a>
	<span class="gt">&rarr;</span>
	Overview
</div>

$::const{'AdminForm'}
<input type="hidden" name="Action" value="Rewrite" />
<input type="hidden" name="sa" value="save" />

		<p><b>Input Filters</b></p>

		<p>The following Perl substitutions will be performed, in order, on all links as they are extracted from files during a crawl session.</p>

		<p>If the <b>$::str[309]</b> bit is set, then a statement will be printed to screen whenever the substitution is successful. Use this for testing.</p>

		<p>You may add new rewrite rules by using the first or last two blank tables. If you need to add more than that, simply enter two,
		then save, and then you will be able to add more. To delete a rule, delete the <b>Pattern</b> portion.</p>

		<p>Use the <b>Enabled</b> bit to turn rules on or off during development. Link extraction rewrite rules are part of the critical path and should only be enabled if needed.</p>

		$out[0]

		<p><b>Output Filters</b></p>

		<p>The following Perl substitutions will be performed, in order, on all links just before they are shown in the search results.</p>

		<p>If the <b>$::str[309]</b> bit is set, then a statement will be printed to screen whenever the substitution is successful. Use this for testing.</p>

		$out[1]

<p><input type="submit" class="submit" value="$::str[362]" /></p>

</form>


EOM

		last Err;
		}
	continue {
		&ppstr(29,$err);
		}
	}





sub ui_License {
	my $err = '';
	Err: {

		print qq!<div class="breadcrumbs"><a href="$::const{'admin_url'}">$::str[96]</a> <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=UL">$::str[467]</a> <span class="gt">&rarr;</span> !;

		my $sa = $::FORM{'sa'} || '';
		if ($sa eq 'Write') {

			print "$::str[362]</div>";

			if ($::private{'is_demo'}) {
				$err = $::str[435];
				next Err;
				}

			if ($::FORM{'regkey'}) {
				unless (&regkey_validate($::FORM{'regkey'})) {
					$err = $::str[454] . " (<a href=\"$::const{'help_file'}1088.html\" target=\"_blank\">$::str[432]</a>)";
					next Err;
					}
				}
			elsif ($::FORM{'mode'} == 2) {
				$err = $::str[455];
				next Err;
				}

			if ($::FORM{'mode'} == 3) {
				if (1 < $::realms->realm_count('all')) {
					$err = $::str[456];
					next Err;
					}
				my $p_realm_data = ();
				foreach $p_realm_data ($::realms->listrealms('all')) {
					if ($$p_realm_data{'type'} == 1) {
						$err = &pstr(457,$$p_realm_data{'html_name'});
						next Err;
						}
					elsif ($$p_realm_data{'type'} == 6) {
						$err = &pstr(175,$$p_realm_data{'html_name'});
						next Err;
						}
					}
				}
			if (($::FORM{'regkey'}) and ('' eq $::Rules{'regkey'})) {
				$::FORM{'mode'} = 2;
				}
			$err = &WriteRule('mode', $::FORM{'mode'});
			next Err if ($err);
			$err = &WriteRule('regkey', &ue($::FORM{'regkey'}));
			next Err if ($err);
			&ppstr(174,$::str[114]);
			last Err;
			}
		print "$::str[152]</div>";

		my %defaults = (
			'mode' => $::private{'mode'},
			'regkey' => &ud($::Rules{'regkey'}),
			);

		$defaults{'regkey'} =~ s!(\015|\012|\r|\n)+!\015\012!sg;

print &SetDefaults(<<"EOM", \%defaults);

$::const{'AdminForm'}
<input type="hidden" name="Action" value="UL" />
<input type="hidden" name="sa" value="Write" />

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2">$::str[458]</th>
	<th>$::str[447]</th>
</tr>
<tr class="fdtan" valign="top">
	<td><input type="radio" name="mode" value="3" id="mode_3" /></td>
	<td><label for="mode_3">$::str[463]</label></td>
	<td>$::str[459]</td>
</tr>
<tr class="fdtan" valign="top">
	<td><input type="radio" name="mode" value="1" id="mode_1" /></td>
	<td><label for="mode_1">$::str[462]</label></td>
	<td>$::str[460]</td>
</tr>
<tr class="fdtan" valign="top">
	<td><input type="radio" name="mode" value="2" id="mode_2" /></td>
	<td><label for="mode_2">$::str[461]</label></td>
	<td>$::str[468]</td>
</tr>
</table>

<p>$::str[386]<br /><tt><textarea name="regkey" rows="10" cols="65"></textarea></tt></p>

<p><input type="submit" class="submit" value="$::str[362]" /></p>

$::str[446]

</form>

EOM
		last Err;
		}
	continue {
		&ppstr(29,$err);
		}
	}





sub parse_text_record {
	local $_ = defined($_[0]) ? $_[0] : '';
	my ($is_valid, %pagedata) = (0);
	if (m!^(\d\d)(\d\d)(\d\d)(\d\d\d\d)(\d+) (\d+) (\d+) u= (.+?) t= (.*?) d= (.*?) uM= (.*?) uT= (.*?) uD= (.*?) uK= (.*?) h= (.*?) l= (.*)!s) {
		%pagedata = (
			'promote' => $1,
			'dd' => $2,
			'mm' => $3,
			'yyyy' => $4,
			'size' => 1 * $5,
			'lastmodtime' => $6,
			'lastindex' => $7,
			'url' => $8,
			'title' => $9,
			'description' => $10,
			'um' => $11,
			'ut' => $12,
			'ud' => $13,
			'keywords' => $14,
			'uk' => $14,
			'text' => $15,
			'links' => $16,
			);
		$is_valid = 1;
		}

#revcompat - older yet supported format

	elsif (m!^(\d\d)(\d\d)(\d\d)(\d\d\d\d)(\d+) u= (.+?) t= (.*?) d= (.*?) uM= (.*?) uT= (.*?) uD= (.*?) uK= (.*?) h= (.*?) l= (.*)!s) {
		%pagedata = (
			'promote' => $1,
			'dd' => $2,
			'mm' => $3,
			'yyyy' => $4,
			'size' => 1 * $5,
			'url' => $6,
			'title' => $7,
			'description' => $8,
			'um' => $9,
			'ut' => $10,
			'ud' => $11,
			'keywords' => $12,
			'uk' => $12,
			'text' => $13,
			'links' => $14,
			);
		$is_valid = 1;
		}
#/revcompat

	return ($is_valid, %pagedata);
	}





sub ui_FilterRules {

	my $subaction = $::FORM{'subaction'} || '';

	my $ApproveLink = "<a href=\"$::const{'admin_url'}&amp;Action=FilterRules&amp;subaction=ShowPending&amp;Realm=" . &ue( $::FORM{'Realm'} ) . "\">$::str[160]</a>";

	my %subactions = (
		'' => $::str[152],
		'CreateEdit' => $::str[412],
		'create_edit_rule' => $::str[412],
		'delete_rule' => $::str[413],
		'ShowPending' => $ApproveLink,
		'PQP' => $ApproveLink,
		'save_settings' => $::str[362],
		);

	print qq!<div class="breadcrumbs"><a href="$::const{'admin_url'}">$::str[96]</a> <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=FilterRules">$::str[162]</a>!;

	if ($subactions{$subaction}) {
		print qq! <span class="gt">&rarr;</span> $subactions{$subaction}!;
		}

	print "</div>\n";

	my $err = '';
	Err: {
		local $_;

		if (($subaction eq 'CreateEdit') or ($subaction eq 'create_edit_rule')) {
			$err = &s_create_edit_rule();
			next Err if ($err);
			last Err;
			}

		if ($subaction eq 'ShowPending') {
			&present_queued_pages($::FORM{'Realm'});
			last Err;
			}

		if ($subaction eq 'PQP') {
			&process_queued_pages();
			last Err;
			}

		my $fr = &fdse_filter_rules_new();

		if ($subaction eq 'delete_rule') {
			$err = $fr->delete_filter_rule($::FORM{'name'});
			next Err if ($err);
			&ppstr(174,&pstr(414,&he($::FORM{'name'})));
			print '<p>' . $::str[329] . '</p>';
			last Err;
			}

		if ($subaction eq 'save_settings') {
			my $p_data = ();
			foreach $p_data ($fr->list_filter_rules()) {
				next if (($::private{'is_freeware'}) and ($$p_data{'is_system'} == 0));
				my $name = $$p_data{'name'};
				if ($::FORM{"$name-enabled"}) {
					$$p_data{'enabled'} = 1;
					}
				else {
					$$p_data{'enabled'} = 0;
					}
				}
			$err = $fr->frwrite();
			next Err if ($err);

			foreach (
				'allowanonadd',
				'require anon approval',
				'allowanonadd: notify admin',
				'allowanonadd: require user email',
				'allowanonadd: log',
				'allowanonadd: use rate',
				'allowanonadd: max rate',
				) {
				if (not exists($::FORM{$_})) {
					$err = "invalid argument. Required parameter '$_' is not defined";
					next Err;
					}
				$err = &WriteRule($_, $::FORM{$_});
				next Err if ($err);
				}

			my $private_key = '';
			if ((exists($::FORM{'_virtual_aaa_ufs'})) and ($::FORM{'_virtual_aaa_ufs'})) {
				# generate a random 30-character alphanumeric server key
				my @charset = (0..9,'A'..'Z','a'..'z');
				for (1..30) {
					$private_key .= $charset[int(rand(@charset))];
					}
				}
			$err = &WriteRule( 'allowanonadd: use form-signature', $private_key );
			next Err if ($err);

			$::FORM{'pics_rasci_enable'} = 0 unless ($::FORM{'pics_rasci_enable'});
			$::FORM{'pics_ss_enable'} = 0 unless ($::FORM{'pics_ss_enable'});
			foreach (keys %::FORM) {
				next unless (m!^pics_!s);
				$err = &WriteRule($_, $::FORM{$_} || 0);
				next Err if ($err);
				}
			&ppstr(174,$::str[114]);
			last Err;
			}

print <<"EOM";

$::const{'AdminForm'}
	<input type="hidden" name="Action" value="FilterRules" />
	<input type="hidden" name="subaction" value="save_settings" />

EOM

		my $str_rule_list = '';

		my @action_names = (
			$::str[479], # always allow
			$::str[142], # deny
			$::str[478], # require approval
			$::str[477], # promote
			$::str[476], # no update on redirect
			$::str[338], # index nofollow
			$::str[337], # follow noindex
			);

		my $p_data = ();
		foreach $p_data ($fr->list_filter_rules()) {

			if ($::private{'is_freeware'}) {
				next unless ($$p_data{'is_system'});
				}


			my $en = '';

			if ($$p_data{'enabled'}) {
				$en = ' checked="checked"';
				}

			my $urlname = &ue($$p_data{'name'});
			my $htmlname = &he($$p_data{'name'});
			my $action = $action_names[$$p_data{'action'}];

$str_rule_list .= <<"EOM";

<tr class="fdtan">
	<td><input type="checkbox" name="$htmlname-enabled" value="1"$en /></td>
	<td><b>$htmlname</b></td>
	<td><a href="$::const{'admin_url'}&amp;Action=FilterRules&amp;subaction=CreateEdit&amp;name=$urlname" class="onbrown">$::str[411]</a></td>
	<td>

EOM

			unless ($$p_data{'is_system'}) {
				$str_rule_list .= qq!<a href="$::const{'admin_url'}&amp;Action=FilterRules&amp;subaction=delete_rule&amp;name=$urlname" onclick="return confirm('$::str[108]');" class="onbrown">$::str[430]</a>!;
				}

			my $scope = ($$p_data{'apply_to'} == 1) ? $::str[336] : $::str[342];

$str_rule_list .= <<"EOM";

	<br /></td>
	<td>$action</td>
	<td>$scope</td>
</tr>

EOM
			}

		my %replace = %::const;
		$replace{'HTML_BLOCK_1'} = $str_rule_list;


		my $pics_type = 'RASCi';
		my $rulename = 'rasci';
		my $html = '';
		if ($::Rules{'pics_' . $rulename . '_enable'}) {

$html .= sprintf(<<'EOM', $rulename, $::str[415], $rulename, $::str[416], $::str[417]);

			<table border="0">
			<tr>
				<td><input type="radio" name="pics_%s_handle" value="0" /></td>
				<td>%s</td>
			</tr><tr>
				<td><input type="radio" name="pics_%s_handle" value="1" /></td>
				<td>%s</td>
			</tr>
			</table>

			<p>%s</p>

EOM

			my (@pics_codes, @pics_names, @pics_values) = ();
			my $load_err = &load_pics_descriptions( $pics_type, \@pics_codes, \@pics_names, \@pics_values );
			if ($load_err) {
				&ppstr(29,$load_err);
				}
			else {
				$html .= '<dl>';
				my $i = 0;
				for (0..$#pics_codes) {
					my $code = $pics_codes[$_];
					my $name = $pics_names[$_];
					my $p_values = $pics_values[$_];
					my @values = @$p_values;

					$html .= "<dt><b>PICS / $pics_type / $name</b></dt>\n";
					$html .= "<dd>\n";

					my $i = 0;
					foreach (@values) {
						$html .= sprintf('<input type="radio" name="pics_%s_%s" value="%d" /> (%s%d) %s<br />', $rulename, $code, $i, $code, $i, $_ );
						$i++;
						}
					$html .= "</dd>\n";
					}
				$html .= '</dl>';
				}
			}
		$replace{'HTML_BLOCK_2'} = $html;


		$pics_type = 'SafeSurf';
		$rulename = 'ss';
		$html = '';
		if ($::Rules{'pics_' . $rulename . '_enable'}) {

$html .= sprintf(<<'EOM', $rulename, $::str[415], $rulename, $::str[416], $::str[417]);

			<table border="0">
			<tr>
				<td><input type="radio" name="pics_%s_handle" value="0" /></td>
				<td>%s</td>
			</tr><tr>
				<td><input type="radio" name="pics_%s_handle" value="1" /></td>
				<td>%s</td>
			</tr>
			</table>

			<p>%s</p>

EOM

			my (@pics_codes, @pics_names, @pics_values) = ();
			my $load_err = &load_pics_descriptions( $pics_type, \@pics_codes, \@pics_names, \@pics_values );
			if ($load_err) {
				&ppstr(29,$load_err);
				}
			else {
				$html .= '<dl>';
				my $i = 0;
				for (0..$#pics_codes) {
					my $code = $pics_codes[$_];
					my $name = $pics_names[$_];
					my $p_values = $pics_values[$_];
					my @values = @$p_values;

					$html .= "<dt><b>PICS / $pics_type / $name</b></dt>\n";
					$html .= "<dd>\n";

					my $i = 0;
					foreach (@values) {
						$html .= sprintf('<input type="radio" name="pics_%s_%s" value="%d" /> %d. %s<br />', $rulename, $code, $i, $i, $_ );
						$i++;
						}
					$html .= "</dd>\n";
					}
				$html .= '</dl>';
				}
			}
		$replace{'HTML_BLOCK_3'} = $html;

		$replace{'HTML_BLOCK_4'} = qq!<label for="i8">! . &pstr(556, qq!</label><input name="allowanonadd: max rate" size="4" style="text-align:right" />! );;

		$::Rules{'_virtual_aaa_ufs'} = $::Rules{'allowanonadd: use form-signature'} ? 1 : 0;

		my $template = &PrintTemplate( 1, 'admin_fr.txt', $::Rules{'language'}, \%replace );
		print &SetDefaults( $template, \%::Rules );
		print "</form>";




		last Err;
		}
	continue {
		&ppstr(29,$err);
		}
	}





sub load_pics_descriptions {
	my $err = '';
	Err: {
		my ($pics_type, $p_codes, $p_names, $p_values) = @_;
		my $text = '';
		($err, $text) = &ReadFileL('templates/pics_descriptions.txt');
		next Err if ($err);
		my $current_code = '';
		my $p_myvalues = ();
		foreach (split(m!\n!s, $text)) {
			next if (m!^\#!s);
			my @fields = split(m! \| !s);
			next unless ($#fields == 4);
			if ($fields[0] eq $pics_type) {
				my ($code, $code_name, $value, $value_name) = @fields[1..4];
				if ($current_code ne $code) {
					$current_code = $code;
					push(@$p_codes, $code);
					push(@$p_names, $code_name);
					my @values = ();
					$p_myvalues = \@values;
					push(@$p_values, $p_myvalues);
					}
				$$p_myvalues[$value] = $value_name;
				}
			}
		}
	return $err;
	}





sub s_create_edit_rule {
	my $err = '';
	Err: {
		local $_;

		my $fr = &fdse_filter_rules_new();
		my %system_rules = $fr->list_system_rules();

		if ($::private{'is_freeware'}) {
			unless (($::FORM{'name'}) and ($system_rules{$::FORM{'name'}})) {
				$err = $::str[158];
				next Err;
				}
			}

		my %defaults = (
			'enabled' => 1,
			'fr_action' => 2,
			'fr_analyze' => 2,
			'fr_mode' => 0,
			'name' => 'New Rule',
			'occurrences' => 1,
			'promote_val' => 5,
			'substr' => '',
			'fr_apply_to' => 1,
			);

		if ($::FORM{'write'}) {

			my @strings = ();
			foreach (split(m!\r|\n!s, $::FORM{'substr'})) {
				$_ = &Trim($_);
				next unless ($_);
				push(@strings, $_);
				}
			my @litstrings = ();
			foreach (split(m!\r|\n!s, $::FORM{'litsubstr'})) {
				$_ = &Trim($_);
				next unless ($_);
				push(@litstrings, $_);
				}

			my $apply_to_str = '';
			if ($::FORM{'fr_apply_to'} eq '2') {
				for (1..6) {
					next unless ($::FORM{"z$_"} eq '1');
					$apply_to_str .= "$_,";
					}
				}
			elsif ($::FORM{'fr_apply_to'} eq '3') {
				foreach (keys %::FORM) {
					next unless (m!^zz(.*)$!s);
					$apply_to_str .= &ue($1) . ',';
					}
				}

			$err = $fr->add_filter_rule( $::FORM{'enabled'}, $::FORM{'name'}, $::FORM{'fr_action'}, $::FORM{'promote_val'}, $::FORM{'fr_analyze'}, $::FORM{'fr_mode'}, $::FORM{'occurrences'}, $::FORM{'fr_apply_to'}, $apply_to_str, \@strings, \@litstrings );
			next Err if ($err);
			if (($::FORM{'orig_name'}) and ($::FORM{'orig_name'} ne $::FORM{'name'})) {
				$err = $fr->delete_filter_rule($::FORM{'orig_name'});
				next Err if ($err);
				&ppstr(174, &pstr(465,&he($::FORM{'orig_name'},$::FORM{'name'})) );
				}
			&ppstr(174, &pstr(464,&he($::FORM{'name'})) );
			print '<p>' . $::str[329] . '</p>';
			last Err;
			}

		my $html_orig_name = '';

		if ($::FORM{'name'}) {
			$html_orig_name = &he($::FORM{'name'});
			my $p_data = $fr->{$::FORM{'name'}};

			unless ('HASH' eq ref($p_data)) {
				$err = &pstr(55,&he($::FORM{'name'}));
				next Err;
				}

			my $p_strings = $$p_data{'p_strings'};
			$defaults{'substr'} = join("\n", @$p_strings);

			my $p_litstrings = $$p_data{'p_litstrings'};
			$defaults{'litsubstr'} = join("\n", @$p_litstrings);

			foreach ('name', 'fr_action', 'promote_val', 'fr_analyze', 'fr_mode', 'enabled', 'occurrences', 'fr_apply_to') {
				my $name = $_;
				$name =~ s!^fr_!!o;
				$defaults{$_} = $$p_data{$name};
				}

			if ($$p_data{'apply_to'} eq '2') {
				my @realm_types = split(m!\,!s, $$p_data{'apply_to_str'} );
				foreach (@realm_types) {
					next unless (m!^\d+$!s);
					$defaults{"z$_"} = 1;
					}
				}
			elsif ($$p_data{'apply_to'} eq '3') {
				my @realms = split(m!\,!s, $$p_data{'apply_to_str'} );
				foreach (@realms) {
					$_ = &ud($_);
					next unless ($_);
					$defaults{"zz$_"} = 1;
					}
				}


			}
		else {
			my $num = 1;
			my $p_data = ();
			foreach $p_data ($fr->list_filter_rules()) {
				if ($$p_data{'name'} =~ m!New Rule (\d+)!is) {
					$num = ($1 + 1) if ($1 >= $num);
					}
				}
			$defaults{'name'} = "New Rule $num";
			}

		my $name = $defaults{'name'};
		$name = &he( $name );

		my $name_form = qq!<input name="name" value="$name" size="40" />!;
		if ($system_rules{$name}) {
			$name_form = qq!<input type="hidden" name="name" value="$name" />$name!;
			}

print <<"EOM";

$::const{'AdminForm'}
<input type="hidden" name="Action" value="FilterRules" />
<input type="hidden" name="subaction" value="CreateEdit" />
<input type="hidden" name="write" value="1" />
<input type="hidden" name="orig_name" value="$html_orig_name" />

EOM

		my %replace = %::const;
		$replace{'HTML_BLOCK_1'} = $name_form;

		my $i = 0;
		my $realm_list = '';
		my $p_realm_data = ();
		foreach $p_realm_data ($::realms->listrealms('all')) {
			$i++;
			$realm_list .= qq!<input type="checkbox" name="zz$$p_realm_data{'html_name'}" value="1" id="zz$i" /> <label for="zz$i">$$p_realm_data{'html_name'}</label><br />\n!;
			}

		$replace{'HTML_BLOCK_2'} = $realm_list;

		my $template = &PrintTemplate( 1, 'admin_fr2.txt', $::Rules{'language'}, \%replace );
		print &SetDefaults( $template, \%defaults );
		print "</form>";
		}
	return $err;
	}





sub process_queued_pages {

	my $Realm = $::FORM{'Realm'};

	my %Process = ();

# Map
# 	Proc0 => Wait
#	Proc1 => Approve
#	Proc2 => Deny
#	Proc3 => Delete


	foreach (keys %::FORM) {
		next unless (m!^R\d+$!s);
		next unless ($::FORM{$_} =~ m!^Proc(\d)_(.*)$!s);
		$Process{$2} = $1;
		}

	my ($obj, $p_rhandle, $p_whandle) = ();
	my $obj_needs_closed = 0;

	my $err = '';
	Err: {

		my $p_realm_data = ();
		($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
		next Err if ($err);

		my ($name, $file) = ($$p_realm_data{'name'}, $$p_realm_data{'file'});

		$obj = &LockFile_new();
		($err, $p_rhandle, $p_whandle) = $obj->ReadWrite( "$file.need_approval" );
		next Err if ($err);
		$obj_needs_closed = 1;

		my %crawler_results = ();

		my $b_write_to_file = 0;

		while (defined($_ = readline($$p_rhandle))) {
			my @Fields = split(m!\|\|!s);
			next unless ($#Fields > 4);
			# time, remote_host, error_msg, is_error, url, record, email

			my $URL = $Fields[4];

			if ($Process{$URL}) {


				my ($is_valid, %pagedata) = &parse_text_record( $Fields[5] );
				if ($is_valid) {
					&compress_hash( \%pagedata );
					}
				else {
					# init as clean hash; could be a delete command, which won't come with a full record; that's ok:
					%pagedata = ();
					}
				$pagedata{'url'} = $URL;
				$pagedata{'is_error'} = 0;
				$pagedata{'record'} = "$Fields[5]\n";


				# deny a valid entry
				if ($Process{$URL} == 2) {
					$pagedata{'is_error'} = 1;
					$crawler_results{$URL} = \%pagedata;
					$b_write_to_file = 1;
					next;
					}

				# Delete an invalid URL:
				elsif ($Process{$URL} == 3) {
					$pagedata{'is_error'} = 1;
					$crawler_results{$URL} = \%pagedata;
					$b_write_to_file = 1;
					next;
					}

				# allow a valid entry
				elsif ($Process{$URL} == 1) {
					$pagedata{'is_error'} = 0;
					$crawler_results{$URL} = \%pagedata;
					$b_write_to_file = 1;
					next;
					}
				}
			# those other records can just stay there:
			print { $$p_whandle } $_;
			}

		if ($b_write_to_file) {
			my ($total_records, $new_records, $updated_records, $deleted_records) = (0, 0, 0, 0);

			($err, $total_records, $new_records, $updated_records, $deleted_records) = &update_realm( $Realm, \%crawler_results );
			next Err if ($err);

			$err = $obj->Merge();
			$obj_needs_closed = 0;
			next Err if ($err);


			$::realms->setpagecount($Realm, $total_records, 1);
			$err = &SaveLinksToFileEx( $p_realm_data, \%crawler_results );
			next Err if ($err);

			&pppstr(289, $total_records, $$p_realm_data{'html_name'}, $new_records, $updated_records, $deleted_records );
			}
		else {
			&pppstr(418);
			}

		my $URL = '';

		my @localname = (
			$::str[426],
			$::str[427],
			$::str[142],
			$::str[430],
			);

		foreach $URL (sort keys %crawler_results) {
			my $ref_pagedata = $crawler_results{$URL};
			if ($$ref_pagedata{'sub status msg'}) {
				&ppstr(174, "$localname[$Process{$URL}] URL '" . &he($URL) . "' - $$ref_pagedata{'sub status msg'}" );
				}
			else {
				&ppstr(174, "$localname[$Process{$URL}] URL '" . &he($URL) . "'" );
				}
			}

		last Err;
		}
	continue {
		&ppstr(29,$err);
		}

	# If something went wrong, then close the file without committing changes:
	if ($obj_needs_closed) {
		$err = $obj->Cancel();
		if ($err) {
			&ppstr(29,$err);
			}
		}

	}





sub present_queued_pages {
	my $err = '';
	Err: {
		my ($Realm) = @_;

		my $Start = ($::FORM{'Start'}) ? $::FORM{'Start'} : 1;

		my $End = $Start + $::Rules{'crawler: max pages per batch'} - 1;

		my $p_realm_data = ();
		($err, $p_realm_data) = $::realms->hashref( $Realm );
		next Err if ($err);

		my $file = $$p_realm_data{'file'};

		my $display_html = '';

		my $Count = 0;

		my $obj = &LockFile_new();
		my $p_rhandle = ();
		($err, $p_rhandle) = $obj->Read( "$file.need_approval" );
		next Err if ($err);

		my %shown_urls = ();

		my @allow_change = ();

		while (defined($_ = readline($$p_rhandle))) {
			my @Fields = split(m!\|\|!s, &Trim($_));
			# time, remote_host, error_msg, is_error, url, record, email

			my $URL = $Fields[4];

			# just show these guys once; skip duplicates
			next if ($shown_urls{$URL});
			$shown_urls{$URL}++;

			my $html_status = '';

			my ($index_time, $index_host, $index_error) = ($Fields[0], $Fields[1], $Fields[2]);

			my $str_index_time = &FormatDateTime( $index_time, $::Rules{'ui: date format'} );

			my ($t1, $t2) = ('Allow', 'Deny');

			my $is_error = ($Fields[3]) ? 1 : 0;

			my %pagedata = ();

			unless ($is_error) {
				my $is_valid = 1;
				($is_valid, %pagedata) = &parse_text_record( $Fields[5] );
				next unless ($is_valid);
				}

			$Count++;

			next if ($Count < $Start);
			next if ($Count > $End);

			my $html_url = &he( $URL );

			my $user_html = '';
			if ($Fields[6]) {
				my $user_email = &he( $Fields[6] );
				$user_html = " - <a href=\"mailto:$user_email\">$user_email</a>";
				}

			if ($is_error) {

				$html_status = &StandardVersion(
					'rank' => $Count,
					'url' => $URL,
					'title' => "Remove: " . &he($URL),
					'description' => $Fields[2],
					);
				($t1, $t2) = ('Remove', 'Ignore');

				my $text_user = &pstr(419, $index_host);

$display_html .= <<"EOM";

		<p>$str_index_time - $text_user $user_html.</p>
		<p>$index_error</p>
		<table border="0">
		<tr>
			<td valign="top" width="120"><input type="radio" name="R$Count" value="Proc3_$html_url" checked="checked" /> $::str[430]</td>
			<td valign="top">$html_status</td>
		</tr>
		</table>
		<hr size="1" />

EOM


				}
			else {

				$html_status = &AdminVersion(
					'rank' => $Count,
					%pagedata,
					);

				push(@allow_change, $Count);

				my $text_user = &pstr(419,$index_host);


$display_html .= <<"EOM";

		<p>$str_index_time - $text_user $user_html.</p>
		<p>$index_error</p>
		<table border="0">
		<tr>
			<td valign="top" width="120" nowrap="nowrap">
				<input type="radio" name="R$Count" value="Proc0_$html_url" checked="checked" /> $::str[426]<br />
				<input type="radio" name="R$Count" value="Proc1_$html_url" /> $::str[427]<br />
				<input type="radio" name="R$Count" value="Proc2_$html_url" /> $::str[142]</td>
			<td valign="top">$html_status</td>
		</tr>
		</table>
		<hr size="1" />

EOM
				}
			}
		$err = $obj->Close();
		next Err if ($err);

		if ($Start > $Count) {
			&pppstr(420);
			}
		else {

			my $link = "$::const{'admin_url'}&amp;Realm=" . &ue( $Realm ) . "&amp;Action=$::FORM{'Action'}&amp;subaction=ShowPending&amp;Start=";
			my ($jump_sum, $jumptext) = &str_jumptext( $Start, $::Rules{'crawler: max pages per batch'}, $Count, $link, 1 );
			print $jump_sum;
			print $jumptext;

			my $is_okay = (scalar @allow_change) ? 'true' : 'false';

print <<"EOM";

$::const{'AdminForm'}
		<input type="hidden" name="Action" value="FilterRules" />
		<input type="hidden" name="subaction" value="PQP" />
		<input type="hidden" name="Realm" value="$Realm" />

		<script type="text/javascript">
		<!--
		var okay = false;
		if ((document) && (document.F1)) {
			okay = $is_okay;
			}
		function SetDef (x) {
			if (okay) {
EOM

			foreach (@allow_change) {
				print "\t\tif (document.F1.R$_) { document.F1.R" . $_ . "[x].checked = true; }\n";
				}

print <<"EOM";
				}
			}
		//--></script>

		<p><b>$::str[421] - '$Realm'</b></p>

		<p><input type="submit" class="submit" value="$::str[362]" /></p>

		<script type="text/javascript">
		<!--
		if (okay) {
			document.write("<p>[$::str[148] <a href=javascript:SetDef(0)>$::str[426]</a> - <a href=javascript:SetDef(1)>$::str[427]</a> - <a href=javascript:SetDef(2)>$::str[142]</a> ]</p>");
			}
		//-->
		</script>

		<hr size="1" />

		$display_html

		<script type="text/javascript">
		<!--
		if (okay) {
			document.write("<p>[ $::str[148] <a href=javascript:SetDef(0)>$::str[426]</a> - <a href=javascript:SetDef(1)>$::str[427]</a> - <a href=javascript:SetDef(2)>$::str[142]</a> ]</p>");
			}
		//-->
		</script>

		<p><input type="submit" class="submit" value="$::str[362]" /></p>

		<p><b>$::str[430]</b> - $::str[423].<br />
		<b>$::str[142]</b> - $::str[423].<br />
		<b>$::str[427]</b> - $::str[424]<br />
		<b>$::str[426]</b> - $::str[425]</p>
		<p>$::str[422]</p>

		</form>

EOM

			print $jumptext;
			}
		last Err;
		}
	continue {
		&ppstr(29,$err);
		}
	}





sub anonadd_main {
	my $err = '';
	Err: {

		if (not $::Rules{'allowanonadd'}) {
			$err = $::str[173];
			next Err;
			}
		elsif (0 == $::realms->realm_count('has_no_base_url')) {
			$err = &pstr( 552, $::str[431] );
			next Err;
			}

		LimitSubmitRate: {

			last unless $::Rules{'allowanonadd: use rate'};

			my @submit_times = split(m!\.!s, $::Rules{'allowanonadd: recent submit times'});
			# format: newest.new.medium.old.oldest

			my $submit_count = scalar @submit_times;

			last if ($submit_count < $::Rules{'allowanonadd: max rate'}); # not enough data to block

			my $time_of_nth_submission = $submit_times[ $::Rules{'allowanonadd: max rate'} - 1 ];

			my $five_min = 5 * 60;

			if (($::private{'script_start_time'} - $time_of_nth_submission) < $five_min) {
				$err = &pstr( 557, $::Rules{'allowanonadd: max rate'} );
				next Err;
				}
			}

		if ((exists($::FORM{'Realm'})) and ((exists($::FORM{'URL'})) or (exists($::FORM{'b_submit'})))) {

			# validate 'Realm' existence:
			my $p_realm;
			($err, $p_realm) = $::realms->hashref( $::FORM{'Realm'} );
			next Err if ($err);

			unless ($p_realm->{'is_open_realm'}) {
				$err = "realm '$p_realm->{'html_name'}' is not an open realm";
				next Err;
				}


			my $failpoint = 0;
			ValidateFormSignature: {

				last unless $::Rules{'allowanonadd: use form-signature'};

				unless ((exists($::FORM{'keynames'})) and ($::FORM{'keynames'} =~ m!^(\w{3})(\w{3})(\w{3})(\w{3})(\w{3})(\w{3})(\w{3})(\w{3})(\w{3})$!s)) {
					$failpoint = 1;
					next;
					}

				my @names = ($1, $2, $3, $4, $5, $6, $7, $8);

				# reverse the aliases:
				$::FORM{'URL'}   = $::FORM{$names[1]};
				$::FORM{'EMAIL'} = $::FORM{$names[2]};
				my $timestamp = $::FORM{$names[3]};
				my $signature = $::FORM{$names[4]};

				if (($::private{'script_start_time'} - $timestamp) > 20 * 60) {
					$failpoint = 2;
					next;
					}

				my $audit_sig = '';

				my $index;
				foreach $index (0..4) {
					my $char8 = '';

					$char8 .= substr( $timestamp, 2 * $index, 2 );
					$char8 .= substr( $::Rules{'allowanonadd: use form-signature'}, 6 * $index, 6 );

					my $salt = substr( $signature, 13 * $index, 13 );

					$audit_sig .= crypt( $char8, $salt );

					}

				if ($audit_sig ne $signature) {
					$failpoint = 3;
					next;
					}

				# full decoys:

				if (exists $::FORM{$names[5]}) {
					$failpoint = 4;
					next;
					}
				if (exists $::FORM{$names[6]}) {
					$failpoint = 5;
					next;
					}

				# either-or decoy:

				if ((exists $::FORM{$names[7]}) and (exists $::FORM{$names[0]})) {
					$failpoint = 6;
					next;
					}
				if ((not exists $::FORM{$names[7]}) and (not exists $::FORM{$names[0]})) {
					$failpoint = 7;
					next;
					}

				last;
				}
			continue {
				$err = qq!invalid form signature.  Please visit the <a href="$::const{'search_url_ex'}Mode=AnonAdd">submission form</a> and try again (failpoint $failpoint)!;
				next Err;
				}





			$::const{'is_cmd'} = 0;
			$err = &s_AddURL(1, $::FORM{'Realm'}, $::FORM{'URL'});
			next Err if ($err);

			LimitSubmitRate: {

				last unless $::Rules{'allowanonadd: use rate'};

				my @submit_times = split(m!\.!s, $::Rules{'allowanonadd: recent submit times'});
				# format: newest.new.medium.old.oldest

				my $submit_count = scalar @submit_times;

				if ($submit_count >= $::Rules{'allowanonadd: max rate'}) {
					splice( @submit_times, $::Rules{'allowanonadd: max rate'} - 1 );
					}

				my $new = join( '.', ($::private{'script_start_time'}, @submit_times) );

				$err = &WriteRule( 'allowanonadd: recent submit times', $new );
				next Err if ($err);
				}

			}

		my ($count, $html_hidden, $html_tr) = $::realms->html_select_ex('is_open_realm', $::FORM{'Realm'} );

		my $hidden = '';
		my ($n, $v);
		while (($n, $v) = &he(each %::FORM)) {
			next unless ($n =~ m!^p:!s);
			$hidden .= qq!<input type="hidden" name="$n" value="$v" />\n!;
			}

		if (($::Rules{'default search terms'}) and (not ($::FORM{'EMAIL'}))) {
			$::FORM{'EMAIL'} = 'you@yourhost.tld';
			}


		my %defaults = %::FORM;
		$defaults{'URL'} = $::FORM{'URL'} || 'http://';
		my %alias_field_names = ('URL' => 'URL','EMAIL' => 'EMAIL');
		my %inserted_form_elements = ();

		CreateFormSignature: {

			last unless $::Rules{'allowanonadd: use form-signature'};

			my $timestamp = substr($::private{'script_start_time'},0,10); # limit to 10 chars
			$timestamp = ('0' x (10 - length($timestamp))) . $timestamp; # 0-pad for earlier times

			my @charset = (0..9,'a'..'z','A'..'Z');

			# create eight unique random 3-character strings:
			my %uniq = ();
			my @names = ();
			while ($#names < 8) {
				my $ran = '';
				$ran .= $charset[int(rand(@charset))];
				$ran .= $charset[int(rand(@charset))];
				$ran .= $charset[int(rand(@charset))];
				next if exists $uniq{$ran};
				push(@names,$ran);
				$uniq{$ran} = 1;
				}

			my $signature = '';

			my $index;
			foreach $index (0..4) {
				my $char8 = '';

				$char8 .= substr( $timestamp, 2 * $index, 2 );
				$char8 .= substr( $::Rules{'allowanonadd: use form-signature'}, 6 * $index, 6 );

				my $salt = $charset[int(rand(@charset))] . $charset[int(rand(@charset))];

				$signature .= crypt( $char8, $salt );

				}

			%alias_field_names = (
				'URL'   => $names[1],
				'EMAIL' => $names[2],
				'time'  => $names[3],
				'sig'   => $names[4],
				);

			$defaults{'keynames'} = join( '', @names );
			$defaults{$names[3]} = $timestamp;
			$defaults{$names[4]} = $signature;
			$defaults{$names[1]} = $::FORM{'URL'} || 'http://';
			$defaults{$names[2]} = $::FORM{'EMAIL'};


			$inserted_form_elements{ qq!<input type="hidden" name="keynames" />! } = 1;
			$inserted_form_elements{ qq!<input type="hidden" name="$alias_field_names{'sig'}" />! } = 1;
			$inserted_form_elements{ qq!<input type="hidden" name="$alias_field_names{'time'}" />! } = 1;

			# full decoys:
			$inserted_form_elements{ qq!<script>//<input type="hidden" name="$names[5]" value="$names[6]" /></script>! } = 1;
			$inserted_form_elements{ qq~<!-- <input type="hidden" name="$names[6]" value="$names[5]" /> -->~ } = 1;

			# either-or decoy:
			$inserted_form_elements{ qq!<script>document.write('<input type="hidden" name="$names[7]" value="$names[0]" />');</script>! } = 1;
			$inserted_form_elements{ qq!<noscript><input type="hidden" name="$names[0]" value="$names[7]" /></noscript>! } = 1;

			}


		my $input = qq!<input name="$alias_field_names{'URL'}" size="40" id="fdse_URL" />!;
		if ($::Rules{'multi-line add-url form - visitors'}) {
			$input = qq!<textarea name="$alias_field_names{'URL'}" rows="3" cols="40" style="wrap:soft" id="fdse_URL"></textarea>!;
			}


		$hidden .= join('', keys %inserted_form_elements);

print &SetDefaults( <<"EOM", \%defaults );

<p><b>$::str[172]</b></p>
<blockquote>
	<form method="post" action="$::const{'script_name'}">
	<input type="hidden" name="Mode" value="AnonAdd" />
	<input type="hidden" name="b_submit" value="1" />
	$hidden
	$html_hidden

	<p>$::str[288]</p>
	<table border="0">
	<tr>
		<td align="right"><b><label for="fdse_URL">$::str[74]:</label></b></td>
		<td>$input</td>
	</tr>
	<tr>
		<td align="right"><b><label for="fdse_EMAIL">$::str[206]:</label></b></td>
		<td><input name="$alias_field_names{'EMAIL'}" size="40" id="fdse_EMAIL" /></td>
	</tr>
$html_tr
	<tr>
		<td><br /></td>
		<td><input type="submit" class="submit" value="$::str[172]" /></td>
	</tr>
	</table>

	</form>
</blockquote>

EOM
		last Err;
		}
	return $err;
	}





sub admin_main {
	my $err = '';
	Err: {
		local $_;

		#changed 0056
		IPLimit: {

			last IPLimit unless (($::private{'visitor_ip_addr'}) and ($::private{'allow_admin_access_from'}));

			# patterns must be of the format a.b.c.d or a.b.c.* or a.b.* or a.*
			if ($::private{'allow_admin_access_from'} =~ m![^0-9\.\s\*]!s) {
				my $hstr = &he($::private{'allow_admin_access_from'});
				$err = "string 'allow_admin_access_from' can only contain numbers, spaces, dots, and asterisks. An example of a valid string is '123.45.6.*'. Your string is currently set to '$hstr' which includes characters from outside the allowed set";
				next Err;
				}
			my @patterns = split(m!\s+!s, $::private{'allow_admin_access_from'});
			foreach (@patterns) {
				s!\.!\\\.!sg;
				s!\*!\.\*!sg;
				last IPLimit if ($::private{'visitor_ip_addr'} =~ m!^$_$!s);
				}
			$err = "access denied to admin functions. Your IP address $::private{'visitor_ip_addr'} is not among the list of allowed addresses. The list of allowed addresses is controlled with the 'allow_admin_access_from' variable within the source code";
			next Err;
			}


		$| = 1;

		my $action = (exists $::FORM{'Action'}) ? $::FORM{'Action'} : '';

		if ($action ne 'NavBar') {
			#changed 0045 -- is this folder writable?
			my $w_test = 'is_writable.txt';
			if ((-e $w_test) and (not unlink($w_test))) {
				$err = &pstr(54, $w_test, $!);
				next Err;
				}
			unless (open( FILE, ">$w_test" )) {
				$err = &pstr(472, $!);
				next Err;
				}
			close(FILE);
			unlink($w_test);
			}

		$::const{'is_cmd'} = ((exists($::FORM{'interface'})) and ($::FORM{'interface'} eq 'cmdline')) ? 1 : 0;
		if (exists($::FORM{'fdrk_audit'})) { &regkey_verify(); last Err; }
		my ($is_auth, $form_password, $url_password) = &Authenticate( $::Rules{'password'} );
		last Err unless ($is_auth);

		# Initialize network client cache:
		my %nc_cache = ();
		$::private{'p_nc_cache'} = \%nc_cache;

		$::const{'AdminForm'} = qq!<form method="post" action="$::const{'script_name'}" name="F1">\n<input type="hidden" name="Mode" value="Admin" />\n$form_password!;

		$::const{'admin_url'} .= $url_password;

		if ($ENV{'FDSE_NO_EXEC'}) {
			eval 'eval $FDSE_CALLBACK_SUB;';
			last Err;
			}

		my %admin_replace = %::const;

		$admin_replace{'copyright'} =~ s!<a href!<a class="onbrown" href!s;

		&header_print();

		$admin_replace{'ue_msg'} = &pstr(325, "$::const{'help_file'}1162.html" );
		$admin_replace{'ue_msg'} =~ s!\"!\\\"!sg; # escape quotes " for Javascript

		if (not $::const{'is_cmd'}) {

			my $warn_uncontrolled_exit = &pstr(325, "$::const{'help_file'}1162.html" );
			$warn_uncontrolled_exit =~ s!\"!\\\"!sg; # escape quotes " for Javascript


print <<"EOM";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title>FDSE: Admin Page</title>
	<meta http-equiv="Content-Type" content="$::const{'content_type'}" />
	<meta name="version" content="$::VERSION" />
	<meta name="robots" content="none" />
	<style type="text/css">
	<!--
	#sidebar {
		position:absolute;
		top:0;
		left:0;
		border-right:2px solid #000000;
		border-bottom:2px solid #000000;
		width:10em;
		color:#000000;
		background-color:#d5d2bb;
		padding-top:3px;
		padding-bottom:3px;
		}
	.mi {
		width:8em;
		margin-left:0.5em;
		color:#000000;
		background-color:#9eb3c7;
		border-left:2px solid #ffffff;
		border-right:2px solid #ffffff;
		border-top:2px solid #ffffff;
		padding:2px;
		text-align:center;
		font-weight:bold;
		}
	.mif {
		border-bottom:2px solid #ffffff;
		margin-bottom:1em;
		}
	#script_output {
		margin-top:7px;
		margin-left:11em;
		margin-right:1em;
		padding:0;
		}
	.breadcrumbs {
		font-weight:bold;
		margin-bottom:1em;
		}
	.defaultsetting {
		color:#009900;
		background-color:#ffffff;
		font-weight:bold;
		}
	.customsetting {
		color:#990099;
		background-color:#ffffff;
		font-weight:bold;
		}
	.navbar,.fdtan,.t {
		color:#000000;
		background-color:#d5d2bb;
		}
	.g,.grey {
		color:#000000;
		background-color:#eeeeee;
		}
	.fdblue,th,.b {
		color:#000000;
		background-color:#9eb3c7;
		}
	input.submit,body,p,dl,dt,dd,td,th,li,ul,ol {
		font-family:verdana,sans-serif;
		font-size:small;
		}
	textarea,input {
		font-family:monospace;
		}
	input.submit {
		color:#000000;
		background-color:#ffffff;
		cursor:pointer;
		font-weight:bold;
		}
	a.onblue,#sidebar a {
		color:#000000;
		background-color:#9eb3c7;
		}
	a.onblue:hover,#sidebar a:hover {
		color: #ff4444;
		background-color:#9eb3c7;
		}
	a.onbrown,#sidebar a.onbrown {
		color:#cc0000;
		background-color:#d5d2bb;
		}
	a.onbrown:hover,#sidebar a.onbrown:hover {
		color: #ff4444;
		background-color:#d5d2bb;
		}
	a {
		color:#cc0000;
		background-color:#ffffff;
		}
	a:hover {
		color: #ff4444;
		background-color:#ffffff;
		}
	.existingdata {
		color:#000000;
		background-color:#cccccc;
		}
	form,body {
		margin:0;
		padding:0;
		}
	//-->
	</style>
	<script type="text/javascript">
	<!--
	var g_loaded = false;
	function HandleUncontrolledExit() {
		if (!g_loaded) {
			var err_msg = "$warn_uncontrolled_exit";
			if ((document) && (document.all) && (document.all("script_output"))) {
				document.all("script_output").innerHTML += "<p>" + err_msg + "</p>";
				}
			else {
				alert(err_msg);
				}
			}
		}
	//-->
	</script>
</head>
<body dir="$::const{'dir'}" onload="HandleUncontrolledExit();">

<div id="sidebar">

	<div class="mi mif"><a href="$::const{'admin_url'}">$::str[96]</a></div>

	<div class="mi"><a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a></div>

	<div class="mi"><a href="$::const{'admin_url'}&amp;Action=UserInterface">$::str[165]</a></div>

	<div class="mi"><a href="$::const{'admin_url'}&amp;Action=FilterRules">$::str[162]</a></div>

	<div class="mi"><a href="$::const{'admin_url'}&amp;Action=AdPage">$::str[145]</a></div>

	<div class="mi"><a href="$::const{'admin_url'}&amp;Action=manage_data_storage">$::str[292]</a></div>

	<div class="mi"><a href="$::const{'admin_url'}&amp;Action=ViewLog">$::str[106]</a></div>

	<div class="mi"><a href="$::const{'admin_url'}&amp;Action=UL">$::str[467]</a></div>

	<div class="mi"><a href="$::const{'admin_url'}&amp;Action=PS">$::str[183]</a></div>

	<div class="mi mif"><a href="$::const{'admin_url'}&amp;Action=GeneralRules">$::str[159]</a></div>

	<div class="mi"><a href="$::const{'help_file'}" target="_blank">$::str[432]</a></div>

	<div class="mi"><a href="$::const{'search_url'}">$::str[433]</a></div>

	<div class="mi mif"><a href="$::const{'admin_url'}&amp;Action=LogOut">$::str[434]</a></div>

	$admin_replace{'copyright'}
	$::str[352]
	<noscript>
		<p align="center"><small><a href="$::const{'help_file'}1187.html" class="onbrown" target="_blank">$::str[551]</a></small></p>
	</noscript>

</div>
<div id="script_output">

EOM


$::private{'html_footer'} = <<"EOM";

</div>
<script type="text/javascript">
<!--
g_loaded = true;
//-->
</script>

<p><br /></p>

<p><br /></p>

</body>
</html>

EOM

			}

		$| = 0;

		if ($action =~ m!^Add\s?URL$!s) {

			# allow for single URL, this will need to be cleaned up.

			my @addresses_to_index = ();

			if (defined($::FORM{'URL'})) {
				push(@addresses_to_index, $::FORM{'URL'});
				}
			else {
				while (defined($_ = each %::FORM)) {
					next unless (m!^(A|AddLink)\d+$!s);
					push(@addresses_to_index, $::FORM{$_});
					}
				}
			if (($::FORM{'EntireSite'}) and ('1' eq $::FORM{'EntireSite'})) {
				$::FORM{'StartTime'} = $::private{'script_start_time'} - 5;
				$action = $::FORM{'Action'} = 'CrawlEntireSite';
				$::FORM{'LimitPattern'} = '^' . quotemeta(&get_web_folder($::FORM{'URL'}));
				}
			$err = &s_AddURL(0, $::FORM{'Realm'}, @addresses_to_index);
			next Err if ($err);
			}
		elsif ($action eq 'Rewrite') {
			&ui_Rewrite();
			}
		elsif ($action eq 'UL') {
			&ui_License();
			}
		elsif ($action eq 'Review') {
			&ui_ReviewIndex();
			}
		elsif ($action eq 'SI') {
			&ui_sysinfo();
			}
		elsif ($action eq 'BCST') {
			$err = &ui_BCST();
			next Err if ($err);
			}
		elsif ($action eq 'rebuild') {
			&ui_Rebuild();
			}
		elsif ($action eq 'CrawlEntireSite') {
			&s_CrawlEntireSite($::FORM{'Realm'});
			}
		elsif ($action eq 'ViewLog') {
			&ui_ViewStats();
			}
		elsif ($action eq 'UserInterface') {
			&ui_UserInterface();
			}
		elsif ($action eq 'Edit') {
			$err = &ui_EditRecord();
			next Err if ($err);
			}
		elsif ($action eq 'DeleteRecord') {
			&ui_DeleteRecord();
			}
		elsif ($action eq 'FilterRules') {
			&ui_FilterRules();
			}
		elsif ($action eq 'GeneralRules') {
			$err = &ui_GeneralRules();
			next Err if ($err);
			}
		elsif ($action eq 'manage_data_storage') {
			&ui_DataStorage();
			}
		elsif ($action eq 'AdPage') {
			$err = &ui_ManageAds();
			next Err if ($err);
			}
		elsif ($action eq 'AddForbidSite') {
			my $fr = &fdse_filter_rules_new();
			my $p_data = $fr->{'Forbid Sites'};
			my $p_array = ($::FORM{'URL'} =~ m!\.\*!s) ? $$p_data{'p_strings'} : $$p_data{'p_litstrings'};
			push(@$p_array,$::FORM{'URL'});
			$err = $fr->frwrite();
			next Err if ($err);

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=DeleteRecord">$::str[95]</a>
</div>


EOM
			&ppstr(174, &pstr(466,&he($::FORM{'URL'})) );
			}
		elsif ($action eq 'PS') {
			&ui_PersonalSettings();
			}
		elsif ($action eq 'ManageRealms') {
			$err = &ui_ManageRealms();
			next Err if ($err);
			}
		else {
			&ui_AdminPage();
			}
		last Err;
		}
	return $err;
	}





sub get_web_folder {
	my ($err, $clean, $host, $port, $path, $query, $frag, $folder) = &uri_parse(@_);
	return $folder;
	}





sub ui_ManageAds {
	my $err = '';
	Err: {
		my $subaction = $::FORM{'SA'} || '';

		my %sub_desc = (
			'' => $::str[152],
			'RC' => $::str[147],
			'WA' => $::str[362],
			);

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=AdPage">$::str[145]</a>
	<span class="gt">&rarr;</span>
	$sub_desc{$subaction}
</div>

EOM

		my $default_text = qq~<p align="center"><!-- $::str[143] --></p>~;

		if ($::private{'is_freeware'}) {
			$err = $::str[158];
			next Err;
			}

		if ($subaction eq 'RC') {
			# clear everything:

			my $curtime = time();

			my ($obj, $p_rhandle, $p_whandle) = ();
			$obj = &LockFile_new(
				'create_if_needed' => 1,
				);
			($err, $p_rhandle, $p_whandle) = $obj->ReadWrite('ads.xml');
			next Err if ($err);
			while (defined($_ = readline($$p_rhandle))) {
				s!start_date\=\"(.*?)\"!start_date\=\"$curtime\"!sg;
				print { $$p_whandle } $_;
				}
			$err = $obj->Merge();
			next Err if ($err);

			unless (opendir(DIR,'.')) {
				$err = &pstr(63,'.',$!);
				next Err;
				}
			foreach (readdir(DIR)) {
				next unless (m!^ads_hitcount_\d+\.txt$!s);
				$err = &WriteFile($_,0);
				next Err if ($err);
				}
			closedir(DIR);
			&ppstr(174,$::str[129]);
			last Err;
			}

		# Load ad info from file:

		my ($place_str, $body_str, @p_Ads) = ('', '');

		my $FileText = '<FDSE:Ads placement=" 2 3 4"></FDSE:Ads>'; # default
		if (-e 'ads.xml') {
			($err, $FileText) = &ReadFile('ads.xml');
			next Err if ($err);
			}
		$FileText =~ s!\015|\012! !sg;

		my $ads_ver = 1;
		if ($FileText =~ m! version=\"(\d+)!s) {
			$ads_ver = $1;
			}

		if ($FileText =~ m!<FDSE:Ads placement="(.*?)"!s) {
			$place_str = $1;
			}
		if ($FileText =~ m!<FDSE:Ads.*?>(.*)</FDSE:Ads>!s) {
			$body_str = $1;
			}

		foreach (split(m!<FDSE:Ad !s, $FileText)) {
			next unless m!(.*?)>(.*)</FDSE:Ad>!s;
			my $strParams = $1;
			my %Params = ();
			if ($ads_ver > 1) {
				$Params{'='} = &Trim(&ud($2));
				}
			else {
				$Params{'='} = &Trim($2);
				}
			while ($strParams =~ m!^\s*(.*?)=\"(.*?)\"(.*)$!s) {
				if ($ads_ver > 1) {
					$Params{&ud($1)} = &ud($2);
					}
				else {
					$Params{$1} = $2;
					}
				$strParams = $3;
				}
			push(@p_Ads, \%Params);
			}



		if ($subaction eq 'save-ads') {
			my $new = qq!<FDSE:Ads placement="$place_str">\015\012!;
			my $record = "\t" . '<FDSE:Ad version="2.0" ident="%d" weight="%d" keywords="%s" start_date="%d" placement="%s" kw="%d">' . "\015\012\t\t" . '%s' . "\015\012\t" . '</FDSE:Ad>' . "\015\012";
			my $i = 1;
			while (defined($::FORM{"weight_$i"})) {
				my $AdText = &Trim($::FORM{"content_$i"});
				if (($AdText) and ($AdText ne $default_text)) {
					my $Advert = $p_Ads[$i - 1];
					my $start_date = time();
					if (($Advert) and ($$Advert{'start_date'})) {
						$start_date = $$Advert{'start_date'};
						}
					my $pos_str = '';
					for (1..4) {
						$pos_str .= " $_" if ($::FORM{"pos:$i:$_"});
						}
					$new .= sprintf( $record, int($i), int($::FORM{"weight_$i"}) || 0, &ue($::FORM{"keywords_$i"}), int($start_date) || 0, &ue($pos_str), int($::FORM{"kw_$i"}) || 0, &ue($AdText) );
					}
				$i++;
				}
			$new .= '</FDSE:Ads>';
			$err = &WriteFile('ads.xml',$new);
			next Err if ($err);
			&ppstr(174,$::str[114]);
			last Err;
			}
		if ($subaction eq 'save-pos') {
			$err = &WriteRule('ui: search form display', 2 * $::FORM{'sfp2'} + $::FORM{'sfp1'} );
			next Err if ($err);
			my $new = '<FDSE:Ads placement="';
			for (1..4) {
				$new .= " $_ " if ($::FORM{"adplace$_"});
				}
			$new .= "\">\015\012";
			$new .= $body_str;
			$new .= '</FDSE:Ads>';
			$err = &WriteFile('ads.xml',$new);
			next Err if ($err);
			&ppstr(174,$::str[114]);
			last Err;
			}









		my %replace = %::const;
		$replace{'total_ads'} = scalar @p_Ads;
		$replace{'total_positions'} = 0;

		my %defaults = ();

		for (1..4) {
			if ($place_str =~ m!$_!s) {
				$defaults{"adplace$_"} = 1;
				$replace{'total_positions'}++;
				}
			}


		my $CurAdsText = '';
		my $demo_ads = '';

		my $OldestTime = 0;
		my $TotalImp = 0;

		my $AdId = 0;
		my $Advert;
		foreach $Advert (@p_Ads) {
			my $AdText = &he($$Advert{'='});

			$AdId++;

			my $imp = 0;
			if (open( FILE, "<ads_hitcount_$AdId.txt" )) {
				$imp = $1 if (<FILE> =~ m!(\d+)!s);
				close(FILE);
				}
			$TotalImp += $imp;

			if ($OldestTime == 0) {
				$OldestTime = $$Advert{'start_date'};
				}
			elsif ($OldestTime > $$Advert{'start_date'}) {
				$OldestTime = $$Advert{'start_date'};
				}

			my $StartDate = &FormatDateTime( $$Advert{'start_date'}, $::Rules{'ui: date format'} );

			my $str_ago = &get_age_str( time() - $$Advert{'start_date'} );
			my $imp_rate = &FormatNumber( (86400 * $imp / ( 1 + time() - $$Advert{'start_date'} ) ), 4, 1, 0, 1, $::Rules{'ui: number format'} );

			my %record_defaults = (
				"keywords_$AdId" => $$Advert{'keywords'} || '',
				"kw_$AdId"    => $$Advert{'kw'} || 0,
				"weight_$AdId"  => $$Advert{'weight'} || 0,
				"content_$AdId" => $$Advert{'='} || '',
				);

			my @ch = ('','','','','');
			for (1..4) {
				$record_defaults{"pos:$AdId:$_"} = (($$Advert{'placement'}) and ($$Advert{'placement'} =~ m!$_!s)) ? 1 : 0;
				}

			my $description = &pstr(101, $imp, $StartDate, $str_ago );
			$description .= "<br />" . &pstr(149, $imp_rate );

			my $show = $$Advert{'='};

			$demo_ads .= <<"EOM";

<table border="1" cellspacing="1" cellpadding="2" width="650">
<tr class="fdblue">
	<td><b>$AdId.</b></td>
</tr>
<tr class="data1">
	<td>$show</td>
</tr>
</table>

<p><br /></p>


EOM

			$CurAdsText .= &SetDefaults(<<"EOM", \%record_defaults);

<table border="1" cellspacing="1" cellpadding="2">
<tr class="fdblue">
	<td><b>$AdId.</b> $description<br />
	$::str[151]: <tt><input name="keywords_$AdId" /></tt>
	$::str[150]: <tt><input name="weight_$AdId" size="4" style="text-align:right" /></tt><br />
	<input type="radio" name="kw_$AdId" value="0" id="kw_0_$AdId" /> <label for="kw_0_$AdId">$::str[370]</label><br />
	<input type="radio" name="kw_$AdId" value="1" id="kw_1_$AdId" /> <label for="kw_1_$AdId">$::str[361]</label><br />
	$::str[363]:
			1.<input type="checkbox" name="pos:$AdId:1" value="1" />
			2.<input type="checkbox" name="pos:$AdId:2" value="1" />
			3.<input type="checkbox" name="pos:$AdId:3" value="1" />
			4.<input type="checkbox" name="pos:$AdId:4" value="1" />
	</td>
</tr>
<tr class="fdblue">
	<td><tt><textarea name="content_$AdId" rows="4" cols="80" style="wrap:soft"></textarea></tt></td>
</tr>
</table>

<p><br /></p>

EOM
		}
	$AdId++;
	my $x3 = 0;
	my $html_default_text = &he($default_text);
	for $x3 ($AdId, ($AdId + 1)) {
		$CurAdsText .= <<"EOM";

<table border="1" cellspacing="1" cellpadding="2">
<tr class="fdblue">
	<td><b>$::str[364]</b><br />
	$::str[151]: <tt><input name="keywords_$x3" /></tt>
	$::str[150]: <tt><input name="weight_$x3" value="100" size="4" style="text-align:right" /></tt><br />
	<input type="radio" name="kw_$x3" value="0" id="kw_0_$x3" checked="checked" /> <label for="kw_0_$x3">$::str[370]</label><br />
	<input type="radio" name="kw_$x3" value="1" id="kw_1_$x3" /> <label for="kw_1_$x3">$::str[361]</label><br />
	$::str[363]:
			1.<input type="checkbox" name="pos:$x3:1" checked="checked" />
			2.<input type="checkbox" name="pos:$x3:2" checked="checked" />
			3.<input type="checkbox" name="pos:$x3:3" checked="checked" />
			4.<input type="checkbox" name="pos:$x3:4" checked="checked" />
	</td>
</tr>
<tr class="fdblue">
	<td><tt><textarea name="content_$x3" rows="4" cols="80" style="wrap:soft">$html_default_text</textarea></tt></td>
</tr>
</table>

<p><br /></p>

EOM
			}
		unless (($replace{'total_ads'}) and ($replace{'total_positions'})) {
			&ppstr(53,$::str[262]);
			}
		elsif ($TotalImp) {
			my $StartDate = &FormatDateTime( $OldestTime, $::Rules{'ui: date format'} );
			my $str_ago = &get_age_str( time() - $OldestTime );
			my $imp_rate = &FormatNumber( ( 86400 * $TotalImp / ( 1 + time() - $OldestTime ) ), 4, 1, 0, 1, $::Rules{'ui: number format'} );
			my $description = &pstr(101, $TotalImp, $StartDate, $str_ago );
			$description .= '<br />' . &pstr(149, $imp_rate );
			print "<p>$description</p>\n";
			}
		$replace{'HTML_BLOCK_1'} = $CurAdsText;
		$replace{'HTML_BLOCK_2'} = $demo_ads;
		$defaults{'sfp1'} = $::Rules{'ui: search form display'} % 2;
		$defaults{'sfp2'} = ($::Rules{'ui: search form display'} < 2) ? 0 : 1;
		my $template = &PrintTemplate( 1, 'admin_ads.txt', $::Rules{'language'}, \%replace );
		print &SetDefaults($template,\%defaults);
		last Err;
		}
	return $err;
	}





sub migrate_log {
#revcompat 0029
	my $err = '';
	Err: {

		print "<p>$::str[103]</p>\n";

		my ($obj, $p_rhandle, $p_whandle) = ();

		$obj = &LockFile_new();
		($err, $p_rhandle, $p_whandle) = $obj->ReadWrite('search.log.txt');
		next Err if ($err);

		my %timecache = ();

		my %Record = ();

		my $i = 1;
		while (defined($_ = readline( $$p_rhandle ))) {

			next if (m!^\r?$!s); # skip blank lines
			if (m!^(\w+)\:\t(.*)$!s) {
				$Record{$1} = $2;

				if ($1 eq 'Found') {
					foreach (keys %Record) {
						$Record{$_} =~ s!\,|\n|\r|\015|\012! !sg;
						$Record{$_} =~ s!\s+! !sg;
						$Record{$_} =~ s!^ !!so;
						$Record{$_} =~ s! $!!so;
						}

					my $time = '';
					if ($Record{'Time'} =~ m!^\s*\w+\s+(\w+)\s+(\d+)\s+(\d+)\:(\d+)\:(\d+)\s+(\d+)\s*$!s) {
						my ($mon_str, $mday, $hh, $mm, $ss, $yyyy) = (lc($1), $2, $3, $4, $5, $6);
						$time = &timelocal($ss,$mm, $hh, $mday, $mon_str, $yyyy, \%timecache);

						#print "Time is $time - $Record{'Time'} - " . scalar localtime($time) . "<br />\n" if ($i < 100);
						}
					else {
						&ppstr(53, &pstr(104, $Record{'Time'} ));
						}

					my $logline = "$Record{'Host'} ,$time,$Record{'Time'},," . &he($Record{'Terms'}) . ",,$Record{'Found'},,\n";

					print { $$p_whandle } $logline;
					$i++;
					if (($i % 500) == 0) {
						&ppstr(105, $i );
						print "<br />\n";
						}
					%Record = ();
					}
				}
			else {
				print { $$p_whandle } $_;
				$i++;
				if (($i % 500) == 0) { &ppstr(105, $i ); print "<br />\n"; }
				}
			}

		$err = $obj->Merge();
		next Err if ($err);

		last Err;
		}
	continue {
		&ppstr(29,$err);
		}
#/revcompat
	}





sub ui_ViewStats {
	local $_;

	my @FieldNames = (
		$::str[125],
		$::str[126],
		$::str[127],
		$::str[128],
		$::str[161],
		$::str[130],
		$::str[131],
		$::str[132],
		$::str[133],
		$::str[134],
		$::str[135],
		$::str[136],
		$::str[137],
		'Interface language',
		);


	my %rev_FieldNames = ();
	my $i = 0;
	foreach (@FieldNames) {
		$rev_FieldNames{$_} = $i;
		$i++;
		}
	my $err = '';
	Err: {

		# either list or group:
		my $subaction = lc($::FORM{'subaction'});


print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ViewLog">$::str[106]</a>
	<span class="gt">&rarr;</span>
EOM

		if ($subaction =~ m!^(dbm|list|group)$!s) {
			my $url = "$::const{'admin_url'}&amp;Action=ViewLog";
			foreach ('subaction','ob','orderby','sort','file') {
				next unless (defined($::FORM{$_}));
				$url .= "&amp;$_=" . &ue($::FORM{$_});
				}
			print qq!<a href="$url">View Log</a></div>\n!;
			}
		else {
			print "$::str[152]</div>\n";
			}


		unless ($subaction) {

print <<"EOM";

			<p><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=list">$::str[110]</a>

EOM

			if ($::private{'is_freeware'}) {
				print '</p>';
				}
			else {


print <<"EOM";

$::str[111]</p>

			<ul>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=value&amp;orderby=5">$::str[112]</a></li>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=value&amp;orderby=9">$::str[134]</a></li>
			</ul>
			<ul>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=value&amp;orderby=1">$::str[126]</a></li>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=key&amp;orderby=7">$::str[115]</a></li>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=key&amp;orderby=6">$::str[131]</a></li>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=value&amp;orderby=4">$::str[161]</a></li>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=value&amp;orderby=13">Interface language</a></li>
			</ul>
			<ul>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=key&amp;orderby=10">$::str[135]</a> $::str[120]</li>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=key&amp;orderby=11">$::str[118]</a> $::str[121]</li>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;ob=key&amp;orderby=12">$::str[119]</a> $::str[121]</li>
			</ul>

EOM

print <<"EOM" if ($::Rules{'use dbm routines'});

<p>Graphs can also be made based on the DBM files:</p>

			<ul>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=dbm&amp;file=dbm_strlog_top">$::str[112]</a> (dbm_strlog_top; top $::Rules{'logging: display most popular'})</li>
				<li><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=dbm&amp;file=dbm_strlog_all">$::str[112]</a> (dbm_strlog_all)</li>
			</ul>


EOM
				}

			print '<hr size="1" />';

			my @settings = ('logging: enable');
			push(@settings, 'logging: display most popular' ) if ($::Rules{'use dbm routines'});

			$err = &ui_GeneralRules( $::str[106], 'ViewLog', @settings );
			next Err if ($err);

			my $csvkb = 0;
			if (-e 'search.log.txt') {
				$csvkb = &FormatNumber( int((1023 + (-s 'search.log.txt')) / 1024), 0, 0, 0, 1, $::Rules{'ui: number format'} );
				}
			my $dbmkb = 0;
			my $basefile;
			foreach $basefile ('dbm_strlog_top','dbm_strlog_top') {
				my $ext;
				foreach $ext ('', '.dir', '.pag', '.db') {
					my $file = $basefile . $ext;
					next unless (-e $file);
					$dbmkb += -s $file;
					}
				}
			$dbmkb = &FormatNumber( int((1023 + $dbmkb) / 1024), 0, 0, 0, 1, $::Rules{'ui: number format'} );

			my $str = &pstr(98, 'Logging: Display Most Popular' );

print <<"EOM";

<hr size="1" />

$::const{'AdminForm'}
<input type="hidden" name="Action" value="ViewLog" />
<input type="hidden" name="subaction" value="delete" />

$str

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th>$::str[430]</th>
	<th>Format</th>
	<th>Log File</th>
	<th>$::str[153]</th>
</tr>
<tr>
	<td align="center"><input type="checkbox" name="del:csv" value="1" /></td>
	<td align="center">CSV</td>
	<td>searchdata/search.log.txt</td>
	<td align="right">$csvkb KB</td>
</tr>
<tr>
	<td align="center"><input type="checkbox" name="del:dbm" value="1" /></td>
	<td align="center">DBM</td>
	<td>searchdata/dbm_strlog *</td>
	<td align="right">$dbmkb KB</td>
</tr>
</table>

<p><input type="submit" class="submit" value="$::str[321]" /></p>

</form>

EOM


			last Err;
			}

		if ($subaction eq 'delete') {
			my $delcount = 0;
			if ($::FORM{'del:csv'}) {
				$err = &WriteFile('search.log.txt','');
				next Err if ($err);
				&ppstr( 174, &pstr( 383, 'search.log.txt' ) );
				$delcount++;
				}
			if ($::FORM{'del:dbm'}) {
				if (not $::Rules{'use dbm routines'}) {
					&pppstr(347, $::str[328] );
					}
				else {
					eval {
						foreach ('dbm_strlog_top','dbm_strlog_all') {
							my %hash = ();
							dbmopen( %hash, $_, 0666 ) || die &pstr( 43, $_, $! );
							%hash = (); # clear
							dbmclose(%hash);
							&ppstr( 174, &pstr( 383, $_ ) );
							}
						};
					if ($@) {
						&ppstr(53, &pstr(20, &he($@), "$::const{'help_file'}1169.html" ) );
						}
					$delcount++;
					}
				}
			unless ($delcount) {
				$err = $::str[354];
				next Err;
				}
			last Err;
			}



		my $focus = lc($::FORM{'focus'});
		$focus = 'id' unless ($focus);
		# name of a field

		my $query = 0;
		if ($::FORM{'orderby'} =~ m!^\d+$!s) {
			$query = $::FORM{'orderby'};
			}


		#change 0049 - queries on string date-time (3) are internally handled as 2, the Unix datetime
		$query = 2 if ($query == 3);



		my $field_name = $FieldNames[$query];
		my $AsciiSort = not ($query =~ m!^(0|2|6|7|8)$!s);

		my %Groups = ();
		my $ptr = 0;


		#DBM-based sorts

		if ($subaction eq 'dbm') {

			unless ($::Rules{'use dbm routines'}) {
				$err = $::str[328];
				next Err;
				}

			unless (defined($::FORM{'file'})) {
				$err = "parameter 'file' missing";
				next Err;
				}
			my $file = $::FORM{'file'};
			unless ($file =~ m!^dbm_strlog_(all|top)$!s) {
				$err = "file must match ^dbm_strlog_(all|top)\$";
				next Err;
				}

			eval {
				my %str = ();
				dbmopen( %str, $file, 0666 ) || die &pstr( 44, $file, $! );
				my $count = 1;

print "<p>This file '$file' was initialized on " . &FormatDateTime( $str{'++'}, $::Rules{'ui: date format'} ) . ".</p>\n" if ($str{'++'});


				my $obkey = (($::FORM{'ob'}) and ($::FORM{'ob'} eq 'key')) ? 1 : 0;
				my $rev = (($::FORM{'sort'}) and ($::FORM{'sort'} eq 'rev')) ? 1 : 0;

				my $nsort = $rev ? 'n' : 'rev';

print <<"EOM";

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2"><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=dbm&amp;file=$file&amp;ob=value&amp;sort=$nsort" class="onblue">Frequency</a></th>
	<th><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=dbm&amp;file=$file&amp;ob=key&amp;sort=$nsort" class="onblue">$::str[112]</a></th>
</tr>

EOM

				my $max_value = $str{'+++'} || 100;
				my $total = 0;

				my $p_raw = sub {
					my ($name, $value, $p_count) = @_;
					my $b_last = 0;
					if ($name !~ m!^\++$!s) {
						$total += $value;
						my $width = 1 + int( 120 * $value / $max_value );
print <<"EOM";

<tr>
	<td align="right"><img src="http://xav.com/i/red.gif" width="$width" height="10" border="1" alt="" /></td>
	<td align="right"><tt>$value</tt></td>
	<td>$name<br /></td>
</tr>

EOM
						$$p_count++;
						if (($file eq 'dbm_strlog_top') and ($$p_count > $::Rules{'logging: display most popular'})) {
							$b_last = 1;
							}
						}
					return $b_last;
					};



				if ($obkey) {
					if ($rev) {
						foreach (sort { $b cmp $a } keys %str) {
							last if &{ $p_raw }( $_, $str{$_}, \$count );
							}
						}
					else {
						foreach (sort { $a cmp $b } keys %str) {
							last if &{ $p_raw }( $_, $str{$_}, \$count );
							}
						}
					}
				else {
					if ($rev) {
						foreach (sort { $str{$a} <=> $str{$b} || $b cmp $a } keys %str) {
							last if &{ $p_raw }( $_, $str{$_}, \$count );
							}
						}
					else {
						foreach (sort { $str{$b} <=> $str{$a} || $a cmp $b } keys %str) {
							last if &{ $p_raw }( $_, $str{$_}, \$count );
							}
						}
					}


print <<"EOM";

</table>

<p>Handled $total total records.</p>

EOM

				};
			if ($@) {
				$err = &pstr(20, &he($@), "$::const{'help_file'}1169.html" );
				next Err;
				}
			}

		else {

			unless (-e 'search.log.txt') {
				$err = &pstr(155,'search.log.txt');
				next Err;
				}

			# Migrate log file format if necessary:

			if (open(LOGFILE, "<search.log.txt" )) {
				binmode(LOGFILE);
				my $buffer = '';
				read(LOGFILE, $buffer, 1024);
				close(LOGFILE);

				if ($buffer =~ m!Time:\t.*?Host:\t.*?Terms:\t.*?Found:\t!is) {

					# yep... we have us a legacy log - convert it real quick...

					&migrate_log('search.log.txt');
					}
				}

			my (@Newtable, @table, @SortField) = ();

			if ($subaction eq 'list') {

				my $focus_term = '';

				unless (open( LOGFILE, "<search.log.txt" )) {
					$err = &pstr(44,'search.log.txt',$!);
					next Err;
					}
				binmode(LOGFILE);
				while (defined($_ = <LOGFILE>)) {
					$ptr++;
					my $full_record = "$ptr,$_";
					push(@table, $full_record);
					$focus_term = (split(m!\,!s, $full_record))[$query];
					push(@SortField, $focus_term);
					}
				close(LOGFILE);

				if ($AsciiSort) {
					@Newtable = @table[sort{ $SortField[$a] cmp $SortField[$b] } 0..$#table];
					}
				else {
					@Newtable = @table[sort{ $SortField[$b] <=> $SortField[$a] } 0..$#table];
					}

				if (($::FORM{'sort'}) and ($::FORM{'sort'} eq 'rev')) {
					@Newtable = reverse @Newtable;
					}

print <<"EOM";

				<p>$::str[122]</p>
				<table border="1" cellspacing="0" cellpadding="3">
				<tr valign="bottom">

EOM
				my $separ = '';
				my $name = ();
				foreach $name ((@FieldNames)[0,1,3..8]) {
					$separ .= "<th>$name</th>\n";
					if (($::FORM{'orderby'} eq $rev_FieldNames{$name}) and (not ($::FORM{'sort'}))) {
						print "<th><a href=\"$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=list&amp;orderby=$rev_FieldNames{$name}&amp;sort=rev\" class=\"onblue\">$name</a></th>";
						}
					else {
						print "<th><a href=\"$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=list&amp;orderby=$rev_FieldNames{$name}\" class=\"onblue\">$name</a></th>";
						}
					}
				print "</tr>\n";

				my $matchcount = 0;
				my $i = 0;
				my @Fields = ();
				foreach (@Newtable) {
					@Fields = split(m!,!s);
					if ($i % 2) {
						print '<tr>';
						}
					else {
						print '<tr class="g">';
						}

					my @diplay_fields = @Fields[0,1,3..8];


					$matchcount += $Fields[7];
					$diplay_fields[7] = &FormatNumber( $diplay_fields[7], 0, 0, 0, 1, $::Rules{'ui: number format'} );


					printf( qq!<td align="right">%s</td><td align="right">%s</td><td align="right" nowrap="nowrap">%s</td><td nowrap="nowrap">%s<br /></td><td>%s<br /></td><td align="right">%s<br /></td><td align="right">%s<br /></td><td align="right">%s<br /></td></tr>\n!, @diplay_fields );

					$i++;
					if (($i % 200) == 0) {
						print "</table>";
						&pppstr(105,$i);
						print qq!<table border="1" cellspacing="0" cellpadding="3"><tr>$separ</tr>\n!;
						}
					}

				print '</table>';
				&pppstr(139, $ptr );
				if ($matchcount) {
					&pppstr(138, &FormatNumber( ($matchcount / $ptr), 2, 1, 0, 1, $::Rules{'ui: number format'} ) );
					}

				}

			elsif ($subaction eq 'group') {

				my $name_align_right = ($AsciiSort) ? 0 : 1;

				unless (open( LOGFILE, "<search.log.txt" )) {
					$err = &pstr(44,'search.log.txt',$!);
					next Err;
					}
				binmode(LOGFILE);
				my $focus_term = '';
				while (defined($_ = <LOGFILE>)) {
					$ptr++;

					my $full_record = "$ptr,$_";


					if (($query > 9) and ($query < 13)) {
						# time-based grouping
						my $unixtime = (split(m!\,!s, $full_record))[2];
						if ($query == 10) {
							# linear day

							my ($mon, $day, $year) = (localtime($unixtime))[4,3,5];
							$year += 1900;
							$mon++;
							$mon = "0$mon" if (length($mon) == 1);
							$day = "0$day" if (length($day) == 1);
							$Groups{"$year/$mon/$day"}++;
							}
						elsif ($query == 11) {
							# hour of day
							my $hour = (localtime($unixtime))[2];
							$Groups{$hour}++;
							}
						elsif ($query == 12) {
							# day of week
							my $wday = (localtime($unixtime))[6];
							$Groups{$wday}++;
							}
						next;
						}

					$focus_term = (split(m!\,!s, $full_record))[$query];
					if ($query == 9) {
						my $Terms = (split(m!\,!s, $full_record))[5];
						foreach (split(m!\s+!s, lc($Terms))) {
							$Groups{$_}++;
							}
						}
					elsif ($query == 13) {
						my $interface_lang = (split(m!\,!s, $full_record))[9];
						$interface_lang =~ s!\r|\n!!sg;
						$Groups{$interface_lang}++;
						}
					else {
						$Groups{lc($focus_term)}++;
						}
					}
				close(LOGFILE);

				if (($query > 9) and ($query < 13)) {
					if ($query == 10) {
						$AsciiSort = 1;
						}
					elsif ($query == 11) {
						$AsciiSort = 0;
						$name_align_right = 1;
						}
					elsif ($query == 12) {
						$AsciiSort = 0;
						$name_align_right = 0;
						}
					}


print <<"EOM";

				<p>$::str[122]</p>
				<table border="1" cellspacing="0" cellpadding="3">
				<tr valign="bottom">

EOM

				print qq!<th colspan="2"><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;orderby=$::FORM{'orderby'}&amp;ob=value!;

				if (($::FORM{'ob'} eq 'value') and (!$::FORM{'sort'})) {
					print '&amp;sort=rev';
					}

				print qq!" class="onblue">$::str[140]</a></th><th><a href="$::const{'admin_url'}&amp;Action=ViewLog&amp;subaction=group&amp;orderby=$::FORM{'orderby'}&amp;ob=key!;

				if (($::FORM{'ob'} eq 'key') and (!$::FORM{'sort'})) {
					print "&amp;sort=rev";
					}
				print qq!" class="onblue">$FieldNames[$query]</a></th></tr>\n!;


				my $by_value = (($::FORM{'ob'}) and ($::FORM{'ob'} eq 'value'));
				my $ascending = (($::FORM{'sort'}) and ($::FORM{'sort'} eq 'rev'));

				$err = &PrintOrderedHash( \%Groups, $by_value, $AsciiSort, $ascending, $query, $name_align_right );
				next Err if ($err);

				print '</table>';
				&pppstr(139, $ptr );
				}
			}
		last Err;
		}
	continue {
		&ppstr(29,$err);
		}
	}





sub PrintOrderedHash {
	my ($p_hash, $by_value, $ascii_sort, $ascending, $date_map, $name_align_right) = @_;
	my $err = '';

	my $max_value = 1;
	my ($name, $value) = ();
	while (($name, $value) = each %$p_hash) {
		$max_value = $value if ($value > $max_value);
		}


	my $template1 = '<tr><td align="right"><img src="http://xav.com/i/red.gif" height="10" width="$width" alt="" border="1" /></td><td align="right">&nbsp;$value&nbsp;</td><td>$name<br /></td></tr>\n';
	if ($name_align_right) {
		$template1 = '<tr><td align="right"><img src="http://xav.com/i/red.gif" height="10" width="$width" alt="" border="1" /></td><td align="right">&nbsp;$value&nbsp;</td><td align="right">$name<br /></td></tr>\n';
		}
	my $template2 = '<tr class="g"><td align="right"><img src="http://xav.com/i/red.gif" height="10" width="$width" alt="" border="1" /></td><td align="right">&nbsp;$value&nbsp;</td><td>$name<br /></td></tr>\n';
	if ($name_align_right) {
		$template2 = '<tr class="g"><td align="right"><img src="http://xav.com/i/red.gif" height="10" width="$width" alt="" border="1" /></td><td align="right">&nbsp;$value&nbsp;</td><td align="right">$name<br /></td></tr>\n';
		}

	my $descriptor = '';
	if ($ascending) {
		$descriptor .= 'reverse ';
		}

	my $comp_op = "<=>";
	if ($ascii_sort) {
		$comp_op = "cmp";
		}

	if ($by_value) {
		$descriptor .= 'sort {$$p_hash{$b} <=> $$p_hash{$a} || $a ' . $comp_op . ' $b} keys %$p_hash';
		}
	else {
		$descriptor .= 'sort {$a ' . $comp_op . ' $b} keys %$p_hash';
		}

	# Initialize all fields for the cyclic date hashes:
	if ($date_map == 12) {
		foreach (0..6) {
			$$p_hash{$_} = 0 unless ($$p_hash{$_});
			}
		}
	elsif ($date_map == 11) {
		foreach (0..23) {
			$$p_hash{$_} = 0 unless ($$p_hash{$_});
			}
		}

	my @Weekdays = (
		$::str[25],
		$::str[24],
		$::str[28],
		$::str[7],
		$::str[6],
		$::str[5],
		$::str[22],
		);


	my @HourNames = ('midnight', '1:00 AM', '2:00 AM', '3:00 AM', '4:00 AM', '5:00 AM', '6:00 AM', '7:00 AM', '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', 'noon', '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM', '7:00 PM', '8:00 PM', '9:00 PM', '10:00 PM', '11:00 PM');

	if ($date_map !~ m!^\d+!s) {
		$date_map = 0;
		}

	my $code = <<"EOM";

my \$i = 0;
foreach ($descriptor) {
	my (\$name, \$value) = (\$_, \$\$p_hash{\$_});

	if (\$date_map == 12) {
		\$name = \$Weekdays[\$name];
		}
	elsif (\$date_map == 11) {
		\$name = \$HourNames[\$name];
		}

	my \$width = 1 + int((120 * \$value) / \$max_value);
	if (\$i % 2) {
		print qq!$template1!;
		}
	else {
		print qq!$template2!;
		}
	\$i++;
	}

EOM
	eval $code;
	die $@ if $@;
	return $err;
	}



sub is_valid_filename {
	my ($file) = @_;
	my $err = '';
	Err: {

		# make sure it only contains \w characters and '.'
		my $filechars = $file;
		$filechars =~ s!\w!!sg; # strip all alphanumerics and _
		$filechars =~ s!\.!!so; # strip up to one '.'
		if ($filechars) { # uh-oh - other characters remain
			$err = &pstr(54, &he($file), 'invalid characters' );
			next Err;
			}
		}
	return $err;
	}





sub delete_index_file {
	my ($file) = @_;
	my $hfile = &he($file);
	my $err = '';
	Err: {

		$err = &is_valid_filename($file);
		next Err if ($err);

		# Delete the file and any associated files, if they exist. Continue on failure.

		&untaintme(\$file);

		local $_;
		foreach ('', '.working_copy', '.exclusive_lock_request', '.need_approval', '.pagecount', '.temp_file_list.txt') {
			next unless (-e "$file$_");
			unless (unlink("$file$_")) {
				&ppstr(29, &pstr(54, "$hfile$_", $! ) );
				}
			else {
				&ppstr(174, &pstr(383, "$hfile$_" ) );
				}
			}
		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	}





sub ui_ManageRealms {
	my $err = '';
	Err: {

		my $is_update = 0;
		if ((exists $::FORM{'is_update'}) and ($::FORM{'is_update'})) {
			$is_update = 1;
			}

		my ($file, $base_dir, $base_url, $limit_pattern) = ();

		# so... what's the plan?

		my $subaction = '';
		if ($::FORM{'Delete'}) {
			$subaction = 'DeleteRealm';
			}
		elsif ($::FORM{'subaction'}) {
			$subaction = $::FORM{'subaction'};
			}


		my $Name = '';

		if (($subaction eq 'Edit') and (not $::FORM{'Write'}) and (not defined($::FORM{'is_update'}))) {

			# We need to load defaults:

			$is_update = 1;

			$::FORM{'is_update'} = 1;
			$Name = $::FORM{'Realm'};

			$::FORM{'orig_name'} = $Name;

			my $p_realm_data = ();
			($err, $p_realm_data) = $::realms->hashref( $Name );
			next Err if ($err);

			($file, $base_dir, $base_url) = ($$p_realm_data{'file'}, $$p_realm_data{'base_dir'}, $$p_realm_data{'base_url'});

			$::FORM{'is_runtime'} = $$p_realm_data{'is_runtime'};
			$::FORM{'type'} = $$p_realm_data{'type'};

			if ($$p_realm_data{'is_filefed'}) {
				$::FORM{'is_filefed'} = 1;
				$::FORM{'start_url'} = $$p_realm_data{'base_url'};
				}

			if ($$p_realm_data{'type'} > 3) {
				$::FORM{'is_local'} = 1;
				}
			if ($$p_realm_data{'type'} > 2) {
				$::FORM{'is_website'} = 1;
				}
			$limit_pattern = $$p_realm_data{'limit_pattern'};
			}


		if (($subaction eq 'Create') and (not defined($::FORM{'is_update'}))) {

			$::FORM{'is_update'} = 0;
			my ($temp_err,$clean, $host, $port) = &uri_parse(&get_absolute_url());
			if (not $temp_err) {
				$base_url = 'http://' . $host . (($port == 80) ? '' : ":$port");
				}

			}

		if ($subaction eq 'Create') {
			# What is my local path?
			$base_dir = $base_dir || &api_get_webroot(0);
			}



		# Admin banner:
		print qq!<div class="breadcrumbs"><a href="$::const{'admin_url'}">$::str[96]</a> <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a> <span class="gt">&rarr;</span> !;

		if ($subaction eq 'DeleteRealm') {
			print $::str[430];
			}
		elsif ($subaction eq 'Create') {
			print qq!<a href="$::const{'admin_url'}&amp;Action=ManageRealms&amp;subaction=Create">$::str[94]</a>!;
			}
		elsif ($subaction eq 'Edit') {
			print $::str[368];
			}
		else {
			print $::str[152];
			}
		print "</div>\n";

		if ($subaction eq 'DeleteRealm') {

			my $p_realm_data = ();
			($err, $p_realm_data) = $::realms->hashref($::FORM{'Delete'} );
			next Err if ($err);

			my $realm_id = $$p_realm_data{'realm_id'};

			my $realm_name = $$p_realm_data{'name'};#keep - we won't be able to query p_realm_data later!

			my $index_file = $$p_realm_data{'file'};

			$::realms->remove( $$p_realm_data{'name'}, 1 );
			$err = $::realms->save_realm_data();
			next Err if ($err);

			# Deal with the remaining data:

			&ppstr(174, $::str[177] );

			my $delcount = 0;
			($err, $delcount) = &DeleteFromPending( $realm_name );
			next Err if ($err);

			&ppstr(174, &pstr(178,$delcount,'search.pending.txt'));

			# Deal with file data:

			if ($::Rules{'delete index file with realm'}) {
				&delete_index_file( $index_file );
				}
			else {

				if (($index_file) and (-e $index_file)) {
					&pppstr(176, $index_file, int((1023 + (-s $index_file))/1024) );


# is this a valid file name, according to our check in DelFile? only offer to delete the file if the check will pass:

					# make sure it only contains \w characters and '.'
					my $filechars = $index_file;
					$filechars =~ s!\w!!sg; # strip all alphanumerics and _
					$filechars =~ s!\.!!so; # strip up to one '.'

					if ($filechars) { # uh-oh - other characters remain

						# no offer to delete

						}
					else {


print <<"EOM";

$::const{'AdminForm'}
<input type="hidden" name="Action" value="ManageRealms" />
<input type="hidden" name="subaction" value="DelFile" />
<input type="hidden" name="File" value="$index_file" />

<blockquote>
	<p><input type="submit" class="submit" value="$::str[382]" /></p>
	<p><input type="checkbox" name="ad" value="1" /> $::str[331]</p>
</blockquote>
</form>

EOM
						}
					}



				}

			last Err;
			}
		elsif ($subaction eq 'DelFile') {
			&delete_index_file( $::FORM{'File'} );
			if ($::FORM{'ad'}) {
				$err = &WriteRule('delete index file with realm',1);
				next Err if ($err);
				&ppstr(174,&pstr(404,'delete index file with realm',1));
				}
			last Err;
			}
		elsif (($subaction eq 'Create') or ($subaction eq 'Edit')) {

			if ($::private{'is_freeware'}) {
				if ($subaction eq 'Create') {
					if ($::realms->realm_count('all')) {
						$err = "only one realm is allowed in Freeware mode";
						next Err;
						}
					}
				}



			my ($defname, $deffile) = $::realms->get_default_name();
			unless ($file) {
				$file = $deffile;
				}
			unless ($Name) {
				$Name = $defname;
				}


			unless ($::FORM{'type'}) {
				# default realm type:
				$::FORM{'type'} = $::Rules{'use socket routines'} ? 3 : 4;
				}

			$base_url = 'http://' unless ($base_url);
			$base_url = 'http://' if ($::FORM{'type'} == 6);

			my %defaults = (
				'type' => $::FORM{'type'},
				'name' => $Name,
				'is_update' => $::FORM{'is_update'},
				'is_website' => 0,
				'is_filefed' => 0,
				'is_local'  => 0,
				'is_runtime' => 0,
				'file'    => $file,

				'base_url2' => $base_url,
				'base_url3' => $base_url,
				'base_url4' => $base_url,
				'base_url5' => $base_url,

				'base_dir4' => $base_dir,
				'base_dir5' => $base_dir,
				'limit_pattern' => $limit_pattern,
				);

			my $table_header = $is_update ? $::str[368] : $::str[94];
			my $submit_button = $is_update ? $::str[362] : $::str[94];

			my $h_orig_name = &he( $::FORM{'orig_name'} );


			my $b_allow_filtered_realms = (($::Rules{'show advanced commands'}) or ($defaults{'type'} == 6));


unless ($::FORM{'Write'}) {


			# prevent people from switching to/from runtime type of realm
			my $b_only_runtime = 0;
			my $b_no_runtime = 0;
			if ($is_update) {
				if ($::FORM{'type'} == 5) {
					$b_only_runtime = 1;
					}
				else {
					$b_no_runtime = 1;
					}

				if (($::FORM{'type'} != 4) and ($::FORM{'type'} != 5) and (not $::Rules{'use socket routines'})) {
					# special case -- user has disabled sockets, but they are editing an existing realm that
					# depends on sockets.  Make sure that all realm types are present
					$::Rules{'use socket routines'} = 1;
					}

				}





print &SetDefaults(<<"EOM", \%defaults);

$::const{'AdminForm'}
<input type="hidden" name="is_update" value="$is_update" />
<input type="hidden" name="Action" value="ManageRealms" />
<input type="hidden" name="subaction" value="$::FORM{'subaction'}" />
<input type="hidden" name="Write" value="1" />
<input type="hidden" name="orig_name" value="$h_orig_name" />

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2">$table_header</th>
</tr>
<tr class="fdtan">
	<td align="right" width="120"><b>$::str[428]:</b></td>
	<td><tt><input name="name" /></tt></td>
</tr>
<tr class="fdtan">
	<td align="right" width="120"><b>$::str[369]:</b></td>
	<td><tt><input name="file" /></tt></td>
</tr>
</table>

<p>$::str[367]</p>

<table border="1" cellpadding="4" cellspacing="1" width="50%">

EOM

# open realms:
print &SetDefaults(<<"EOM", \%defaults) if ((not $::private{'is_freeware'}) and (not $b_only_runtime) and ($::Rules{'use socket routines'}));

<tr>
	<th colspan="3" align="left"><label for="type_1">$::str[431]</label></th>
</tr>
<tr class="fdtan" valign="top">
	<td><input type="radio" name="type" value="1" id="type_1" /></td>
	<td colspan="2">$::str[475]</td>
</tr>

EOM

# filtered realms:
print &SetDefaults(<<"EOM", \%defaults) if ((not $::private{'is_freeware'}) and ($b_allow_filtered_realms) and (not $b_only_runtime) and ($::Rules{'use socket routines'}));

<tr>
	<th colspan="3" align="left"><label for="type_6">$::str[268]</label></th>
</tr>
<tr class="fdtan" valign="top">
	<td><input type="radio" name="type" value="6" id="type_6" /></td>
	<td colspan="2">$::str[314]</td>
</tr>


EOM

my $limit_pattern_visible = <<"EOM";

<tr class="fdtan">
	<td align="right" width="120"><b>Pattern:</b></td>
	<td><tt><input name="limit_pattern" size="60" /></tt></td>
</tr>

EOM
my $limit_pattern_hidden = qq!<input type="hidden" name="limit_pattern" />!;
my $website_realm_rows = 2;
if ($::Rules{'show advanced commands'}) {
	$limit_pattern_hidden = '';
	$website_realm_rows++;
	}
else {
	$limit_pattern_visible = '';
	}

# file-fed realms and website realms (crawler):
print &SetDefaults(<<"EOM", \%defaults) if ((not $b_only_runtime) and ($::Rules{'use socket routines'}));

<tr>
	<th colspan="3" align="left"><label for="type_2">$::str[489]</label></th>
</tr>
<tr class="fdtan" valign="top">
	<td rowspan="2"><input type="radio" name="type" value="2" id="type_2" /></td>
	<td colspan="2">$::str[208]</td>
</tr>
<tr class="fdtan">
	<td align="right" width="120" nowrap="nowrap"><b>$::str[166]:</b></td>
	<td><tt><input name="base_url2" size="60" /></tt></td>
</tr>

<tr>
	<th colspan="3" align="left"><label for="type_3">$::str[365]</label></th>
</tr>
<tr class="fdtan" valign="top">
	<td rowspan="$website_realm_rows"><input type="radio" name="type" value="3" id="type_3" /></td>
	<td colspan="2">$::str[471]</td>
</tr>
<tr class="fdtan">
	<td align="right" width="120"><b>$::str[166]:</b></td>
	<td><tt><input name="base_url3" size="60" />$limit_pattern_hidden</tt></td>
</tr>
$limit_pattern_visible

EOM

# website realms (file system):
print &SetDefaults(<<"EOM", \%defaults) if (not $b_only_runtime);

<tr>
	<th colspan="3" align="left"><label for="type_4">$::str[366]</label></th>
</tr>
<tr class="fdtan" valign="top">
	<td rowspan="3"><input type="radio" name="type" value="4" id="type_4" /></td>
	<td colspan="2">$::str[471]</td>
</tr>
<tr class="fdtan">
	<td align="right" width="120"><b>$::str[166]:</b></td>
	<td><tt><input name="base_url4" size="60" /></tt></td>
</tr>
<tr class="fdtan">
	<td align="right" width="120"><b>$::str[399]:</b></td>
	<td><tt><input name="base_dir4" size="60" /></tt></td>
</tr>

EOM

# runtime realms:
print &SetDefaults(<<"EOM", \%defaults) unless ($b_no_runtime);

<tr>
	<th colspan="3" align="left"><label for="type_5">$::str[339]</label></th>
</tr>
<tr class="fdtan" valign="top">
	<td rowspan="3"><input type="radio" name="type" value="5" id="type_5" /></td>
	<td colspan="2">$::str[212]</td>
</tr>
<tr class="fdtan">
	<td align="right" width="120"><b>$::str[166]:</b></td>
	<td><tt><input name="base_url5" size="60" /></tt></td>
</tr>
<tr class="fdtan">
	<td align="right" width="120"><b>$::str[399]:</b></td>
	<td><tt><input name="base_dir5" size="60" /></tt></td>
</tr>

EOM
print &SetDefaults(<<"EOM", \%defaults);

</table>

<blockquote>
	<p><input type="submit" class="submit" value="$submit_button" /></p>
</blockquote>

</form>

EOM
				}

			if ($::FORM{'Write'}) {

				my ($base_url, $base_dir) = ('', '');

				my $Name = $::FORM{'name'};
				if ($Name =~ m!^(all|include-by-name)$!is) {
					$err = &pstr(441,$Name);
					next Err;
					}

				my $File = $::FORM{'file'};

				my $type = $::FORM{'type'};
				my ($is_runtime, $is_filefed) = (0, 0);

				if ($type == 6) {
					$base_url = 'http://filtered:1/';
					}
				elsif ($type == 5) {
					$is_runtime = 1;
					$File = 'RUNTIME';
					$base_url = $::FORM{'base_url5'};
					$base_dir = $::FORM{'base_dir5'};
					}
				elsif ($type == 4) {
					# oka
					$base_url = $::FORM{'base_url4'};
					$base_dir = $::FORM{'base_dir4'};
					}
				elsif ($type == 3) {
					$base_url = $::FORM{'base_url3'};
					}
				elsif ($type == 2) {
					$is_filefed = 1;
					$base_url = $::FORM{'base_url2'};
					}
				elsif ($type == 1) {
					# cool
					}
				else {
					$err = "invalid type - $type";
					next Err;
					}

				if (($type > 3) and ($::private{'is_demo'})) {
					$err = $::str[435];
					next Err;
					}

				#changed 0035 - this occurs when somebody chooses "Edit" a RUNTIME realm and they toggle the
				# radio buttons to change type, but don't type in a new filename. Also if somebody
				# enters the otherwise reserved word "runtime" we should point them in a different direction
				if ((uc($File) eq 'RUNTIME') and ($type != 5)) {
					my ($defname, $deffile) = $::realms->get_default_name();
					$File = $deffile;
					}


				unless ($Name) {
					$err = &pstr(21, $::str[428] );
					next Err;
					}
				unless ($File) {
					$err = &pstr(21, $::str[369] );
					next Err;
					}

				# use all forward slashes:
				$base_dir =~ s!\\!/!sg;

				if ($type != 1) {
					($err, $base_url) = &uri_parse($base_url);
					next Err if ($err);
					}

				# do not allow delimiters within the values:
				for ($Name, $File, $base_dir, $base_url) {
					if (m!(\r|\n|\||\012|\015)!s) {
						my $bad = &he($1);
						$err = &pstr(75,&he($_),$bad);
						next Err;
						}
					}

				#0054: -T compat
				if ($File =~ m!\.\.!s) {
					$err = "realm file name cannot contain '..' substring";
					next Err;
					}
				&untaintme( \$File );
				&untaintme( \$base_dir );

				if (($type == 4) or ($type == 5)) {
					unless (opendir(DIR, $base_dir)) {
						$err = &pstr(63, &he($base_dir), $! );
						next Err;
						}
					closedir(DIR);
					}

				unless ($is_runtime) {

					# don't bother with LockFile here, because index file is not yet being hammered by multiple processes:
					if (open( FILE, ">>$File" )) {
						close(FILE);
						chmod($::private{'file_mask'},$File);
						}
					else {
						$err = &pstr(42, &he($File), $! );
						next Err;
						}
					}

				if ($::FORM{'limit_pattern'}) {
					$err = &check_regex($::FORM{'limit_pattern'});
					next Err if ($err);
					}


				my $realm_id = 0;
				my $page_count = 0;

				my $p_realm_data = ();

				# Is this really an update operation? If so, retain the 'realm_id' - that's kinda important:
				if ($is_update) {
					($err, $p_realm_data) = $::realms->hashref( $::FORM{'orig_name'} );
					unless ($err) {
						$realm_id = $$p_realm_data{'realm_id'};
						$page_count = $$p_realm_data{'pagecount'};
						}
					else {
						$err = ''; # clear
						}
					}

				if ($::FORM{'orig_name'}) {
					$::realms->remove( $::FORM{'orig_name'}, 0 );
					}

				$::realms->remove( $Name, 0 );
				$::realms->add( $realm_id, $Name, $::Rules{'sql: enable'}, $File, $is_runtime, $base_dir, $base_url, '', $page_count, $is_filefed, $type, ($::FORM{'limit_pattern'} || '') );
				$err = $::realms->save_realm_data();
				next Err if ($err);

				($err, $p_realm_data) = $::realms->hashref($Name);
				next Err if ($err);

				#changed 0050 update realm-specific filter rules on a rename op:
				if (($is_update) and ($::FORM{'orig_name'} ne $Name)) {
					my $url_orig = &ue($::FORM{'orig_name'});
					my $is_changed = 0;
					my $fr = &fdse_filter_rules_new();
					my $p_fr = ();
					foreach $p_fr ($fr->list_filter_rules()) {
						next unless ($$p_fr{'apply_to'} == 3); # only realm-specific rules
						$is_changed += scalar ($$p_fr{'apply_to_str'} =~ s!(^|,)$url_orig($|,)!$1$$p_realm_data{'url_name'}$2!sg);
						}
					if ($is_changed) {
						$err = $fr->frwrite();
						next Err if ($err);
						}
					}

				if ($is_update) {
					&ppstr(174, $::str[114] );
					}
				else {
					&ppstr(174, &pstr(372, &he($Name) ) );
					}


				Pending: {

				# update the pending pages file because we may have just added or removed a non-empty index file, and we need to
				# sync the contents of pending.txt with that data

				# we may have renamed a realm, and we need to sync the realm name


					last Pending if ($File eq 'RUNTIME');

					my @NewRecords = ();
					my $new_record_count = 0;

					my $url_realm = &ue( $Name );
					my $Time = $::private{'script_start_time'};
					last Pending unless (open( FILE, "<$File" ));
					binmode(FILE);
					while (defined($_ = <FILE>)) {
						next unless (m! u= (.*?) t=!s);
						push(@NewRecords, "$1 $url_realm $Time\n");
						}
					close(FILE);
					$new_record_count = 1 + $#NewRecords;
					if ($new_record_count) {
						&pppstr(373, $new_record_count, $File );
						}

					my $obj = &LockFile_new(
						'create_if_needed' => 1,
						);

					my ($p_rhandle, $p_whandle);

					($err, $p_rhandle) = $obj->Read('search.pending.txt');
					next Err if ($err);

					my @OldRecords = ();

					# This is horribly innefficient code and must be optimized

					# Read in all of the entries except those tied to name or orig_name
					my $exclude = '';
					if (($::FORM{'orig_name'}) and ($::FORM{'orig_name'} ne $Name)) {
						$exclude = '(' . quotemeta( $::FORM{'orig_name'} ) . '|' . quotemeta( $Name ) . ')';
						}
					else {
						$exclude = quotemeta($Name);
						}
					while (defined($_ = readline($$p_rhandle))) {
						next if (m! $exclude !s);
						push(@OldRecords, $_);
						}
					$err = $obj->Close();
					next Err if ($err);

					undef($obj);

					$obj = &LockFile_new(
						'create_if_needed' => 1,
						);
					($err, $p_rhandle, $p_whandle) = $obj->ReadWrite('search.pending.txt');
					next Err if ($err);

					my ($Current, $Previous) = ('', '');
					my ($CurrentNum, $PreviousNum) = (0, 0);
					foreach (sort (@OldRecords, @NewRecords)) {
						next unless m!^(.*?) (.*?) (\d+)$!s;
						$Current = "$1 $2";
						$CurrentNum = $3;
						if ($Current ne $Previous) {
							my $data = "$Current ";
							$data .= (($CurrentNum > $PreviousNum) ? $CurrentNum : $PreviousNum);
							$data .= "\n";
							print { $$p_whandle } $data;
							}
						$Previous = $Current;
						$PreviousNum = $CurrentNum;
						}
					$err = $obj->Merge();
					next Err if ($err);

					$::realms->setpagecount($Name, $new_record_count, 1);
					if ($new_record_count) {
						&ppstr(174, &pstr(179, $new_record_count,'search.pending.txt'));
						}
					}

				# offer "Click to rebuild":
				if (($$p_realm_data{'type'} != 5) and ($$p_realm_data{'has_base_url'})) {
					&pppstr(330, "$::const{'admin_url'}&amp;Action=rebuild&amp;Realm=$$p_realm_data{'url_name'}");
					}

				if ($$p_realm_data{'type'} == 6) {
					# Filtered Realm
					# create a realm-specific Filter Rule, if none exist
					# link to the realm-specific Filter Rule

					my $fname = "$$p_realm_data{'name'} - limit";

					my $b_has_rule = 0;

					my $fr = &fdse_filter_rules_new();
					my $p_data = ();
					foreach $p_data ($fr->list_filter_rules()) {
						if ($fname eq $$p_data{'name'}) {
							$b_has_rule = 1;
							last;
							}
						}

					unless ($b_has_rule) {
						my @limits = ();
						$err = $fr->add_filter_rule(
							0,
							$fname,
							1,
							5,
							1,
							1,
							1,
							3,
							$$p_realm_data{'url_name'} . ',',
							\@limits,
							\@limits,
							);
						next Err if ($err);
						}


					my ($ufname, $hfname) = (&ue($fname), &he($fname));
					print qq!<p>This <b>Filtered Realm</b> must be restricted by filter rules to prevent it from indexing the entire web.</p>
					<p>The rule <a href="$::const{'admin_url'}&amp;Action=FilterRules&amp;subaction=create_edit_rule&amp;name=$ufname">$hfname</a> has
					been created as a sample rule to get you started.</p><p>That filter rule is disabled by default. Before enabling it, you
					must enter some strings or patterns to describe the type of URL's that you would like to include in this realm.</p>\n!;


					}

				last Err;
				}
			last Err;
			}

		print <<"EOM";

	<p><b>$::str[327]</b></p>
	<ul>
		<li><p><a href="$::const{'admin_url'}&amp;Action=ManageRealms&amp;subaction=Create">$::str[94]</a></p></li>
		<li><p><a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a></p></li>
		<li><p><a href="$::const{'admin_url'}&amp;Action=DeleteRecord">$::str[95]</a></p></li>
	</ul>
	<p><br /></p>

EOM


		my $p_realm_data = ();

		my (@filefed, @open_realms, @filtered_realms, @website_realms, @runtime_realms) = ();

		my @realms = ();

		@realms = $::realms->listrealms('all');
		foreach $p_realm_data (@realms) {
			if ($$p_realm_data{'is_filefed'}) {
				push(@filefed, $p_realm_data);
				}
			elsif ($$p_realm_data{'type'} == 1) {
				push(@open_realms, $p_realm_data);
				}
			elsif ($$p_realm_data{'type'} == 6) {
				push(@filtered_realms, $p_realm_data);
				}
			elsif ($$p_realm_data{'is_runtime'}) {
				push(@runtime_realms, $p_realm_data);
				}
			else {
				push(@website_realms, $p_realm_data);
				}
			}

		@realms = $::realms->listrealms('is_error');
		if (@realms) {
			&ppstr(29, $::str[180] );
			foreach $p_realm_data (@realms) {
				print "<p><b>$$p_realm_data{'html_name'}</b> - $$p_realm_data{'err'}.</p><p>";
				&ppstr(182, "<a href=\"$::const{'admin_url'}&amp;Action=ManageRealms&amp;Realm=$$p_realm_data{'url_name'}\">$::str[411]</a>", "<a href=\"$::const{'admin_url'}&amp;Action=ManageRealms&amp;Delete=$$p_realm_data{'url_name'}\" onclick=\"return confirm('$::str[108]');\">$::str[430]</a>" );
				print "</p>\n";
				}
			}

		if (@open_realms) {

			my $n_actions = 2;
			$n_actions++ if ($::realms->{'need_approval'});

			my $suggest_rules = &pstr(107, "<a href=\"$::const{'admin_url'}&amp;Action=FilterRules\">$::str[162]</a>" );

print <<"EOM";

<p><b>$::str[431]</b></p>

<p>$::str[475]</p>
<p>$suggest_rules</p>

EOM
			print '<table border="1" cellpadding="4" cellspacing="1">';
			&print_realm_table_header();
			foreach $p_realm_data (@open_realms) {
				next if ($$p_realm_data{'is_error'});
				&print_realm_table_row($p_realm_data);
				}
			print '</table><p><br /></p>';
			}



		if (@filtered_realms) {

			my $n_actions = 2;
			$n_actions++ if ($::realms->{'need_approval'});

print <<"EOM";

<p><b>$::str[268]</b></p>

<p>$::str[314]</p>

EOM
			print '<table border="1" cellpadding="4" cellspacing="1">';
			&print_realm_table_header();
			foreach $p_realm_data (@filtered_realms) {
				next if ($$p_realm_data{'is_error'});
				&print_realm_table_row($p_realm_data);
				}
			print '</table><p><br /></p>';
			}







		if (@website_realms) {

print <<"EOM";

<p><b>$::str[474]</b></p>

<p>$::str[471]</p>

EOM
			print '<table border="1" cellpadding="4" cellspacing="1">';
			&print_realm_table_header();
			foreach $p_realm_data (@website_realms) {
				next if ($$p_realm_data{'is_error'});
				&print_realm_table_row($p_realm_data);
				}
			print '</table><p><br /></p>';
			}

		if (@runtime_realms) {

print <<"EOM";

<p><b>$::str[339]</b></p>

<p>$::str[212]</p>

EOM
			print '<table border="1" cellpadding="4" cellspacing="1">';
			&print_realm_table_header();
			foreach $p_realm_data (@runtime_realms) {
				next if ($$p_realm_data{'is_error'});
				&print_realm_table_row($p_realm_data);
				}
			print '</table><p><br /></p>';
			}


		if (@filefed) {

print <<"EOM";

<p><b>$::str[489]</b></p>

<p>$::str[208]</p>

EOM
			print '<table border="1" cellpadding="4" cellspacing="1">';
			&print_realm_table_header();
			foreach $p_realm_data (@filefed) {
				next if ($$p_realm_data{'is_error'});
				&print_realm_table_row($p_realm_data);
				}
			print '</table><p><br /></p>';
			}

		$err = &ui_GeneralRules( $::str[327], 'ManageRealms', 'show advanced commands', 'delete index file with realm' );
		next Err if ($err);
		last Err;
		}
	return $err;
	}





sub print_realm_table_header {
	my ($name) = @_;
	print "<tr><th>$::str[190]</th><th width=\"240\">";
	print defined($name) ? $name : $::str[428];
	print '</th>';

print <<"EOM";

	<th>$::str[153]</th>
	<th>$::str[156]</th>
	<th>$::str[113]</th>
	<th>$::str[146]</th>
</tr>

EOM

	}





sub print_realm_table_row {
	my ($p_realm_data) = @_;
	my $index_size_bytes = 0;
	my $pages = '<center>-</center>';
	my $size = '<center>-</center>';
	my $lastmodtime = '-';
	if ($$p_realm_data{'has_file'}) {
		$index_size_bytes = -s $$p_realm_data{'file'};
		$size = &FormatNumber( (1023 + $index_size_bytes) / 1024, 0, 1, 0, 1, $::Rules{'ui: number format'} );
		my $lastmodt = (stat($$p_realm_data{'file'}))[9];
		$lastmodtime = &FormatDateTime( $lastmodt, $::Rules{'ui: date format'} );
		$lastmodtime .= '<br />' . &get_age_str( time() - $lastmodt );
		}
	unless ($$p_realm_data{'is_runtime'}) {
		$pages = &FormatNumber( $$p_realm_data{'pagecount'}, 0, 1, 0, 1, $::Rules{'ui: number format'} );
		}


	my $h_base_url = (($$p_realm_data{'type'} == 1) or ($$p_realm_data{'type'} == 6)) ? '-' : $$p_realm_data{'base_url'};
	#changed 0054 - substr to 65 chars
	if (64 < length($h_base_url)) {
		$h_base_url = substr($h_base_url,0,64) . '...';
		}
	$h_base_url = &he($h_base_url);

	#changed 0056 - substr to 65 chars for name as well
	my $hname = $$p_realm_data{'html_name'};
	if (64 < length($$p_realm_data{'name'})) {
		$hname = &he( substr($$p_realm_data{'name'},0,64) . '...' );
		}




print <<"EOM";

<tr class="fdtan">
	<td align="center"><a href="$::const{'admin_url'}&amp;Action=ManageRealms&amp;subaction=Edit&amp;Realm=$$p_realm_data{'url_name'}" class="onbrown">$::str[411]</a></td>
	<td rowspan="2" nowrap="nowrap">
		<b>$hname</b><br />$h_base_url</td>

EOM

print <<"EOM";
	<td align="right" rowspan="2" nowrap="nowrap">$size KB</td>
	<td align="right" rowspan="2">$pages</td>
	<td align="center" rowspan="2">$lastmodtime</td>
EOM


print <<"EOM";

	<td nowrap="nowrap">
		<a href="$::const{'admin_url'}&amp;Action=Review&amp;Realm=$$p_realm_data{'url_name'}" class="onbrown">$::str[154]</a>

EOM

print <<"EOM" if ($$p_realm_data{'need_approval'});

- <a href="$::const{'admin_url'}&amp;Action=FilterRules&amp;subaction=ShowPending&amp;Realm=$$p_realm_data{'url_name'}" class="onbrown">$::str[427]</a>

EOM


print <<"EOM";
	</td>
</tr>
<tr class="fdtan">
	<td align="center"><a href="$::const{'admin_url'}&amp;Action=ManageRealms&amp;Delete=$$p_realm_data{'url_name'}" onclick="return confirm('$::str[108]');" class="onbrown">$::str[430]</a></td>

EOM

if ($$p_realm_data{'is_runtime'}) {
	print '<td><br /></td>';
	}
else {
print <<"EOM";

	<td nowrap="nowrap"><a href="$::const{'admin_url'}&amp;Action=rebuild&amp;DaysPast=0&amp;Realm=$$p_realm_data{'url_name'}" class="onbrown">$::str[123]</a> - <a href="$::const{'admin_url'}&amp;Action=rebuild&amp;DaysPast=$::Rules{'crawler: days til refresh'}&amp;Realm=$$p_realm_data{'url_name'}" class="onbrown">$::str[124]</a></td>

EOM
		}
	print '</tr>';
	return $index_size_bytes;
	}





sub ui_AdminPage {

	print qq!<div class="breadcrumbs"><a href="$::const{'admin_url'}">$::str[96]</a> <span class="gt">&rarr;</span> $::str[443]</div>\r\n!;

	&pppstr(348, "$::const{'help_file'}1150.html" );

	my $err = '';
	Err: {


		if ($::Rules{'sql: enable'}) {
			print qq!<table border="1"><tr><td><p><b>Warning:</b> mysql data storage support has been removed from FDSE.  See <a href="$::const{'help_file'}1188.html" target="_blank">this help file</a> for more information and for instructions on how to upgrade.</p><p>This warning appears because the <a href="$::const{'admin_url'}&amp;Action=GeneralRules&amp;gr1=&amp;gr0=&amp;Edit=sql:%20enable">SQL: Enable</a> General Setting is checked.</p></td></tr></table>!;
			}


		my $i = 0;

		$err = $::realms->{'last_realm_err'};
		next Err if ($err);

		my $p_realm_data = ();

		my (@filefed, @open_realms, @filtered_realms, @website_realms, @runtime_realms) = ();

		my @realms = ();

		@realms = $::realms->listrealms('all');
		foreach $p_realm_data (@realms) {
			if ($$p_realm_data{'is_filefed'}) {
				push(@filefed, $p_realm_data);
				}
			elsif ($$p_realm_data{'type'} == 1) {
				push(@open_realms, $p_realm_data);
				}
			elsif ($$p_realm_data{'type'} == 6) {
				push(@filtered_realms, $p_realm_data);
				}
			elsif ($$p_realm_data{'is_runtime'}) {
				push(@runtime_realms, $p_realm_data);
				}
			else {
				push(@website_realms, $p_realm_data);
				}
			}

		@realms = $::realms->listrealms('is_error');
		if (@realms) {
			&ppstr(29, $::str[180] );
			foreach $p_realm_data (@realms) {
				print "<p><b>$$p_realm_data{'html_name'}</b> - $$p_realm_data{'err'}.</p>\n";
				&pppstr(182, "<a href=\"$::const{'admin_url'}&amp;Action=ManageRealms&amp;Realm=$$p_realm_data{'url_name'}\">$::str[411]</a>", "<a href=\"$::const{'admin_url'}&amp;Action=ManageRealms&amp;Delete=$$p_realm_data{'url_name'}\" onclick=\"return confirm('$::str[108]');\">$::str[430]</a>" );
				}
			}

		#changed 0054 -- allow website, file-fed, filtered, and open realms to use Add New URL form
		my $count = 0;
		my $ChooseRealmLine = '';

		my $p_data;
		foreach $p_data ($::realms->listrealms('all')) {
			next if (($$p_data{'type'} == 4) or ($$p_data{'type'} == 5));
			my $type = '';
			if ($$p_data{'type'} == 1) {
				$type = $::str[553];
				}
			elsif ($$p_data{'type'} == 2) {
				$type = $::str[554];
				}
			elsif ($$p_data{'type'} == 3) {
				$type = $::str[550];
				}
			$type .= ': ' if $type;
			$ChooseRealmLine .= qq!<option value="$$p_data{'html_name'}">$type$$p_data{'html_name'}</option>\n!;
			$count++;
			}



		my $ref_manage_realms = &pstr(371, qq!<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>! );


# the "Add New URL" form appears in all non-Freeware versions and in Freeware if there are valid realms which can accept
# single URL additions (count > 0)
if (((not $::private{'is_freeware'}) or ($count)) and ($::Rules{'use socket routines'})) {


		if (not $::private{'is_freeware'}) {
			$ChooseRealmLine .= qq!<option value="">! . &pstr(555, $::str[553] ) . qq!</option>\n!;
			}


		my $input = qq!<textarea name="URL" rows="3" cols="40" style="wrap:soft">http://</textarea>!;
		if (($::Rules{'show advanced commands'}) or (not $::Rules{'multi-line add-url form - admin'})) {
			$input = qq!<input name="URL" value="http://" size="40" />!;
			}


print <<"EOM";

<p><b>$::str[172]</b></p>
<blockquote>

	<p>$::str[291]</p>

$::const{'AdminForm'}
<input type="hidden" name="Action" value="AddURL" />

	<table border="0">
	<tr>
		<td align="right"><b>$::str[74]:</b></td>
		<td>$input</td>
	</tr>

EOM

print <<"EOM" if ($count);

	<tr>
		<td align="right"><b>$::str[161]:</b></td>
		<td><select name="Realm">$ChooseRealmLine</select></td>
	</tr>

EOM

print <<"EOM" if ($::Rules{'show advanced commands'});
	<tr>
		<td><br /></td>
		<td><input type="checkbox" name="EntireSite" value="1" /> $::str[429]</td>
	</tr>
EOM

print <<"EOM";
	<tr>
		<td><br /></td>
		<td><input type="submit" class="submit" value="$::str[172]" /></td>
	</tr>
	</table>

	</form>
</blockquote>

EOM
	}



# the "Add New Site" form:

if (((not $::private{'is_freeware'}) or (0 == $::realms->realm_count('all'))) and ($::Rules{'use socket routines'})) {

print <<"EOM";

<p><b>$::str[290]</b></p>
<blockquote>
	<p>$::str[287]</p>

$::const{'AdminForm'}

	<input type="hidden" name="Action" value="AddURL" />
	<input type="hidden" name="EntireSite" value="1" />
	<input type="hidden" name="CreateSelectRealm" value="1" />
	<table border="0">
	<tr>
		<td align="right"><b>$::str[74]:</b></td>
		<td><tt><input name="URL" value="http://" size="40" /></tt></td>
	</tr>
	<tr>
		<td><br /></td>
		<td><input type="submit" class="submit" value="$::str[290]" /></td>
	</tr>
	</table>

</form>

</blockquote>

EOM
	}

print <<"EOM";


<p><b>$::str[377]</b></p>

<p>$::str[326]</p>
<p>$ref_manage_realms</p>

EOM

print '<table border="1" cellpadding="4" cellspacing="1">' if (@open_realms or @filtered_realms or @website_realms or @runtime_realms or @filefed);

		my $total_size = 0;
		my $total_pages = 0;
		my $realm_count = 0;

		if (@open_realms) {
			&print_realm_table_header($::str[431]);
			foreach $p_realm_data (@open_realms) {
				next if ($$p_realm_data{'is_error'});
				$total_size += &print_realm_table_row($p_realm_data);
				$realm_count++;
				$total_pages += $$p_realm_data{'pagecount'};
				}
			}
		if (@filtered_realms) {
			&print_realm_table_header($::str[268]);
			foreach $p_realm_data (@filtered_realms) {
				next if ($$p_realm_data{'is_error'});
				$total_size += &print_realm_table_row($p_realm_data);
				$realm_count++;
				$total_pages += $$p_realm_data{'pagecount'};
				}
			}
		if (@website_realms) {
			&print_realm_table_header($::str[474]);
			foreach $p_realm_data (@website_realms) {
				next if ($$p_realm_data{'is_error'});
				$total_size += &print_realm_table_row($p_realm_data);
				$realm_count++;
				$total_pages += $$p_realm_data{'pagecount'};
				}
			}
		if (@runtime_realms) {
			&print_realm_table_header($::str[339]);
			foreach $p_realm_data (@runtime_realms) {
				next if ($$p_realm_data{'is_error'});
				$total_size += &print_realm_table_row($p_realm_data);
				$realm_count++;
				$total_pages += $$p_realm_data{'pagecount'};
				}
			}
		if (@filefed) {
			&print_realm_table_header($::str[489]);
			foreach $p_realm_data (@filefed) {
				next if ($$p_realm_data{'is_error'});
				$total_size += &print_realm_table_row($p_realm_data);
				$realm_count++;
				$total_pages += $$p_realm_data{'pagecount'};
				}
			}

if ($realm_count) {

		$total_size = &FormatNumber( (1023 + $total_size) / 1024, 0, 1, 0, 1, $::Rules{'ui: number format'} );
		$total_pages = &FormatNumber( $total_pages, 0, 1, 0, 1, $::Rules{'ui: number format'} );

print <<"EOM";

<tr>
	<th><br /></th>
	<th>Totals</th>
	<th>Size</th>
	<th>Pages</th>
	<th><br /></th>
	<th><br /></th>
</tr>
<tr class="fdtan">
	<td><br /></td>
	<td><br /></td>
	<td nowrap="nowrap" align="right">$total_size KB</td>
	<td nowrap="nowrap" align="right">$total_pages</td>
	<td><br /></td>
	<td><br /></td>
</tr>


EOM

	}

		print '</table>' if (@open_realms or @filtered_realms or @website_realms or @runtime_realms or @filefed);
		last Err;
		}
	continue {
		&ppstr(29, $err );
		}


print <<"EOM";

	<p><br /></p>

EOM
	}





sub ui_PersonalSettings {
	my $err = '';
	Err: {
		local $_;

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=PS">$::str[183]</a>

EOM

		my $subaction = $::FORM{'subaction'} || '';

		if ($subaction eq 'SaveData') {
			print qq! <span class="gt">&rarr;</span> $::str[362]</div>\n!;


			if ($::FORM{'admin notify: sendmail program'}) {
				my $b_is_valid = 0;
				foreach (@::sendmail) {
					$b_is_valid = 1 if ($_ eq $::FORM{'admin notify: sendmail program'});
					}
				unless ($b_is_valid) {
					$err = &pstr(144, &he($::FORM{'admin notify: sendmail program'}) );
					next Err;
					}
				}

			foreach ('admin notify: email address', 'admin notify: smtp server', 'admin notify: sendmail program') {
				$err = &WriteRule($_,$::FORM{$_} || '');
				next Err if ($err);
				&ppstr(174, &pstr(404,&he($_, $::FORM{$_})));
				}
			foreach ('security: session timeout') {
				$err = &WriteRule($_,$::FORM{$_} || 0);
				next Err if ($err);
				&ppstr(174, &pstr(404,&he($_,$::FORM{$_})));
				}

			if (($::FORM{'op'}) and ($::FORM{'np'}) and ($::FORM{'cp'})) {

				if ($::private{'is_demo'}) {
					&ppstr(53, $::str[435] );
					last Err;
					}

				my $seed = 'sX';
				if ($::FORM{'np'} ne $::FORM{'cp'}) {
					&ppstr(29, $::str[285] );
					}
				elsif ($::Rules{'password'} eq crypt($::FORM{'op'}, $seed)) {
					# well, okay so far:

					my $newpass = crypt($::FORM{'np'}, $seed);

					$err = &WriteRule( 'password', $newpass );
					next Err if ($err);
					&ppstr(174, $::str[293] );
					}
				else {
					&ppstr(29, $::str[181] );
					}
				}


			last Err;
			}

		if ($subaction eq 'TestMail') {
			print qq! <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=PS&amp;subaction=TestMail">$::str[168]</a></div>\n!;

my $test_msg = <<"EOM";
Hello!

This is a test message from your search engine. The following options were used to send it:

   Email address: $::Rules{'admin notify: email address'}
     SMTP server: $::Rules{'admin notify: smtp server'}
Sendmail Program: $::Rules{'admin notify: sendmail program'}

EOM

			my $trace = '';

			($err, $trace) = &SendMailEx(
				'handler_order' => '12',
				'to'  => $::Rules{'admin notify: email address'},
				'from' => $::Rules{'admin notify: email address'},
				'host' => $::Rules{'admin notify: smtp server'},
				'pipeto' => $::Rules{'admin notify: sendmail program'},
				'p_nc_cache' => $::private{'p_nc_cache'},
				'use standard io' => $::Rules{'use standard io'},
				'subject' => "Test Message from search engine",
				'message' => $test_msg,
				);
			next Err if ($err);

			$trace = &he( $trace );

			&ppstr(174, $::str[116] );
			print qq!<p>$::str[117]</p><p><textarea rows="10" cols="65">$trace</textarea></p>\n!;

			last Err;
			}

print <<"EOM";

	<span class="gt">&rarr;</span>
	$::str[152]
</div>

$::const{'AdminForm'}
<input type="hidden" name="Action" value="PS" />
<input type="hidden" name="subaction" value="SaveData" />

EOM

		$::const{'sendmail_options'} = '<option value="">[ None ]</option>';
		foreach (sort @::sendmail) {
			next unless (m!^(\S+)!s);
			next unless (-e $1);
			$::const{'sendmail_options'} .= '<option value="' . &he($_) . '">' . &he($_) . '</option>';
			}


		my $text = &PrintTemplate( 1, 'admin_personal.txt', $::Rules{'language'}, \%::const );
		print &SetDefaults($text, \%::Rules);
		print '</form>';
		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	}





sub ui_BCST {
	my $err = '';
	Err: {

		&handlers_init( 1 ); # load all handlers...


		my $sa = &he($::FORM{'sa'} || '');

		if ($sa eq '') {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=GeneralRules">$::str[159]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=BCST">Binary Converters - Setup and Test</a>
</div>

<p><b>Enabled Converters</b></p>

<p>The following table lists all binary-to-HTML handlers:</p>

<table border="1" cellpadding="4" cellspacing="0">
<tr>
	<th>Enabled</th>
	<th>Name</th>
	<th>Extension Pattern</th>
	<th>Content-Type Pattern</th>
	<th colspan="2">Actions</th>
</tr>

EOM

			my $b_disabled = 0;

			my $p_handler;
			foreach $p_handler (@{ $::private{'handlers'} }) {

				my $str_enabled = $p_handler->{'enabled'} ? '<b>x</b>' : 'no';

				$b_disabled++ unless $p_handler->{'enabled'};

				my $test_link = 'n/a';

				if (exists($p_handler->{'test_syntax'})) {
					$test_link = qq!<a href="$::const{'admin_url'}&amp;Action=BCST&amp;sa=test&amp;name=$p_handler->{'name'}">Syntax Test</a>!;
					}

print <<"EOM";

<tr>
	<td align="center">$str_enabled</td>
	<td><b>$p_handler->{'name'}</b></td>
	<td>$p_handler->{'extension_pattern'}</td>
	<td>$p_handler->{'content_type_pattern'}</td>
	<td align="center">$test_link</td>
	<td align="center"><a href="$p_handler->{'help'}" target="_blank">Help</a></td>
</tr>

EOM

				}

			print '</table>';

			if ($b_disabled) {
				print "<p>To enable one of the disabled handlers, click the corresponding Help link.</p>\n";
				}

			my $test_realm_name = 'Binary Conversion Test';
			my $ue_name = &ue($test_realm_name);


			my $adv_test = qq!

	<ol>

		<li>

			<p><b>Create Test Realm</b></p>

			<p>DO NOT click the "rebuild" link after creating the test realm.  Instead, return to this page and move to the next step.</p>

			<ul>

				<li><p>Click here to <a href="$::const{'admin_url'}&amp;Action=ManageRealms&amp;subaction=Create&amp;Write=1&amp;name=$ue_name&amp;type=2&amp;base_url2=http://www.xav.com/scripts/search/test/binaries/_conversion.html&amp;is_update=0&amp;orig_name=&amp;file=RUNTIME" target="_blank">automatically create a realm</a> that searches the test binaries on xav.com.</p></li>

				<li><p>Or, to test on your own content, go to the <a href="$::const{'admin_url'}&amp;Action=ManageRealms&amp;subaction=Create" target="_blank">Create New Realm</a> interface.  Create a realm named "$test_realm_name".  Configure the realm to index your binary files.</p></li>

			</ul>

		</li>

		<li>

			<p><b>Index Test Realm</b></p>

			<p>Create a realm named "$test_realm_name" first.  Then return to this page and <a href="$::const{'admin_url'}&amp;Action=BCST">reload</a> it.</p>

		</li>

	</ol>

				!;

			my $p_realm;
			($err, $p_realm) = $::realms->hashref( $test_realm_name );
			if ($err) {
				# no realm exists...
				$err = '';
				}
			else {

$adv_test = qq!

	<ol>

		<li>

			<p><b>Create Test Realm</b></p>

			<p>Click here to <a href="$::const{'admin_url'}&amp;Action=ManageRealms&amp;subaction=Edit&amp;Realm=$ue_name">edit</a> the "$test_realm_name" realm.  Make sure it includes binary files.</p>

		</li>

		<li>

			<p><b>Index Test Realm</b></p>

			<p>Click here to <a href="$::const{'admin_url'}&amp;Action=rebuild&amp;Realm=$ue_name&amp;debug=1">index all files</a> in the "$test_realm_name" realm.  This indexing will be done with the "debug=1" flag, which causes extra status messages to be printed.  These extra status messages should help you determine whether the conversion is working.</p>

		</li>

	</ol>


				!;
				}



print <<"EOM";

<p><br /></p>

<p><b>Integration Test</b></p>

<p>Click here to <a href="$::const{'admin_url'}&amp;Action=BCST&amp;sa=crossref">cross-reference enabled binary converters</a> with related General Settings.  This will confirm that your system is configured to discover all binary file types that it knows how to read.</p>

<p><br /></p>

<p><b>Advanced Test</b></p>

<p>The <b>Syntax Test</b> and <b>Integration Test</b> actions only perform basic validation of the settings.  Before you can be sure the converters are working, you need to test them on actual binary files.</p>

$adv_test

<p><br /></p>

EOM

			last Err;
			}

		if ($sa eq 'test') {
			my $hname = &he($::FORM{'name'});


print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=GeneralRules">$::str[159]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=BCST">Binary Converters - Setup and Test</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=BCST&amp;sa=test&amp;name=$hname">$hname</a>
</div>

EOM

			my $p_handler;
			foreach $p_handler (@{ $::private{'handlers'} }) {
				next unless ($::FORM{'name'} eq $p_handler->{'name'});
				if (not exists($p_handler->{'test_syntax'})) {
					$err = "binary handler '$hname' does not have a test routine";
					next Err;
					}
				$err = &{ $p_handler->{'test_syntax'} }( 1 );
				next Err if ($err);
				last Err;
				}
			$err = "binary handler '$hname' not found in handler array";
			next Err;
			}

		if ($sa eq 'crossref') {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=GeneralRules">$::str[159]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=BCST">Binary Converters - Setup and Test</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=BCST&amp;sa=$sa">Integration Test</a>
</div>

EOM

			my @file_extensions_supported = ();
			my @file_extensions_not = ();

			my $p_handler;
			foreach $p_handler (@{ $::private{'handlers'} }) {
				my $hname = &he($p_handler->{'name'});


				my $ext_pattern = $p_handler->{'extension_pattern'};
				if (not $p_handler->{'enabled'}) {
					push(@file_extensions_not, $ext_pattern );
					print "<p>File extension pattern $ext_pattern not supported because binary converted is not enabled.</p>\n";
					next;
					}

				if (exists($p_handler->{'test_syntax'})) {
					my $test_err = &{ $p_handler->{'test_syntax'} }( 0 );
					if ($test_err) {
						push( @file_extensions_not, $ext_pattern );
						print "<p>File extension pattern $ext_pattern not supported because syntax test returns error '$test_err'.</p>\n";
						next;
						}
					}

				push( @file_extensions_supported, $ext_pattern );
				print "<p>File extension pattern $ext_pattern supported.</p>\n";
				}

			my $warnings = 0;

			my $hext = &he($::Rules{'ext'});

			my @exts = split(m!\s+!s, $::Rules{'ext'});
			my $ext;

			# do any of these allowed extensions match an unsupported handler?
			foreach $ext (@exts) {

				foreach (@file_extensions_not) {

					if ($ext =~ m!$_!is) {
						print qq!<p><b>Warning:</b> General Setting <a href="$::const{'admin_url'}&amp;Action=GeneralRules&amp;Edit=Ext"><b>Ext</b></a> contains extension '$ext' which pattern matches to '$_', but that pattern is not supported.  File extension '$ext' should be removed.</p>\n!;
						$warnings++;
						}
					}
				}

			my $pattern;
			Pattern: foreach $pattern (@file_extensions_supported) {
				# is there some 'Ext' setting to match this?

				foreach $ext (@exts) {
					if ($ext =~ m!$pattern!is) {
						# okay, all good
						next Pattern;
						}
					}

				print qq!<p><b>Warning:</b> there is a binary converter available for extension pattern $pattern, but no file extensions in General Setting <a href="$::const{'admin_url'}&amp;Action=GeneralRules&amp;Edit=Ext"><b>Ext</b></a> match this pattern.  You should add extensions for this binary type.</p>\n!;
				$warnings++;
				}

			if ($warnings == 0) {
				print "<p><b>Success:</b> confirmed that General Setting <b>Ext</b> is configured properly.</p>\n";
				}


			$warnings = 0;

			$hext = &he($::Rules{'crawler: ignore links to'});
			@exts = split(m!\s+!s, $::Rules{'crawler: ignore links to'});

			# do any of these allowed extensions match a supported handler?
			foreach $ext (@exts) {

				foreach (@file_extensions_supported) {

					if ($ext =~ m!$_!is) {
						print qq!<p><b>Warning:</b> General Setting <a href="$::const{'admin_url'}&amp;Action=GeneralRules&amp;Edit=Crawler:+Ignore+Links+To"><b>Crawler: Ignore Links To</b></a> contains extension '$ext' which pattern matches to '$_'.  A converter is defined for that pattern, and so the extension should not be ignored.  File extension '$ext' should be removed from this General Setting.</p>\n!;
						$warnings++;
						}
					}
				}

			Pattern: foreach $pattern (@file_extensions_not) {
				# is there some 'Ext' setting to match this?

				foreach $ext (@exts) {
					if ($ext =~ m!$pattern!is) {
						# okay, all good
						next Pattern;
						}
					}

				print qq!<p><b>Warning:</b> General Setting <a href="$::const{'admin_url'}&amp;Action=GeneralRules&amp;Edit=Crawler:+Ignore+Links+To"><b>Crawler: Ignore Links To</b></a> does not include an extension for unsupported pattern $pattern.  You should add a file extension to this General Setting so that this unsupported binary type is ignored.</p>\n!;
				$warnings++;
				}

			if ($warnings == 0) {
				print "<p><b>Success:</b> confirmed that General Setting <b>Crawler: Ignore Links To</b> is configured properly.</p>\n";
				}

			last Err;
			}



		$err = "subaction '$sa' not defined for this interface";
		next Err;
		}
	return $err;
	}



sub ui_sysinfo {

print <<"EOM";
<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=GeneralRules">$::str[159]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=SI">$::str[92]</a>
</div>

EOM

	&pppstr(488, $], $^X, $^O, &query_env('SERVER_SOFTWARE'));

	my $xpdf = $::private{'pdf utility folder'} ? $::private{'pdf utility folder'} : '[none]';

print <<"EOM";

<table border="1" cellpadding="4" cellspacing="0">
<tr>
	<td align="right"><b>Data Folder:</b></td>
	<td>$::private{'support_dir'}</td>
	<td><a href="$::const{'help_file'}1079.html" target="_blank">$::str[432]</a></td>
</tr>
</table>

<p><b>$::str[91]</b></p>

<table border="1" cellpadding="4" cellspacing="0">

EOM

	foreach (sort keys %ENV) {
		my ($name, $value) = &he( $_, $ENV{$_} );
		print qq!<tr><td align="right">$name</td><td>$value<br /></td></tr>\n!;
		}
	print "</table>";

print <<"EOM";

<p><b>Perl libraries loaded</b></p>

<table border="1" cellpadding="4" cellspacing="0">

EOM


	foreach (sort keys %INC) {
		my ($name, $value) = &he( $_, $INC{$_} );
		print qq!<tr><td align="right">$name</td><td>$value<br /></td></tr>\n!;
		}
	print "</table>";


	}





sub ui_GeneralRules {

	my ($name, $action, @settings) = @_;

	# FORM{'gr1'} takes prec -> name
	# FORM{'gr0'} takes prec -> action

	# initialize:
	$::FORM{'gr1'} = &he($name || $::FORM{'gr1'} || '');
	$::FORM{'gr0'} = &he($action || $::FORM{'gr0'} || '');

	my $ugr1 = &ue($::FORM{'gr1'});

	my $top_name = $name || $::FORM{'gr1'} || $::str[159];
	my $top_action = $action || $::FORM{'gr0'} || 'GeneralRules';

	my $err = '';
	Err: {

		my %setting_info = (
#			'lc_name' => [ $desc_string, $b_handled_by_general_settings_interface, $b_require_rebuild_after_change; 0->no; 1->should 2->must ],

			'allowbinaryfiles' => [ $::str[490], 1, 1 ],
			'allowsymboliclinks' => [ $::str[491], 1, 1 ],
			'crawler: days til refresh' => [ $::str[492], 1, 0 ],
			'crawler: follow offsite links' => [ $::str[493], 1, 1 ],
			'crawler: follow query strings' => [ $::str[494], 1, 1 ],
			'crawler: ignore links to' => [ $::str[495], 1, 1 ],
			'crawler: max pages per batch' => [ $::str[496], 1, 0 ],
			'crawler: max redirects' => [ $::str[497], 1, 0 ],
			'crawler: minimum whitespace' => [ $::str[498], 1, 1 ],
			'crawler: rogue' => [ $::str[499], 1, 1 ],
			'crawler: user agent' => [ $::str[549], 1, 0 ],
			'crawler: use cookies' => [ 'Controls whether the FDSE crawler will attempt to be cookies-aware during each crawl session.', 1, 1 ],
			'default match' => [ $::str[501], 0, 0 ],
			'delete index file with realm' => [ $::str[502], 0, 0 ],
			'ext' => [ $::str[503], 1, 1 ],
			'forbid all cap descriptions' => [ $::str[504], 1, 1 ],
			'forbid all cap titles' => [ $::str[505], 1, 1 ],
			'handling url search terms' => [ $::str[506], 0, 0 ],
			'hits per page' => [ $::str[507], 0, 0 ],
			'ignore words' => [ $::str[508], 1, 2 ],
			'index alt text' => [ $::str[509], 1, 1 ],
			'index links' => [ $::str[510], 1, 1 ],
			'max characters: auto description' => [ $::str[511], 1, 1 ],
			'max characters: description' => [ $::str[512], 1, 1 ],
			'max characters: file' => [ $::str[513], 1, 1 ],
			'max characters: keywords' => [ $::str[514], 1, 1 ],
			'max characters: text' => [ $::str[515], 1, 1 ],
			'max characters: title' => [ $::str[516], 1, 1 ],
			'max characters: url' => [ $::str[517], 1, 1 ],
			'max index file size' => [ $::str[518], 1, 0 ],
			'minimum page size' => [ $::str[519], 1, 1 ],
			'multiplier: description' => [ $::str[520], 1, 0 ],
			'multiplier: keyword' => [ $::str[521], 1, 0 ],
			'multiplier: title' => [ $::str[522], 1, 0 ],
			'multiplier: url' => [ $::str[523], 1, 0 ],
			'parse fdse-index-as header' => [ $::str[525], 1, 1 ],
			'redirector' => [ $::str[526], 1, 0 ],
			'sql: enable' => [ $::str[527], 1, 0 ],
			'show examples: enable' => [ $::str[528], 0, 0 ],
			'show examples: number to display' => [ $::str[529], 0, 0 ],
			'sorting: default sort method' => [ $::str[530], 0, 0 ],
			'sorting: randomize equally-relevant search results' => [ $::str[531], 0, 0 ],
			'time interval between restarts' => [ $::str[532], 1, 0 ],
			'timeout' => [ $::str[533], 1, 0 ],
			'trustsymboliclinks' => [ $::str[534], 1, 1 ],
			'use standard io' => [ $::str[535], 1, 0 ],
			'wildcard match' => [ $::str[536], 1, 0 ],
			'logging: enable' => [ $::str[537], 0, 0 ],
			'sorting: time sensitive' => [ $::str[538], 0, 0 ],
			'multi-line add-url form - admin' => [ $::str[539], 1, 0 ],
			'multi-line add-url form - visitors' => [ $::str[540], 1, 0 ],
			'network timeout' => [ $::str[541], 1, 0 ],
			'user language selection' => [ $::str[542], 0, 0 ],
			'logging: display most popular' => [ $::str[543], 0, 0 ],
			'default search terms' => [ $::str[544], 0, 0 ],
			'show advanced commands' => [ $::str[545], 0, 0 ],
			'use dbm routines' => [ $::str[546], 1, 0 ],
			'use socket routines' => [ $::str[547], 1, 0 ],
			'default substring match' => [ $::str[548], 0, 0 ],
			'refresh time delay' => [ $::str[184], 1, 0 ],
			);






		# Load Fluid Dynamics Rules object:

		my $FDR = &FD_Rules_new();
		my $r_defaults = $FDR->get_defaults();

		my $sa = $::FORM{'subaction'} || '';


		# Print the header, *unless* this is an inline-list request (only those requests have $name initialized)

		unless ($name) {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=$top_action&amp;gr1=$ugr1&amp;gr0=$::FORM{'gr0'}">$top_name</a>

EOM
			if ($::FORM{'Edit'}) {
				my $html_name = &he( $::FORM{'Edit'} );
				print qq! <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=GeneralRules&amp;gr1=$ugr1&amp;gr0=$::FORM{'gr0'}&amp;Edit=$html_name">$html_name</a>!;
				}
			if ($sa eq 'Write') {
				print qq! <span class="gt">&rarr;</span> $::str[362]</div>\r\n!;
				}
			else {
				print qq! <span class="gt">&rarr;</span> $::str[152]</div>\r\n!;
				}
			}


		if ($::FORM{'Edit'}) {

			my $name = $::FORM{'Edit'};
			my $lc_name = lc($name);
			my $html_name = &he($name);
			my $type = $$r_defaults{$lc_name}[1];

			if ($sa eq 'Write') {
				my $value = $::FORM{'VALUE'};
				if ($type == 1) {
					$value = ($value) ? 1 : 0;
					}
				# strip line breaks, as promised:
				$value =~ s!(\n|\r|\015|\012)! !sg;
				my $b_changed = ($::Rules{$lc_name} ne $value) ? 1 : 0;
				$err = &WriteRule( $lc_name, $value );
				next Err if ($err);
				&ppstr(174, &pstr(404,$html_name,&he($value)));
				if (($b_changed) and ($setting_info{$lc_name}) and ($setting_info{$lc_name}->[2])) {
					if (1 == $setting_info{$lc_name}->[2]) {
						print '<p>' . $::str[329] . '</p>';
						}
					else {
						print '<p>' . $::str[109] . '</p>';
						}
					}
				last Err;
				}

			my $value = $::Rules{$lc_name};
			my $def_value = $$r_defaults{$lc_name}[0];

			my @type_desc = (
				0,
				$::str[392],
				$::str[393],
				$::str[394],
				$::str[395],
				$::str[396],
				);

			my $minmax = '';


			if ($type == 3) {
				$minmax = " ($::str[405] " . $$r_defaults{$lc_name}[2] . "; $::str[406] " . $$r_defaults{$lc_name}[3] . ")";
				}

			my %defaults = (
				'VALUE' => $::Rules{$lc_name},
				);


print <<"EOM";

$::const{'AdminForm'}
<input type="hidden" name="Action" value="GeneralRules" />
<input type="hidden" name="Edit" value="$html_name" />
<input type="hidden" name="subaction" value="Write" />
<input type="hidden" name="gr1" value="$::FORM{'gr1'}" />
<input type="hidden" name="gr0" value="$::FORM{'gr0'}" />

EOM


			my $description = $setting_info{$lc_name}->[0];

			# if Boolean checkbox value:
			if ($type == 1) {

print &SetDefaults(<<"EOM", \%defaults);
<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2" align="left">$::str[402]</th>
</tr>
<tr>
	<td><input type="checkbox" name="VALUE" value="1" id="VALUE_1" /></td>
	<td><label for="VALUE_1"><b>$html_name</b></label></td>
</tr>
</table>
<p>$description</p>
<p><input type="submit" class="submit" value="$::str[362]" /></p>
</form>

EOM

				# option to restore default with single click:
				if ($value ne $def_value) {
					&pppstr(401, "<a href=\"$::const{'admin_url'}&amp;Action=GeneralRules&amp;Edit=$html_name&amp;VALUE=$def_value&amp;subaction=Write&amp;gr1=$ugr1&amp;gr0=$::FORM{'gr0'}\">$::str[193]</a>" );
					}
				else {
					print "<p>$::str[353]</p>\n";
					}
				}

			# otherwise, if not a Boolean value (string/int/text):
			else {

				my $form_element = '<input name="VALUE" />';
				if ((40 < length($value)) or (40 < length($def_value))) {
					$form_element = '<textarea name="VALUE" rows="5" cols="60" style="wrap:soft"></textarea>';
					}
				elsif (($type == 2) or ($type == 3)) {
					$form_element = '<input name="VALUE" size="8" style="text-align:right" />';
					}



print &SetDefaults(<<"EOM", \%defaults);

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2" align="left">$::str[159]: $html_name</th>
</tr>
<tr>
	<td width="120" align="right" valign="top"><b>$::str[428]:</b></td>
	<td><b>$html_name</b></td>
</tr>
<tr>
	<td align="right" valign="top"><b>$::str[45]:</b></td>
	<td>$description</td>
</tr>
<tr>
	<td align="right" valign="top"><b>$::str[157]:</b></td>
	<td>$type_desc[$type]$minmax</td>
</tr>
</table>

<table border="0" cellpadding="4" cellspacing="2">
<tr>
	<td width="120" align="right" valign="top"><b>$::str[90]:</b></td>
	<td>$form_element</td>
</tr>
<tr>
	<td><br /></td>
	<td><p><input type="submit" class="submit" value="$::str[362]" /></p></td>
</tr>
</table>

</form>
EOM

				if ($value ne $def_value) {
					$defaults{'VALUE'} = $def_value;

print &SetDefaults(<<"EOM", \%defaults);
$::const{'AdminForm'}
<input type="hidden" name="Action" value="GeneralRules" />
<input type="hidden" name="Edit" value="$html_name" />
<input type="hidden" name="subaction" value="Write" />
<input type="hidden" name="gr1" value="$::FORM{'gr1'}" />
<input type="hidden" name="gr0" value="$::FORM{'gr0'}" />

<table border="0" cellpadding="4" cellspacing="2">
<tr>
	<td width="120" align="right" valign="top"><b>$::str[97]:</b></td>
	<td>$form_element</td>
</tr>
<tr>
	<td><br /></td>
	<td><input type="submit" class="submit" value="$::str[375]" /></td>
</tr>
</table>

</form>


EOM

					}
				else {
					print "<p>$::str[353]</p>\n";
					}
				print "<p>" . $::str[403] . "</p>\n";
				}
			last Err;
			}

		my $show_all_opt = 0;
		unless (@settings) {
			$show_all_opt = 1;
			foreach (keys %setting_info) {
				next unless ($setting_info{$_}->[1]);
				push(@settings,$_);
				}
			}
		my %show_settings = ();
		foreach (@settings) {
			$show_settings{$_} = 1;
			}


		if ($show_all_opt) {
			print '<p>';
			&ppstr(488, $], $^X, $^O, &query_env('SERVER_SOFTWARE'));
			print "<br />[ <a href=\"$::const{'admin_url'}&amp;Action=SI\">$::str[358]</a> ]</p>\n";

print <<"EOM";

<blockquote>

	<p>$::str[486]: <a href="$::const{'admin_url'}&amp;Action=BCST"><b>Binary Converters - Setup and Test</b></a></p>

	<p>$::str[486]: <a href="$::const{'admin_url'}&amp;Action=UserInterface&amp;subaction=viewmap"><b>$::str[473]</b></a></p>

</blockquote>

EOM

			}

		my $lc_name;
		foreach $lc_name (sort keys %setting_info) {
			next unless ($show_settings{$lc_name});

			my $name = &Capitalize($lc_name);

			my $url_name = &ue($name);
			my $html_name = &he($name);
			my $default = $$r_defaults{$lc_name}[0];
			my $current_val = $::Rules{$lc_name};


			my $def = '';
			if ($current_val eq $default) {
				$def = " (<span class=\"defaultsetting\">$::str[234]</span>) ";
				}
			else {
				$def = " (<span class=\"customsetting\">$::str[223]</span>) ";
				}

			my $display_val = $current_val;
			if (length($current_val) > 15) {
				$display_val = substr($current_val, 0, 12) . "...";
				}
			$display_val = &he($display_val);

			my $description = $setting_info{$lc_name}->[0];

			print "<p>[ <a href=\"$::const{'admin_url'}&amp;Action=GeneralRules&amp;Edit=$url_name&amp;gr1=$ugr1&amp;gr0=$::FORM{'gr0'}\">$::str[411]</a> ] <b>$html_name</b> = $display_val $def<br />$description</p>\n";
			}

		last Err;
		}
	return $err;
	}





sub update_file {
	my ($realm, $ref_crawler_results) = @_;

	my ($total_records, $new_records, $updated_records, $deleted_records) = (0, 0, 0, 0);

	my $err = '';
	Err: {
		local $_;

		my $p_realm_data = ();
		($err, $p_realm_data) = $::realms->hashref($realm);
		next Err if ($err);

		unless ($$p_realm_data{'file'}) {
			$err = &pstr(141, $$p_realm_data{'html_realm'} );
			next Err;
			}

		my $obj = &LockFile_new();

		my ($p_rhandle, $p_whandle) = ();
		($err, $p_rhandle, $p_whandle) = $obj->ReadWrite( $$p_realm_data{'file'} );
		next Err if ($err);

		my $TempFile = $obj->get_wname();

		WriteF: {

			my $ref_data = ();

			while (defined($_ = readline($$p_rhandle))) {
				# compare whether an existing entry is there:
				next unless (m!u= (.*?) t=!s); # skip invalid lines and isolate URL
				my $record_url = $1;
				if ($ref_data = $$ref_crawler_results{$record_url}) {

					if ($$ref_data{'b_write_to_temp'}) {
						# oh, this crawler result is a write-to-temp... do nothing here
						}
					else {

						if (($$ref_data{'is_error'}) or ($$ref_data{'experienced'})) {
							$$ref_data{'sub status msg'} = $::str[408];
							$deleted_records++;
							next;
							}

						$$ref_data{'experienced'} = 1;

						if ($$ref_data{'is_update'}) {

							# Create a new replacement record:
							if (m!^(\d+) (\d+) (\d+) u= .*? t= .*? d= .*? uM= .*? uT= .*? uD= .*? uK= .*? h= (.*?) l= (.*)!s) {

								my ($promote, $dd, $mm, $yyyy) = unpack('A2A2A2A4', $1);
								$$ref_data{'lastmodtime'} = $2;
								$$ref_data{'lastindex'} = $3;
								$$ref_data{'text'} = $4;
								$$ref_data{'links'} = $3;

								#$$ref_data{'promote'} = $promote;

								$$ref_data{'dd'} = $dd;
								$$ref_data{'mm'} = $mm;
								$$ref_data{'yyyy'} = $yyyy;

								}

							#revcompat - older yet support record format
							elsif (m!^(\d+) u= .*? t= .*? d= .*? uM= .*? uT= .*? uD= .*? uK= .*? h= (.*?) l= (.*)!s) {
								my ($promote, $dd, $mm, $yyyy) = unpack('A2A2A2A4', $1);
								#$$ref_data{'promote'} = $promote;
								$$ref_data{'dd'} = $dd;
								$$ref_data{'mm'} = $mm;
								$$ref_data{'yyyy'} = $yyyy;
								$$ref_data{'text'} = $2;
								$$ref_data{'links'} = $3;
								}
							#/revcompat

							else {
								&ppstr(29, $::str[409] );
								next;
								}
							}
						$$ref_data{'is_update'} = 1;

						my ($temp_err_msg, $text_record) = &text_record_from_hash( $ref_data );
						if ($temp_err_msg) {
							&ppstr(29, $temp_err_msg );
							next;
							}

						$_ = $text_record;
						$$ref_data{'sub status msg'} = $::str[312];
						$updated_records++;
						}
					}

				unless (print { $$p_whandle } $_) {
					$err = &pstr(43, $TempFile, $!);
					next WriteF;
					}
				$total_records++;
				}
			#end changes

			my ($URL, $ref_pagedata) = ();
			while (($URL, $ref_pagedata) = each %$ref_crawler_results) {
				next if (($$ref_pagedata{'is_error'}) or ($$ref_pagedata{'is_update'}) or ($$ref_pagedata{'b_write_to_temp'}));
				if ($$ref_pagedata{'record'}) {
					unless (print { $$p_whandle } $$ref_pagedata{'record'}) {
						$err = &pstr(43,$TempFile,$!);
						next WriteF;
						}
					}
				else {
					my ($temp_err_msg, $record) = &text_record_from_hash( $ref_pagedata );
					if ($temp_err_msg) {
						$$ref_pagedata{'sub status msg'} = $temp_err_msg;
						next;
						}
					else {
						unless (print { $$p_whandle } $record) {
							$err = &pstr(43,$TempFile,$!);
							next WriteF;
							}
						}
					}
				unless ($$ref_pagedata{'sub status msg'}) {
					$$ref_pagedata{'sub status msg'} = $::str[407];
					}
				$new_records++;
				$total_records++;
				}
			last WriteF;
			}

		# was there an error during the write? if so that's too bad - better abort and call it a day
		if ($err) {
			my $cancel_msg = $obj->Cancel();
			if ($cancel_msg) {
				$err .= "</p><p><b>$::str[73]:</b> $cancel_msg";
				}
			next Err;
			}

		# has our file grown too big?

		my $TempSize = -s $TempFile;

		# zero max size negates size checking
		if (($::Rules{'max index file size'}) and ($TempSize > $::Rules{'max index file size'})) {
			# The temp file is too big - abort everything:

			my $max_size = &FormatNumber( $::Rules{'max index file size'}, 0, 1, 0, 1, $::Rules{'ui: number format'} );

			$TempSize = &FormatNumber( $TempSize , 0, 1, 0, 1, $::Rules{'ui: number format'} );
			$err = &pstr(410, $max_size, $$p_realm_data{'file'}, $TempSize );
			my $cancel_msg = $obj->Cancel();
			if ($cancel_msg) {
				$err .= "</p><p><b>$::str[73]:</b> $cancel_msg";
				}
			next Err;
			}

		$err = $obj->Merge();
		next Err if ($err);

		$err = $::realms->setpagecount($realm, $total_records, 1);
		next Err if ($err);
		}
	return ($err, $total_records, $new_records, $updated_records, $deleted_records);
	}





sub update_realm {
	return &update_file(@_);
	}





sub query_realm {
	my ($realm, $query_pattern, $start_pos, $max_results, $ref_crawler_results) = @_;
	my $err = '';
	Err: {

		$err = &check_regex($query_pattern);
		next Err if ($err);

		my $p_realm_data = ();
		($err, $p_realm_data) = $::realms->hashref($realm);
		next Err if ($err);

		if ($$p_realm_data{'is_runtime'}) {
			return &query_runtime(@_);
			}
		else {
			return &query_file(@_);
			}
		}
	return $err;
	}





sub query_runtime {
	my ($realm, $query_pattern, $start_pos, $max_results, $ref_crawler_results) = @_;
	my $err = '';
	Err: {

		$err = &check_regex($query_pattern);
		next Err if ($err);


		my ($p_realm_data) = ();
		($err, $p_realm_data) = $::realms->hashref($realm);
		next Err if ($err);

		my $fr = &fdse_filter_rules_new($p_realm_data);

		my $gf = &GetFiles_new();

		$err = $gf->create_file_list(
			'base_dir' => $$p_realm_data{'base_dir'},
			'base_url' => $$p_realm_data{'base_url'},
			'fr'    => \$fr,
			'tempfile' => "runtime.file_list. " . int(100 * rand()) . ".txt",
			'verbose' => 0,
			);
		next Err if ($err);

		if ($start_pos) {
			$gf->resume_file_position( $start_pos );
			}

		my $count = 0;

		my $record_err_msg = '';

		while ($count < $max_results) {
			my ($lastmodt, $size, $fullfile, $basefile, $url) = $gf->get_next_file();
			last unless ($url);
			my %pagedata = ();

			($record_err_msg,$url) = &pagedata_from_file( $fullfile, $url, \%pagedata, \$fr );
			if ($record_err_msg) {
			#	&ppstr(29, $record_err_msg );
				}
			else {
				$$ref_crawler_results{$url} = \%pagedata;
				$count++;
				}
			}
		$err = $gf->quit(0);
		}
	return $err;
	}





sub query_file {
	my ($realm, $query_pattern, $start_pos, $max_results, $ref_crawler_results) = @_;
	my $err = '';
	Err: {

		$err = &check_regex($query_pattern);
		next Err if ($err);

		my ($obj, $p_rhandle, $p_whandle) = ();

		my ($p_realm_data) = ();
		($err, $p_realm_data) = $::realms->hashref($realm);
		next Err if ($err);

		my $file = $$p_realm_data{'file'};

		$obj = &LockFile_new();

		($err, $p_rhandle) = $obj->Read( $file );
		next Err if ($err);

		my $linecount = -1;
		while (defined($_ = readline($$p_rhandle))) {
			next if (($query_pattern) and (not m! u= $query_pattern t= !s));
			$linecount++;
			next if ($linecount < $start_pos);
			last if ($linecount >= ($start_pos + $max_results));
			my ($is_valid, %pagedata) = &parse_text_record($_);
			if ($is_valid) {
				my $URL = $pagedata{'url'};
				$$ref_crawler_results{$URL} = \%pagedata;
				}
			}
		$err = $obj->Close();
		next Err if ($err);
		}
	return $err;
	}





sub get_remote_host {
	unless (exists $::private{'remote_host'}) {
		$::private{'remote_host'} = &query_env('REMOTE_HOST');
		if ((!$::private{'remote_host'}) || ($::private{'remote_host'} =~ m!^\d+\.\d+\.\d+\.\d+$!s)) {
			if ($::private{'visitor_ip_addr'} =~ m!^(\d+)\.(\d+)\.(\d+)\.(\d+)$!s) {
				$::private{'remote_host'} = (gethostbyaddr(pack('C4',$1,$2,$3,$4),2))[0] || $::private{'visitor_ip_addr'};
				}
			}
		$::private{'remote_host'} = lc($::private{'remote_host'});
		}
	return $::private{'remote_host'};
	}





sub get_absolute_url {
	my $URL = '';
	my $script_name = &query_env('SCRIPT_NAME','/');
	if ($ENV{'HTTP_HOST'}) {
		$URL = 'http://' . &query_env('HTTP_HOST') . $script_name;
		}
	elsif ($ENV{'SERVER_NAME'}) {
		$URL = 'http://' . &query_env('HTTP_HOST') . $script_name;
		}
	elsif ($ENV{'HTTP_REFERER'}) {
		$URL = &query_env('HTTP_REFERER');
		$URL =~ s!(\?|\$\|\#)(.*)!!os;
		}
	return $URL;
	}



sub print_AddURL_nav_header {
	my ($b_anon, $action) = @_;
	if ((not $b_anon) and (not $::const{'is_cmd'}) and ($action ne 'rebuild')) {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}">$::str[443]</a>
	<span class="gt">&rarr;</span> $::str[442]
</div>

EOM
		}
	}





sub s_AddURL {
	my ($b_IsAnonAdd, $Realm, @addr_strings) = @_;


	my @AddressesToIndex = (); #changed 0054; support multi-line inputs
	local $_;
	foreach (@addr_strings) {
		foreach (split(m!\r|\n|\015|\012!s)) {
			my $addr = &Trim($_);
			next unless ($addr);
			if ($addr =~ m!^\w+://!s) { # good; explicit proto
				}
			else {
				$addr = "http://$addr";
				}
			push( @AddressesToIndex, $addr );
			}
		}


	my $action = $::FORM{'Action'} || '';

	&print_AddURL_nav_header( $b_IsAnonAdd, $action );

	my $p_realm_data = ();

	my $err = '';
	Err: {


		if (($Realm) or ($b_IsAnonAdd)) {
			($err, $p_realm_data) = $::realms->hashref($Realm);
			next Err if ($err);
			}
		elsif (($::FORM{'CreateSelectRealm'}) and (not $b_IsAnonAdd)) {
			my $url;
			($err, $url) = &uri_parse($::FORM{'URL'});
			next Err if ($err);
			($err, $p_realm_data) = $::realms->get_website_realm($url);
			next Err if ($err);
			}
		else {
			# changed 0064: get_open_realm should always auto-create new realm...s
			($err, $p_realm_data) = $::realms->get_open_realm();
			next Err if ($err);
			$Realm = $$p_realm_data{'name'};
			}

		$::FORM{'Realm'} = $$p_realm_data{'name'}; #0035 for benefit of &AdminVersion later


		if ($$p_realm_data{'type'} == 3) {
			if (length($$p_realm_data{'limit_pattern'})) {
				$::FORM{'LimitPattern'} = $$p_realm_data{'limit_pattern'};
				}
			else {
				$::FORM{'LimitPattern'} = '^' . quotemeta(&get_web_folder($$p_realm_data{'base_url'}));
				}
			}
		elsif ($$p_realm_data{'type'} == 5) {
			$err = &pstr(277, $$p_realm_data{'html_name'});
			next Err;
			}


		if (($b_IsAnonAdd) and ($::Rules{'allowanonadd: require user email'})) {
			$err = &CheckEmail( $::FORM{'EMAIL'} );
			next Err if ($err);
			}


		# Initialize and validate FORM-based integers:
		foreach ('Batch','PagesDone','LimitIndexed','LimitFailed','LimitPending') {
			$::FORM{$_} = 0 unless exists $::FORM{$_};
			next if ($::FORM{$_} =~ m!^\d+$!s);
			$err = "parameter '$_' not numeric";
			next Err;
			}
		foreach ('DaysPast') {
			$::FORM{$_} = 0 unless exists $::FORM{$_};
			next if (($::FORM{$_} =~ m!^\d*\.?\d*$!s) and ($::FORM{$_} ne '.'));
			$err = "parameter '$_' not numeric";
			next Err;
			}


		my $NextLink = '';

		my $display_failed = $::FORM{'LimitFailed'};
		if ($display_failed) {
			$display_failed = qq!<a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=ViewErrors&amp;Realm=$p_realm_data->{'url_name'}" target="_blank">$display_failed</a>!;
			}

		if (($action eq 'CrawlEntireSite') or ($::FORM{'LimitPattern'})) {
			$::FORM{'Batch'}++;
			print "\n<p><b>" . &pstr(186,&he($::FORM{'LimitPattern'}), $$p_realm_data{'html_name'} ) . "</b><br />\n";
			&ppstr(189, $::FORM{'Batch'} );
			print ' ';
			&ppstr(191, $::FORM{'LimitIndexed'}, $display_failed, $::FORM{'LimitPending'} );
			print "</p>\n\n";
			}
		elsif ($action eq 'rebuild') {
			$::FORM{'Batch'}++;
			print "\n<p><b>" . &pstr(185, $$p_realm_data{'html_name'} ) . "</b><br />\n";
			&ppstr(188, $::FORM{'DaysPast'} ) if ($::FORM{'DaysPast'});
			&ppstr(189, $::FORM{'Batch'} );
			print ' ';
			&ppstr(191, $::FORM{'LimitIndexed'}, $display_failed, $::FORM{'LimitPending'} );
			print "</p>\n\n";
			}
		else {
			print "\n<p><b>" . &pstr(187, $$p_realm_data{'html_name'} ) . "</b></p>\n\n";
			}

		$::FORM{'PerBatch'} = $::FORM{'PerBatch'} || $::Rules{'crawler: max pages per batch'};
		$::FORM{'PerBatch'} = $::Rules{'crawler: max pages per batch'} if ($::FORM{'PerBatch'} > $::Rules{'crawler: max pages per batch'});


		my (@spidered_links, @crawled_pages, %crawler_results, %Response) = ();

		if (($::FORM{'istimeout'}) and (not $b_IsAnonAdd)) {
			# shoot... they suffered a timeout...
			# Are the already only trying one at a time? if so, and if they have multiple addresses waiting, delete the first in the queue:

			&ppstr(53, $::str[390] );

			if (($::FORM{'PerBatch'} == 1) and ($#AddressesToIndex > 0)) {

				my $URL = $AddressesToIndex[0];

				&pppstr(389, $URL );
				@AddressesToIndex = (); #@AddressesToIndex[1..$#AddressesToIndex]; #changed 0054

				push(@crawled_pages, $URL);

				my $hURL = &he($URL);
				my %pagedata = (
					'is_error' => 1,
					'url' => $URL,
					'err' => 'operation timed out',
					'html listing' => "<dl><dt><b>1. $::str[73]: $hURL</b></dt><dd>operation timed out</dd></dl>",
					'sub status msg' => '',
					'b_write_to_temp' => 0,
					);
				$crawler_results{$URL} = \%pagedata;
				}
			else {

				# reduce the workload by 50% if that would keep at least 1 URL
				my $test = int( $::FORM{'PerBatch'} / 2 );
				if ($test > 0) {
					&pppstr(388, $::FORM{'PerBatch'}, $test );
					$::FORM{'PerBatch'} = $test;
					}
				}
			}
		elsif ($::FORM{'PerBatch'} < $::Rules{'crawler: max pages per batch'}) {
			&pppstr(387, $::FORM{'PerBatch'}, $::FORM{'PerBatch'} + 1 );
			$::FORM{'PerBatch'}++;
			}

		if ((not $::const{'is_cmd'}) and (($action eq 'rebuild') or ($action eq 'CrawlEntireSite'))) {

			$NextLink = &admin_link(
				'PerBatch' => $::FORM{'PerBatch'},
				'Action' => $action,
				'LimitPattern' => $::FORM{'LimitPattern'},
				'Batch' => $::FORM{'Batch'},
				'DaysPast' => $::FORM{'DaysPast'},
				'StartTime' => $::FORM{'StartTime'},
				'Realm' => $$p_realm_data{'name'},
				);

			my $message = &pstr(325, "$::const{'help_file'}1162.html" );
			$message =~ s!\"!\\\"!sg; # escape quotes " for Javascript

print <<"EOM";

<script type="text/javascript">
<!--
function HandleUncontrolledExit() {
	if (!g_loaded) {
		// hmm.... we never made it to the end of this document... we are going to refresh this page after sleeping a bit...
		// probably the server timed out.
		window.setTimeout( "Reload();", 1000 * $::Rules{'time interval between restarts'} );
		if ((document) && (document.all) && (document.all("script_output"))) {
			document.all("script_output").innerHTML += "<p>$message</p><p>To handle this error, this page will attempt to reload itself in $::Rules{'time interval between restarts'} seconds.</p>";
			}
		}
	}
function Reload() {
	location.href = "$NextLink&PagesDone=$::FORM{'PagesDone'}&istimeout=1";
	}
//-->
</script>

EOM


			&pppstr(192, qq!<a href="$NextLink&amp;PagesDone=$::FORM{'PagesDone'}&amp;istimeout=1">$::str[193]</a>! );
			}

		print "<p>$::str[194]</p>\n" unless ($::const{'is_cmd'});

		my $crawler = &Crawler_new();
		my $fr = &fdse_filter_rules_new($p_realm_data);

		my $b_continue = 1;

		my $b_write_to_index = 1;
		my $b_write_to_temp = 0;
		my $b_write_to_temp_default = 0;

		my $default_approval_required = 0;

		if (($b_IsAnonAdd) and ($::Rules{'require anon approval'})) {
			$default_approval_required = 1;
			$b_write_to_index = 0;
			$b_write_to_temp = $b_write_to_temp_default = 1;
			}


		my ($trailer, $URL) = ('', '', '', '', '', '', '');
		my ($pux_err,$source_url,$clean) = ();

		if ((1 <= $::Rules{'timeout'}) and ($::Rules{'timeout'} <= 12)) {
			$::Rules{'timeout'} += 10;
			}

		my $index_count = 0;
		my $no_network_errs = 0;

		my ($is_denied, $require_approval, $promote_val, $filter_err_msg, $no_update_on_redirect, $b_index_nofollow, $b_follow_noindex);

		$| = 1;

		ADDRESS: foreach (@AddressesToIndex) {

			my %pagedata = (
				'realm_id' => $$p_realm_data{'realm_id'},
				'url' => '',
				'final url' => '',
				'is_error' => 0,
				'err' => '',
				'require_approval' => $default_approval_required,
				'is_intermediate' => 0,
				'record' => '',
				'html listing' => '',
				'sub status msg' => '',
				'b_write_to_temp' => $b_write_to_temp_default,
				);

			$b_continue = 1;

			$source_url = $URL = &Trim($_);

			CrawlErr: {

				if ((($index_count - $no_network_errs) >= $::FORM{'PerBatch'}) or ($no_network_errs >= (5 * $::FORM{'PerBatch'}))) {
					$trailer = "<dl><dt><b>$::str[197]</b></dt><dd>";
					if ($b_IsAnonAdd) {
						$trailer .= "The crawler cannot index more than $::FORM{'PerBatch'} links at one time.";
						}
					else {
						$trailer .= &pstr(196, $::FORM{'PerBatch'}, &admin_link(
							'Action' => 'GeneralRules',
							'Edit' => 'Crawler: Max Pages Per Batch',
							));
						}
					$trailer .= "</dd></dl>\n";
					$b_continue = 0;
					next CrawlErr;
					}

				# check elapsed time - we budget 10 seconds for file operations, after crawling is done:
				my $elapsed_time = time - $::private{'script_start_time'};
				if (($::Rules{'timeout'}) and ($elapsed_time > ($::Rules{'timeout'} - 10))) {
					$trailer = "<dl><dt><b>$::str[197]</b></dt><dd>";
					$trailer .= &pstr(198, $elapsed_time );
					$trailer .= "</dd></dl>\n";
					$b_continue = 0;
					next CrawlErr;
					}

				# apply input filter:
				$URL = &rewrite_url( 0, $URL );


				# the purpose of this call is to convert $URL to its "clean" form
				# we don't worry about error handling, because $crawler->webrequest will do that for us
				($pux_err, $clean) = &uri_parse($URL);
				if (not $pux_err) {
					$URL = $clean;
					}


				my $hURL = &he($URL);

				$index_count++;

				($is_denied, $require_approval, $promote_val, $filter_err_msg, $no_update_on_redirect, $b_index_nofollow, $b_follow_noindex) = $fr->check_filter_rules( $URL, '', 1);
				if ($is_denied) {
					$pagedata{'html listing'} = "<dl><dt><b>$index_count. $::str[73]: $hURL</b></dt><dd>$::str[73]: " . &he($filter_err_msg) . ".</dd></dl>";
					$pagedata{'is_error'} = 1;
					$pagedata{'err'} = &he($filter_err_msg);
					$no_network_errs++;
					next CrawlErr;
					}

				my $stime = time();
				if ($::const{'is_cmd'}) {
					print STDERR "$URL... ";
					}
				else {
					print "-&gt; $::str[195] '$hURL'... ";
					}
				%Response = $crawler->webrequest(
					'page' => $URL,
					'limit' => $::FORM{'LimitPattern'},
					);
				my $duration = time() - $stime;
				if ($::const{'is_cmd'}) {
					print STDERR "$duration sec\n";
					print STDERR "\t$::str[73]: $Response{'err'}.\n" if ($Response{'err'});
					print STDERR "\t$::str[202]: $Response{'final_url'}\n" if ($Response{'total_requests'} > 1);
					}
				else {
					&ppstr(204, $duration );
					print "<br />\n";
					}

				if ($no_update_on_redirect) {
					$pagedata{'url'} = $URL;
					}
				else {
					$pagedata{'url'} = $Response{'final_url'};
					}


				#changed 0054 - search.pending.txt rewrite bug fix
				if ($URL ne $source_url) {
					my $ref_redirects = $Response{'ref_redirects'};
					my @array = ($source_url, @$ref_redirects);
					@$ref_redirects = (); # zero anon array in mem
					$ref_redirects = 0; # zero refcount
					$Response{'ref_redirects'} = \@array;
					$Response{'total_requests'}++;
					}


				if ($Response{'total_requests'} > 1) {
					my $ref_redirects = $Response{'ref_redirects'};
					$pagedata{'redirects'} = &he("$::str[202]: " . join(' => ', @$ref_redirects));

					# Log the fact that these URLs will redirect to other places:

					my @redirects = @$ref_redirects;

					if ($no_update_on_redirect) {

						#kill the first entry:
						my $len = scalar @redirects;
						@redirects = @redirects[1..($len-1)];
						}
					else {

						# kill the last entry:
						pop(@redirects);

						}

					foreach (@redirects) {
						next if (defined($crawler_results{$_}));
						my %pd = (
							'url' => $_,
							'is_error' => 1,
							'is_intermediate' => 1,
							'err' => $::str[203],
							'require_approval' => $default_approval_required,
							);
						push(@crawled_pages, $_);
						$crawler_results{$_} = \%pd;
						}


					}
				$URL = $Response{'final_url'} unless ($no_update_on_redirect);
				$hURL = &he($URL);

				if ($Response{'err'}) {
					$pagedata{'html listing'} = "<dl><dt><b>$index_count. $::str[73]: $hURL</b></dt><dd>$::str[73]: $Response{'err'}.</dd></dl>";
					$pagedata{'is_error'} = 1;
					$pagedata{'err'} = $Response{'err'};
					next CrawlErr unless ($Response{'no_index_but_follow'}); # stick around a little longer if we wanna parse links
					}


				($is_denied, $require_approval, $promote_val, $filter_err_msg, $no_update_on_redirect, $b_index_nofollow, $b_follow_noindex) = $fr->check_filter_rules( $URL, $Response{'text'}, 0);
				if (($is_denied) or ($b_follow_noindex)) {
					if ($b_follow_noindex) {
						$Response{'no_index_but_follow'} = 1;
						$filter_err_msg = $::str[87];
						}
					$pagedata{'html listing'} = "<dl><dt><b>$index_count. $::str[73]: $hURL</b></dt><dd>$::str[73]: " . &he($filter_err_msg) . ".</dd></dl>";
					$pagedata{'is_error'} = 1;
					$pagedata{'err'} = &he($filter_err_msg);
					next CrawlErr unless ($Response{'no_index_but_follow'}); # stick around a little longer if we wanna parse links
					}

				if ($b_index_nofollow) {
					next CrawlErr if ($Response{'no_index_but_follow'});
					$Response{'no_follow'} = 1;
					}

				if (($require_approval) or (($b_IsAnonAdd) and ($::Rules{'require anon approval'}))) {

					$b_write_to_temp = 1;
					$pagedata{'b_write_to_temp'} = 1; # save this record to temp file only

					unless ($Response{'no_index_but_follow'}) {

						$pagedata{'require_approval'} = 1;
						$pagedata{'err'} = &he( $filter_err_msg );
						if ($b_IsAnonAdd) {
							$pagedata{'sub status msg'} = $::str[199];
							}
						else {
							$pagedata{'sub status msg'} = "$::str[356] - $filter_err_msg";
							}
						}
					}
				my $Text = $Response{'text'};

				if ($Response{'lastmodt'}) {
					$pagedata{'lastmodtime'} = $Response{'lastmodt'};
					}

				my $b_extract_links = $Response{'no_follow'} ? 0 : 1;
				&parse_html_ex($Text, $Response{'final_url'}, $b_extract_links, \@spidered_links, \%pagedata);

				$pagedata{'size'} = $Response{'size'} || length($Text);

				next CrawlErr if ($Response{'no_index_but_follow'}); # all we wanted was to populate \@spidered_links
				&compress_hash( \%pagedata );

				$pagedata{'promote'} = $promote_val;
				}
			last unless ($b_continue);
			push(@crawled_pages, $URL) unless (defined($crawler_results{$URL}));
			$crawler_results{$URL} = \%pagedata;
			}
		if ($::const{'is_cmd'}) {
			print "\n$::str[201]\n";
			}
		else {
			print "<p>$::str[201]</p>\n";
			}

		$| = 0;


		# If we're a filefed realm, discard all the spidered links:
		if ($$p_realm_data{'type'} == 2) {
			@spidered_links = ();
			}
		elsif ($::FORM{'LimitPattern'}) {
			my @new_links = ();
			my $pattern = $::FORM{'LimitPattern'};
			foreach (@spidered_links) {
				next unless (m!$pattern!is);
				push(@new_links, $_);
				}
			@spidered_links = @new_links;
			}


		my (@LN, @LVN, @LVO, @LE) = ();
		my ($total_records, $new_records, $updated_records, $deleted_records) = ('', 0, 0, 0, 0);

		if ($b_write_to_index) {
			($err, $total_records, $new_records, $updated_records, $deleted_records) = &update_realm( $$p_realm_data{'name'}, \%crawler_results);
			next Err if ($err);
			$err = &SaveLinksToFileEx( $p_realm_data, \%crawler_results, \@spidered_links, \@LN, \@LVN, \@LVO, \@LE );
			next Err if ($err);
			}

		my $approval_count = 0;


		if ($b_write_to_temp) {

			my $user_email = $::FORM{'EMAIL'} || '';

			my ($obj, $p_whandle) = ();
			$obj = &LockFile_new();
			($err, $p_whandle) = $obj->Append( $$p_realm_data{'file'} . '.need_approval' );
			next Err if ($err);

			foreach (@crawled_pages) {
				my $p_pagedata = $crawler_results{$_};
				next unless ($$p_pagedata{'require_approval'});

				my ($temp_err_msg, $text_record) = ('', '');

				unless ($$p_pagedata{'is_error'}) {
					($temp_err_msg, $text_record) = &text_record_from_hash($p_pagedata);
					if ($temp_err_msg) {
						&ppstr(29, $temp_err_msg );
						next;
						}
					# strip line breaks:
					$text_record =~ s!\n|\r|\015|\012!!sg;
					$text_record =~ s!\|\|!\&#124;\&#124;!sg;
					}

				my $Record = join('||', $::private{'script_start_time'}, &get_remote_host(), $$p_pagedata{'err'}, $$p_pagedata{'is_error'}, $$p_pagedata{'url'}, $text_record, $user_email);
				print { $$p_whandle } $Record . "\n";
				$approval_count++;
				}

			$err = $obj->FinishAppend();
			next Err if ($err);
			}

		if (($b_IsAnonAdd) and ($::Rules{'allowanonadd: log'})) {
			my $user_email = $::FORM{'EMAIL'} || '';
			my ($obj, $p_whandle) = ();
			$obj = &LockFile_new();
			($err, $p_whandle) = $obj->Append( 'submissions.csv' );
			next Err if ($err);

			# write schema as first line
			unless (-s 'submissions.csv') {
				print { $$p_whandle } "perl_time,human_time,remote_host,remote_addr,visitor_email,URL,realm,error,\n";
				}

			foreach (@crawled_pages) {
				my $p_pagedata = $crawler_results{$_};

				my $record = '';

				my $field;
				foreach $field (

					$::private{'script_start_time'},
					&FormatDateTime( $::private{'script_start_time'}, $::Rules{'ui: date format'} ),
					&get_remote_host(),
					$::private{'visitor_ip_addr'},
					$user_email,
					$$p_pagedata{'url'},
					$$p_realm_data{'name'},
					$$p_pagedata{'err'},

					) {
					if ($field =~ m!\"|\015|\012!s) {
						$field =~ s!\"!""!sg;
						$field = qq!"$field"!;
						}
					$record .= "$field,";
					}

				print { $$p_whandle } "$record\n";
				}
			$err = $obj->FinishAppend();
			next Err if ($err);
			}


		if (($b_IsAnonAdd) and ($::Rules{'allowanonadd: notify admin'})) {

			MailAdmin: {

				last MailAdmin unless (($::Rules{'admin notify: smtp server'}) or ($::Rules{'admin notify: sendmail program'}));
				last MailAdmin unless ($::Rules{'admin notify: email address'});

				my $URL = &get_absolute_url();

				my $mail_message = '';

				$mail_message .= "$::str[205]\015\012\015\012";

				$mail_message .= "Visitor Information:\015\012" . '-' x 20 . "\015\012";

				$mail_message .= ' ' x (10 - length($::str[206])) . $::str[206] . ": $::FORM{'EMAIL'}\015\012";
				$mail_message .= ' ' x (10 - length($::str[207])) . $::str[207] . ": $::private{'visitor_ip_addr'}\015\012";
				$mail_message .= ' ' x (10 - length($::str[85])) . $::str[85] . ": " . &get_remote_host() . "\015\012";

				$mail_message .= "\015\012";
				$mail_message .= "Submitted Page Information:\015\012";
				$mail_message .= '-' x length("Submitted Page Information:") . "\015\012";

				$mail_message .= ' ' x (10 - length($::str[161])) . $::str[161] . ": $$p_realm_data{'name'}\015\012";
				$mail_message .= "\015\012";

				my $LastURL = '';
				foreach (@crawled_pages) {
					my $p_pagedata = $crawler_results{$_};
					$mail_message .= ' ' x (10 - length($::str[74])) . $::str[74] . ": $$p_pagedata{'url'}\015\012";

					if ($$p_pagedata{'err'}) {
						$mail_message .= ' ' x (10 - length($::str[73])) . $::str[73] . ": $$p_pagedata{'err'}\015\012";
						}
					elsif ($$p_pagedata{'require_approval'}) {
						$mail_message .= "          - $::str[356]\015\012";
						}
					else {
						$mail_message .= "          - OK\015\012";
						}



					$mail_message .= "\015\012";

					$LastURL = $$p_pagedata{'url'};
					}

				$mail_message .= "\015\012" . '-' x 78 . "\015\012\015\012";

				if ($approval_count) {
					$mail_message .= "$::str[356]:\n\t$URL?ApproveRealm=$$p_realm_data{'url_name'}";
					}
				else {
					$mail_message .= $::str[381];
					}

$mail_message .= <<"EOM";


Fluid Dynamics Search Engine
	$URL?Mode=Admin

-----------------------------------------------------------------------------

EOM

				foreach (sort keys %::FORM) {
					next if (m!^(Mode|Match|PagesDone|PerBatch|EMAIL|Realm|URL|Terms|maxhits|p:pm|q|terms)$!s);
					$mail_message .= "$_: $::FORM{$_}\015\012\015\012";
					}

				# Use end-user-address *if* it is valid:
				my $from_addr = $::Rules{'admin notify: email address'};
				unless (&CheckEmail( $::FORM{'EMAIL'} )) {
					$from_addr = $::FORM{'EMAIL'};
					}


				&SendMailEx(
					'handler_order' => '12',
					'to'   => $::Rules{'admin notify: email address'},
					'to name' => 'FDSE Administrator',
					'from'  => $from_addr,
					'host'  => $::Rules{'admin notify: smtp server'},
					'pipeto' => $::Rules{'admin notify: sendmail program'},
					'p_nc_cache' => $::private{'p_nc_cache'},
					'use standard io' => $::Rules{'use standard io'},
					'subject' => &pstr(209, $LastURL ),
					'message' => $mail_message,
					);

				}

			}



		my $i = 0;
		ADDRESS: foreach (@crawled_pages) {
			last if ($::const{'is_cmd'});
			my $p_pagedata = $crawler_results{$_};
			next if ($$p_pagedata{'is_intermediate'});
			$i++;
			if ($$p_pagedata{'html listing'}) {
				print $$p_pagedata{'html listing'};
				}
			elsif ($b_IsAnonAdd) {
				print &StandardVersion('rank' => $i, %$p_pagedata);
				}
			else {
				print &AdminVersion('rank' => $i, %$p_pagedata);
				}
			print "<p>[ " . $$p_pagedata{'redirects'} . " ]</p>\n" if ($$p_pagedata{'redirects'});
			print "<p>[ " . $$p_pagedata{'sub status msg'} . " ]</p>\n" if ($$p_pagedata{'sub status msg'});
			}

		print $trailer;

		if ($b_write_to_index) {
			&pppstr(289, $total_records, $$p_realm_data{'html_name'}, $new_records, $updated_records, $deleted_records );
			}


		last Err if ($b_IsAnonAdd);
		last Err if ($::const{'is_cmd'});

		if (($action eq 'rebuild') or ($action eq 'CrawlEntireSite')) {

			$NextLink .= "&PagesDone=" . ($::FORM{'PagesDone'} + $index_count);

			my $advice = &pstr(211, $::Rules{'time interval between restarts'}, $NextLink );

print <<"EOM";

<meta http-equiv="refresh" content="$::Rules{'time interval between restarts'};URL=$NextLink" />
<p><b>$::str[210]:</b></p>
<blockquote>
	<p>$advice</p>
</blockquote>

EOM

			last Err;
			}






		#changed 0054 -- allow website, file-fed, filtered, and open realms to use Add New URL form
		my $count = 0;
		my $ChooseRealmLine = '';

		my $p_data;
		foreach $p_data ($::realms->listrealms('all')) {
			next if (($$p_data{'type'} == 4) or ($$p_data{'type'} == 5));
			my $type = '';
			if ($$p_data{'type'} == 1) {
				$type = $::str[553];
				}
			elsif ($$p_data{'type'} == 2) {
				$type = $::str[554];
				}
			elsif ($$p_data{'type'} == 3) {
				$type = $::str[550];
				}
			$type .= ': ' if $type;
			$ChooseRealmLine .= qq!<option value="$$p_data{'html_name'}">$type$$p_data{'html_name'}</option>\n!;
			$count++;
			}

		if (not $::private{'is_freeware'}) {
			$ChooseRealmLine .= qq!<option value="">! . &pstr(555, $::str[553] ) . qq!</option>\n!;
			}




		my $formtag = $::const{'AdminForm'};
		$formtag =~ s! name="?F1"?!!sg;

		my $input = '<input name="URL" size="40" value="http://" />';
		if ($::Rules{'multi-line add-url form - visitors'}) {
			$input = '<textarea name="URL" rows="3" cols="40" style="wrap:soft">http://</textarea>';
			}


print <<"EOM";

<p><b>$::str[172]</b></p>
<blockquote>

	<p>$::str[291]</p>
	$formtag
	<input type="hidden" name="Action" value="AddURL" />
	<table border="0">
	<tr>
		<td align="right"><b>$::str[74]:</b></td>
		<td>$input</td>
	</tr>

EOM

my %defaults = (
	'Realm' => $Realm,
	);

print &SetDefaults(<<"EOM", \%defaults);

	<tr>
		<td align="right"><b>$::str[161]:</b></td>
		<td><select name="Realm">$ChooseRealmLine</select></td>
	</tr>

EOM

print <<"EOM";

	<tr>
		<td><br /></td>
		<td><input type="submit" class="submit" value="$::str[172]" /></td>
	</tr>
	</table>

	</form>
</blockquote>

EOM

		my $LinkCount = $#LN + $#LVO + $#LVN + $#LE + 4;

		unless ($LinkCount) {
			print "<p>$::str[213]</p>\n";
			last Err;
			}

print <<"EOM";

		<p><b>$::str[214]</b></p>
		<blockquote>

$::const{'AdminForm'}
<input type="hidden" name="Action" value="AddURL" />
<input type="hidden" name="Realm" value="$$p_realm_data{'name'}" />

		<p>$::str[215]</p>

		<blockquote>

EOM
		if ($::FORM{'LimitPattern'}) {
			my $hval = &he($::FORM{'LimitPattern'});
			print qq!<input type="hidden" name="LimitPattern" value="$hval" />\n!;
			}

print <<"EOM";

<input type="submit" class="submit" value="$::str[374]" />
<script type="text/javascript">
<!--
function ClearAll(state) {
	if ((document) && (document.forms[1])) {
EOM
for (1..$LinkCount) {
	print "document.forms[1].A$_.checked = state;\n";
	}
print <<"EOM";
		}
	}
if ((document) && (document.forms[1])) {
	document.write('<font size="-1">[ <a href="javascript:ClearAll(false)">$::str[397]</a> ] [ <a href="javascript:ClearAll(true)">$::str[398]</a> ]</font>');
	}
//-->
</script>
</blockquote>
EOM

		$LinkCount = 1;

		if (@LN) {
			print "<p>$::str[216]</p>\n";
			foreach (sort @LN) {
				my $html_url = &he( $_ );
				print qq!<input type="checkbox" name="A$LinkCount" value="$html_url" checked="checked" /> $html_url<br />\n!;
				$LinkCount++;
				}
			}

		if (@LE) {
			print "<p>$::str[217]</p>\n";
			foreach (sort @LE) {
				my $html_url = &he( $_ );
				print qq!<input type="checkbox" name="A$LinkCount" value="$html_url" /> $html_url<br />\n!;
				$LinkCount++;
				}
			}
		if (@LVO) {
			&pppstr(218, $::Rules{'crawler: days til refresh'} );
			foreach (sort @LVO) {
				my $html_url = &he( $_ );
				print qq!<input type="checkbox" name="A$LinkCount" value="$html_url" checked="checked" /> $html_url<br />\n!;
				$LinkCount++;
				}
			}
		if (@LVN) {
			&pppstr(219, $::Rules{'crawler: days til refresh'} );
			foreach (sort @LVN) {
				my $html_url = &he( $_ );
				print qq!<input type="checkbox" name="A$LinkCount" value="$html_url" /> $html_url<br />\n!;
				$LinkCount++;
				}
			}

		print "</form></blockquote>";

		last Err;
		}
	return $err;
	}





sub admin_link {
	local $_;
	my (%params) = @_;
	my $link = $::const{'admin_url'};
	my ($name, $value) = ();
	while (($name, $value) = each %params) {
		$link .= '&' . &ue($name) . '=' . &ue($value);
		}
	return $link;
	}





sub SaveLinksToFileEx {
	my ($p_realm_data, $ref_crawler_results, $ref_spidered_links, $ref_links_new, $ref_links_visited_fresh, $ref_links_visited_old, $ref_links_error) = @_;
	my $err = '';
	Err: {

		unless (($p_realm_data) and ('HASH' eq ref($p_realm_data))) {
			$err = &pstr(21, 'p_realm_data' );
			next Err;
			}

		# ONLY save those code-0 links if we're a website realm with crawler discovery or we're LimitEntireSite mode:
		my $b_save_waiting_links = 0;
		if (($$p_realm_data{'type'} == 3) or (($::FORM{'LimitPattern'}) and ($::FORM{'Action'}) and ($::FORM{'Action'} eq 'CrawlEntireSite'))) {
			$b_save_waiting_links = 1;
			}
		elsif ($$p_realm_data{'type'} == 6) {
			$b_save_waiting_links = 1;
			}


		my $url_realm = $$p_realm_data{'url_name'};

		my %return_status = ();
		my $b_return_status_info = 0;
		if (($ref_spidered_links) and ($ref_links_new) and ($ref_links_visited_fresh) and ($ref_links_visited_old) and ($ref_links_error)) {
			$b_return_status_info = 1;
			}


		my @Global = ();

		# Take all pages indexed during this round and assign them a value of the
		# current time if they were successful and a 2 if they failed.

		my %written = ();

		my ($name, $value);
		while (($name, $value) = each %$ref_crawler_results) {
			if ($$value{'is_error'}) {
				push( @Global, "$name $url_realm 2" );
				}
			else {
				push( @Global, "$name $url_realm $::private{'script_start_time'}" );
				}
			$written{$name} = 1;
			}

		if (($ref_spidered_links) and ('ARRAY' eq ref($ref_spidered_links))) {

			# Add all saved links to this array with a 0 numeric index. Also create an
			# associative array of them for later comparisons:

			foreach (@$ref_spidered_links) {
				next if ($written{$_});
				push( @Global, "$_ $url_realm 0" );
				$return_status{$_} = 0;
				$written{$_} = 1;
				}
			}

		last Err unless (@Global); # don't bother if we have nothin to work with...

		my ($obj, $p_rhandle, $p_whandle) = ();

		$obj = &LockFile_new(
			'create_if_needed' => 1,
			);

		($err, $p_rhandle, $p_whandle) = $obj->ReadWrite( 'search.pending.txt' );
		next Err if ($err);


		my $b_compare = 1;

		my $maxi = $#Global;
		@Global = sort @Global;
		my $i = 0;

		my ($insert_url, $insert_realm, $insert_code) = ('','',0);

		if ($Global[$i] =~ m!^(.+) (\S+) (\d+)$!s) {
			($insert_url, $insert_realm, $insert_code) = ($1, $2, $3);
			}

		my ($last_url, $last_realm, $last_code) = ('', '', 0);

		my ($cur_url, $cur_realm, $cur_code) = ('', '', 0);

		my $b_get_next_line = 1;

		my $file_done = 0;

		while (1) {
			if ($b_get_next_line) {
				if (defined($_ = readline($$p_rhandle))) {
					next unless (m!^(.+) (\S+) (\d+)$!s);
					($cur_url, $cur_realm, $cur_code) = ($1, $2, $3);
					}
				elsif ($i <= $maxi) {
					$file_done = 1;
					$cur_url = 'z';
					$b_get_next_line = 0;
					}
				else {
					last;
					}
				}
			else {
				$b_get_next_line = 1;
				# unless the incoming records explicitly reset it to 0
				}

			# If we are different than our predecessors, we print out predecessors and take on their role. We are now pred and will be compared to new input

			# If we are the same, then we resolve which us of is superior, and loop next, without printing

			# This is done to weed out multiple sequential duplicates in the pending file

			if (($file_done) or ("$last_url $last_realm" ne "$cur_url $cur_realm")) {

				if ($b_compare) {

					# Right before we print, we check whether we should insert the current insert record.
					# If the current record falls before this one, we insert clean
					# If the current insert record is equal to this one, we fight it out and winner writes

					if ("$insert_url $insert_realm" lt "$last_url $last_realm") {
						# okay, insert clean:
						print { $$p_whandle } "$insert_url $insert_realm $insert_code\n" if (($b_save_waiting_links) or ($insert_code));
						$i++;
						if ($i > $maxi) {
							$b_get_next_line = 1;
							$b_compare = 0;
							}
						else {
							$Global[$i] =~ m!^(.+) (\S+) (\d+)$!s;
							($insert_url, $insert_realm, $insert_code) = ($1, $2, $3);
							$b_get_next_line = 0; # give the next guy in @Global a chance
							next;
							}
						}
					elsif ("$insert_url $insert_realm" eq "$last_url $last_realm") {
						$last_code = $insert_code if (($insert_code > $last_code) or ($insert_code == 2));
						$return_status{$insert_url} = $last_code if (defined($return_status{$insert_url}));
						$i++;
						if ($i > $maxi) {
							$b_get_next_line = 1;
							$b_compare = 0;
							}
						else {
							$Global[$i] =~ m!^(.+) (\S+) (\d+)$!s;
							($insert_url, $insert_realm, $insert_code) = ($1, $2, $3);
							$b_get_next_line = 0; # give the next guy in @Global a chance
							next;
							}

						}
					}


				print { $$p_whandle } "$last_url $last_realm $last_code\n" if (($last_url) and ($last_url ne 'z'));
				($last_url, $last_realm, $last_code) = ($cur_url, $cur_realm, $cur_code);

				}
			else {
				$last_code = $cur_code if ($cur_code > $last_code);
				}
			$b_get_next_line = 1;
			} # end loop
		print { $$p_whandle } "$last_url $last_realm $last_code\n" if (($last_url) and ($last_url ne 'z'));

		$err = $obj->Merge();
		next Err if ($err);

		last Err unless ($b_return_status_info);

		my $cut_age = $::private{'script_start_time'} - (86400 * $::Rules{'crawler: days til refresh'});

		my $url;
		while (($url, $value) = each %return_status) {
			if ($value == 0) {
				push( @$ref_links_new, $url );
				}
			elsif ($value == 2) {
				push( @$ref_links_error, $url );
				}
			elsif ($value < $cut_age) {
				push( @$ref_links_visited_old, $url );
				}
			else {
				push( @$ref_links_visited_fresh, $url );
				}
			}
		}
	return $err;
	}





sub get_age_str {
	my ($age) = @_;
	my $age_str = '';
	$age += 59; # round up
	if ($age > (2 * 86400)) {
		$age_str = &pstr(220, int($age / 86400) );
		}
	elsif ($age > (100 * 60)) {
		$age_str = &pstr(222, int($age / 3600) );
		}
	else {
		$age_str = &pstr(221, int($age / 60) );
		}
	$age_str;
	}





sub realm_interact {
	my ($p_realm_data, $p_code) = @_;
	%$p_code = ();

	$::private{'embedded_err_msg'} = '';

# Start-up routines:

$$p_code{'init'} = <<'EOM';


		$obji = &LockFile_new();
		($::private{'embedded_err_msg'}, $p_rhandlei, $p_whandlei) = $obji->ReadWrite( $$p_realm_data{'file'} );

EOM

$$p_code{'resume'} = <<'EOM';

		$obji = &LockFile_new();
		($::private{'embedded_err_msg'}, $p_rhandlei, $p_whandlei) = $obji->Resume( $$p_realm_data{'file'} );

EOM


# Shut-down routines:

$$p_code{'finish'} = <<'EOM';

		$::private{'embedded_err_msg'} = $obji->Merge();

EOM

$$p_code{'abort'} = <<'EOM';

		$::private{'embedded_err_msg'} = $obji->Cancel();

EOM

$$p_code{'suspend'} = <<'EOM';

		$::private{'embedded_err_msg'} = $obji->Suspend();

EOM





# Getnext code:

$$p_code{'get_next'} = <<'EOM';

	unless ($index_is_done) {
		while (1) {
			unless (defined($_ = readline($$p_rhandlei))) {
				$index_is_done = 1;
				last;
				}
			if (m!^(\d+) (\d+) (\d+).+?u= (.*?) t=!s) {
				($i_url, $i_lastmodt) = ($4, $2);
				$i_line++;
				$record = $_;
				last;
				}
			}
		}

EOM

$$p_code{'insert'} = $$p_code{'update'} = <<'EOM';

	my ($xrecord_err, $xrecord) = &text_record_from_hash( \%pagedata );
	if ($xrecord_err) {
		&ppstr(29,$xrecord_err);
		}
	else {
		unless (print { $$p_whandlei } $xrecord) {
			$write_err = &pstr(43, $obji->{'wname'}, $! );
			}
		$pagecount++;
		}

EOM

$$p_code{'delete'} = <<'EOM';

	# do nothing

EOM

$$p_code{'preserve'} = <<'EOM';

	unless (print { $$p_whandlei } $record) {
		$write_err = &pstr(43, $obji->{'wname'}, $! );
		}
	$pagecount++;

EOM

	}





sub UpdateIndex {
	my ($p_realm_data) = @_;
	my $err = '';
	my $is_complete = 0;
	Err: {

		local $_;

		# Create a list of all files and their last modified times:

		my $i_line = 0;
		my $a_line = 0;

		my $fr = &fdse_filter_rules_new($p_realm_data);

		my $gf = &GetFiles_new();

		$err = $gf->create_file_list(
			'base_dir' => $$p_realm_data{'base_dir'},
			'base_url' => $$p_realm_data{'base_url'},
			'fr'    => \$fr,
			'tempfile' => $$p_realm_data{'file'} . ".temp_file_list.txt",
			'verbose' => 1,
			);
		&pppstr(224, $gf->{'count'}, $$p_realm_data{'base_dir'} );

		# Open the realm index file for purposes of looping through it and re-writing it:

		my %code = ();
		&realm_interact( $p_realm_data, \%code );
		my ($obji, $p_rhandlei, $p_whandlei, $record, $record_err, $pagecount, $write_err) = ();

		eval $code{'init'};
		die $@ if $@;
		if ($::private{'embedded_err_msg'}) {
			$err = $::private{'embedded_err_msg'};
			next Err;
			}

		# Okay, proceed through the double parallel loop

		my ($a_url, $a_file, $a_lastmodt) = ('', '', 0);
		my ($i_url, $i_lastmodt) = ('', 0);

		my $index_is_done = 0;

		my $getnext = 2;

		$| = 1;

		my ($size, $basefile) = ();

		my $i_url_prev = '';

		my %crawler_results = ();
		my %valid = (
			'is_error' => 0,
			);
		my %invalid = (
			'is_error' => 1,
			);


# $a_url and $a_lastmodt refer to the *actual* sorted files in the folder

# $i_url and $i_lastmodt refer to the contents of the current index file, which may be out-of-date


		DREAD: while (1) {
			last if ($write_err);
			my %pagedata = ();

			if ($getnext == 2) {
				($a_lastmodt, $size, $a_file, $basefile, $a_url) = $gf->get_next_file();
				last DREAD unless ($a_url);
				$a_line++;
				$i_url_prev = $i_url;
				eval $code{'get_next'};
				die $@ if $@;
				if ($::private{'embedded_err_msg'}) {
					$err = $::private{'embedded_err_msg'};
					next Err;
					}
				}
			elsif ($getnext == 1) {
				($a_lastmodt, $size, $a_file, $basefile, $a_url) = $gf->get_next_file();
				last DREAD unless ($a_url);
				$a_line++;
				}
			elsif ($getnext == 0) {
				$i_url_prev = $i_url;
				eval $code{'get_next'};
				die $@ if $@;
				if ($::private{'embedded_err_msg'}) {
					$err = $::private{'embedded_err_msg'};
					next Err;
					}
				}

			if ($i_url lt $i_url_prev) { # fatal/die - alpha sort lost
				eval $code{'cancel'};
				die $@ if $@;
				if ($::private{'embedded_err_msg'}) {
					$err = $::private{'embedded_err_msg'};
					next Err;
					}
				$err = $::str[225] . ' (' . &he($i_url) . ' versus previous ' . &he($i_url_prev) . ')';
				next Err;
				}

			my $action = '';

			if ($a_url eq $i_url) {
				if ($a_lastmodt != $i_lastmodt) {
					$record_err = (&pagedata_from_file( $a_file, $a_url, \%pagedata, \$fr ))[0];
					if ($record_err) {
						&ppstr(29, &he($a_url) . ' - ' . $record_err);
						print "\n\n";
						$action = 'delete';
						}
					else {
						&pppstr(226, $a_url );
						$pagedata{'lastindex'} = $::private{'script_start_time'};
						$action = 'update';
						}
					}
				else {
					$action = 'preserve';
					}
				$getnext = 2;
				}
			elsif (($a_url lt $i_url) or ($index_is_done)) {
				$getnext = 1;
				my $index_url = '';
				($record_err, $index_url) = &pagedata_from_file( $a_file, $a_url, \%pagedata, \$fr );
				if ($record_err) {
					&ppstr(29, &he($a_url) . ' - ' . $record_err);
					print "\n\n";
					}
				else {
					&pppstr(227, &he($a_url) );
					$pagedata{'lastindex'} = $::private{'script_start_time'};
					$action = 'insert';
					$crawler_results{$index_url} = \%valid;
					}
				}
			elsif ($a_url gt $i_url) {
				&pppstr(228, &he($i_url) );
				$getnext = 0;
				$action = 'delete';
				$crawler_results{$a_url} = \%invalid;
				}

			if ($action) {
				eval $code{$action};
				die $@ if $@;
				if ($::private{'embedded_err_msg'}) {
					$err = $::private{'embedded_err_msg'};
					next Err;
					}
				}
			}

		$err = $gf->quit(0);
		next Err if ($err);

		$is_complete = 1;

		if ($write_err) {
			&ppstr(29, $write_err );
			eval $code{'abort'};
			die $@ if $@;
			if ($::private{'embedded_err_msg'}) {
				$err = $::private{'embedded_err_msg'};
				next Err;
				}
			last Err;
			}

		eval $code{'finish'};
		die $@ if $@;
		if ($::private{'embedded_err_msg'}) {
			$err = $::private{'embedded_err_msg'};
			next Err;
			}

		$err = &SaveLinksToFileEx( $p_realm_data, \%crawler_results );
		next Err if ($err);

		$err = $::realms->setpagecount( $$p_realm_data{'name'}, $pagecount, 1 );
		next Err if ($err);

		&ppstr(174, $::str[229] );

		last Err;
		}
	return ($err, $is_complete);
	}





sub BuildIndex {
	my ($p_realm_data) = @_;
	my $is_complete = 0;
	my $err = '';
	Err: {
		my $start_pos = 0;
		if (($::FORM{'StartFile'}) and ($::FORM{'StartFile'} =~ m!^\d+$!s)) {
			$start_pos = $::FORM{'StartFile'};
			}

		# These hashes are used later to update pending.txt via SaveLinksToFileEx

		my %crawler_results = ();
		my %valid = ('is_error' => 0);
		my %invalid = ('is_error' => 1);

		# This loads the generic realm update code, which will be eval'ed:

		my $i_line = $start_pos;
		my %code = ();
		&realm_interact( $p_realm_data, \%code );
		my ($obji, $p_rhandlei, $p_whandlei, $record, $record_err, $pagecount, $write_err) = ();

		if ($start_pos > 0) {
			eval $code{'resume'};
			if ($::private{'embedded_err_msg'}) {
				$err = $::private{'embedded_err_msg'};
				next Err;
				}
			}
		else {
			eval $code{'init'};
			if ($::private{'embedded_err_msg'}) {
				$err = $::private{'embedded_err_msg'};
				next Err;
				}
			}
		die $@ if $@;

		$| = 1;


		&pppstr(391, $$p_realm_data{'html_name'} );

		my $fr = &fdse_filter_rules_new($p_realm_data);


		&pppstr(487, &he($::Rules{'ext'}), "$::const{'admin_url'}&amp;Action=GeneralRules&amp;Edit=Ext" );


		my $gf = &GetFiles_new();

		$err = $gf->create_file_list(
			'base_dir'     => $$p_realm_data{'base_dir'},
			'base_url'     => $$p_realm_data{'base_url'},
			'fr'           => \$fr,
			'tempfile'     => $$p_realm_data{'file'} . ".temp_file_list.txt",
			'use_existing' => 1,
			'verbose'      => 1,
			);
		next Err if ($err);

		$::FORM{'TotalValidFiles'} = $gf->{'count'};

		&pppstr(224, $::FORM{'TotalValidFiles'}, $$p_realm_data{'base_dir'} );

		if ($start_pos) {
			&pppstr(230, $start_pos );
			$gf->resume_file_position( $start_pos );
			}
		else {
			print "<p>$::str[231]</p>";
			}

		$::FORM{'truecount'} = 0 unless ($::FORM{'truecount'});

		my $NextLink = "$::const{'admin_url'}&amp;Action=rebuild&amp;TotalValidFiles=$::FORM{'TotalValidFiles'}&amp;Realm=$$p_realm_data{'url_name'}";

		&pppstr(192, qq!<a href="$NextLink&amp;truecount=$::FORM{'truecount'}&amp;StartFile=$start_pos&amp;b_timeout=1">$::str[193]</a>! );

		my $infile_count = $start_pos;
		my $success_count = $start_pos;

		my $intro = <<"EOM";

<table border="1" cellpadding="4" cellspacing="1" width="100%">
<tr>
	<th width="10%">$::str[113]</th>
	<th width="10%">$::str[153]</th>
	<th width="30%">$::str[369]</th>
	<th width="50%">$::str[74]</th>
</tr>

EOM


		my $b_table_open = 0;

		my ($lastmodt, $size, $abs_file, $basename, $URL) = ();

		while (1) {
			($lastmodt, $size, $abs_file, $basename, $URL) = $gf->get_next_file();
			$infile_count++;
			last unless ($URL);

			if ((0 == $b_table_open) and (not $::const{'is_cmd'})) {
				print $intro;
				$b_table_open = 1;
				}

			my %pagedata = ();
			my $index_url = '';

			($err, $index_url) = &pagedata_from_file( $abs_file, $URL, \%pagedata, \$fr );
			if ($err) {
				# Is Error...
				if ($::const{'is_cmd'}) {
					print "$::str[73]: '$basename' - $err.\n";
					}
				else {
					print qq!<tr><td colspan="4" class="fdtan"><b>$::str[73]:</b> '$basename' - $err.</td></tr>\n!;
					}
				next;
				}

			my $html_Size = &FormatNumber( $pagedata{'size'}, 0, 1, 0, 1, $::Rules{'ui: number format'} );
			my $fileage = &get_age_str( time() - $pagedata{'lastmodtime'} );


			if ($::const{'is_cmd'}) {
				print "URL $URL...\n";
				}
			else {
				my @var = &he($basename,$URL);

print <<"EOM";

<tr class="fdtan">
	<td align="right" nowrap="nowrap">$fileage</td>
	<td align="right" nowrap="nowrap">$html_Size bytes</td>
	<td>$var[0]</td>
	<td>$var[1]</td>
</tr>

EOM
				}

			$crawler_results{$index_url} = \%valid;

			eval $code{'insert'};
			die $@ if $@;
			if ($::private{'embedded_err_msg'}) {
				$err = $::private{'embedded_err_msg'};
				next Err;
				}
			last if ($write_err);

			$success_count++;
			$::FORM{'truecount'}++;

			my $duration = time() - $::private{'script_start_time'};


			if ($::Rules{'timeout'}) {
				last if ($duration > $::Rules{'timeout'});
				}

			if (($::FORM{'TotalValidFiles'}) and (0 == $success_count % 10) and (not $::const{'is_cmd'})) {

				my $percent = &FormatNumber( 100 * $success_count / $::FORM{'TotalValidFiles'}, 2, 1, 0, 1, $::Rules{'ui: number format'} );
				$| = 1;
				print "</table>";
				$b_table_open = 0;
				&pppstr(233, "$percent%", $success_count, $::FORM{'TotalValidFiles'}, $duration, $::Rules{'timeout'} );
				$| = 0;
				}

			}
		print '</table>' if ($b_table_open);

		if ($write_err) {
			$err = $gf->quit(0);
			next Err if ($err);

			&ppstr(29, $write_err );
			eval $code{'abort'};
			die $@ if $@;
			if ($::private{'embedded_err_msg'}) {
				$err = $::private{'embedded_err_msg'};
				next Err;
				}
			last Err;
			}
		elsif ($infile_count < ($::FORM{'TotalValidFiles'} - 1)) {
			$err = $gf->quit(1);
			next Err if ($err);

			eval $code{'suspend'};
			die $@ if $@;
			if ($::private{'embedded_err_msg'}) {
				$err = $::private{'embedded_err_msg'};
				next Err;
				}
			$NextLink .= "&amp;truecount=$::FORM{'truecount'}&amp;StartFile=$infile_count";

			my $advice = &pstr(211, $::Rules{'time interval between restarts'}, $NextLink );

print <<"EOM";

<meta http-equiv="refresh" content="$::Rules{'time interval between restarts'};URL=$NextLink" />
<p><b>$::str[210]:</b></p>
<blockquote>
	<p>$advice</p>
</blockquote>

EOM

			&pppstr(105, &FormatNumber( $::FORM{'truecount'}, 0, 1, 0, 1, $::Rules{'ui: number format'} ) );
			}
		else {
			$err = $gf->quit(0);
			next Err if ($err);


			eval $code{'finish'};
			die $@ if $@;
			if ($::private{'embedded_err_msg'}) {
				$err = $::private{'embedded_err_msg'};
				next Err;
				}
			$err = $::realms->setpagecount($$p_realm_data{'name'}, $::FORM{'truecount'}, 1);
			delete $::FORM{'truecount'};
			next Err if ($err);
			&ppstr(174, $::str[229] );
			$is_complete = 1;
			}
		$err = &SaveLinksToFileEx( $p_realm_data, \%crawler_results );
		next Err if ($err);
		&pppstr(232, time() - $::private{'script_start_time'} );
		last Err;
		}
	return ($err, $is_complete);
	}





sub AdminVersion {
	my %pagedata = @_;

	my $ue_url = &ue( $pagedata{'url'} );
	my $type = 1;
	my $ue_realm = '';

	my ($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
	if ((not $err) and ($p_realm_data)) {
		$ue_realm = $$p_realm_data{'url_name'};
		$type = $$p_realm_data{'type'};
		}

	if ($type == 5) {
		# runtime -
		$pagedata{'admin_options'} = '';
		}
	elsif ($type == 4) {
		# file-system; edit, delete, no crawl

	$pagedata{'admin_options'} = <<"EOM";

[ <a href="$::const{'admin_url'}&amp;Action=Edit&amp;URL=$ue_url&amp;Realm=$ue_realm">$::str[411]</a> |
 <a href="$::const{'admin_url'}&amp;Action=DeleteRecord&amp;URL=$ue_url&amp;Realm=$ue_realm" onclick="return confirm('$::str[108]');">$::str[430]</a> ]

EOM

		}
	else {

	$pagedata{'admin_options'} = <<"EOM";

[ <a href="$::const{'admin_url'}&amp;Action=Edit&amp;URL=$ue_url&amp;Realm=$ue_realm">$::str[411]</a> |
 <a href="$::const{'admin_url'}&amp;Action=AddURL&amp;URL=$ue_url&amp;Realm=$ue_realm">$::str[444]</a> |
 <a href="$::const{'admin_url'}&amp;Action=DeleteRecord&amp;URL=$ue_url&amp;Realm=$ue_realm" onclick="return confirm('$::str[108]');">$::str[430]</a> ]

EOM
		}

	$pagedata{'redirector'} = "$::const{'script_name'}?NextLink=";

	return &StandardVersion(%pagedata);
	}





sub ui_ReviewIndex {
	my $err = '';
	Err: {

		my $p_realm_data = ();
		($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
		next Err if ($err);

		my $start_pos = $::FORM{'Start'} || 1;
		my $max_results_to_show = $::Rules{'crawler: max pages per batch'};

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	$::str[154] '$$p_realm_data{'html_name'}'
</div>

EOM

		my %crawler_results = ();
		$err = &query_realm( $$p_realm_data{'name'}, '', $start_pos - 1, $max_results_to_show, \%crawler_results);
		next Err if ($err);

		my $URL = '';

		my $total = $start_pos - 1 + scalar (keys %crawler_results);

		my $linkhits = "$::const{'admin_url'}&amp;Realm=$$p_realm_data{'url_name'}&amp;Action=Review&amp;Start=";

		my $b_is_exact_count = 1;
		my $maximum = $$p_realm_data{'pagecount'};
		if (($total) and (not ($$p_realm_data{'pagecount'}))) {
			$maximum = $total;
			$b_is_exact_count = 0;
			}

		my ($jump_sum, $jumptext) = &str_jumptext( $start_pos, $max_results_to_show, $maximum, $linkhits, $b_is_exact_count );

		my $Count = $start_pos;

		my $nresults = scalar (keys %crawler_results);
		if ($nresults) {


			print $jump_sum;
			print $jumptext;

			foreach (sort (keys %crawler_results)) {
				my $p_data = $crawler_results{$_};
				$$p_data{'rank'} = $Count;
				print &AdminVersion(%$p_data);
				$Count++;
				}

			print $jump_sum;
			print $jumptext;

			}
		else {
			print "<p>$::str[235]</p>\n";
			}

		if ($Count < ($start_pos + $max_results_to_show)) {
			print "<p><b>$::str[236]:</b> $::str[238].</p>\n";
			}
		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	}





sub ui_UserInterface {
	my $err = '';
	Err: {
		local $_;

		my $subaction = $::FORM{'subaction'} || '';

		my %subactions = (
			'' => $::str[152],
			'EditTemplate' => $::str[411],
			'SaveTemplate' => $::str[362],
			'SaveSettings' => $::str[362],
			'Write' => $::str[362],

			'IL' => $::str[351],

			);

		if (defined($subactions{$subaction})) {
			print qq!<div class="breadcrumbs"><a href="$::const{'admin_url'}">$::str[96]</a> <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=UserInterface">$::str[165]</a> <span class="gt">&rarr;</span> $subactions{$subaction}</div>\r\n!;
			}

		my %name_to_file = (
			'Link Line 1' => 'linkline1.txt',
			'Link Line 2' => 'linkline2.txt',
			'Line Listing' => 'line_listing.txt',
			'Main Footer' => 'footer.htm',
			'Main Header' => 'header.htm',
			'Search Form' => 'searchform.htm',
			'Search Tips' => 'tips.htm',
			'Style Sheet' => 'style.inc',
			);

		my %name_to_desc = (
			'Line Listing' => $::str[237],
			'Main Footer' => $::str[239],
			'Main Header' => $::str[240],
			'Search Form' => $::str[241],
			'Search Tips' => $::str[242],
			'Style Sheet' => $::str[243],
			'Link Line 1' => $::str[171],
			'Link Line 2' => $::str[169],
			);


		if ($subaction eq 'IL') {
			# install language pack...

			my @langfiles_over = (
				'admin_ads.txt',
				'admin_fr.txt',
				'admin_fr2.txt',
				'admin_pass1.txt',
				'admin_pass2.txt',
				'admin_personal.txt',
				'admin_ui.txt',
				'strings.txt',
				);

			my @langfiles_preserve_old = (
				'linkline1.txt',
				'linkline2.txt',
				'searchform.htm',
				'tips.htm',
				);

			my $foldername = $::FORM{'fn'};
			if ($foldername =~ m!\W!s) {
				$err = &pstr(350,&he($foldername));
				next Err;
				}

			unless (-d "templates/$foldername") {
				unless (mkdir("templates/$foldername",0777)) {
					$err = &pstr(349,&he("templates/$foldername"),$!);
					next Err;
					}
				chmod(0777, "templates/$foldername"); # for good measure - sometimes needed
				}

			&pppstr(347, &pstr(346, $foldername, $::VERSION));

			my $base_path = "http://www.xav.com/latest/translator/$::VERSION/$foldername";


			# temporarily set some overrides
			$::Rules{'crawler: rogue'} = 1;
			$::Rules{'max characters: file'} = &max($::Rules{'max characters: file'},16777216);
			$::Rules{'crawler: max redirects'} = 6;
			$::Rules{'minimum page size'} = 0;
			my $crawler = &Crawler_new();

			my $langfile;
			foreach $langfile (@langfiles_over) {
				print "<p>-&gt; $::str[195] $langfile...</p>\n";
				my %webrq = $crawler->webrequest( "page" => "$base_path/$langfile" );
				if ($webrq{'err'}) {
					&ppstr(29, $webrq{'err'} );
					&pppstr(345, $base_path, "searchdata/templates/$foldername");
					last Err;
					}
				$err = &WriteFile( "templates/$foldername/$langfile", $webrq{'text'} );
				next Err if ($err);
				}

			foreach $langfile (@langfiles_preserve_old) {
				if (-e "templates/$foldername/$langfile") {
					&pppstr(347, &pstr(344, $langfile));
					next;
					}
				print "<p>-&gt; $::str[195] $langfile...</p>\n";
				my %webrq = $crawler->webrequest( "page" => "$base_path/$langfile" );
				if ($webrq{'err'}) {
					&ppstr(29, $webrq{'err'} );
					&pppstr(345, $base_path, "searchdata/templates/$foldername");
					last Err;
					}
				$err = &WriteFile( "templates/$foldername/$langfile", $webrq{'text'} );
				next Err if ($err);
				}
			&ppstr(174, &pstr(343, $foldername));

			my $cache = 'valid_languages_cache.txt';
			if (-e $cache) {
				unlink($cache);
				}

			last Err;
			}

		if ($subaction eq 'EditTemplate') {

			my $template = $::FORM{'template'};
			my $html_template = &he( $template );

			unless ($name_to_file{ $template }) {
				$err = &pstr(244, $html_template );
				next Err;
				}

			my $text = '';

			my $file = '';
			if (-e "templates/$::Rules{'language'}/$name_to_file{ $template }") {
				$file = "templates/$::Rules{'language'}/$name_to_file{ $template }";
				}
			elsif (-e "templates/$name_to_file{ $template }") {
				$file = "templates/$name_to_file{ $template }";
				}
			else {
				$err = &pstr(245, $name_to_file{ $template } );
				next Err;
				}

			($err, $text) = &ReadFile( $file );
			next Err if ($err);

			# Collapse multiple line breaks:
			$text =~ s!\015\012!\012!sg;
			$text =~ s!\015!\012!sg;
			$text =~ s!\012+!\n!sg;

			$text = &he( $text );

			my $html_file = &he( $file );

			my $descr = &pstr(246, $html_template, $html_file );

print <<"EOM";

$::const{'AdminForm'}
<input type="hidden" name="Action" value="UserInterface" />
<input type="hidden" name="subaction" value="SaveTemplate" />
<input type="hidden" name="template" value="$html_template" />

<p>$descr</p>
<p><textarea name="filetext" rows="20" cols="95">$text</textarea></p>

<p><input type="submit" class="submit" value="$::str[362]" /></p>
<p><br /></p>

</form>

<p>Click here to <a href="http://www.xav.com/cgi-sys/cgiwrap/xav/fdseddt.cgi?version=$::VERSION&amp;language=$::Rules{'language'}&amp;template=$name_to_file{ $template }" target="_blank">view the default text</a> for this template (offsite link; opens in new window).</p>

EOM


			last Err;
			}
		elsif ($subaction eq 'SaveTemplate') {

			if ($::private{'is_demo'}) {
				&ppstr(53, $::str[435] );
				last Err;
				}

			my $template = $::FORM{'template'};

			unless ($name_to_file{ $template }) {
				$err = &pstr(244, &he($template) );
				next Err;
				}

			my $file = "templates/$::Rules{'language'}/$name_to_file{ $template }";

			if ((-e "templates/$name_to_file{ $template }") and (not (-e $file))) {
				$file = "templates/$name_to_file{ $template }";
				}
			$err = &WriteFile( $file, $::FORM{'filetext'} );
			next Err if ($err);
			&ppstr(174, &pstr(469,$name_to_file{$template}));
			last Err;
			}
		elsif ($subaction eq 'SaveSettings') {
			if ($::private{'is_demo'}) {
				&ppstr(53, $::str[435] );
				last Err;
				}

			my $old_lang = $::Rules{'language'};
			my $new_lang = $::FORM{'language'};

			$::FORM{'ui: search form display'} = 2 * $::FORM{'sfp2'} + $::FORM{'sfp1'};

			foreach ('language', 'ui: number format', 'ui: date format','ui: search form display') {
				if (not defined($::FORM{$_})) {
					$err = "invalid argument - required parameter '$_' is not defined";
					next Err;
					}
				$err = &WriteRule($_, $::FORM{$_});
				next Err if ($err);
				}

			if ($old_lang ne $new_lang) {
				&ppstr( 174, &pstr(357, &he( $old_lang, $new_lang ) ) );
				}

			&ppstr(174,$::str[114]);
			last Err;
			}
		elsif ($subaction eq 'SS2') {
			print qq!<div class="breadcrumbs"><a href="$::const{'admin_url'}">$::str[96]</a> <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=UserInterface">$::str[165]</a> <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=UserInterface&amp;subaction=viewmap">$::str[473]</a> <span class="gt">&rarr;</span> $::str[362]</div>\r\n!;

			if ($::private{'is_demo'}) {
				&ppstr(53, $::str[435] );
				last Err;
				}

			my $b_need_rebuild = 0;

			foreach ('character conversion: accent insensitive', 'character conversion: case insensitive') {
				$b_need_rebuild = 1 if ($::Rules{$_} ne $::FORM{$_});
				$err = &WriteRule($_, $::FORM{$_});
				next Err if ($err);
				}
			&ppstr(174,$::str[114]);
			print '<P>' . $::str[109] . '</P>' if ($b_need_rebuild);
			last Err;
			}
		elsif ($subaction eq 'viewmap') {

			print qq!<div class="breadcrumbs"><a href="$::const{'admin_url'}">$::str[96]</a> <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=UserInterface">$::str[165]</a> <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=UserInterface&amp;subaction=viewmap">$::str[473]</a></div>\r\n!;

			my $ex = '&' . 'uuml';

print &SetDefaults(<<"EOM",\%::Rules);

<p><b>$::str[473]</b> (<a href="$::const{'help_file'}1095.html" target="_blank">$::str[432]</a>)</p>

$::const{'AdminForm'}
<input type="hidden" name="Action" value="UserInterface" />
<input type="hidden" name="subaction" value="SS2" />

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2">$::str[481]</th>
	<th>$::str[60]</th>
</tr>
<tr class="fdtan">
	<td><input type="radio" name="character conversion: accent insensitive" value="1" id="ccai_1" /></td>
	<td><label for="ccai_1">$::str[59]</label></td>
	<td>m$ex;ller == mueller</td>
</tr>
<tr class="fdtan">
	<td><input type="radio" name="character conversion: accent insensitive" value="0" id="ccai_0" /></td>
	<td><label for="ccai_0">$::str[58]</label></td>
	<td>m$ex;ller != mueller</td>
</tr>
<tr>
	<th colspan="2">$::str[481]</th>
	<th>$::str[60]</th>
</tr>
<tr class="fdtan">
	<td><input type="radio" name="character conversion: case insensitive" value="1" id="ccci_1" /></td>
	<td><label for="ccci_1">$::str[57]</label></td>
	<td>Miller == miller</td>
</tr>
<tr class="fdtan">
	<td><input type="radio" name="character conversion: case insensitive" value="0" id="ccci_0" /></td>
	<td><label for="ccci_0">$::str[56]</label></td>
	<td>Miller != miller</td>
</tr>
</table>
<p><input type="submit" class="submit" value="$::str[362]" /></p>
</form>


<p>$::str[485]</p>
<ol>
	<li><p>$::str[484]</p></li>
	<li><p>$::str[483]</p></li>
</ol>
<p>$::str[482]</p>


EOM


			&create_conversion_code(1);
			last Err;
			}

		print "<p><b>$::str[163]</b></p>\n";
		print "<p>$::str[164]</p>\n";

		$err = &ui_GeneralRules( $::str[165], 'UserInterface',
			'default match',
			'default search terms',
			'default substring match',
			'hits per page',
			'show examples: enable',
			'show examples: number to display',
			'handling url search terms',
			'sorting: randomize equally-relevant search results',
			'sorting: default sort method',
			'sorting: time sensitive',
			'user language selection',
			);
		next Err if ($err);

		my %support_lang = (
			'ar' => '&#1575;&#1604;&#1593;&#1585;&#1576;&#1610;&#1577;',
			'bs' => 'Bosanski',
			'dutch' => 'Nederlands',
			'english' => 'English',
			'fi' => 'Finnish',
			'french' => 'Fran&#231;ais',
			'german' => 'Deutsch',
			'italian' => 'Italiano',
			'lv' => 'Latviski',
			'nb' => 'Norsk-bokm&#229;l',
			'portuguese' => 'Portugu&#234;s',
			'ro' => 'Romanian',
			'ru' => '&#1068;&#1103;&#1101;&#1101;&#1094;&#1092;&#1093;',
			'sl' => 'Slovenski',
			'spanish' => 'Espa&#241;ol',
			'sr' => 'Srpski',
			'sv' => 'Svenska',
			'tl' => 'Tagalog',
			'tr' => '&#84;&#252;&#114;&#107;&#231;&#101;',
			);

		my $lang_opt = '';
		if (opendir(DIR, 'templates')) {
			my @folders = sort readdir(DIR);
			closedir(DIR);
			foreach (@folders) {
				next unless (-e "templates/$_/strings.txt");
				unless (open(FILE, "<templates/$_/strings.txt" )) {
					&ppstr(29, &pstr(44, "templates/$_/strings.txt", $! ) );
					next;
					}
				my ($ver, $selfname) = (<FILE>, <FILE>);
				close(FILE);
				if ($ver =~ m!^VERSION $::VERSION!s) {
					$lang_opt .= qq!<input type="radio" name="language" value="$_" id="lang_$_" /><label for="lang_$_"> $selfname / $_</label><br />!;
					delete $support_lang{$_};
					}
				else {
					$lang_opt .= qq![<a href="$::const{'admin_url'}&amp;Action=UserInterface&amp;subaction=IL&amp;fn=$_" class="onbrown">$::str[340]</a>]  !;
					$lang_opt .= "$selfname / $_<br />" . &pstr(341,$ver) . "<br />";
					delete $support_lang{$_};
					}
				}
			}
		foreach (sort keys %support_lang) {
			$lang_opt .= qq![<a href="$::const{'admin_url'}&amp;Action=UserInterface&amp;subaction=IL&amp;fn=$_" class="onbrown">$::str[340]</a>] !;
			$lang_opt .= "$support_lang{$_} / $_<br />";
			$support_lang{$_} = 0;
			}


		my $abs_url = &get_absolute_url();
		my $code = &str_search_form( $abs_url );

		# Collapse multiple line breaks:
		$code =~ s!\015\012!\012!sg;
		$code =~ s!\015!\012!sg;

		my $template_list = '';
		foreach (sort keys %name_to_desc) {
			my $url_name = &ue( $_ );
			my $lang = $::Rules{'language'};
			my $basefile = $name_to_file{ $_ };
			unless (-e "templates/$::Rules{'language'}/$basefile") {
				$lang = '-';
				}
			$template_list .= qq!<tr class="fdtan"><td align="center"><a href="$::const{'admin_url'}&amp;Action=UserInterface&amp;subaction=EditTemplate&amp;template=$url_name" class="onbrown"><b>$_</b></a></td><td align="center">$lang</td><td>$name_to_desc{$_}<br /></td></tr>\n!;
			}

print <<"EOM";

$::const{'AdminForm'}
<input type="hidden" name="Action" value="UserInterface" />
<input type="hidden" name="subaction" value="SaveSettings" />

EOM

		my %defaults = %::const;
		$defaults{'html_language_options'} = $lang_opt;
		$defaults{'html_templates'} = $template_list;


		$::Rules{'search_code'} = $code;
		$::Rules{'simple_code'} = <<"EOM";
<form method="get" action="$abs_url">
	<label for="fdse_TermsEx">$::str[470] </label><input name="Terms" id="fdse_TermsEx" />
	<input type="submit" value="$::str[315]" />
</form>
EOM
		if ($::Rules{'default search terms'}) {
			my $ht = &he($::Rules{'default search terms'});
			$::Rules{'simple_code'} =~ s!name="Terms"!name="Terms" value="$ht"!s;
			}


		$::Rules{'link_code'} = '<p>' . $::str[470] . " <a href=\"$abs_url?Terms=" . &ue($::str[46]) . "\">$::str[46]</a>" . '</p>';

		$defaults{'html_search_code'} = $code;
		$defaults{'html_simple_code'} = $::Rules{'simple_code'};
		$defaults{'html_link_code'} = $::Rules{'link_code'};
		my $text = &PrintTemplate( 1, 'admin_ui.txt', $::Rules{'language'}, \%defaults );
		$::Rules{'sfp1'} = $::Rules{'ui: search form display'} % 2;
		$::Rules{'sfp2'} = ($::Rules{'ui: search form display'} < 2) ? 0 : 1;
		print &SetDefaults($text, \%::Rules);
		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	}





sub save_custom_metadata {
	my ($url, %metadata) = @_;
	my $err = '';
	Err: {

		unless ($::Rules{'use dbm routines'}) {
			$err = $::str[328];
			next Err;
			}

		eval {
			my %custom = ();
			dbmopen( %custom, 'custom_metadata', 0666 ) || die &pstr( 43, 'custom_metadata', $! );
			if (%metadata) {
				my $str = '';
				my @pairs = ();
				foreach (keys %metadata) {
					push(@pairs, "$_=" . &ue($metadata{$_}) );
					}
				$str = join( ' ', @pairs );
				$custom{$url} = $str;
				}
			else {
				delete $custom{$url};
				}
			dbmclose( %custom );
			};
		if ($@) {
			$err = &pstr(20, &he($@), "$::const{'help_file'}1169.html" );
			}
		last Err;
		}
	return $err;
	}



sub ui_EditRecord {
	my $err = '';
	Err: {
		my $sa = $::FORM{'sa'} || '';

		if ($sa eq 'save_all') {


print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit&amp;sa=$sa">Persist All Metadata</a>
	<span class="gt">&rarr;</span>
	$::str[362]
</div>

EOM

			unless ($::Rules{'use dbm routines'}) {
				$err = $::str[328];
				next Err;
				}

			eval {
				my %custom = ();
				dbmopen( %custom, 'custom_metadata', 0666 ) || die &pstr( 43, 'custom_metadata', $! );

				my $p_realm;
				foreach $p_realm ($::realms->listrealms('has_index_data')) {

					my $count = 0;

					print "<p><b>Status:</b> opening realm $p_realm->{'html_name'}.</p>\n";
					open(FILE, "<$p_realm->{'file'}") || die $!;
					binmode(FILE);
					while (defined($_ = <FILE>)) {
						next unless (m!^(\d\d)(\d\d)(\d\d)(\d\d\d\d)(\d+) (\d+) (\d+) u= (.+?) t= (.*?) d= (.*?) uM= (.*?) uT= (.*?) uD= (.*?) uK= (.*?) h=!s);
						my $url = $8;
						my %metadata = (
							'title' => $9,
							'description' => $10,
							'keywords' => $14,
							);
						my @pairs = ();
						foreach (keys %metadata) {
							push(@pairs, "$_=" . &ue($metadata{$_}) );
							}
						$custom{$url} = join( ' ', @pairs );
						$count++;
						}
					close(FILE);
					print "<p><b>Status:</b> finished with <b>$count</b> records.</p>\n";
					}
				dbmclose( %custom );
				};
			if ($@) {
				$err = &pstr(20, &he($@), "$::const{'help_file'}1169.html" );
				}
			else {
				print "<p><b>Success:</b> saved all metadata as persistent customizations.</p>\n";
				}
			last Err;
			}

		if ($sa eq 'delete_all') {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit&amp;sa=$sa">Delete All Customizations</a>
	<span class="gt">&rarr;</span>
	$::str[362]
</div>

EOM


			unless ($::Rules{'use dbm routines'}) {
				$err = $::str[328];
				next Err;
				}

			eval {
				my %custom = ();
				dbmopen( %custom, 'custom_metadata', 0666 ) || die &pstr( 43, 'custom_metadata', $! );
				%custom = ();
				dbmclose( %custom );
				};
			if ($@) {
				$err = &pstr(20, &he($@), "$::const{'help_file'}1169.html" );
				}
			else {
				print "<p><b>Success:</b> deleted all persistent customizations.</p>\n";
				}
			last Err;
			}



		if ($sa eq 'write') {

			my $p_realm_data = ();
			($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
			next Err if ($err);

			my ($old_url,$new_url) = ('', '');

			($err,$old_url) = &uri_parse($::FORM{'EditURL'});
			next Err if ($err);

			($err,$new_url) = &uri_parse($::FORM{'url'});
			next Err if ($err);

			my $uurl = &ue($new_url);

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit&amp;URL=$uurl&amp;Realm=$$p_realm_data{'url_name'}">$::str[324]</a>
	<span class="gt">&rarr;</span>
	$::str[362]
</div>

EOM



			foreach ('title','description','keywords') {
				$::FORM{$_} = '' unless (defined($::FORM{$_}));
				$::FORM{$_} =~ s!\r|\n|\=!!sg;

				$::FORM{$_} =~ s!\<!&lt;!sg;
				$::FORM{$_} =~ s!\>!&gt;!sg;
				$::FORM{$_} =~ s!\"!&quot;!sg;
				}

			my %crawler_results = ();
			my %pagedata;

			if ($old_url ne $new_url) {
				# Okay, they're doing a rename. well this is a little more tricky
				# lookup a full %pagedata hash on the old record
				# build a new insert %pagedata hash with the new meta-info
				# build a 'is_error' %pagedata hash forl the old url


				$err = &query_realm( $$p_realm_data{'name'}, quotemeta($old_url), 0, 1, \%crawler_results );
				next Err if ($err);
				unless ($crawler_results{$old_url}) {
					$err = &pstr(249,&he($old_url),$$p_realm_data{'html_name'} );
					next Err;
					}
				#end changes

				# updated record:
				my $p_pagedata = $crawler_results{$old_url};
				%pagedata = %$p_pagedata;

				$pagedata{'is_error'} = 0;
				$pagedata{'url'} = $new_url;
				$pagedata{'title'} = $::FORM{'title'};
				$pagedata{'description'} = $::FORM{'description'};
				$pagedata{'keywords'} = $::FORM{'keywords'};

				# kill record:
				my %kill = (
					'is_error' => 1,
					'url' => $old_url,
					);
				$crawler_results{ $old_url } = \%kill;
				}
			else {

				%pagedata = (
					'is_error' => 0,
					'is_update' => 1,

					'url' => $new_url,
					'new_url' => $new_url,
					'title' => $::FORM{'title'},
					'description' => $::FORM{'description'},
					'keywords' => $::FORM{'keywords'},
					);
				}


			$pagedata{'size'} = $::FORM{'size'};
			unless ($pagedata{'size'} =~ m!^\d+$!s) {
				$err = &pstr(69,'size',0,999999);
				next Err;
				}
			$pagedata{'promote'} = $::FORM{'promote'};
			unless ($pagedata{'promote'} =~ m!^\d+$!s) {
				$err = &pstr(69,'promote',1,99);
				next Err;
				}
			$crawler_results{$new_url} = \%pagedata;


			my ($total_records, $new_records, $updated_records, $deleted_records) = (0, 0, 0, 0);

			($err, $total_records, $new_records, $updated_records, $deleted_records) = &update_realm( $$p_realm_data{'name'}, \%crawler_results );
			next Err if ($err);

			&pppstr(289, $total_records, $$p_realm_data{'html_name'}, $new_records, $updated_records, $deleted_records );

my $html_code = &he(<<"EOM");

<html>
<head>
  <title>$pagedata{'title'}</title>
  <meta name="description" content="$pagedata{'description'}">
  <meta name="keywords" content="$pagedata{'keywords'}">
  ....
EOM

			&ppstr(53, $::str[252] );

print <<"EOM";

<p><form><textarea rows="8" cols="80" name="x">$html_code</textarea></form></p>

EOM

			last Err unless ($::Rules{'use dbm routines'});

			my %persist_meta = ();
			if ($::FORM{'persist_title'}) {
				$persist_meta{'title'} = $pagedata{'title'};
				}
			if ($::FORM{'persist_description'}) {
				$persist_meta{'description'} = $pagedata{'description'};
				}
			if ($::FORM{'persist_keywords'}) {
				$persist_meta{'keywords'} = $pagedata{'keywords'};
				}

			$err = &save_custom_metadata( $new_url, %persist_meta );
			next Err if ($err);
			last Err;
			}

		my $query_pattern = $::FORM{'query_pattern'};

		$query_pattern = defined($query_pattern) ? $query_pattern : '';
		my $html_query_pattern = &he( $query_pattern );

		if ($query_pattern) {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a>
	<span class="gt">&rarr;</span>
	$::str[263]
</div>

EOM


			$err = &check_regex($query_pattern);
			next Err if ($err);

			$query_pattern = ".*$query_pattern.*" unless ($query_pattern =~ m!\.\*!s);

			my $p_realm_data = ();
			($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
			next Err if ($err);


			my %crawler_results = ();
			$err = &query_realm( $$p_realm_data{'name'}, $query_pattern, 0, 1000000, \%crawler_results ); # changed 0072
			next Err if ($err);

			my @match_urls = sort (keys %crawler_results);

			my $query_count = scalar @match_urls;

			&pppstr(273, &he($query_pattern), $query_count );
			last Err if ($query_count == 0);

			my $x = 0;
			foreach (@match_urls) {
				$x++;
				print &AdminVersion(
					'rank' => $x,
					%{ $crawler_results{$_} },
					);

				}

			last Err;
			}

		if ($sa eq 'delete') {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit&amp;sa=list">$::str[323]</a>
	<span class="gt">&rarr;</span>
	$::str[95]
</div>

EOM

			unless ($::Rules{'use dbm routines'}) {
				$err = $::str[328];
				next Err;
				}


			local $_;
			foreach (keys %::FORM) {
				next unless (m!^del:(.+)$!s);
				my $url = $1;
				$err = &save_custom_metadata( $url );
				next Err if ($err);
				}

			&ppstr(174,$::str[267]);
			print $::str[322];
			last Err;
			}

		if ($sa eq 'list') {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit&amp;sa=list">$::str[323]</a>
	<span class="gt">&rarr;</span>
	$::str[152]
</div>

EOM

			unless ($::Rules{'use dbm routines'}) {
				$err = $::str[328];
				next Err;
				}

			eval {

				my %data_by_url = ();
				my %realm_by_url = ();

				dbmopen( %data_by_url, 'custom_metadata', 0666 ) || die &pstr( 43, 'custom_metadata', $! );

				my $count = scalar keys %data_by_url;

				my ($obj, $p_rhandle) = ();
				$obj = &LockFile_new(
					'create_if_needed' => 1,
					);
				($err, $p_rhandle) = $obj->Read('search.pending.txt');
				next Err if ($err);
				while (defined($_ = readline($$p_rhandle))) {
					next unless (m!^(\S+) (\S+) (\d+)(\r|\n|\015|\012)$!s);
					if ((defined($data_by_url{$1})) and ($3 > 2)) {
						$realm_by_url{$1} = $2;
						}
					}
				$err = $obj->Close();
				next Err if ($err);

				unless ($count) {
					print "<p>$::str[266]</p>\n";
					}
				else {

print <<"EOM";

$::const{'AdminForm'}
<input type="hidden" name="Action" value="Edit" />
<input type="hidden" name="sa" value="delete" />

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2">$::str[74]</th>
	<th colspan="2">Actions</th>
</tr>

EOM


					foreach (sort keys %data_by_url) {

						my $uurl = &ue($_);
						my $hurl = &he($_);

						if (defined($realm_by_url{$_})) {

print <<"EOM";

<tr class="fdtan">
	<td colspan="2">$hurl<br /></td>
	<td align="center"><a href="$::const{'admin_url'}&amp;Action=Edit&amp;URL=$uurl&amp;Realm=$realm_by_url{$_}" class="onbrown">$::str[411]</a></td>
	<td align="center"><input type="checkbox" name="del:$hurl" value="1" /></td>
</tr>


EOM


							}
						else {

print <<"EOM";

<tr class="fdtan">
	<td colspan="2">$hurl<br /></td>
	<td align="center">$::str[265]</td>
	<td align="center"><input type="checkbox" name="del:$hurl" value="1" checked="checked" /></td>
</tr>


EOM


							}

						my $data = $data_by_url{$_};
						foreach (sort (split(m! !s, $data))) {
							next unless (m!^(.+)=(.*?)$!s);
							my ($attrib, $value) = ($1, &he(&ud($2)));
print <<"EOM";

<tr class="fdtan">
	<td align="right">$attrib:</td>
	<td>$value<br /></td>
	<td colspan="2"><br /></td>
</tr>


EOM



							}
						}



print <<"EOM";

<tr class="fdtan">
	<td colspan="4" align="right"><input type="submit" class="submit" value="$::str[321]" /></td>
</tr>
</table>
</form>

EOM
					dbmclose( %data_by_url );
					print $::str[322];
					}

				};
			if ($@) {
				$err = &pstr(20, &he($@), "$::const{'help_file'}1169.html" );
				next Err;
				}


			last Err;
			}
		elsif (($::FORM{'URL'}) and ($::FORM{'URL'} ne 'http://')) {

			my $EditURL;
			($err,$EditURL) = &uri_parse($::FORM{'URL'});
			next Err if ($err);

			my $p_realm_data = ();
			($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
			next Err if ($err);


			my $uurl = &ue($EditURL);



print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit&amp;URL=$uurl&amp;Realm=$$p_realm_data{'url_name'}">$::str[324]</a>
	<span class="gt">&rarr;</span>
	$::str[152]
</div>

EOM




			my $file = $$p_realm_data{'file'};

			if ($$p_realm_data{'is_runtime'}) {
				$err = $::str[248];
				next Err;
				}

			my $pattern = quotemeta($EditURL);

			my %crawler_results = ();
			$err = &query_realm( $$p_realm_data{'name'}, $pattern, 0, 1, \%crawler_results );
			next Err if ($err);

			unless (%crawler_results) {
				$err = &pstr(249,&he($EditURL),$$p_realm_data{'html_name'} );
				next Err;
				}

			my $r_pagedata = $crawler_results{$EditURL};

			# this is just to set the checkbox defaults properly in the edit form...
			my %metadata = ();
			$err = &load_custom_metadata($EditURL, \%metadata);
			next Err if ($err);
			foreach ('title','description','keywords') {
				next unless (defined($metadata{$_}));
				$$r_pagedata{"persist_$_"} = 1;
				}





			print '<hr size="1" /><blockquote>';
			print &AdminVersion('rank' => 1, %$r_pagedata);
			print '</blockquote>';

print &SetDefaults(<<"EOM",$r_pagedata);

$::const{'AdminForm'}
<input type="hidden" name="Action" value="Edit" />
<input type="hidden" name="sa" value="write" />
<input type="hidden" name="Realm" value="$$p_realm_data{'html_name'}" />
<input type="hidden" name="EditURL" value="$EditURL" />

<hr size="1" />

<table border="0" cellpadding="4" cellspacing="0">
<tr>
	<td align="right"><b>$::str[250]:</b></td>
	<td><input name="title" size="60" onactivate="ch('fd_t');" /></td>
</tr>
<tr>
	<td align="right"><b>$::str[74]:</b></td>
	<td><input name="url" size="60" /></td>
</tr>
<tr>
	<td align="right"><b>$::str[153]:</b></td>
	<td><input name="size" size="8" maxlength="8" style="text-align:right" /> bytes</td>
</tr>
<tr>
	<td align="right"><b>$::str[251]:</b></td>
	<td><input name="promote" size="2" maxlength="2" style="text-align:right" /></td>
</tr>
<tr>
	<td align="right" valign="top"><b>$::str[45]:</b></td>
	<td><textarea name="description" rows="3" cols="60" onactivate="ch('fd_d');"></textarea></td>
</tr>
<tr>
	<td align="right" valign="top"><b>$::str[151]:</b></td>
	<td><textarea name="keywords" rows="3" cols="60" onactivate="ch('fd_k');"></textarea></td>
</tr>
<tr>
	<td><br /></td>
	<td><input type="submit" class="submit" value="$::str[362]" /></td>
</tr>
</table>

EOM

print &SetDefaults(<<"EOM",$r_pagedata) if ($::Rules{'use dbm routines'});

<hr size="1" />

<p>$::str[253]</p>

<table border="0">
<tr>
	<td align="right" width="120"><input type="checkbox" name="persist_title" value="1" id="fd_t" onactivate="quiet();" /></td>
	<td><b>$::str[250]</b></td>
</tr>
<tr>
	<td align="right"><input type="checkbox" name="persist_description" value="1" id="fd_d" onactivate="quiet();" /></td>
	<td><b>$::str[45]</b></td>
</tr>
<tr>
	<td align="right"><input type="checkbox" name="persist_keywords" value="1" id="fd_k" onactivate="quiet();" /></td>
	<td><b>$::str[151]</b></td>
</tr>
</table>
<script type="text/javascript">
<!--
var b_stop = false;
function quiet () {
	b_stop = true;
	}
function ch (on) {
	if ((!b_stop) && (document) && (document.all) && (document.all(on))) {
		document.all(on).checked = true;
		}
	}
//-->
</script>

EOM

print <<"EOM";


<hr size="1" />

</form>

<p>$::str[254]</p>
<p>$::str[255]</p>
<p>$::str[256]</p>

EOM
			}
		else {



print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=Edit">$::str[99]</a>
	<span class="gt">&rarr;</span>
	$::str[152]
</div>

EOM




			my ($count, $html_hidden, $html_tr) = $::realms->html_select_ex('has_index_data', '', 'fdtan', 120);
			unless ($count) {
				$err = $::str[257];
				next Err;
				}

print <<"EOM";

<p>$::str[258]</p>

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2">$::str[259]</th>
</tr>
<tr class="fdtan" valign="top">
	<td align="right" width="120"><b>$::str[161]:</b></td>
	<td>

EOM

my $p_temp_data = ();
foreach $p_temp_data ($::realms->listrealms('has_index_data')) {
	print "<a href=\"$::const{'admin_url'}&amp;Action=Review&amp;Realm=" . &ue( $$p_temp_data{'name'} ) . "\" class=\"onbrown\">" . &he( $$p_temp_data{'name'} ) . "</a> ($$p_temp_data{'pagecount'})<br />\n";
	}


print <<"EOM";

	</td>
</tr>
</table>

<p><br /></p>

$::const{'AdminForm'}
<input type="hidden" name="Action" value="Edit" />
$html_hidden

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2">$::str[260]</th>
</tr>
<tr class="fdtan">
	<td align="right"><b>$::str[261]:</b></td>
	<td><input name="query_pattern" /></td>
</tr>
$html_tr
</table>

<blockquote>
	<p><input type="submit" class="submit" value="$::str[263]" /></p>
</blockquote>

</form>

<p>$::str[264]</p>

EOM

			&pppstr(247, "$::const{'admin_url'}&amp;Action=Edit&amp;sa=list") if ($::Rules{'use dbm routines'});
			}


		last Err;
		}
	return $err;
	}





sub DeleteFromPending {
	my ($realm, $p_urls) = @_;
	my $delcount = 0;
	my $err = '';
	Err: {
		local $_;
		my $pattern = '^(';
		if (($p_urls) and ('ARRAY' eq ref($p_urls))) {
			foreach (@$p_urls) {
				$pattern .= quotemeta($_) . '|';
				}
			$pattern =~ s!\|$!!os;
			$pattern .= ') ';
			}
		else {
			$pattern .= '.*) ';
			}
		if ($realm) {
			$pattern .= quotemeta(&ue($realm));
			}
		else {
			$pattern .= '(\S+)';
			}
		$pattern .= ' \d+$';

		my ($obj, $p_rhandle, $p_whandle) = ();

		$obj = &LockFile_new(
			'create_if_needed' => 1,
			);
		($err, $p_rhandle, $p_whandle) = $obj->ReadWrite('search.pending.txt');
		next Err if ($err);
		while (defined($_ = readline($$p_rhandle))) {
			if (m!$pattern!os) {
				$delcount++;
				next;
				}
			print { $$p_whandle } $_;
			}
		$err = $obj->Merge();
		next Err if ($err);
		}
	return ($err, $delcount);
	}





sub ui_DeleteRecord {
	my $err = '';
	Err: {

		unless ($::FORM{'Realm'}) {



print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=DeleteRecord">$::str[95]</a>
	<span class="gt">&rarr;</span>
	$::str[152]
</div>

EOM


			my ($count, $html_hidden, $html_tr) = $::realms->html_select_ex('has_index_data', '', 'fdtan', 120);
			unless ($count) {
				$err = $::str[257];
				next Err;
				}

print <<"EOM";

<p>$::str[258]</p>

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2">$::str[259]</th>
</tr>
<tr class="fdtan" valign="top">
	<td align="right" width="120"><b>$::str[161]:</b></td>
	<td>

EOM

my $p_temp_data = ();
foreach $p_temp_data ($::realms->listrealms('has_index_data')) {
	print qq!<a href="$::const{'admin_url'}&amp;Action=Review&amp;Realm=$$p_temp_data{'url_name'}" class="onbrown">$$p_temp_data{'html_name'}</a> ($$p_temp_data{'pagecount'})<br />\n!;
	}


print <<"EOM";

	</td>
</tr>
</table>

<p><br /></p>

$::const{'AdminForm'}
<input type="hidden" name="Action" value="DeleteRecord" />
$html_hidden

<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th colspan="2">$::str[260]</th>
</tr>
<tr class="fdtan">
	<td align="right"><b>$::str[261]:</b></td>
	<td><input name="query_pattern" /></td>
</tr>
$html_tr
</table>

<blockquote>
	<p><input type="submit" class="submit" value="$::str[263]" /></p>
</blockquote>

</form>

<p>$::str[264]</p>

EOM
			last Err;
			}






		my @urls_to_delete = ();
		while (defined($_ = each %::FORM)) {
			next unless (m!^URL\d*$!s);
			push(@urls_to_delete, $::FORM{$_});
			}


		my $p_realm_data = ();
		($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
		next Err if ($err);

		my $query_pattern = $::FORM{'query_pattern'};

		$query_pattern = defined($query_pattern) ? $query_pattern : '';
		my $html_query_pattern = &he( $query_pattern );


		my %pagedata = ();
		my %crawler_results = ();


		if (@urls_to_delete) {



print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=DeleteRecord">$::str[95]</a>
	<span class="gt">&rarr;</span>
	$::str[430]
</div>

EOM


			my $URL = '';
			foreach $URL (@urls_to_delete) {
				my %pagedata = (
					'url' => $URL,
					'is_error' => 1,
					);
				$crawler_results{$URL} = \%pagedata;
				}
			my ($total_records, $new_records, $updated_records, $deleted_records) = (0, 0, 0, 0);
			($err, $total_records, $new_records, $updated_records, $deleted_records) = &update_realm( $$p_realm_data{'name'}, \%crawler_results );
			next Err if ($err);

			my $delcount = 0;
			($err, $delcount) = &DeleteFromPending( $$p_realm_data{'name'}, \@urls_to_delete );
			next Err if ($err);

			&ppstr(174, &pstr(178,$delcount,'search.pending.txt'));

			print "<blockquote>\n";
			foreach $URL (sort keys %crawler_results) {
				my $r_pagedata = $crawler_results{$URL};
				if ($$r_pagedata{'sub status msg'}) {
					print "URL '" . &he($URL) . "' - $$r_pagedata{'sub status msg'}<br />\n";
					}
				else {
					print "<b>$::str[73]:</b> ";
					&ppstr(249, &he($URL), $$p_realm_data{'html_name'} );
					print ".<br />\n";
					}
				}
			print "</blockquote>\n";
			&pppstr(289, $total_records, $$p_realm_data{'html_name'}, $new_records, $updated_records, $deleted_records );

			my $default_forbid_url = $urls_to_delete[0];
			if ($query_pattern) {
				$default_forbid_url = $query_pattern;
				}
			$default_forbid_url = &he($default_forbid_url);



			&ppstr(269, '<blockquote><tt>&lt;meta name="robots" content="none" /&gt;</tt></blockquote>', <<"EOM");
$::const{'AdminForm'}
<input type="hidden" name="Action" value="AddForbidSite" />
			<table border="0">
			<tr>
				<td><b>$::str[261]:</b></td>
				<td><input name="URL" value="$default_forbid_url" size="60" /></td>
			</tr>
			<tr>
				<td><br /></td>
				<td><input type="submit" class="submit" value="$::str[362]" /></td>
			</tr>
			</table>
</form>
EOM


			# did this guy just do a single deletion? advertise our new multiple delete feature:

			if ((1 == scalar @urls_to_delete) and (not $query_pattern)) {

				my $temp_url = $urls_to_delete[0];

				print "<p><b>$::str[270]</b></p>\n";

				my $x = 0;
				while (1) {
					$x++;
					last if ($x > 10);
					if ($temp_url =~ m!^http://(.*)/!s) {
						$temp_url = "http://$1";
						print "<p>$::str[271] <a href=\"$::const{'admin_url'}&amp;Action=DeleteRecord&amp;Realm=$$p_realm_data{'url_name'}&amp;query_pattern=" . &ue($temp_url) . "/.*\">" . &he($temp_url) . "/.*</a>.</p>\n";
						next;
						}
					last;
					}

				}



			last Err;
			}


		if ($query_pattern) {


print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=ManageRealms">$::str[327]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=DeleteRecord">$::str[95]</a>
	<span class="gt">&rarr;</span>
	$::str[263]
</div>

<p><b>$::str[272]</b></p>

EOM

			$err = &check_regex($query_pattern);
			next Err if ($err);

			$query_pattern = ".*$query_pattern.*" unless ($query_pattern =~ m!\.\*!s);

			my %crawler_results = ();

			$err = &query_realm( $$p_realm_data{'name'}, $query_pattern, 0, 1000000, \%crawler_results );
			next Err if ($err);

			my @kill_us = sort (keys %crawler_results);

			my $query_count = scalar @kill_us;

			&pppstr(273, &he($query_pattern), $query_count );
			last Err if ($query_count == 0);

print <<"EOM";

$::const{'AdminForm'}
<input type="hidden" name="Action" value="DeleteRecord" />
<input type="hidden" name="query_pattern" value="$html_query_pattern" />
<input type="hidden" name="Realm" value="$$p_realm_data{'name'}" />

<p>$::str[274]</p>

EOM

			my $x = 0;
			foreach (@kill_us) {
				$x++;
				my $hurl = &he($_);
				print qq!<input type="checkbox" name="URL$x" value="$hurl" checked="checked" /> $hurl<br />\n!;
				}

print <<"EOM";

<p>$::str[275]

<script type="text/javascript">
<!--
function ClearAll(state) {
	if (!(document && document.F1)) { return 1; }
EOM
for (1..$x) {
	print "\tif (document.F1.URL$_) {document.F1.URL$_.checked = state;}\n";
	}
print <<"EOM";
	}
document.write('<font size="-1">[ <a href="javascript:ClearAll(false)">$::str[397]</a> ] [ <a href="javascript:ClearAll(true)">$::str[398]</a> ]</font>');
//-->
</script>


</p>

<p><input type="submit" class="submit" value="$::str[321]" /></p>

</form>

EOM

			last Err;
			}


		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	}





sub s_CrawlEntireSite {
	local $_;
	my ($Realm) = @_;
	my @ReIndex = ();
	my ($Count, $Limit) = (0, 2 * $::Rules{'crawler: max pages per batch'});
	# limit is 2*; we send extra since URL's kicked out by first-pass filter rules aren't counted against total

	my $is_complete = 0;
	my $err = '';
	Err: {
		$::FORM{'LimitFailed'} = $::FORM{'LimitIndexed'} = $::FORM{'LimitPending'} = 0;
		my ($obj, $p_rhandle) = ();

		$obj = &LockFile_new();
		($err, $p_rhandle) = $obj->Read('search.pending.txt');
		next Err if ($err);

		my $matchRealm = quotemeta( &ue($Realm) );
		my $cutTime = $::FORM{'StartTime'};
		if ($::FORM{'DaysPast'}) {
			$cutTime -= (86400 * $::FORM{'DaysPast'});
			}

		my $qm_limit = $::FORM{'LimitPattern'};
		while (defined($_ = readline($$p_rhandle))) {
			next unless (m!^(.*?) $matchRealm (\d+)!s);
			my ($URL, $time) = ($1, $2);
			next unless ($URL =~ m!$qm_limit!is);
			if ($time == 2) {
				$::FORM{'LimitFailed'}++;
				}
			elsif ($time >= $cutTime) {
				$::FORM{'LimitIndexed'}++;
				}
			else {
				$::FORM{'LimitPending'}++;
				push(@ReIndex,$URL) unless ($Count > $Limit);
				$Count++;
				}
			}
		$err = $obj->Close();
		next Err if ($err);
		unless (@ReIndex) {
			&print_AddURL_nav_header( 0, $::FORM{'Action'} || '' );
			&ppstr(174, $::str[276] );
			$is_complete = 1;
			last Err;
			}

		$err = &s_AddURL(0, $Realm, @ReIndex);
		next Err if ($err);

		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	return ($err, $is_complete);
	}





sub ui_Rebuild {
	my $realm = $::FORM{'Realm'} || '';
	my ($err, $is_complete) = ('', 0);

	my $b_clear_err = 1;
	if ($::const{'is_cmd'}) {
		$::Rules{'timeout'} = 0; # no timeout in command-line rebuilds
		delete $::FORM{'LimitPattern'}; # changed 0062
		while (1) {
			($err, $is_complete) = &rebuild_realm( $realm, $b_clear_err );
			last if ($is_complete);
			$b_clear_err = 0; # don't rebuild on subsequent iterations
			last if ($err);
			}
		}
	else {
		# don't clear err if this looks like a secondary request in a multi-request rebuild...
		$b_clear_err = ((exists($::FORM{'PagesDone'})) or (exists($::FORM{'StartFile'}))) ? 0 : 1;
		&rebuild_realm( $realm, $b_clear_err );
		}
	}





sub rebuild_realm {
	my ($realm, $b_clear_err) = @_;
	my $is_complete = 0;
	my $err = '';
	Err: {
		local $_;
		$::FORM{'LimitFailed'} = $::FORM{'LimitIndexed'} = $::FORM{'LimitPending'} = 0;


		# Initialize and validate FORM-based integers:
		foreach ('StartTime') {
			$::FORM{$_} = 0 unless exists $::FORM{$_};
			next if ($::FORM{$_} =~ m!^\d+$!s);
			$err = "parameter '$_' not numeric";
			next Err;
			}
		foreach ('DaysPast') {
			$::FORM{$_} = 0 unless exists $::FORM{$_};
			next if (($::FORM{$_} =~ m!^\d*\.?\d*$!s) and ($::FORM{$_} ne '.'));
			$err = "parameter '$_' not numeric";
			next Err;
			}


		if ($::const{'is_cmd'}) {
			&pppstr(185, $realm );
			}
		else {
			print qq!<div class="breadcrumbs"><a href="$::const{'admin_url'}">$::str[96]</a> <span class="gt">&rarr;</span> !;
			&ppstr(185, &he($realm) );
			print "</div>\n";
			}

		my $p_realm_data = ();
		($err, $p_realm_data) = $::realms->hashref($realm);
		next Err if ($err);

		if ($b_clear_err) {
			# clear the error cache:
			my $error_lines = 0;
			($err, $error_lines) = &clear_error_cache();
			next Err if ($err);
			}

		# What does "rebuild" mean? Well, it depends on the type of realm we're dealing with:

		my $type = $$p_realm_data{'type'};

		if ($type == 5) { # runtime realm; all dynamic data, no index; cannot rebuild
			$err = &pstr(277, $$p_realm_data{'html_name'} );
			$is_complete = 1;
			next Err;
			}
		elsif ($type == 4) { # website realm w/ file system
			if ($::FORM{'DaysPast'}) {
				($err, $is_complete) = &UpdateIndex( $p_realm_data );
				}
			else {
				($err, $is_complete) = &BuildIndex( $p_realm_data );
				}
			next Err if ($err);
			last Err;
			}


		# Logic is different is we're rebuilding *all* pages or re-indexing old pages.
		# For website realms and filefed realms, a "rebuild" includes the full discovery process. A "re-index" only consists of re-indexing known pages that haven't been visited lately.
		# For "open" realms, the rebuild/re-index is essentially the same except for the time, since there is no discovery process for open realms.


		unless ($::FORM{'DaysPast'}) {

			# Okay this is a "rebuild":

			if ($type == 3) {

				# a website-realm which is handled via the crawler:
				unless ($::FORM{'LimitPattern'}) {
					unless ($::FORM{'StartTime'}) {
						$::FORM{'StartTime'} = $::private{'script_start_time'} - 5;
						}

					if ($$p_realm_data{'limit_pattern'}) {
						$::FORM{'LimitPattern'} = $$p_realm_data{'limit_pattern'};
						}
					else {
						$::FORM{'LimitPattern'} = '^' . quotemeta(&get_web_folder($$p_realm_data{'base_url'}));
						}

					$err = &s_AddURL(0, $$p_realm_data{'name'}, $$p_realm_data{'base_url'});
					next Err if ($err);

					last Err;
					}
				($err, $is_complete) = &s_CrawlEntireSite($$p_realm_data{'name'});
				next Err if ($err);
				last Err;
				}
			}

		if ($type == 2) {
			# ahh, a filefed realm

			# 4 steps:
			# 1. request start file and extract all links
			# 2. delete all entries from search.pending.txt; replace them with new links array, using code "10"
			# 3. delete all index data
			# 4. initiate normal "index-all-old-pages" process for this realm

			unless ($::FORM{'StartTime'}) {

				&pppstr(278, $$p_realm_data{'base_url'} );

				my @fresh_links = ();
				my $crawler = &Crawler_new();
				my @saved = ($::Rules{'crawler: follow query strings'}, $::Rules{'crawler: follow offsite links'}, $::Rules{'max characters: file'}, $::Rules{'crawler: rogue'});

				($::Rules{'crawler: follow query strings'}, $::Rules{'crawler: follow offsite links'}, $::Rules{'max characters: file'},
				$::Rules{'crawler: rogue'}) = (1, 1, &max($::Rules{'max characters: file'},16777216),1);

				my %Response = $crawler->webrequest( 'page' => $$p_realm_data{'base_url'} );

				if ($Response{'err'}) {
					$err = $Response{'err'};
					next Err;
					}

				my %pagedata = ();

				&parse_html_ex( $Response{'text'}, $Response{'final_url'}, 1, \@fresh_links, \%pagedata);

				($::Rules{'crawler: follow query strings'}, $::Rules{'crawler: follow offsite links'}, $::Rules{'max characters: file'}, $::Rules{'crawler: rogue'}) = @saved;

				my %fresh_uniq_links = ();
				foreach (@fresh_links) {
					$fresh_uniq_links{$_}++;
					}

				@fresh_links = sort (keys %fresh_uniq_links);
				my $count = scalar @fresh_links;

				my %expired_urls = ();

				&pppstr(279, $count );

				# delete all entries:
				my ($obj, $p_rhandle, $p_whandle) = ();

				$obj = &LockFile_new(
					'create_if_needed' => 1,
					);

				my %orig_times = ();

				($err, $p_rhandle, $p_whandle) = $obj->ReadWrite('search.pending.txt');
				next Err if ($err);

				my $i = 0;
				my $get_next = 1;
				my $file_done = 0;
				my ($u,$r,$c) = ();
				while (($file_done == 0) or ($fresh_links[$i])) {
					if (($get_next) and ($file_done == 0)) {
						if (defined($_ = readline( $$p_rhandle ))) {
							next unless (m!^(.*?) (\S+) (\d+)$!s);
							($u,$r,$c) = ($1, $2, $3);
							if ($r eq $$p_realm_data{'url_name'}) {
								if ($fresh_uniq_links{$u}) {
									# still valid

									if ($::FORM{'DaysPast'}) { # preserve original index times
										$orig_times{$u} = $c;
										}

									}
								else {
									$expired_urls{$u} = 1;
									}
								next;
								}
							}
						else {
							$file_done = 1;
							$_ = '';
							$u = 'z';
							}
						}
					$get_next = 1;
					if (($fresh_links[$i]) and ("$u $r" gt "$fresh_links[$i] $$p_realm_data{'url_name'}")) {

						my $timecode = defined($orig_times{$fresh_links[$i]}) ? $orig_times{$fresh_links[$i]} : 0;

						unless (print { $$p_whandle } "$fresh_links[$i] $$p_realm_data{'url_name'} $timecode\n") {
							$err = &pstr( 43, $obj->{'wname'}, $! );
							$obj->Cancel();
							next Err;
							}

						$i++;
						$get_next = 0;
						next;
						}
					unless (print { $$p_whandle } $_) {
						$err = &pstr( 43, $obj->{'wname'}, $! );
						$obj->Cancel();
						next Err;
						}
					}

				$err = $obj->Merge();
				next Err if ($err);

				# step 3 -- kill expired URL's

				# delete all expired entries:

				$obj = &LockFile_new(
					'create_if_needed' => 1,
					);

				($err, $p_rhandle, $p_whandle) = $obj->ReadWrite( $$p_realm_data{'file'} );
				next Err if ($err);

				while (defined($_ = readline( $$p_rhandle ))) {
					next unless (m!^.*? u= (.*?) t=!s);
					my $url = $1;
					next if ($expired_urls{$url});

					unless (print { $$p_whandle } $_) {
						$err = &pstr( 43, $obj->{'wname'}, $! );
						$obj->Cancel();
						next Err;
						}
					}

				$err = $obj->Merge();
				next Err if ($err);


				}
			}

		unless ($::FORM{'StartTime'}) {
			$::FORM{'StartTime'} = $::private{'script_start_time'} - 5;
			}

		my @list = ();
		my $count = 0;

		my $age = $::FORM{'StartTime'};
		if ($::FORM{'DaysPast'}) {
			$age -= (86400 * $::FORM{'DaysPast'});
			}

		$err = &GetCrawlList( $$p_realm_data{'name'}, $age, 2 * $::Rules{'crawler: max pages per batch'}, \@list, \$count );
		next Err if ($err);

		unless (@list) {
			# Well, we're done
			print "<p>$::str[280]</p>\n";
			$is_complete = 1;
			last Err;
			}

		$err = &s_AddURL(0, $$p_realm_data{'name'}, @list );
		next Err if ($err);

		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	return ($err, $is_complete);
	}





sub GetCrawlList {
	my ( $realm, $age, $max_list_size, $p_list, $p_count) = @_;

	my $err = '';
	Err: {
		local $_;

		#&Assert( 'ARRAY' eq ref( $p_list ) );
		#&Assert( 'SCALAR' eq ref( $p_count ) );

		my ($obj, $p_rhandle) = ();
		$obj = &LockFile_new(
			'create_if_needed' => 1,
			);
		($err, $p_rhandle) = $obj->Read('search.pending.txt');
		next Err if ($err);

		my $pattern = quotemeta( &ue( $realm ) );

		$$p_count = 0;
		while (defined($_ = readline($$p_rhandle))) {
			next unless (m!^(.*?) $pattern (\d+)!s);
			my ($URL, $time) = ($1, $2);
			if ($time == 2) {
				$::FORM{'LimitFailed'}++;
				}
			elsif ($time > $age) {
				$::FORM{'LimitIndexed'}++;
				}
			else {
				$::FORM{'LimitPending'}++;
				push(@$p_list, $URL) if ($$p_count < $max_list_size);
				$$p_count++;
				}
			}
		$err = $obj->Close();
		next Err if ($err);
		}
	return $err;
	}





sub Authenticate {
	my ($crypt_pass) = @_;




	my ($is_auth, $form_password, $url_password) = (1, '', '');

	my $sn = &query_env('SCRIPT_NAME');

	my $seed = 'sX';

	my $test_cookie = '0';

	my $session_lifetime = 60 * $::Rules{'security: session timeout'};
	my $grace_period = int($session_lifetime / 6);

	my %auth_tokens = ();

	my ($status_msg, $public_token) = ('','');


	my $pri_token = exists($::FORM{'CP'}) ? $::FORM{'CP'} : '';


	my $is_cookies_aware = 0;
	my $clear_cookie = 0;

	if (&query_env('HTTP_COOKIE') =~ m!fdse_cp=([^\;]+)!s) {
		$is_cookies_aware = 1;

		my $auth_cookie = &ud($1);
		if ($auth_cookie ne $test_cookie) {
			$pri_token = $auth_cookie;
			}

		}


	my $b_is_api = ((exists($ENV{'FDSE_NO_EXEC'})) and (not exists($ENV{'SERVER_SOFTWARE'})) and (not exists($ENV{'SCRIPT_NAME'})) and (not exists($ENV{'HTTP_HOST'}))) ? 1 : 0;
	if ($b_is_api) {
		$::const{'is_cmd'} = 1;
		}

	my $b_print_status_only = 0;

	Auth: {
	# next for auth failure:

		# changed 0063
		if (($b_is_api) and ($::private{'trust_api'})) {
			last Auth;
			}


		if ((exists($::FORM{'Action'})) and ($::FORM{'Action'} eq 'LogOut')) {
			$status_msg = &pstr(174,$::str[102]);
			if ($pri_token) {




				my $cpass = crypt($pri_token, $seed);
				if ($cpass eq '0') {
					my $temp_err_msg = "Perl crypt() function returned literal '0' - you have an incomplete Perl crypt installation. If you are running Lunix 2.2.16 with Perl 5.6.1, please upgrade with latest patches or downgrade to Perl 5.6.0";
					$status_msg = &pstr(29, "$::str[282] - '$temp_err_msg'" );
					next Auth;
					}





				delete $auth_tokens{$cpass};
				&write_tokens(%auth_tokens); # no error check
				}
			next Auth;
			}


		# Is the user setting a new password? - they will still return AUTH_FAIL, but this will set the text message to an appropriate value:
		unless ($crypt_pass) {
			if (($::FORM{'new_pass_1'}) or ($::FORM{'new_pass_2'})) {
				$::FORM{'new_pass_1'} = $::FORM{'new_pass_1'} || '';
				$::FORM{'new_pass_2'} = $::FORM{'new_pass_2'} || '';

				$crypt_pass = 1;

				if ($::FORM{'new_pass_1'} ne $::FORM{'new_pass_2'}) {
					$status_msg = &pstr(29,$::str[285]);
					$b_print_status_only = 1;
					next Auth;
					}

				my $cpass = crypt($::FORM{'new_pass_1'}, $seed);
				if ($cpass eq '0') {
					my $temp_err_msg = "Perl crypt() function returned literal '0' - you have an incomplete Perl crypt installation. If you are running Linux 2.2.16 with Perl 5.6.1, please upgrade with latest patches or downgrade to Perl 5.6.0";
					$status_msg = &pstr(29, "$::str[282] - '$temp_err_msg'" );
					$b_print_status_only = 1;
					next Auth;
					}

				my ($temp_err_msg) = &WriteRule('password', $cpass);
				if ($temp_err_msg) {
					$status_msg = &pstr(29, "$::str[282] - '$temp_err_msg'" );
					$b_print_status_only = 1;
					}
				else {
					$status_msg = &pstr(174, $::str[283] );
					}
				}
			next Auth;
			}

		#changed 0054 - let 'Password' override 'CP'
		if ((exists $::FORM{'Password'}) and (length($::FORM{'Password'}))) {
			if (crypt($::FORM{'Password'}, $seed) ne $crypt_pass) {
				$status_msg = &pstr(29,$::str[181]);
				next Auth;
				}

			# the user provided a valid password; give that man a token!

			$pri_token = '';
			foreach (1..8) {
				$pri_token .= chr(ord('a') + int(rand(26)));
				}



			my $cpass = crypt($pri_token, $seed);
			if ($cpass eq '0') {
				my $temp_err_msg = "Perl crypt() function returned literal '0' - you have an incomplete Perl crypt installation. If you are running Lunix 2.2.16 with Perl 5.6.1, please upgrade with latest patches or downgrade to Perl 5.6.0";
				$status_msg = &pstr(29, "$::str[282] - '$temp_err_msg'" );
				next Auth;
				}



			$public_token = $cpass;

			($status_msg, %auth_tokens) = &read_tokens();
			if ($status_msg) {
				$status_msg = &pstr(29, $status_msg);
				next Auth;
				}

			$auth_tokens{$public_token} = time() + $session_lifetime;

			$status_msg = &write_tokens(%auth_tokens);
			if ($status_msg) {
				$status_msg = &pstr(29, $status_msg);
				next Auth;
				}
			last Auth;
			}


		if ($pri_token) {

			($status_msg, %auth_tokens) = &read_tokens();
			if ($status_msg) {
				$status_msg = &pstr(29, $status_msg);
				next Auth;
				}





				my $cpass = crypt($pri_token, $seed);
				if ($cpass eq '0') {
					my $temp_err_msg = "Perl crypt() function returned literal '0' - you have an incomplete Perl crypt installation. If you are running Lunix 2.2.16 with Perl 5.6.1, please upgrade with latest patches or downgrade to Perl 5.6.0";
					$status_msg = &pstr(29, "$::str[282] - '$temp_err_msg'" );
					next Auth;
					}



			$public_token = $cpass;

			unless ($auth_tokens{$public_token}) {
				$status_msg = &pstr(29, $::str[281]);
				next Auth;
				}

			my $expire_time = $auth_tokens{$public_token};

			if ($expire_time < time) {

				$status_msg = '<p>' . $::str[284] . '</p>';
				$clear_cookie = 1 if ($is_cookies_aware);
				next Auth;

				}
			elsif (($expire_time - $grace_period) < time) {

				# this token is about to expire; set a fresh one:

				$pri_token = '';
				foreach (1..8) {
					$pri_token .= chr(ord('a') + int(rand(26)));
					}




				my $cpass = crypt($pri_token, $seed);
				if ($cpass eq '0') {
					my $temp_err_msg = "Perl crypt() function returned literal '0' - you have an incomplete Perl crypt installation. If you are running Lunix 2.2.16 with Perl 5.6.1, please upgrade with latest patches or downgrade to Perl 5.6.0";
					$status_msg = &pstr(29, "$::str[282] - '$temp_err_msg'" );
					next Auth;
					}



				$public_token = $cpass;
				$auth_tokens{$public_token} = time() + $session_lifetime;

				$status_msg = &write_tokens(%auth_tokens);
				if ($status_msg) {
					$status_msg = &pstr(29, $status_msg);
					next Auth;
					}

				}

			last Auth;

			}



		}
	continue {

		# AUTH_FAIL

		unless ($::const{'is_cmd'}) {

			&header_add( "Set-Cookie: fdse_cp=; path=$sn" ) if ($clear_cookie);
			&header_print( "Set-Cookie: fdse_cp=$test_cookie; path=$sn" );

			print <<"EOM";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title>Login</title>
	<meta name="robots" content="none" />
	<meta http-equiv="Content-Type" content="$::const{'content_type'}" />
	<style type="text/css">
	<!--
	.submit {
		color:#000000;
		background-color:#ffffff;
		font-weight:bold;
		cursor:pointer;
		}
	//-->
	</style>
</head>
<body dir="$::const{'dir'}">
<blockquote>
<form method="post" action="$::const{'script_name'}" name="F1" onsubmit="return Validate();">
<input type="hidden" name="Mode" value="Admin" />

EOM

			unless (($::FORM{'Action'}) and ($::FORM{'Action'} eq 'LogOut')) {
				my ($name, $value);
				while (($name, $value) = each %::FORM) {
					next if ($name =~ m!^(Mode|CP|Password|new_pass_1|new_pass_2)$!s);
					$value = &he($value);
					print qq!<input type="hidden" name="$name" value="$value" />\n!;
					}
				}

			}

		my %replace = (
			'html_status_msg' => $status_msg,
			'pass_value' => $::private{'is_demo'} ? 'password' : '',
			);

		unless ($crypt_pass) {
			if ($b_is_api) {
				print "Password not yet defined.  Must be set via web-based interface.\n";
				}
			else {
				&PrintTemplate( 0, 'admin_pass2.txt', $::Rules{'language'}, \%replace );
				}
			}
		elsif (($::const{'is_cmd'}) or ($b_print_status_only)) {
			print $status_msg;
			}
		else {
			&PrintTemplate( 0, 'admin_pass1.txt', $::Rules{'language'}, \%replace );
			&pppstr(89, $::const{'help_file'} );
			}

print <<"FOOTER" unless ($::const{'is_cmd'});

</form>
<script type="text/javascript">
<!--
if ((document) && (document.F1) && (document.F1.Password)) {
	document.F1.Password.focus();
	}
function Validate() {
	if (!((document) && (document.F1) && (document.F1.new_pass_1) && (document.F1.new_pass_2))) {
		return true;
		}
	if (document.F1.new_pass_1.value != document.F1.new_pass_2.value) {
		alert("$::str[73]: $::str[285].");
		return false;
		}
	else if (document.F1.new_pass_1.value.length == 0) {
		alert("$::str[73]: $::str[286].");
		return false;
		}
	return true;
	}
// -->
</script>
<p>Fluid Dynamics Search Engine v$::VERSION</p>
</blockquote>
</body>
</html>

FOOTER
		$is_auth = 0;
		}
	if ($is_auth) {
		if ($is_cookies_aware) {
			&header_add( "Set-Cookie: fdse_cp=" . &ue( $pri_token ) . "; path=$sn" );
			}
		else {
			$url_password = "&amp;CP=" . &ue($pri_token);
			$form_password = '<input type="hidden" name="CP" value="' . &he($pri_token) . '" />';
			}
		}
	return ($is_auth, $form_password, $url_password);
	}





sub read_tokens {
	my %tokens = ();
	my $err = '';
	Err: {
		local $_;
		my $text = '';
		if (-e 'auth_tokens.txt') {
			($err, $text) = &ReadFile('auth_tokens.txt');
			next Err if ($err);
			}
		foreach (split(m!\015\012!s, $text)) {
			next unless (m!Token: (\S+); Expires: (\d+)!s);
			$tokens{$1} = $2;
			}
		}
	return ($err,%tokens);
	}





sub write_tokens {
	my %tokens = @_;
	my $text = '';
	my ($token, $expires) = ();
	while (($token, $expires) = each %tokens) {
		next if ($expires < time());
		$text .= "Token: $token; Expires: $expires\015\012";
		}
	return &WriteFile('auth_tokens.txt', $text);
	}





sub WriteRule {
	my $name = $_[0];
	my $value = defined($_[1]) ? $_[1] : 0;
	my $err = '';
	Err: {
		last Err if ($::Rules{$name} eq $value);

		my $FDR = &FD_Rules_new();

		my ($is_valid, $valid_value) = $FDR->_fdr_validate($name, $value);
		unless ($is_valid) {
			$err = &pstr(170,&he($name,$value));
			next Err;
			}

		$valid_value =~ s!(\r|\n|\015|\012)! !sg; # all line breaks become spaces

		my $default_value = $FDR->{'r_defaults'}->{$name}->[0]; # changed 0068 - strip defaults
		my $b_strip = ($valid_value eq $default_value) ? 1 : 0;


		my $text = '';
		my $text_new = '';

		if (-e $FDR->{'file'}) {
			($err, $text) = &ReadFileL( $FDR->{'file'} );
			next Err if ($err);
			}

		my $qm_name = quotemeta($name);

		my $blank_line_count = 0;#changed 0068 - prevent blank-line buildup

		local $_;
		foreach (split(m!\n!s, $text)) {
			next if (m!^\s*$qm_name\s*=!is);
			if (m!^\s*$!s) {
				$blank_line_count++;
				next if ($blank_line_count > 2);
				}
			else {
				$blank_line_count = 0;
				}
			$text_new .= "$_\n";
			}
		unless ($b_strip) {
			$text_new .= "$name=$valid_value\n";
			}
		$err = &WriteFile( $FDR->{'file'}, $text_new );
		next Err if ($err);
		$::Rules{$name} = $valid_value;
		}
	return $err;
	}





sub clear_error_cache {
	my $error_lines = 0;
	my $err = '';
	Err: {
		my ($obj, $p_rhandle, $p_whandle) = ();
		$obj = &LockFile_new(
			'create_if_needed' => 1,
			);
		($err, $p_rhandle, $p_whandle) = $obj->ReadWrite('search.pending.txt');
		next Err if ($err);
		while (defined($_ = readline($$p_rhandle))) {
			if (m! 2$!s) {
				$error_lines++;
				next;
				}
			unless (print { $$p_whandle } $_) {
				$err = &pstr(43,$obj->get_wname(),$!);
				$obj->Cancel();
				next Err;
				}
			}
		$err = $obj->Merge();
		next Err if ($err);
		last Err;
		}
	return ($err, $error_lines);
	}





sub ui_DataStorage {
	my $err = '';
	Err: {

print <<"EOM";

<div class="breadcrumbs">
	<a href="$::const{'admin_url'}">$::str[96]</a>
	<span class="gt">&rarr;</span>
	<a href="$::const{'admin_url'}&amp;Action=manage_data_storage">$::str[292]</a>

EOM

		my $status_msg = '';

		my $is_error = 0;

		my $subaction = $::FORM{'subaction'} || '';


		if ($subaction eq 'VAO') {

			print qq! <span class="gt">&rarr;</span> Verify Alphabetic Order</div>\n!;

			my $p_realm;
			($err, $p_realm) = $::realms->hashref( $::FORM{'Realm'} );
			next Err if ($err);

			if ($p_realm->{'type'} != 4) {
				$err = "subaction $subaction is only available for realms of type $::str[366]";
				next Err;
				}

			#require
			my $lib = 'common_test.pl';
			delete $INC{$lib};
			require $lib;
			if (&version_test() ne $::VERSION) {
				$err = "the library '$lib' is not version $::VERSION";
				next Err;
				}
			#/require

			$err = &test_file_based_index( $p_realm->{'file'}, 1 );
			next Err if ($err);

			last Err;
			}


		if ($subaction eq 'ClearError') {
			print qq! <span class="gt">&rarr;</span> $::str[332]</div>\n!;
			my $error_lines = 0;
			($err, $error_lines) = &clear_error_cache();
			next Err if ($err);
			&ppstr(174, &pstr(178,$error_lines,'search.pending.txt'));
			last Err;
			}

		if ($subaction eq 'ViewErrors') {

			print qq!
				<span class="gt">&rarr;</span>
				<a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=ReviewPending">$::str[294]</a>
				<span class="gt">&rarr;</span>
				View Errors
				</div>\n!;

			if (not exists $::FORM{'Realm'}) {
				$err = "must supply a Realm parameter";
				next Err;
				}

			my $error_count = 0;
			my $total_count = 0;

			my $url_name = '';
			my $realm_type = -1;
				# 1 => open
				# 2 => filefed
				# 3 => website, crawler
				# 4 => website, filesys
				# 5 => runtime

			my $p_realm_data = ();
			foreach $p_realm_data ($::realms->listrealms('all')) {
				next unless $p_realm_data->{'name'} eq $::FORM{'Realm'};
				$url_name = &ue( $p_realm_data->{'name'} );
				$realm_type = $p_realm_data->{'type'};
				last;
				}

			my $h = &he( $::FORM{'Realm'} );
			unless ($url_name) {
				$err = "there is no realm named $h";
				next Err;
				}

			&pppstr( 524, $h );

			my ($obj, $p_rhandle) = ();
			$obj = &LockFile_new(
				'create_if_needed' => 1,
				);
			($err, $p_rhandle) = $obj->Read('search.pending.txt');
			next Err if ($err);

			local $_;
			while (defined($_ = readline($$p_rhandle))) {
				unless (m!^http://(.*) (\S+) (\d+)\r?$!s) {
					next;
					}
				my ($url, $realm, $time) = ("http://$1", $2, $3);
				next unless $realm eq $url_name;
				$total_count++;
				next unless ($time == 2);
				$error_count++;
				my $hurl = &he( $url );

				my $retry = '';
				if ($realm_type =~ m!^(1|2|3)$!s) {
					my $uurl = &ue( $url );
					$retry = qq! - <a href="$::const{'admin_url'}&amp;Action=AddURL&amp;URL=$uurl&amp;Realm=$url_name" target="_blank">retry</a>!;
					}

				print "<p>$hurl$retry</p>\r\n";
				}
			$err = $obj->Close();
			next Err if ($err);

			&pppstr(301, $total_count, $error_count );

			last Err;
			}


		if ($subaction eq 'ReviewPending') {

			print qq! <span class="gt">&rarr;</span> <a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=ReviewPending">$::str[294]</a></div>\n!;

			my %valid_realms = ();
			my %true_count = ();
			my %err_count = ();

			my $error_count = 0;
			my $total_count = 0;

			my %kill_waiting = ();

			my %wait_count = ();
			my $p_realm_data = ();
			foreach $p_realm_data ($::realms->listrealms('all')) {
				my ($count, $url_name, $html_name) = ($$p_realm_data{'pagecount'}, &ue($$p_realm_data{'name'}), &he($$p_realm_data{'name'}));
				$valid_realms{$url_name} = $count;
				$true_count{$url_name} = 0;
				$wait_count{$url_name} = 0;
				$err_count{$url_name} = 0;
				$kill_waiting{$url_name} = ($$p_realm_data{'type'} == 3) ? 0 : 1;
				}

			my ($obj, $p_rhandle, $p_whandle) = ();

			$obj = &LockFile_new(
				'create_if_needed' => 1,
				);
			($err, $p_rhandle, $p_whandle) = $obj->ReadWrite('search.pending.txt');
			next Err if ($err);

			my $invalid_lines = 0;
			my $old_realms = 0;

			my $prev_url = '';
			local $_;
			while (defined($_ = readline($$p_rhandle))) {
				unless (m!^http://(.*) (\S+) (\d+)\r?$!s) {
					next;
					}
				my ($url, $realm, $time) = ("http://$1", $2, $3);
				if ($time == 2) {
					$error_count++;
					$err_count{$realm}++;
					}
				else {
					unless ($valid_realms{$realm}) {
						$realm = &he( &ud( $realm ) );
						&ppstr(53, &pstr(295, $realm ) );
						$old_realms++;
						next;
						}
					elsif (($time == 0) and ($kill_waiting{$realm})) {
						next;
						}
					if ($url lt $prev_url) {
						&ppstr(53, $::str[296] );
						&pppstr(297, $url, $prev_url );
						next;
						}
					$true_count{$realm}++ if ($time > 10);
					$wait_count{$realm}++ if ($time == 0);
					}
				$total_count++;
				$prev_url = $url;
				print { $$p_whandle } $_;
				}
			$err = $obj->Merge();
			next Err if ($err);

			if ($invalid_lines) {
				&pppstr(298, $invalid_lines );
				}
			if ($old_realms) {
				&pppstr(299, $old_realms );
				}

			&ppstr(174, $::str[355] );
			&pppstr(301, $total_count, $error_count );


print <<"EOM";
<table border="1" cellpadding="4" cellspacing="1">
<tr>
	<th>$::str[428]</th>
	<th>$::str[146]</th>
	<th>$::str[302]</th>
	<th>$::str[303]</th>
	<th>$::str[304]</th>
	<th>$::str[305]</th>
</tr>
EOM

			my ($name, $pagecount, $truecount) = ();
			while (($name, $pagecount) = each %valid_realms) {
				my $truecount = $true_count{$name};

				my $true_name = &ud( $name );
				my $display_name = &he( $true_name );

				my $p_realm;
				($err, $p_realm) = $::realms->hashref( $true_name );
				next Err if ($err);

				my $action_VAO = '';

				if ($p_realm->{'type'} == 4) {
					$action_VAO = qq! | <a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=VAO&amp;Realm=$name" class="onbrown">Verify Alphabetic Order</a>!;
					}

				my $display_error_count = '';
				if ($err_count{$name}) {
					$display_error_count = qq!<a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=ViewErrors&amp;Realm=$name" class="onbrown">$err_count{$name}</a>!;
					}
				else {
					$display_error_count = $err_count{$name};
					}


print <<"EOM";

<tr class="fdtan">
	<td>$display_name</td>
	<td align="center">
		<a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=sync&amp;Realm=$name" class="onbrown">$::str[306]</a> |
		<a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=rmdupe&amp;Realm=$name" class="onbrown">$::str[307]</a>
		$action_VAO
		</td>
	<td align="right">$truecount</td>
	<td align="right">$pagecount</td>
	<td align="right">$wait_count{$name}</td>
	<td align="right">$display_error_count</td>
</tr>

EOM
				}

print <<"EOM";
</table>

<p><b>$::str[45]:</b></p>

$::str[308]

EOM
			last Err;
			}



		if ($subaction eq 'rmdupe') {
			print qq! <span class="gt">&rarr;</span> <a href=\"$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=ReviewPending\">$::str[294]</a> <span class="gt">&rarr;</span> $::str[307]</div>\n!;

			my $p_realm_data = ();
			($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
			next Err if ($err);

			if ($$p_realm_data{'is_runtime'}) {
				$err = &pstr(277, $$p_realm_data{'html_name'} );
				next Err;
				}

			# Get a list of all pages in the realm - import them into the pending file
			my %crawler_results = ();

			my $count = 0;
			my $dupes = 0;

			my ($obj, $p_rhandle, $p_whandle) = ();


			my %pages = ();

			$obj = &LockFile_new(
				'create_if_needed' => 1,
				);

			($err, $p_rhandle, $p_whandle) = $obj->ReadWrite( $$p_realm_data{'file'} );
			next Err if ($err);

			while (defined($_ = readline( $$p_rhandle ))) {
				next unless (m! u= (.+?) t=!s);
				if ($pages{$1}) {
					&pppstr(310, $1 );
					$dupes++;
					}
				else {
					$count++;
					print { $$p_whandle } $_;
					}
				$pages{$1}++;
				}
			$err = $obj->Merge();
			next Err if ($err);

			&pppstr(311, $dupes );
			&pppstr(313, $$p_realm_data{'html_name'}, $count );

			$err = $::realms->setpagecount( $$p_realm_data{'name'}, $count, 1);
			next Err if ($err);

			last Err;
			}



		if ($subaction eq 'sync') {
			print qq! <span class="gt">&rarr;</span> <a href=\"$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=ReviewPending\">$::str[294]</a> <span class="gt">&rarr;</span> $::str[306]</div>\n!;

			my $p_realm_data = ();
			($err, $p_realm_data) = $::realms->hashref($::FORM{'Realm'});
			next Err if ($err);

			my $url_realm = $$p_realm_data{'url_name'};

			if ($$p_realm_data{'is_runtime'}) {
				$err = &pstr(277, $$p_realm_data{'html_name'} );
				next Err;
				}

			# Get a list of all pages in the realm - import them into the pending file
			my %crawler_results = ();

			my $count = 0;

			my ($obj, $p_rhandle, $p_whandle) = ();

			my %valid = ( 'is_error' => 0 );

			$obj = &LockFile_new(
				'create_if_needed' => 1,
				);

			($err, $p_rhandle) = $obj->Read( $$p_realm_data{'file'} );
			next Err if ($err);

			while (defined($_ = readline( $$p_rhandle ))) {
				next unless (m! u= (.+?) t=!s);
				if ($crawler_results{$1}) {
					&ppstr(53, $::str[317] );
					&pppstr(318);
					}
				else {
					$crawler_results{$1} = \%valid;
					}
				$count++;
				}
			$err = $obj->Close();
			next Err if ($err);


			print "<p>$::str[319]</p>\n";
			foreach (sort keys %crawler_results) {
				print &he($_) . "<br />\n";
				}
			$obj = &LockFile_new(
				'create_if_needed' => 1,
				);
			($err, $p_rhandle, $p_whandle) = $obj->ReadWrite('search.pending.txt');
			next Err if ($err);

			while (defined($_ = readline( $$p_rhandle ))) {
				if (m!^(.*) $url_realm (\d+)$!s) {
					my ($url, $code) = ($1, $2);
					if ($code > 2) {
						unless ($crawler_results{$url}) {
							&ppstr( 316 , &he($url) );
							print "<br />\n";
							}
						next;
						}
					}
				print { $$p_whandle } $_;#TODO
				}

			$err = $obj->Merge();
			next Err if ($err);

			$err = &SaveLinksToFileEx( $p_realm_data, \%crawler_results );
			next Err if ($err);

			&pppstr(313, $$p_realm_data{'html_name'}, $count );

			$err = $::realms->setpagecount( $$p_realm_data{'name'}, $count, 1);
			next Err if ($err);

			last Err;
			}

		print qq! <span class="gt">&rarr;</span> $::str[152]</div>!; # Finish toplink

print <<"EOM";

<p><b>$::str[333]</b></p>
<ul>
	<li><a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=ReviewPending">$::str[294]</a> - $::str[334]</li>
	<li><a href="$::const{'admin_url'}&amp;Action=manage_data_storage&amp;subaction=ClearError">$::str[332]</a> - $::str[335]</li>
</ul>

EOM

		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	}





sub CheckEmail {
	my ($address) = @_;
	my $err = '';
	Err: {
		unless ($address) {
			$err = $::str[359];
			next Err;
			}

		unless ($address =~ m!^(.+?)\@(.+?)$!s) {
			$err = &pstr(360, $address );
			next Err;
			}

		}
	return $err;
	}





sub SendMailEx {
	my %params = @_;
	my $basename = '';
	my $full_message = '';
	my $trace = '';
	my $err = '';
	Err: {
		local $_;

		my $p_nc_cache = ();
		if ($params{'p_nc_cache'}) {
			$p_nc_cache = $params{'p_nc_cache'};
			}
		else {
			my %nc_cache = ();
			$p_nc_cache = \%nc_cache;
			}


		# validate inputs:
		if ((not $params{'to name'}) and ($params{'to_name'})) {
			$params{'to name'} = $params{'to_name'};
			}
		if ((not $params{'from name'}) and ($params{'from_name'})) {
			$params{'from name'} = $params{'from_name'};
			}
		if ((not $params{'message'}) and ($params{'body'})) {
			$params{'message'} = $params{'body'};
			}

		foreach ('to', 'from') {
			unless ($params{$_}) {
				$err = &pstr(21,$_);
				next Err;
				}
			}

		$params{'port'} = 25 unless ($params{'port'});

		# build the full message:

		$full_message = '';


		if ($params{'raw'}) {
			$full_message = $params{'raw'};
			}
		else {
			$full_message = &sendmail_build_raw_message($params{'to'},$params{'to name'},$params{'from'},$params{'from name'},$params{'subject'},$params{'message'},$params{'is_html'});
			}

		# Fix for bare LF

		$full_message =~ s!\015\012!\012!sg;
		$full_message =~ s!\015!\012!sg;
		$full_message =~ s!\012!\015\012!sg;


		# Escape any literal CRLF . CRLF sequences (this is the end-of-message sequence in SMTP)
		$full_message =~ s!\015\012\.\015\012!\015\012\. \015\012!sg;

		# Message has been built - now send it:

		my %hosts_tried = ();

		my $b_message_sent = 0;

		$params{'handler_order'} = '12345' unless (defined($params{'handler_order'}));
		TryToSend: foreach (split(m!!s, $params{'handler_order'})) {
			next TryToSend unless (m!^\d$!s);

			if (($_ == 1) and ($params{'pipeto'})) {
				if (open(PIPE, "|$params{'pipeto'} -t")) {
					binmode(PIPE);
					$full_message =~ s!\015\012!\012!sg; # Unix-friendly for Unix
					print PIPE $full_message;
					close(PIPE);
					$trace = $full_message;
					$b_message_sent = 1;
					last TryToSend;
					}
				$err = &pstr(440, $params{'pipeto'}, $!);
				next TryToSend;
				}

			if (($_ == 2) and ($params{'host'})) {
				next if ($hosts_tried{$params{'host'}});
				($err, $trace) = &sendmail_socket( $params{'host'}, $params{'port'}, $params{'to'}, $params{'from'}, $full_message, $p_nc_cache, $params{'use standard io'} );
				$hosts_tried{$params{'host'}} = 1;
				next TryToSend if ($err);
				$b_message_sent = 1;
				last TryToSend;
				}
			}
		if ((not $b_message_sent) and (not $err)) {
			$err = $::str[445];
			last Err;
			}
		}
	return ($err, $trace);
	}





sub sendmail_build_raw_message {
	my ($to_addr,$to_name,$from_addr,$from_name,$subject,$body,$is_html) = @_;
	my $raw_message = '';

	if ($to_name) {
		$raw_message .= qq!To: "$to_name" <$to_addr>\015\012!;
		}
	else {
		$raw_message .= "To: $to_addr\015\012";
		}


	if ($from_name) {
		$raw_message .= qq!From: "$from_name" <$from_addr>\015\012!;
		}
	else {
		$raw_message .= "From: $from_addr\015\012";
		}


	$raw_message .= "Subject: $subject\015\012";
	$raw_message .= "Date: " . &sendmail_datetime(time()) . "\015\012";


	if ($is_html) {
		$raw_message .= "Content-Type: text/html\015\012";
		}
	$raw_message .= "\015\012";
	$raw_message .= $body;
	return $raw_message;
	}





sub sendmail_socket {
	my ($host,$port,$to,$from,$raw,$p_nc_cache,$b_use_standard_io) = @_;
	my $is_open = 0;
	my $trace = '';
	my $err = '';
	Err: {
		# connect to the SMTP server
		$err = &leansock($host,$port,\*MAIL,$p_nc_cache);
		next Err if ($err);
		$is_open = 1;
		my @commands = (
			[ 'Welcome',
				220, 0, '',
				],
			[ 'HELO',
				250, 1, "HELO $host",
				],
			[ 'Mail From',
				250, 1, "MAIL FROM:<$from>",
				],
			[ 'Recipient/To',
				250, 1, "RCPT TO:<$to>",
				],
			[ 'Data Initialize',
				354, 1, "DATA",
				],
			[ 'Data Transfer',
				250, 1, "$raw\015\012.",
				],
			);
		my $i = 0;
		for ($i = 0; $i <= $#commands; $i++) {
			my ($expect_code, $sendrecv, $send_data) = ($commands[$i][1], $commands[$i][2], $commands[$i][3]);
			if ($sendrecv) {
				$send_data .= "\015\012";
				my $data_len = length($send_data);
				my $send_len = 0;
				if ($b_use_standard_io) {
					$send_len = send(*MAIL, $send_data, 0);
					}
				else {
					$send_len = syswrite(*MAIL, $send_data, $data_len);
					}
				unless (defined($send_len)) {
					$err = &pstr(452,"$! - $^E");
					next Err;
					}
				if ($send_len != $data_len) {
					$err = &pstr(452, &pstr(453, $send_len, $data_len) . " - $! - $^E");
					next Err;
					}
				$trace .= $send_data;
				}

			next unless ($b_use_standard_io);

			my $response_code = '';
			my $response_text = '';
			local $_;
			while (defined($_ = readline(*MAIL))) {
				$response_text .= $_;
				$trace .= $_;
				s!(\r|\n|\015|\012)!!sg;#correct for MacPerl
				if ((m!^(\d\d\d)\-!s) and ($1 ne '000')) {
					$response_code = $1 unless ($response_code);
					}
				elsif (m!^(\d\d\d)\r?(\s|$)!s) {
					$response_code = $1 unless ($response_code);
					last;
					}
				else {
					$err = &pstr(448, "$host:$port", $commands[$i][0], $response_text);
					next Err;
					}
				}
			unless ($response_code =~ m!$expect_code!s) {
				$err = &pstr(449, "$host:$port", $commands[$i][0], $expect_code, $response_code, $response_text);
				next Err;
				}

			}
		}
	close(*MAIL) if ($is_open);
	return ($err, $trace);
	}





sub leansock {
	my ($host,$port,$p_socket,$p_nc_cache) = @_;
	my $err = '';
	Err: {
		$host = lc($host);
		$p_nc_cache = {} unless $p_nc_cache; # initialize
		unless (exists($$p_nc_cache{"H:$host"})) {
			$$p_nc_cache{"H:$host"} = (gethostbyname($host))[4];
			}
		my $addr = $$p_nc_cache{"H:$host"};
		unless ($addr) {
			$err = &pstr(436, $host, $!, $^E);
			next Err;
			}
		#optout use Socket;
		eval 'use Socket;';
		if ($@) {
			$err = &pstr(93, 'Socket', $@ );
			undef($@);
			next Err;
			}
		#/optout
		unless (socket($$p_socket, &PF_INET(), &SOCK_STREAM(), scalar getprotobyname('tcp'))) {
			$err = &pstr(437, $!, $^E);
			next Err;
			}
		unless (connect($$p_socket, sockaddr_in($port,$addr))) {
			$err = &pstr(438,$host,$port,$!,$^E);
			close($$p_socket);
			next Err;
			}
		unless (binmode($$p_socket)) {
			$err = &pstr(439,$!,$^E);
			close($$p_socket);
			next Err;
			}
		my $h = select($$p_socket);
		$| = 1;
		select($h);
		}
	return $err;
	}





sub sendmail_datetime {
	local $_;
	my ($time_int) = @_;
	my ($sec, $min, $milhour, $day, $month_int, $year, $weekday_int) = gmtime($time_int);
	$year += 1900;
	foreach ($milhour, $min, $sec, $day) {
		$_ = "0$_" if (1 == length($_));
		}
	my $month_str = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$month_int];
	my $weekday_str = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')[$weekday_int];
	return "$weekday_str, $day $month_str $year $milhour:$min:$sec -0000";
	}





sub Crawler_new {
	my $self = {
		'b_use_proxy' => 0,
		'proxy_addr' => 'proxy',
		'proxy_port' => 80,
		};
	bless($self);

	my %cookies = ();
	my %robot_files = ();

	$self->{'p_cookies'} = \%cookies;
	$self->{'p_robot_files'} = \%robot_files;

	return $self;
	}





sub webrequest {
	my ($self, %request) = @_;
	my @redirects = ();
	my %webrq = (
		'err' => '',
		'final_url' => '',
		'total_requests' => 0,
		'text' => '',
		'no_index_but_follow' => 0,
		'no_follow' => 0,
		'lastmodt' => 0,
		'ref_redirects' => \@redirects,
		);

	my $current_url = $request{'page'};

	my ($host,$port,$path,$query);

	my $err = '';
	Err: {

		my $max_redirects = $::Rules{'crawler: max redirects'};

		my %rawrq = ();

		FollowRedirects: while ($webrq{'total_requests'} <= (1 + $max_redirects)) {

			$webrq{'total_requests'}++;

			($err,$current_url,$host,$port,$path,$query) = &uri_parse($current_url);
			next Err if ($err);

			$path = $path . $query; # for our purposes here

			$webrq{'final_url'} = $current_url;

			push(@redirects, $current_url);
			if (($request{'limit'}) and ($current_url !~ m!$request{'limit'}!is)) {
				$err = &pstr(376,&he($current_url,$request{'limit'}));
				next Err;
				}

			unless ($::Rules{'crawler: rogue'}) {
				my $RobotFile = "http://$host:$port/robots.txt";
				my $p_robot_files = $self->{'p_robot_files'};
				unless (defined($$p_robot_files{$RobotFile})) {
					my @forbidden_paths = ();
					my %rawrq = $self->raw_get($host, $port, '/robots.txt', 'GET', '', '');
					unless ($rawrq{'err'}) {
						foreach (&ParseRobotFile($rawrq{'text'}, $::Rules{'crawler: user agent'})) {
							push(@forbidden_paths, quotemeta($_));
							}
						}
					$$p_robot_files{$RobotFile} = \@forbidden_paths;
					}
				my $ref_forbidden_paths = $$p_robot_files{$RobotFile};
				foreach (@$ref_forbidden_paths) {
					if ($path =~ m!^$_!s) {
						$RobotFile =~ s!^http://([^/]+):80/!http://$1/!os;
						$err = &pstr(64,$RobotFile,&he($path));
						next Err;
						}
					}
				}
			%rawrq = $self->raw_get($host, $port, $path);

			if ($rawrq{'err'}) {
				if ($rawrq{'is_redirect'}) {
					$webrq{'total_requests'}++;
					push(@redirects, $rawrq{'location'});
					}
				$err = $rawrq{'err'};
				next Err;
				}

			if ($rawrq{'is_redirect'}) {
				$current_url = $rawrq{'location'};
				next FollowRedirects;
				}

			# Is the content-type okay?

			my ($p_sub, $read_last_bytes) = &handler_match( $current_url, $rawrq{'content_type'}, $::FORM{'debug'} );
			if ($p_sub) {
				($err, $rawrq{'text'}) = &$p_sub( $rawrq{'text'}, '', $current_url, $::FORM{'debug'} );
				next Err if ($err);
				}
			elsif ($rawrq{'content_type'} !~ m!text!s) {
				$err = &pstr(378,&he($rawrq{'content_type'}));
				next Err;
				}

			# Has user imposed a response code limit?
			unless (($rawrq{'response_code'} == 200) or ($rawrq{'response_code'} == 206)) {

				if ($rawrq{'response_code'} == 401) {
					$err = &pstr(320,$rawrq{'response_code'},&he($rawrq{'response_expl'}), "$::const{'help_file'}1102.html" );
					}
				else {
					$err = &pstr(379,$rawrq{'response_code'},&he($rawrq{'response_expl'}));
					}
				next Err;
				}

			my $text = $rawrq{'text'};

			if ($rawrq{'last-modified'}) {
				# okay... well, let's try to parse this
				# goal is to extract a Unix time and to drop it inside $response{'lastmodt'}
				if ($rawrq{'last-modified'} =~ m!(\d+)(\s+|-)(\w\w\w)(\s+|-)(\d+)\s+(\d+)\:(\d+)\:?(\d*)!s) {
					my ($mday, $mon, $year, $hours, $min, $sec) = ($1,$3,$5,$6,$7,$8 || 0);
					my $time = &timegm($sec,$min,$hours,$mday,$mon,$year);
					$webrq{'lastmodt'} = $time if ($time);
					}
				}


			my ($temp_err_msg, $no_index_but_follow, $no_follow, $is_redirect, $full_redir_url, $index_as,$lastmodt, $actual_size) = &process_text(\$text, $current_url, 0, $rawrq{'content_length'} );

			if ($is_redirect) {
				$current_url = $full_redir_url;
				next FollowRedirects;
				}
			elsif ($index_as ne $current_url) {
				# treat index-as directives as redirects
				push(@redirects, $index_as);
				$webrq{'total_requests'}++;
				}
			$webrq{'lastmodt'} = $lastmodt if ($lastmodt);

			$webrq{'no_follow'} = $no_follow;
			$webrq{'final_url'} = $index_as;
			$webrq{'text'} = $rawrq{'text'};
			$webrq{'no_index_but_follow'} = $no_index_but_follow;
			$webrq{'size'} = $rawrq{'content_length'} = $actual_size;
			if ($temp_err_msg) {
				$err = $temp_err_msg;
				next Err;
				}

			last Err;
			}

		$err = &pstr(380, $max_redirects );
		next Err;
		}
	continue {
		$webrq{'err'} = $err;
		}
	return %webrq;
	}





sub raw_get {
	if (not exists($::private{'use_alarm'})) {
		if ($::Rules{'network timeout'}) {
			eval 'alarm(0);';
			$::private{'use_alarm'} = ($@) ? 0 : 1;
			}
		else {
			$::private{'use_alarm'} = 0;
			}
		}
	if ($::private{'use_alarm'}) {
		return &raw_get_alarm(@_);
		}
	else {
		return &raw_get_raw(@_);
		}
	}





sub raw_get_alarm {
	my %Response = ();
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm( 2 * $::Rules{'network timeout'} );
		%Response = &raw_get_raw(@_);
		alarm(0);
		};
	if ($@) {
		if ($@ eq "alarm\n") {
			$Response{'err'} = $::str[451] . &network_error_msg( 'alarm' );
			$@ = '';
			}
		else {
			die $@;
			}
		}
	return %Response;
	}





sub raw_get_raw {

	my ($self, $host, $port, $path) = @_;

	my %Response = (

		'err' => '',

		'response_code' => 200,
		'response_expl' => '',

		'is_redirect' => 0,
		'location' => '',
		'content_type' => '',
		'content_length' => 0,

		'text' => '',
		);

	my $err = '';
	Err: {

		my $p_cookies = $self->{'p_cookies'};

		my $Request = '';

		my ($connhost, $connport) = ();

		my $litpath = $path;
		$litpath =~ s! !\%20!sg;

		if ($self->{'b_use_proxy'}) {
			$Request .= "GET http://$host:$port$litpath HTTP/1.0\015\012";
			($connhost, $connport) = ($self->{'proxy_addr'}, $self->{'proxy_port'});
			}
		else {
			$Request .= "GET $litpath HTTP/1.0\015\012";
			($connhost, $connport) = ($host, $port);
			}

		$Request .= "User-Agent: $::Rules{'crawler: user agent'}\015\012";
		$Request .= "Connection: close\015\012";
		$Request .= "Pragma: no-cache\015\012";

		#changed 0054
		my $cookie = join('; ', map { "$_=$$p_cookies{$_}" } keys %$p_cookies);
		if (($cookie) and ($::Rules{'crawler: use cookies'})) {
			$Request .= "Cookie: $cookie\015\012";
			}

		# force a valid host header:
		if ($port == 80) {
			$Request .= "Host: $host\015\012";
			}
		else {
			$Request .= "Host: $host:$port\015\012";
			}



		# allow for 1024-byte header
		my $LimitBytes = 1024 + $::Rules{'max characters: file'};





		my ($p_sub, $read_last_bytes) = &handler_match( $litpath, '', $::FORM{'debug'} );
		if ($p_sub) {

			if ($read_last_bytes) {
				$LimitBytes = 1024 + $read_last_bytes; # MP3 special-case
				$Request .= "Range: bytes=-$read_last_bytes\015\012";
				}
			else {
				$LimitBytes = 0; # Word, PDF special-case; no size limit
				}

			}



		$Request .= "\015\012";



		my $sock = \*HTTP;
		$sock = \*HTTP; # avoid "un-used var" warnings in -w
		$err = &leansock($connhost,$connport,$sock,$::private{'p_nc_cache'});
		if ($err) {
			$err .=  &network_error_msg( 'leansock' );
			}
		next Err if ($err);
		my $select_ok = 0;
		my $sel = ();
		if ($::Rules{'network timeout'}) {
			my $code = 'use IO::Select; $sel = IO::Select->new($sock); ';
			eval $code;
			if ((!$@) and ($sel)) {
				$select_ok = 1;
				}
			}
		if (($select_ok) and (not $sel->can_write($::Rules{'network timeout'}))) {
			close($sock);
			$err = $::str[384] . &network_error_msg( 'sel.can_write' );
			next Err;
			}
		my $ExpectBytes = length($Request);
		my $SentBytes = 0;
		if ($::Rules{'use standard io'}) {
			$SentBytes = send($sock, $Request, 0);
			}
		else {
			$SentBytes = syswrite($sock, $Request, $ExpectBytes);
			}
		if ($SentBytes != $ExpectBytes) {
			close($sock);
			$err = &pstr(385, $ExpectBytes, $SentBytes, $! ) . &network_error_msg( '' );
			next Err;
			}
		if (($select_ok) and (not $sel->can_read($::Rules{'network timeout'}))) {
			close($sock);
			$err = &pstr(450,$::str[451]) . &network_error_msg( 'sel.can_read' );
			next Err;
			}
		my $buffer = '';
		my $readlen = 0;
		do {
			my $tmp = '';
			if ($::Rules{'use standard io'}) {
				$readlen = read($sock, $tmp, 4096, 0);
				}
			else {
				$readlen = sysread($sock, $tmp, 4096, 0);
				}
			$buffer .= $tmp;
			if (not (defined($readlen))) {
				close($sock);
				$err = &pstr(450,"$! - $^E") . &network_error_msg( '' );
				next Err;
				}
			if (($LimitBytes) and (length($buffer) > $LimitBytes)) {
				$readlen = 0;
				}
			}
		until (not $readlen);
		close($sock);
		if (($LimitBytes) and (length($buffer) > $LimitBytes)) {
			$buffer = substr($buffer, 0, $LimitBytes);
			}

		# break up the response buffer into an array of lines
		my @Lines = map { "$_\012" } (split(m!\012!s, $buffer));

		if (@Lines) {
			$Lines[-1] =~ s!\012$!!s; # correct for final trailing line (messes up binary converters in particular)
			}


		my $is_chunked_transfer = 0;

		# Determine the HTTP version:
		if (($Lines[0]) and ($Lines[0] !~ m!^HTTP/1.\d (\d+)(.*)$!s)) {

			# This is just an HTTP 0.9 response, which has no headers; easy:
			$Response{'content_type'} = 'text/html';
			$Response{'text'} = $buffer;
			}

		else {

			# Is HTTP 1.x, great:
			$Response{'response_code'} = $1;
			$Response{'response_expl'} = &Trim($2);

			my $line_count = 1;

			# Get HTTP headers:
			Header: foreach (@Lines[1..$#Lines]) {
				$line_count++;
				last Header unless (m!^(.*?):\s*(.*)\015?\012?$!s);
				my ($lc_name, $value) = (lc(&Trim($1)), $2);

				if (($lc_name eq 'transfer-encoding') and ($value =~ m!^chunked$!is)) {
					$is_chunked_transfer = 1;
					}

				if ($lc_name eq 'location') {
					$Response{'location'} = &Trim($value);
					}

				if (($lc_name eq 'set-cookie') and ($value =~ m!(.*?)=([^\;]+)!s)) {
					$$p_cookies{$1} = $2;
					}

				if ($lc_name eq 'last-modified') {
					$Response{'last-modified'} = $value;
					}

				if ($lc_name eq 'content-type') {
					$Response{'content_type'} = lc(&Trim($value));
					}

				if (($lc_name eq 'content-length') and ($value =~ m!(\d+)!s)) {
					$Response{'content_length'} = $1 unless ($Response{'content_length'});
					}

				if (($lc_name eq 'content-range') and ($value =~ m!bytes \d+-\d+/(\d+)!s)) {
					$Response{'content_length'} = $1;
					}

				}

			# Get the HTTP body:

			if ($is_chunked_transfer) {
				my $max_line = $#Lines;
				while ($line_count <= $max_line) {
					last unless ($Lines[$line_count] =~ m!^(\w+)!s);
					my $content_length = hex($1);
					$line_count++;
					while ($content_length > 0) {
						$Response{'text'} .= $Lines[$line_count];
						$content_length -= length($Lines[$line_count]);
						$line_count++;
						}
					$Response{'content_length'} = $content_length; #changed 0052
					}
				}
			else {
				$Response{'text'} .= join('', @Lines[$line_count..$#Lines]);
				}
			}

		# If we get a 300-series reply, AND a location header, AND that location resolves to a
		# workable URL, then set is_redirect to true:

		if (($Response{'location'}) and ($Response{'response_code'} =~ m!^30\d$!s)) {

			$Response{'is_redirect'} = 1;
			$Response{'location'} = $Response{'location'}; # this is set first, so if the uri_merge kicks out an error, the end user will have a better view of the error

			# determine absolute URL to which we have been redirected
			my $clean;
			($err, $clean) = &uri_merge( "http://$host:$port$path", $Response{'location'} );
			next Err if ($err);

			#changed 0063 -- apply input filters:
			$Response{'location'} = &rewrite_url( 0, $clean );
			}

		last Err;
		}
	continue {
		$Response{'err'} = $err;
		}
	return %Response;
	}





sub setpagecount {
	my ($self, $name, $count, $write) = @_;
	my $err = '';
	Err: {
		my $p_realm_data = ();
		($err, $p_realm_data) = $self->hashref($name);
		next Err if ($err);

		if (($$p_realm_data{'file'}) and (open(FILE, ">$$p_realm_data{'file'}.pagecount"))) {
			print FILE $count;
			close(FILE);
			chmod($::private{'file_mask'},"$$p_realm_data{'file'}.pagecount");
			}
		$$p_realm_data{'pagecount'} = $count;
		}
	return $err;
	}





sub get_open_realm {
	my ($self) = @_;
	my $p_realm_data = ();
	my $err = '';
	Err: {

		if ($::private{'is_freeware'}) {
			$err = $::str[480];
			next Err;
			}

#changed 0064 -- always auto-create new
#		my @xrealms = $self->listrealms('has_no_base_url');
#		if (@xrealms) {
#			$p_realm_data = $xrealms[0];
#			last Err;
#			}

		# shoot... gotta create one on the fly...

		my ($defname, $deffile) = $self->get_default_name();
		$self->add( 0, $defname, $self->{'use_db'}, $deffile, 0, '', '', '', 0, 0 );

		$err = $self->save_realm_data();
		next Err if ($err);

		($err, $p_realm_data) = $self->hashref( $defname );
		next Err if ($err);

		}
	return ($err, $p_realm_data);
	}





sub get_website_realm {
	my ($self, $url) = @_;
	my $p_realm_data = ();
	my $err = '';
	Err: {
		my $curlen = 0;

		my $p_test_data = ();
		foreach $p_test_data ($self->listrealms('has_base_url')) {
			next if ($$p_test_data{'is_filefed'});
			my $qm_base_url = quotemeta($$p_test_data{'base_url'});
			if ($url =~ m!^$qm_base_url!is) {
				# okay... this is a match... but is it the best match?
				if (length($$p_test_data{'base_url'}) > $curlen) {
					$p_realm_data = $p_test_data;
					$curlen = length($$p_test_data{'base_url'});
					}
				}
			}
		last Err if ($p_realm_data);

		# shoot... gotta create one on the fly...

		if (($::private{'is_freeware'}) and ($self->realm_count('all') > 0)) {
			$err = $::str[480];
			next Err;
			}

		my ($defname, $deffile) = $self->get_default_name( $url );

		$self->add( 0, $defname, $self->{'use_db'}, $deffile, 0, '', $url, '', 0, 0 );

		$err = $self->save_realm_data();
		next Err if ($err);

		($err, $p_realm_data) = $self->hashref( $defname );
		next Err if ($err);

		}
	return ($err, $p_realm_data);
	}





sub get_default_name {
	my ($self, $base_url) = @_;
	my ($defname, $deffile) = ('', '');

	if ($base_url) {

		$defname = $base_url;
		$defname =~ s!^http://!!ois;
		$defname =~ s!(\?|\#|\$).*$!!os;
		$defname = substr($defname, 0, 40);
		$defname =~ s!/$!!os;

		if ($defname) {

			my ($temp_err, $temp_ptr) = $self->hashref( $defname );
			if ($temp_err) {
				# yay... keep $defname
				}
			else {
				$defname = '';
				}
			}
		}

	my $realm_num = 1;
	unless ($defname) {
		my $p_data = ();
		foreach $p_data ($self->listrealms('all')) {
			my $name = $$p_data{'name'};
			next unless ($name =~ m!^My Realm (\d+)$!is);
			my $temp_num = $1;
			if ($temp_num > $realm_num) {
				$realm_num = $temp_num + 1;
				}
			}
		}
	while (1) {
		my $basename = "index_file_" . $realm_num . ".txt";
		last unless ((-e $basename) or (-e "$basename.need_approval") or (-e "$basename.exclusive_lock_request"));
		$realm_num++;
		}
	$defname = "My Realm $realm_num" unless ($defname);
	$deffile = "index_file_$realm_num.txt";

	return ($defname, $deffile);
	}





sub save_realm_data {
	my ($self) = @_;
	my $err = '';
	Err: {

		# clear original list:
		my $ref_realms = $self->{'realms'};

		my $text = '';
		my $p_realm_data = ();
		foreach $p_realm_data (@$ref_realms) {
			my %RH = %$p_realm_data;
			my $u_limit = &ue($RH{'limit_pattern'});
			$text .= "$RH{'name'}|$RH{'file'}|$RH{'base_dir'}|$RH{'base_url'}|$RH{'exclude'}|$RH{'pagecount'}|$RH{'is_filefed'}|$RH{'type'}|$u_limit|\015\012";
			}
		$err = &WriteFile( $self->{'file'}, $text );
		next Err if ($err);

		# flush cache:
		foreach (keys %$self) {
			if (m!^cache_!s) { undef($self->{$_}) }
			}

		# Now reload the realms object so that we can read back our values:
		my $p_a = $self->{'realms'};
		@$p_a = ();
		$p_a = $self->{'p_realms_by_name'};
		%$p_a = ();
		$p_a = $self->{'p_delete_realm_ids'};
		@$p_a = ();
		$err = $self->load();
		next Err if ($err);

		last Err;
		}
	return $err;
	}





sub Append {
	my ($self, $filename) = @_;

	$self->{'rname'} = $filename;
	$self->{'ename'} = "$filename.exclusive_lock_request";

	my ($p_rhandle, $rname, $p_whandle, $wname, $p_ehandle, $ename) = ($self->{'p_rhandle'}, $self->{'rname'}, $self->{'p_whandle'}, $self->{'wname'}, $self->{'p_ehandle'}, $self->{'ename'});

	my $progress = 0;

	my $err = '';
	Err: {
		my $attempts = $self->{'timeout'};
		my $success = 0;
		while ((-e $ename) and ($attempts > 0)) {
			# If an "exlusive lock request" file exists, wait up to timeout seconds for it to disappear. If it doesn't, and if it's age is
			# also less than timeout seconds, return an error:
			# is she recent?
			my $lastmodt = (stat($ename))[9];
			my $age = time - $lastmodt;
			last unless ($age < $self->{'timeout'});
			$attempts--;
			sleep(1);
			}
		unless ($attempts > 0) {
			$err = &pstr(44, $rname, &pstr(37, $self->{'timeout'} ) );
			next Err;
			}
		while (($attempts > 0) and (-e $wname)) {
			# How old is the write file?
			my $lastmodt = (stat($wname))[9];
			my $age = time - $lastmodt;
			if ($age > $self->{'timeout'}) {
				# claim it for ourselves - but if the core file doesn't exist, rename this one over to it's spot.
				unless (-e $rname) {
					unless (rename($wname, $rname)) {
						$err = &pstr(38,$wname,$rname,$!);
						next Err;
						}
					}
				last;
				}
			sleep(1);
			$attempts--;
			}
		unless ($attempts > 0) {
			$err = &pstr(44, $rname, &pstr(37, $self->{'timeout'} ) );
			next Err;
			}


		# Create the appropriate files to secure our access from other LockFile.pm processes:

		unless (open($$p_ehandle, "+>$ename" )) {
			$err = &pstr(70, $ename, $! );
			next Err;
			}
		unless (binmode($$p_ehandle)) {
			$err = &pstr(39, $ename, $! );
			next Err;
			}
		unless (&FlockEx($p_ehandle, 6)) {
			$err = &pstr(76, $ename, $! );
			close($$p_ehandle);
			next Err;
			}
		select($$p_ehandle);
		$| = 1;
		select(STDOUT);
		print { $$p_ehandle } '';
		$progress++;
		chmod($::private{'file_mask'}, $ename);

		# Finally, open up the main file for appending:

		unless (open($$p_rhandle, ">>$rname" )) {
			$err = &pstr(42, $rname, $! );
			next Err;
			}
		unless (&FlockEx($p_rhandle, 6)) {
			$err = &pstr(76, $rname, $! );
			close($$p_rhandle);
			next Err;
			}
		$progress++;
		unless (binmode($$p_rhandle)) {
			$err = &pstr(39,$rname,$!);
			next Err;
			}
		chmod($::private{'file_mask'}, $rname);
		}
	return ($err, $p_rhandle);
	}


sub FinishAppend {
	my ($self) = @_;
	my ($p_rhandle, $rname, $p_whandle, $wname, $p_ehandle, $ename) = ($self->{'p_rhandle'}, $self->{'rname'}, $self->{'p_whandle'}, $self->{'wname'}, $self->{'p_ehandle'}, $self->{'ename'});

	my $err = '';
	Err: {

		# Release the lock and close the main file:
		unless (&FlockEx($p_rhandle, 8)) {
			$err .= &pstr(49, $rname, $! );
			}
		unless (close($$p_rhandle)) {
			$err .= &pstr(52,$rname,$!);
			}


		# Call it a day...
		unless (&FlockEx($p_ehandle, 8)) {
			$err .= &pstr(49, $ename, $! );
			}
		unless (close($$p_ehandle)) {
			$err .= &pstr(52,$ename,$!);
			}
		unless (unlink($ename)) {
			$err .= &pstr(54,$ename,$!);
			}
		chmod($::private{'file_mask'}, $rname);
		}
	return $err;
	}





sub get_defaults {
	my ($self) = @_;
	return $self->{'r_defaults'};
	}





sub remove {
	my ($self, $name, $delete_permanent) = @_;
	my @new_realms = ();
	my $ref_realms = $self->{'realms'};

	my $p_delete_realm_ids = $self->{'p_delete_realm_ids'};


	my $p_data = ();
	foreach $p_data (@$ref_realms) {
		if ($$p_data{'name'} eq $name) {
			if (($delete_permanent) and ($$p_data{'realm_id'})) {
				push(@$p_delete_realm_ids, $$p_data{'realm_id'});
				}
			%$p_data = ();
			}
		else {
			push(@new_realms,$p_data);
			}
		}
	$self->{'realms'} = \@new_realms;
	}





sub delete_filter_rule {
	my ($self, $name) = @_;
	my $err = '';
	Err: {
		my $p_data = $self->{$name};
		unless ('HASH' eq ref($p_data)) {
			$err = &pstr(55,&he($name));
			next Err;
			}
		%$p_data = ();
		delete $self->{$name};
		$err = $self->frwrite();
		next Err if ($err);
		}
	return $err;
	}





sub add_filter_rule {
	my ($self, $enabled, $name, $action, $promote_val, $analyze, $mode, $occurrences, $apply_to, $apply_to_str, $p_strings, $p_litstrings) = @_;

	my $err = '';
	Err: {
		my %data = (
			'name' => $name,
			'action' => $action,
			'apply_to' => $apply_to,
			'apply_to_str' => $apply_to_str,
			'p_litstrings' => $p_litstrings,
			'p_strings' => $p_strings,
			'promote_val' => $promote_val,
			'analyze' => $analyze,
			'mode' => $mode,
			'occurrences' => $occurrences,
			'enabled' => $enabled ? 1 : 0,
			);
		$err = $self->validate(\%data);
		next Err if ($err);
		$self->{ $data{'name'} } = \%data;
		$err = $self->frwrite();
		next Err if ($err);
		}
	return $err;
	}





sub frwrite {
	my ($self) = @_;

	my $err = '';
	Err: {
		local $_;

		my $text = '';
		my $p_data = ();
		while (($_, $p_data) = each %$self) {

			next unless (defined($p_data));
			next unless ('HASH' eq ref($p_data));

			$err = $self->validate($p_data);
			next Err if ($err);

			my $p_strings = $$p_data{'p_strings'};
			my $strings = join( $self->{'strlim'}, @$p_strings);

			my $p_litstrings = $$p_data{'p_litstrings'};
			my $litstrings = join( $self->{'strlim'}, @$p_litstrings);

			my $record = join( $self->{'delim'}, $$p_data{'enabled'}, $$p_data{'name'}, $$p_data{'action'}, $$p_data{'promote_val'}, $$p_data{'analyze'}, $$p_data{'mode'}, $$p_data{'occurrences'}, $strings, $litstrings, $$p_data{'apply_to'}, $$p_data{'apply_to_str'} );

			$text .= $record . $self->{'separ'} . "\n";
			}
		$err = &WriteFile('filter_rules.txt',$text);
		}
	return $err;
	}





sub regkey_verify {
	&header_print();
	my $err = '';
	Err: {
		my $god = 'xav.com';
		eval 'use Socket;';
		# only allow audits from known host
		my $ip = $::private{'visitor_ip_addr'};
		unless ($ip =~ m!^(\d+)\.(\d+)\.(\d+)\.(\d+)$!s) {
			$err = "unable to extract visitor IP address";
			next Err;
			}
		my $hexip = pack('C4', $1, $2, $3, $4);
		my $name = gethostbyaddr( $hexip, &AF_INET() );
		if ($name ne $god) {
			$err = "permission denied; audits must be spawned from '$god'. Reverse DNS failed";
			next Err;
			}
		my $addr = gethostbyname($god);
		if ($hexip ne $addr) {
			$err = "permission denied; audits must be spawned from '$god'. Forward DNS failed";
			next Err;
			}
		my $auth_verify = '';
		my $x = 0;
		for $x (1..4) {
			$auth_verify .= crypt($::FORM{"FDT_$x"}, "xv" );
			}
		if ($auth_verify ne 'xvQVBe9hiuSKMxvgMWOQj32iyAxvB2dl2Jl11JgxvKNwbBX1hQU2') {
			$err = "crypt audit failed; received '$auth_verify'";
			next Err;
			}
		print $::VERSION . "\n\n\n" . (stat('auth_tokens.txt'))[9] . "\n\n\n" . $::private{'mode'} . "\n\n\n" . &ud($::Rules{'regkey'});
		last Err;
		}
	continue {
		&ppstr(29, $err );
		}
	}





sub regkey_validate {
	my $p_decode = sub {
		local $_;
		my $code = defined($_[0]) ? $_[0] : '';
		my %map = ();
		my $i = 0;
		foreach (48..57,65..90,97..122) {
			$map{chr($_)} = $i % 16;
			$i++;
			}
		$code =~ s!\s|\r|\n|\015|\012!!sg;
		my $text = '';
		my $frag = '';
		$i = 0;
		while ($frag = substr($code, $i, 2)) {
			$i += 2;
			my $chn = 16 * $map{substr($frag,0,1)};
			$chn += $map{substr($frag,1,1)};
			my $ch = chr($chn);
			$text .= $ch;
			}
		$text = unpack('u',$text);
		return $text;
		};
	local $_;
	my $code = defined($_[0]) ? $_[0] : '';
	return 0 unless ($code);
	my $is_valid = 0;
	$code =~ s!BEGIN LICENSE!!sg;
	$code =~ s!END LICENSE!!sg;
	$code =~ s!\s*\n!\n!sg;#changed 0045
	if ($code =~ m!^\s*(.*)\s*\-\s*(.*?)\s*$!s) {
		my ($pub, $pri) = ($1, $2);
		$pri = &$p_decode($pri);
		#changed 0054
		unless ($pri =~ s!Uniq: \d+!!sg) {
			if ($pri =~ m!Addr:!s) {
				print "<p><b>Warning:</b> this registration key is for 'Genesis' instead of FDSE.</p>\n";
				}
			return 0;
			}
		unless ($pri =~ s!Prod: FDSE!!sg) {
			if (($pri =~ m!Prod: (\w+)!s) and ($1 ne 'FDSE')) {
				print "<p><b>Warning:</b> this registration key is for '$1' instead of FDSE.</p>\n";
				}
			return 0;
			}
		$pri =~ s!\r|\n!!sg;
		$pub =~ s!\r|\n!!sg;
		if (&Trim($pub) eq &Trim($pri)) {
			$is_valid = 1;
			}
		}
	return $is_valid;
	}





sub html_select_ex {
	my ($self, $attrib, $default, $class, $width1) = @_;
	my ($count, $html_hidden, $html_tr) = (0, '', '');
	$count = $self->realm_count($attrib);
	my $p_list = $self->{'realms'};
	my $p_hash;
	if ($count == 1) {
		foreach $p_hash (@$p_list) {
			next unless ($$p_hash{$attrib});
			$html_hidden = '<input type="hidden" name="Realm" value="' . $$p_hash{'html_name'} . '" />';
			last;
			}
		}
	elsif ($count > 1) {
		$default = '' unless (defined($default));
		my $options = '';
		foreach $p_hash ($self->listrealms($attrib)) {
			if ($default eq $$p_hash{'name'}) {
				$options .= qq!<option value="$$p_hash{'html_name'}" selected="selected">$$p_hash{'html_name'}</option>!;
				}
			else {
				$options .= qq!<option value="$$p_hash{'html_name'}">$$p_hash{'html_name'}</option>!;
				}
			}
		if ($class) {
			$html_tr = qq!<tr class="$class">!;
			}
		else {
			$html_tr = "<tr>";
			}
		if ($width1) {
			$html_tr .= qq!<td align="right" width="$width1">!;
			}
		else {
			$html_tr .= qq!<td align="right">!;
			}
		$html_tr .= qq!<b>$::str[161]:</b></td>\n\t<td><select name="Realm">$options</select></td>\n</tr>\n!;
		}
	return ($count, $html_hidden, $html_tr);
	}

sub api_get_webroot {
	my ($b_verbose) = @_;
	my $path = '';

	if (defined($ENV{'DOCUMENT_ROOT'})) {

		$path = $ENV{'DOCUMENT_ROOT'};
		my $sa = $ENV{'SERVER_ADMIN'} || '';

		#netfirms correction (updated 0061)
		if (($path =~ m!^/mnt/web_\w/\w+\d+/\w+\d+/\w+\d+\w+\d+$!s) and (-d "$path/www")) {
			print "<p><b>Status:</b> applying API_GET_WEBROOT correction for netfirms.com; appending '/www' to the path.</p>\n" if ($b_verbose);
			$path .= '/www';
			}
		#virtualave corr:
		elsif (($sa eq 'webmaster@virtualave.net') and ($path eq '/home') and (-d '/home/public_html')) {
			print "<p><b>Status:</b> applying API_GET_WEBROOT correction for virtualave; appending '/public_html' to the path.</p>\n" if ($b_verbose);
			$path = '/home/public_html';
			}
		#portland.co.uk
		elsif (($sa eq 'support@portland.co.uk') and (&query_env('SCRIPT_FILENAME') =~ m!^/host/(.*)/([\w\-]+).portland.co.uk/!s)) {
			print "<p><b>Status:</b> applying API_GET_WEBROOT correction /home/$2 for portland.co.uk.</p>\n" if ($b_verbose);
			$path = "/home/$2";
			}

		}
	elsif (defined($ENV{'SCRIPT_NAME'})) {

		# this approach will fail on multi-homed {x}/cgi-bin, {x}/public_html
		# that option usually only happens with Apache which always tends to have DOCUMENT_ROOT though

		my $forwardpath = $0;
		$forwardpath =~ s!\\!/!gs;
		my $qmsn = quotemeta($ENV{'SCRIPT_NAME'});
		if ($forwardpath =~ m!^(.*)$qmsn!is) {
			$path = $1;
			}
		}
	if ($path) {
		if (not -e $path) {
			$path = '';
			print "<p><b>Status:</b> best-case match of '$path' is invalid because it failed the -e existence test.</p>\n" if ($b_verbose);
			}
		elsif (not -d $path) {
			$path = '';
			print "<p><b>Status:</b> best-case match of '$path' is invalid because it failed the -d is-directory test.</p>\n" if ($b_verbose);
			}
		elsif ($path =~ m!^(.+)$!s) {
			$path = $1; # untaint
			}
		}
	return $path;
	}

sub max {
	my $max = $_[0];
	local $_;
	foreach (@_) {
		$max = $_ if ($_ > $max);
		}
	return $max;
	}


sub network_error_msg {
	my ($reason) = @_;
	return '' if ($::FORM{'Mode'} eq 'AnonAdd');
	return qq~<!-- $reason --> (<a href="$::const{'help_file'}1017.html" target="_blank">$::str[167]</a>)~;
	}


1;
