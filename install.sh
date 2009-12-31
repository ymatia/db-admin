#!/usr/bin/ksh

echo "Welcome to DBAdmin\'s installation program"
if [ "$3" == "" ] ; then
        echo "Bad syntax when running install program"
        echo "Syntax: install.cmd connect_string os oracle_applications"
        echo "  connect_string to the database like \"apps/apps@prod\""
        echo "  os - \"nt\" or \"unix\""
        echo "  oracle_applications - \"no\",\"11i\",\"11i10\""
else
        if [ "$3" == "no" ] ; then
                sqlplus $1 @install_noapps.sql $2 $3
        else
                sqlplus $1 @install.sql $2 $3
        fi
fi
