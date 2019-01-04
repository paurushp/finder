#!/bin/sh

echo __________________________________________________________________
echo
echo Updated 2002-08-01 by Zoltan Milosevic
echo
echo This batch file sets the proper file permissions on Unix for the
echo Fluid Dynamics Search Engine.  Use "setperms.bat" for Windows
echo systems.
echo
echo To run, open a command prompt or telnet window and navigate to
echo the folder just above the "searchdata" folder.  Run this command
echo by typing "./setperms.sh" or "/bin/sh setperms.sh".  All proper
echo permissions will be set.
echo
echo Run this file from an account which has "change permission"
echo rights for all files within the search folder.  Typically the
echo root or file owner accounts would be appropriate.
echo
echo For more information, visit http://www.xav.com/scripts/search/
echo
echo __________________________________________________________________
echo

echo Setting permissions...
chmod 755 search.*
chmod 755 proxy.*
cd searchdata
chmod -R 777 .
chmod -R 666 *.*
cd ..
echo

echo __________________________________________________________________
echo
echo Note: if FDSE has already been installed, then some operations
echo will fail as \"chmod: xxx.txt: Operation not permitted\".  This is
echo expected and is not a problem.
echo
echo Permissions finished.
echo __________________________________________________________________
echo
