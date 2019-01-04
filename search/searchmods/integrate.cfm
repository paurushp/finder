<!--- FDSE Cold Fusion integration template             --->
<!--- originally contributed by David of duick.com with --->
<!--- modifications by Zoltan Milosevic                 --->
<!--- Last updated 2003-11-26                           --->
<!--- VERSION 2.0.0.0073                                --->
<!---
------------------------------------------------------------

Call this module using the following code, with parameters
adjusted to match your server setup:

<cfmodule
	template="searchmods/integrate.cfm"
	search_script="e:\www.xav.com\search\search.pl"
	echo_verbose="1"
	self_url="#cgi.script_name#"
	path_to_perl="c:\perl\bin\Perl.exe"
	>
<cfoutput>
	#FDSE_Output#
</cfoutput>

------------------------------------------------------------
--->


<cfset caller.FDSE_Output="!fatal error while generating search output">

<cfif attributes.echo_verbose>
	<cfoutput>
		<style>p.FDSE { background-color:pink; }</style>
		<p class=FDSE><b>Trace:</b> you can disable these Trace statements by setting echo_verbose = 0 in your CFM file.</p>
		<p class=FDSE><b>Trace:</b> see <a href="http://www.xav.com/scripts/search/help/1195.html">http://www.xav.com/scripts/search/help/1195.html</a> for help.</p>
		<p class=FDSE><b>Trace:</b> starting function FDSE_output</p>
	</cfoutput>
</cfif>

<cfif FileExists(attributes.path_to_perl)>
	<cfif attributes.echo_verbose>
		<cfoutput><p class=FDSE><b>Trace:</b> validated existence of '#attributes.path_to_perl#'.</p></cfoutput>
	</cfif>
<cfelse>
	<cfoutput><p><b>integrate.cfm Fatal Error:</b> path to perl '#attributes.path_to_perl#' does not exist.</p></cfoutput>
	<cfabort>
</cfif>

<cfif FileExists(attributes.search_script)>
	<cfif attributes.echo_verbose>
		<cfoutput><p class=FDSE><b>Trace:</b> validated existence of '#attributes.search_script#'.</p></cfoutput>
	</cfif>
<cfelse>
	<cfoutput><p><b>integrate.cfm Fatal Error:</b> search script '#attributes.search_script#' does not exist.</p></cfoutput>
	<cfabort>
</cfif>

<cfif attributes.echo_verbose>

	<p class=FDSE><b>Trace:</b> testing support for FDSE_shell_exec()</p>
	<cfset TestStr = "Larry Wall">
	<cfsavecontent variable="output">
		<cftry>
			<cfexecute name=#attributes.path_to_perl# arguments="-v" timeOut="5"></cfexecute>
			<cfcatch>
				<cfoutput>#CFCATCH.Message#<br />#CFCATCH.Detail#<br />#CFCATCH.ExtendedInfo#</cfoutput>
				<cfabort>
			</cfcatch>
		</cftry>
	</cfsavecontent>

	<cfif FindNoCase(TestStr,output)>
		<p class=FDSE><b>Success:</b> FDSE_shell_exec tests ok</p>
	<cfelse>
		<cfoutput><p class=FDSE><b>Error fdse-cfm-2:</b> FDSE_shell_exec() test failed. Command '#attributes.attributes.path_to_perl# -v' did not return expected string '#teststr#'. Instead returned #output#.</p> #fdse_help#</cfoutput>
		<cfabort>
	</cfif>

</cfif>

<cfset fdseArguments=#cgi.query_string#>
<cfset fdseArguments=#Replace(fdseArguments,"&"," ","all")#>
<cfset fdseArguments=#Replace(fdseArguments,";","%3B","all")#>
<cfset fdseArguments=#Replace(fdseArguments,"|","%7C","all")#>
<cfset fdseArguments=#Replace(fdseArguments,">","%3E","all")#>
<cfset fdseArguments=#Replace(fdseArguments,"<","%3C","all")#>
<cfset fdseArguments=#Replace(fdseArguments,'"',"%22","all")#>

<cfset fdseArguments="#attributes.search_script# is_shell_include=1 search_url=#attributes.self_url# #fdseArguments#">

<cfif attributes.echo_verbose>
	<cfoutput><p class=FDSE><b>Trace:</b> Perl arguments are:<br /><br /><tt>#fdseArguments#</tt></p></cfoutput>
</cfif>

<cfif attributes.echo_verbose >
	<cfoutput><p class=FDSE><b>Trace:</b> running command:<br /><br /><pre>#attributes.path_to_perl# #fdseArguments#</pre></p></cfoutput>
</cfif>

<cftry>
	<cfset fdseTempFile = #GetTempFile(GetTempDirectory(),"fdse")#>
	<cfexecute name="#attributes.path_to_perl#" arguments="#fdseArguments#" outputfile="#fdseTempFile#" timeOut="10"></cfexecute>
	<cffile action="READ" file="#fdseTempFile#" variable="caller.FDSE_Output">
	<cffile action="DELETE" file="#fdseTempFile#">
	<cfcatch>
		<cfoutput>#CFCATCH.Message#<br />#CFCATCH.Detail#<br />#CFCATCH.ExtendedInfo#</cfoutput>
	</cfcatch>
</cftry>