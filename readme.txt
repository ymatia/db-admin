README file for DBAdmin

How to install:
================
Unzip the zip file to a temporary directory (eg. c:\temp)
Open a command prompt and go to the directory where you extracted the zip file.
run the install.cmd script for every database - it accepts 3 parameters: 
	1. connect string (eg. apps/apps@prod)
	2. database operating system - "UNIX" or "NT"
	3. oracle applications version - "no", "11" or "11i"
Example:
	install.cmd apps/apps@prod UNIX 11i

This script does not need to be run from the server, and you can run it from any PC with an oracle home installed.
If you insist, I have included also an install.sh, so you can extract the zip file to your unix server, and run it from there.

Please notice that non-Oracle Applications databases may get a couple of errors during the install script - you can ignore them.

Good Luck,
Yariv Matia
yariv.matia@gmail.com

Previous Versions:
===================
Version 1.4.2 Beta
    - Extended date to Jan 1st, 2009
Version 1.4.1 Beta
    - Extended date to May 30th, 2008
Version 1.4 Beta
    - Added test of available next free extent (monitor only)
Version 1.3.10 Beta
    - Added Shadow pid also to database users report.
Version 1.3.9 Beta
    - Fixed os process and added shadow pid to Running Programs.
    - Added "Modifiable" column in init.ora screen.
    - Added "Long Running Requests" report.
    - Added "Workflow Errors" report, and a link in the monitor screen.
    - Added CRs in before mrc.
Version 1.3.8 Beta
    - added password protection to kill and terminate (using constant).
    - fixed code to also fit 10g
    - links in the application info open in a new window
Version 1.3.7 Beta
    - added analyze and analyze_conc APIs for analyzing tables not analyzed recently.
    - added DBAX_DBADMIN.resize_all_to_optimal API, that will output a list of all tablespace resizing.
    - added dbax_dbadmin_app.retry_workflow and retry_workflow_conc APIs for retrying errored workflows.
Version 1.3.6 Beta
    - moved constants into a table dbax_dbadmin_const, which you can change and it won''t be overrun
    - added workflow errors to monitor
    - added discoverer, aol/j tests, application manager links to application info
    - added Sid and kill columns to running programs and changed sort order
    - Changed monitor from frameset to one page
    - added an empty dbax_dbadmin_app package for non-apps databases
    - Improved mechanism for recommending tablespace resizing.
    - Fixed bug in monitor - to not show tablespaces that are over 20% free.
    - Modified dbax_profiles_v to also show profiles with no values.
    - Fixed bug with very long db_name
Version 1.3.5
    - added init.ora parameters screen.
    - fixed Bug: monitor doesn't display tablespaces with zero free space.
    - added view dbax_tablespaces_v to the package, and connected it to Tablespaces form.
    - added view dbax_profiles_v to the package, but it has too many rows, so no screen yet.
    - added temporary space usage screen.
    - added application info screen.
Version 1.3.4
    - Modified the re-enqueue notification process
    - Extended free date to 31-MAY-2006
Version 1.3.3
  	- Minor bug fixes
  	- Extended date to 31-DEC-2005
Version 1.3.2
	- Fixed "Locks" and "Locks Extended" not showing Blocking/Not Blocking properly.
	- Added list of changes to Intro screen.
	- Added "View Log" and "View Output" functionality in Running Programs.
	- Added "Completed Requests" screen.
Version 1.3.1
	- small fixes - changes in column order
	- removed number formatting from columns which shouldn't be formatted (process number, patch number, ...)
Version 1.3
	- Changed the tech base to use a specially developed grid - enable sorting, faster development
	- Added User I/O Waits, Active SQLs, Self-Service Sessions, Before MRC
	- Added drill down from Running Programs to the program's details
Version 1.2b 
	- Added an install.cmd script for installing
	- Added support for non-Oracle Applications databases
	- Created this readme file
Version 1.1b - first public version - still needs work in order to become a "product"
Version 1.0b - first version - all the functionality but badly "wrapped"
