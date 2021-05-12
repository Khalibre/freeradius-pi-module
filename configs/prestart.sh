#!/bin/bash
if [ -d "/data/raddb" ]; then
 echo "found custom configuration direcoty"
 echo "copy the follwing to /etc/raddb/"
 rsync -raz --update --links /data/raddb/ /etc/freeradius/
 echo "copy succes"
else
  echo "not found the custom configuration direcoty in /data/raddb/"
fi
