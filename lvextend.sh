#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

PARTITIONS=$(df -h | grep -E '^\/dev\/mapper\/' | awk '{print $1}')

VAR_PART=false
AVAILABLE=$(vgdisplay centos --units B | grep -F 'Free  PE / Size' | cut -d '/'  -f3 | cut -d ' ' -f2)
for PARTITION in ${PARTITIONS}; do
    if [ "$PARTITION" != "/dev/mapper/centos-var" ]; then
        if [ "$AVAILABLE" -ge 2000000000 ]; then
            lvextend -L +2000000000B $PARTITION
            xfs_growfs $PARTITION
            AVAILABLE=$(vgdisplay centos --units B | grep -F 'Free  PE / Size' | cut -d '/'  -f3 | cut -d ' ' -f2)
        fi
    else
        VAR_PART=true
    fi
done

if [ "$AVAILABLE" -gt 0 ]; then
    if $VAR_PART; then
        lvextend -L +${AVAILABLE}B /dev/mapper/centos-var
        xfs_growfs /dev/mapper/centos-var
    fi
fi

exit 0
