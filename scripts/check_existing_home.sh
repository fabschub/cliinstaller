#!/bin/sh
# DESCRIPTION: 	Check for existence of directory USERNAME on partition HOME_PARTITION.
# USAGE:	Call as check_existing_home.sh home_device username.
#
# RETURN VALUES:
#	0 no /home/username exists
#	1 error ocurred while trying to mount
#	2 /home/username exists

HOME_PARTITION="${1}"
USERNAME="${2}"
RETURN_VALUE="0"

MOUNT_POINT="$(mktemp -d /mnt/mount_check.XXXXXXXX)"
mkdir -p "${MOUNT_POINT}"
if mount "${HOME_PARTITION}" "${MOUNT_POINT}"; then
    if [ -d "${MOUNT_POINT}/${USERNAME}" ]; then
	RETURN_VALUE="2"
    fi
    umount "${MOUNT_POINT}"
else
    RETURN_VALUE="1"
fi

rmdir "${MOUNT_POINT}"
exit "${RETURN_VALUE}"