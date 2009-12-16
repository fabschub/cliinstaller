#!/bin/sh
#
# (C) 2008 Joaquim Boura <x-un-i@sidux.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this package; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# On Debian GNU/Linux systems, the text of the GPL license can be
# found in /usr/share/common-licenses/GPL.
#
#--------------------------------------------------------------------------
# Simple script to umount all partitions before the installer starts his work
# or to return 1 if any partition is mounted and could not be umounted
# called with one parameter ( value does not matter) just inquiries if there 
# is at least one partition mounted returning 1 in this case.
# when only swap is mounted then return 2
#--------------------------------------------------------------------------
 
umount_all_drives()
{
	local ok=0
	local do_it=$1
	
	# Kill any process using /media/hdinstall. If install-gui is killed,
	# fll-installer and its rsync processes might still be running.
	if [ -e /media/hdinstall ]; then
		fuser -k /media/hdinstall
	fi

	local TempFile=`mktemp -p /tmp/ .XXXXXXXXXX`

	mount | grep -v "/fll/persist" | awk '/^\/dev/{print $1":"$3":"$5}' > $TempFile

	while IFS=: read device mountpoint typ; do 
		case "$typ" in 
		ext2|ext3|ext4|reiserfs|vfat|jfs|xfs|ntfs) 
			if mount | grep -q "^$device "; then
				uuid=$(udevadm info -q env --name $device | \
					awk 'BEGIN{FS="="}/ID_FS_UUID=/{print $2}')
				if [ ! "/fll${device#/dev}" = "$mountpoint" ];  then
					if [ "$do_it" = "check" ]; then 
						ok=1
					else
						if [ ! "/fll/${uuid}" = "$mountpoint" ]; then
							umount "$mountpoint" 
							ok=$? 
						else
							ok=0
						fi
					fi
				else
					ok=0
					# Caveat: on fromiso we must allow the partition
					# to remain mounted so user is playing russian
					# roulette with his partitions
					#
				fi
			fi
			;;	
		 auto|udf*)  
			ok=0
			;;# nothing to do skip
		squashfs|iso9660)
			ok=0
			;;
		*)
			ok=255 # unknow reason
		esac
		if [ "$ok" -eq 0 ] || [ "$ok" -eq 2 ]; then
			ok=0 # ignore device is not mounted or was sucessfuly umounted
		elif [ "$ok" -eq 1 ]; then  # device busy
			break
		else
			break  # some other errorcode
		fi
	done< $TempFile
	[ -e "${TempFile}" ] && rm -f ${TempFile} 

	# now handle aktive swap devices 
	swapon -s | awk '/^\/dev/{print $1}' > $TempFile
	if [ "$do_it" = "check" ]; then
		if [ "$ok" -eq 0 ]; then
			[ -s "$TempFile" ] && ok=2
		fi
	else
		if [ "$ok" -eq 0 ]; then
			if [ -s "$TempFile" ]; then
				while read part ; do
					swapoff $part
					if [ "$?" -ne 0 ];then
						ok=1
						break;
					fi
				done < $TempFile
			fi
		fi
	fi
	[ -e "${TempFile}" ] && rm -f ${TempFile} 
	
	return $ok
}

if [ $# -eq 1 ] ; then
	par="check"
else
	par="doit"
fi

umount_all_drives $par
rc=$?

exit $rc

