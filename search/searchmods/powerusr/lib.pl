
sub force_CRLF {
	my ($p_text) = @_;
	$$p_text =~ s!\015\012!\012!sg;
	$$p_text =~ s!\015!\012!sg;
	$$p_text =~ s!\012!\015\012!sg;
	}

sub ReadFile {
	my ($file) = @_;
	my $text = '';
	my $err = '';
	Err: {
		if (not defined($file)) {
			$err = "invalid argument; sub ReadFile(file) was passed an undefined value";
			next Err;
			}
		local $_;
		unless (open(FILE, "<$file")) {
			$err = "unable to read file '$file' - $! - $^E";
			next Err;
			}
		unless (binmode(FILE)) {
			$err = "unable to set binmode on file '$file' - $! - $^E";
			next Err;
			}
		while (defined($_ = <FILE>)) {
			$text .= $_;
			}
		unless (close(FILE)) {
			$err = "unable to close file '$file' - $! - $^E";
			next Err;
			}
		last Err;
		}
	return ($err, $text);
	};


sub WriteFile {
	my ($file, $text) = @_;
	my $err = '';
	Err: {
		unless (defined($file)) {
			$err = "invalid argument - 'file' parameter not defined";
			next Err;
			}
		unless (defined($text)) {
			$err = "invalid argument - 'text' parameter not defined";
			next Err;
			}
		unless (open(FILE, ">$file")) {
			$err = "unable to write to file '$file' - $!";
			next Err;
			}
		unless (binmode(FILE)) {
			$err = "unable to set binmode on file '$file' - $!";
			close(FILE);
			next Err;
			}
		unless (print FILE $text) {
			$err = "error occurred while writing to file '$file' - $! - $^E";
			close(FILE);
			next Err;
			}
		unless (close(FILE)) {
			$err = "unable to close file '$file' - $! - $^E";
			next Err;
			}
		last Err;
		}
	return $err;
	};

sub Trim {
	local $_ = defined($_[0]) ? $_[0] : '';
	s!^[\r\n\s]+!!o;
	s![\r\n\s]+$!!o;
	return $_;
	}
1;
