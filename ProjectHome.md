# DBAdmin - the tool for database and E-Business Suite administrators #
## Features: ##
  * Very “light weight”.
  * Easy to install – just 3 packages and a view!
  * No client installation necessary – runs on a browser!
  * Fast responses (Runs on pl/sql cartridge).
  * It’s free.
## Installation instructions: ##
  1. Download the software.
  1. Unzip the zip file into a temporary directory on your PC
  1. Go into the directory where you unzipped the files
  1. You need to run the installation script once for each database that you have. The installation accepts 3 parameters:
    1. connect string (eg. apps/apps@prod)
    1. database operating system - "UNIX" or "NT"
    1. oracle applications version - "no", "11" or "11i"
`Example: install.cmd apps/apps@prod UNIX 11i`

This script does not need to be run from the server, and you can run it from any PC with an oracle home installed.

If you insist, I have included also an install.sh, so you can extract the zip file to your unix server, and run it from there.

Please notice that non-Oracle Applications databases may get a couple of errors during the install script - you can ignore them.

To run the utility, open the internet explorer / netscape and go to this URL:
`http://<host>:<port>/pls/<sid>/dbax_dbadmin.main`

Please notice that this tool is something we are playing with, so there may be some bugs.

There is still no user guide (just click on the different items on the left, it’s not that complicated).

For any question, enhancement requests, ideas, you can reach us at these emails:
[yariv.matia@gmail.com](mailto:yariv.matia@gmail.com) and [kobi@kobtech.co.il](mailto:kobi@kobtech.co.il)



Good Luck,

Yariv Matia and Kobi Masika.