<%

'' VERSION 2.0.0.0073
'' Copyright 2005 Zoltan Milosevic
''
'' Usage:
''
'' 	Response.Write FDSE_output( "search.pl", 0, Request.ServerVariables("SCRIPT_NAME") )
''
'' This function makes a system call to the "search.pl" Perl script, and returns the output of that script, or an error if the script cannot be called.
''
'' The Perl search script is called with the same parameters as the local ASP script was called (i.e., "q", "maxhits", "Rank", and so on.)  The output of the search script will use the self-referencing URL of the ASP script instead of the URL to the Perl script.

dim fdse_help
fdse_help = "<a href=http://www.xav.com/scripts/search/help/1192.html target=_blank>FDSE-ASP integration help</a>"

function FDSE_shell_exec (command)

	dim wshshell, oexec, output
	on error resume next

	output = ""

	set WshShell = CreateObject("WScript.Shell")

	if (Err.Number) then
		FDSE_shell_exec = "<p><b>Error fdse-asp-1:</b> unable to create object WScript.Shell - " & Err.Number & " - " & Err.Description & ".</p>" & fdse_help
		exit function
	end if

	if (not IsObject(WshShell)) then
		FDSE_shell_exec = "<p><b>Error fdse-asp-1:</b> unable to create object WScript.Shell (unknown error).</p>" & fdse_help
		exit function
	end if


	'' shell to the command:

	set oexec = WshShell.Exec(command)

	if (Err.Number) then
		FDSE_shell_exec = "<p><b>Error fdse-asp-2:</b> unable to execute command '" & command & "' - " & Err.Number & " - " & Err.Description & ".</p>" & fdse_help
		exit function
	end if

	if (not IsObject(oexec)) then
		FDSE_shell_exec = "<p><b>Error fdse-asp-2:</b> unable to execute command '" & command & "' (unknown error).</p>" & fdse_help
		exit function
	end if

	do while true
		if oexec.stdout.AtEndOfStream then
			exit do
		else
			  output = output & oexec.stdout.read(1)
		end if
	loop
	do while true
		if oexec.stderr.AtEndOfStream then
			exit do
		else
			  output = output & oexec.stderr.read(1)
		end if
	loop

	FDSE_shell_exec = output

end function


function FDSE_output (search_script, echo_verbose, self_url, path_to_perl)

	if (echo_verbose) then
		Response.Write( "<style>p.FDSE { background-color:#ffcccc; }</style>" )
		Response.Write "<p class=FDSE><b>Trace:</b> you can disable these Trace statements by setting verbose = 0 in your ASP file.</p>"
		Response.Write "<p class=FDSE><b>Trace:</b> starting function FDSE_output</p>"
	end if

	if (echo_verbose) then
		Response.Write "<p class=FDSE><b>Trace:</b> testing support for FDSE_shell_exec()</p>"
		teststr = "Larry Wall"
		command = path_to_perl & " -v"
		output = FDSE_shell_exec(command)
		if (instr( output, teststr )) then
			Response.Write "<p class=FDSE><b>Success:</b> FDSE_shell_exec tests ok</p>"
		else
			FDSE_output = "<p class=FDSE><b>Error fdse-asp-4:</b> FDSE_shell_exec() test failed.  Command '" & command & "' did not return expected string '" & teststr & "'.  Instead returned '" & output & "'.</p>" & fdse_help
			exit function
		end if
	end if


	dim ScriptFilePath
	ScriptFilePath = search_script

	if (InStr( ScriptFilePath, ":\" )) then
		'' ok - full path

		if (echo_verbose) then
			Response.Write "<p class=FDSE><b>Trace:</b> assuming path '" & ScriptFilePath & "' is a fully-qualified file system path (contains ':\')</p>"
		end if

	else

		if (echo_verbose) then
			Response.Write "<p class=FDSE><b>Trace:</b> assuming path '" & ScriptFilePath & "' is relative.  Attempting to expand to fully-qualified path...</p>"
		end if

		dim ServerFilePath
		ServerFilePath = Server.MapPath( self_url )

		if (echo_verbose) then
			Response.Write "<p class=FDSE><b>Trace:</b> local file path is '" & ServerFilePath & "'</p>"
		end if

		dim LastSepar
		LastSepar = InStrRev( ServerFilePath, "\" )

		ScriptFilePath = Left( ServerFilePath, LastSepar ) & search_script

		if (echo_verbose) then
			Response.Write "<p class=FDSE><b>Trace:</b> expanded path to search script is '" & ScriptFilePath & "'</p>"
		end if

	end if


	'' create a readable format for parameters

	dim params
	params = "is_shell_include=1 search_url=" & Server.URLEncode(self_url) & " "

	dim varName
	for each varName in Request.Form
		params = params & Server.URLEncode(varName) & "=" & Server.URLEncode(Request.Form(varName)) & " "
	next
	for each varName in Request.QueryString
		params = params & Server.URLEncode(varName) & "=" & Server.URLEncode(Request.QueryString(varName)) & " "
	next

	dim RegEx
	set RegEx = new RegExp

	RegEx.Pattern = "[^A-Z0-9\_\/\\\-\.\:\~]"
	RegEx.IgnoreCase = true

	if (RegEx.Test( ScriptFilePath )) then
		dim hurl
		hurl = Server.HTMLEncode( ScriptFilePath )
		FDSE_output = "<p class=FDSE><b>Error fdse-asp-5:</b> Perl path " & hurl & " not allowed.  The path can contain only characters in the set A-Z 0-9 _ . / \ - : ~</p>" & fdse_help
		exit function
	end if

	dim command
	command = path_to_perl & " " & ScriptFilePath & " " & params

	if (echo_verbose) then
		hcommand = Server.HTMLEncode(command)
		Response.Write "<p class=FDSE><b>Trace:</b> running command:<br /><br />" & hcommand & "</p>"
	end if

	dim output
	output = FDSE_shell_exec(command)

	if (echo_verbose) then
		outlength = len(output)
		Response.Write "<p class=FDSE><b>Trace:</b> command returned <b>" & outlength & "</b> bytes of output.</p>"
	end if

	FDSE_output = output

end function

%>
