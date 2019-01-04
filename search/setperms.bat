@ECHO OFF

echo _______________________________________________________________________________
echo.
echo   Updated 24 Aug 2001 by Zoltan Milosevic
echo.
echo   This batch file sets the proper file permissions on Windows NT/2000 for the
echo   Fluid Dynamics Search Engine.  Use "setperms.sh" for Unix systems.
echo.
echo   To run, open a command prompt or telnet window and navigate to the folder
echo   just above the "searchdata" folder.  Type the name for
echo   this script, and hit Enter.  All proper permissions will be set.
echo.
echo   Run this file from an account which has the "Change Permission" privilege
echo   for all files in the "searchdata" folder.  Typically the Administrator or
echo   file owner accounts would be appropriate.
echo.
echo   For more information, visit http://www.xav.com/scripts/search/
echo.
echo _______________________________________________________________________________
echo.


REM	This command grants Permission level "Change" to the "Everyone" group.
REM	Other permissions are left in place.  This command acts on all files
REM	in the "searchdata" data folder and all subdirectories.

cacls searchdata /T /E /C /P Everyone:C
attrib -R * /S /D
