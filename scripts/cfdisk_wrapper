#!/bin/sh
if [ "$DEBUG" = "TRUE" ]; then
	set -x
fi

# $1  program to use to make the partitions
# $2  disk that will partitioned

PROG=$1
DISK=$2

PARTITION_BEFORE="$(mktemp -p /tmp/ .partition_before.XXXXXXXXXX)"

PARTITION_AFTER="$(mktemp -p /tmp/ .partition_after.XXXXXXXXXX)"

#-------------------------------------------------
# 1. save old partition table into file b4
#-------------------------------------------------
fdisk -l "$DISK" | grep "^${DISK}" > $PARTITION_BEFORE
#
#-------------------------------------------------
# 2. call partiton program
#-------------------------------------------------
hal-lock --interface org.freedesktop.Hal.Device.Storage --exclusive \
                --run " ${PROG} ${DISK}"
#
#-------------------------------------------------
# 3. get the new partition save it into after
#-------------------------------------------------
fdisk -l "$DISK" | grep "^${DISK}" > $PARTITION_AFTER
#
# Only go on if both files exist
# take care when PARTITION_BEFORE was empty
# otherwise deny any work 
#-------------------------------------------------
# 4. now compare and if there are changes purpose user to format
# the "newly" created partitions
#-------------------------------------------------
#
if [ -s $PARTITION_AFTER -a -s $PARTITION_BEFORE ]; then
	awk  '{var = $(NF-1); if (var == "/") {var = $(NF-4);} printf("%s %s\n", $1, var);}'  $PARTITION_AFTER | \
	while read part id; do
		old_line=$(grep -w "${part}" $PARTITION_BEFORE)
		new_line=$(grep -w "${part}" $PARTITION_AFTER)

		if [ "$new_line" = "$old_line" ]; then
			echo "nothing to be done for partition ${part}"
		else
			case $id in
			82)
				mkswap ${part}
				;;
			83)
				mkfs.ext2 ${part}
				;;
			*)
				echo "Skipping ${part} ..."
				;;
			esac
		fi
	done 
elif [ -s $PARTITION_AFTER -a ! -s $PARTITION_BEFORE ]; then
	awk  '{var = $(NF-1); if (var == "/") {var = $(NF-4);} printf("%s %s\n", $1, var);}'  $PARTITION_AFTER | \
	while read part id; do
		case $id in
		82)
			mkswap ${part}
			;;
		83)
			mkfs.ext2 ${part}
			;;
		*)
			echo "Skipping ${part} ..."
			;;
		esac
	done 
else
	: # do nothing, cleanup and leave
fi

test -e "$PARTITION_BEFORE" && rm -f "$PARTITION_BEFORE"
test -e "$PARTITION_AFTER"  && rm -f "$PARTITION_AFTER"

