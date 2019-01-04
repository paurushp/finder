#use strict;#if-debug
sub version_test {
	return '2.0.0.0073';
	}





sub test_file_based_index {
	my ($file, $b_verbose) = @_;
	my $err = '';
	Err: {

		# determine whether everything is in alphabetic order


		my ($obj, $p_rhandle);
		$obj = &LockFile_new(
			'create_if_needed' => 0,
			);
		($err, $p_rhandle) = $obj->Read($file);
		next Err if ($err);

		my $prev_url = '';
		my $line = 0;
		while (defined($_ = readline($$p_rhandle))) {
			$line++;

			if (not (m!^\d+ \d+ \d+ u= (.+?) t=!)) {
				$err = "line $line of file $file does not pattern match as a valid FDSE index record";
				next Err;
				}

			my $this_url = $1;

			print "<p>Comparing previous $prev_url to current URL $this_url</p>\n";

			if ($prev_url gt $this_url) {
				($prev_url, $this_url) = &he($prev_url, $this_url);
				$err = "line $line of file $file contains URL $this_url; the URL from the previous line $prev_url is greater, violating alphabetic order";
				next Err;
				}
			elsif ($prev_url eq $this_url) {
				$err = "line $line of file $file contains a duplicate URL";
				next Err;
				}

			$prev_url = $this_url;

			# otherwise all ok
			next;
			}

		$err = $obj->Close();
		next Err if ($err);

		if ($b_verbose) {
			print "<p><b>Status:</b> analyzed <strong>$line</strong> lines in file $file.  All lines are valid, ordered URL records.</p>\n";
			}





		last Err;
		}
	return $err;
	}

1;