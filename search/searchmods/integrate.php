<?php

/*

VERSION 2.0.0.0073
Copyright 2005 Zoltan Milosevic

Usage:

	echo FDSE_output( "search.pl", 0, $_SERVER['SCRIPT_NAME'], "/usr/bin/perl" );

This function makes a system call to the local "search.pl" Perl script, and returns the output of that script, or an error if the script cannot be called.

The Perl search script is called with the same parameters as the local PHP script was called (i.e., "q", "maxhits", "Rank", and so on.)  The output of the search script will use the self-referencing URL of the PHP script instead of the URL to the Perl script.

*/

function FDSE_output ($search_script, $echo_verbose, $self_url, $path_to_perl)
{

	$helptext = '

<br />	See also:
<br />
<br />	"Customizing the FDSE layout using PHP"
<br />
<br /><a href="http://www.xav.com/scripts/search/help/1193.html" target="_blank">

    	http://www.xav.com/scripts/search/help/1193.html

</a>';

	if ($echo_verbose) {
		echo "<style>p.FDSE {background-color:#ffcccc;}</style>\n";
		echo "<p class=FDSE><b>Trace:</b> you can disable these Trace statements by setting \$verbose = 0; in your PHP file.</p>\n";
		echo "<p class=FDSE><b>Trace:</b> starting function FDSE_output</p>\n";
		}

	if (!file_exists($search_script)) {
		return "<p class=FDSE><b>Error php-3:</b> script file '$search_script' does not exist - check the \$search_script variable.</p>\n$helptext";
		}

	if (!file_exists($path_to_perl)) {
		return "<p class=FDSE><b>Error:</b> Perl interpreter '$path_to_perl' does not exist - check the \$path_to_perl variable.</p>\n$helptext";
		}

	if ($echo_verbose) {
		echo "<p class=FDSE><b>Trace:</b> testing support for shell_exec()</p>\n";
		$teststr = 'Larry Wall';
		$command = "$path_to_perl -v";
		$output = shell_exec($command);
		if (strstr( $output, $teststr )) {
			echo "<p class=FDSE><b>Success:</b> shell_exec tests ok</p>\n";
			}
		else {
			return "<p class=FDSE><b>Error fdse-php-2:</b> shell_exec() test failed.  Command '$command' did not return expected string '$teststr'.  Instead returned '$output'.</p>\n$helptext";
			}
		}

	# create a readable format for parameters

	$params = 'is_shell_include=1 search_url=' . urlencode($self_url) . ' ';

	if ($_SERVER['REQUEST_METHOD'] == 'POST') {
		foreach ($_POST as $key => $this) {
			if (get_magic_quotes_gpc()) { #changed 0070
				$this = stripslashes($this);
				}
			$params .= urlencode($key) . '=' . urlencode($this) . ' ';
			}
		}
	else {
		foreach ($_GET as $key => $this) {
			if (get_magic_quotes_gpc()) { #changed 0070
				$this = stripslashes($this);
				}
			$params .= urlencode($key) . '=' . urlencode($this) . ' ';
			}
		}

	$command = "$path_to_perl $search_script $params 2>&1";

	if ($echo_verbose) {
		$hcommand = htmlspecialchars($command);
		echo "<p class=FDSE><b>Trace:</b> running command:<br /><br />$hcommand</p>\n";
		}

	$output = shell_exec($command);

	if ($echo_verbose) {
		$len = strlen($output);
		echo "<p class=FDSE><b>Trace:</b> command returned <b>$len</b> bytes of output.</p>\n";
		}


	return $output;

}

?>
