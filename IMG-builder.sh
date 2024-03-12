#!/bin/bash
#
# Copyright © 2024 Quintor B.V.
#
# BCLD is gelicentieerd onder de EUPL, versie 1.2 of
# – zodra ze zullen worden goedgekeurd door de Europese Commissie -
# latere versies van de EUPL (de "Licentie");
# U mag BCLD alleen gebruiken in overeenstemming met de licentie.
# U kunt een kopie van de licentie verkrijgen op:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Tenzij vereist door de toepasselijke wetgeving of overeengekomen in
# schrijven, wordt software onder deze licentie gedistribueerd
# gedistribueerd op een "AS IS"-basis,
# ZONDER ENIGE GARANTIES OF VOORWAARDEN, zowel
# expliciet als impliciet.
# Zie de licentie voor de specifieke taal die van toepassing is
# en de beperkingen van de licentie.
#
#
# Copyright © 2024 Quintor B.V.
#
# BCLD is licensed under the EUPL, Version 1.2 or 
# – as soon they will be approved by the European Commission -
# subsequent versions of the EUPL (the "Licence");
# You may not use BCLD except in compliance with the Licence.
# You may obtain a copy of the License at:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Unless required by applicable law or agreed to in
# writing, software distributed under the License is
# distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
# See the License for the specific language governing
# permissions and limitations under the License.
# 
#
# IMG Builder
# IMG-builder.sh uses the generated ISO image from ISO-builder.sh
# and packs it inside an IMG file using USB partitioning and 
# ./config/bcld/bcld.cfg to create a config file for the user.
#
#
# Set to exit immediately on any sign of errors, because
# grub-install can be tricky
set -e

if [[ -f "$(pwd)/IMG-builder.sh" ]]; then


    
    TAG='IMAGE-INIT'
    
    source './config/BUILD.conf'
    source './script/echo_tools.sh'
    source './script/file_operations.sh'

    list_header "Generating IMG-file"

    # Check for ISO artifact
    check_iso_file

    # Project root
	EFI_PART=102400 # About 50MB for bootloaders
	IMG_NAME="${BCLD_VERSION_FILE}.img"
	PROJECT_DIR="$(pwd)"
	#MOUNT_FS='/mnt/BCLD-USB-FS'
	RW_PART=102400 # About 50MB for logs and configurations
	
	## DIRs
	ART_DIR="${PROJECT_DIR}/artifacts"
	BOOTSTRAP_DIR="${PROJECT_DIR}/bootstrap"
	CONFIG_DIR="${PROJECT_DIR}/config"
	CHROOT_DIR="${PROJECT_DIR}/chroot"
	IMG_DIR="${PROJECT_DIR}/image"
	
	GRUB_DIR="${IMG_DIR}/boot/grub"
	EFI_IMAGE_GRUB="${CONFIG_DIR}/grub/grub.cfg.img"
	IMG_ART="${ART_DIR}/${IMG_NAME}"
	ISO_ART="${ART_DIR}/${ISO_NAME}"
	ISO_DIR="${IMG_DIR}/ISO"
	
	EFI_DIR="${ISO_DIR}/EFI"
	IMAGE_GRUB="${GRUB_DIR}/grub.cfg"
	
	EFI_BOOT_DIR="${EFI_DIR}/BOOT"

	## Calculations	
	iso_size=$(/usr/bin/du "${ISO_ART}" | /usr/bin/awk '{print $1}')
	img_size=$(( iso_size + RW_PART + EFI_PART ))
#	ISO_DIR="${IMG_DIR}/ISO"

    
    # If BCLD_MODEL isn't sourced, it should be declared within the Bamboo agent.
    if [[ -z ${BCLD_MODEL} ]]; then
        list_item_fail "BCLD_MODEL is not allowed to be empty..."
        last_item "Enable this ENVs first!"
        on_failure
    fi

else
    /usr/bin/echo -e "\nPlease run script inside project directory!\n"
	exit 1
fi

# Functions

## Function to unmount systems
function clear_img_mounts () {
	
	# Always sync and wait 2s first
	/usr/bin/sync && /usr/bin/sleep 2s
	clear_mount "${MOUNT_EFI}"
	clear_mount "${MOUNT_FS}"
}

## Function to clean chroot only when debs are installed
function nullfix () {
	if [[ ! -e /dev/null ]]; then
		list_header 'WARNING: /dev/null was removed during build!'
		last_item 'Attempting to fix...'
		/usr/bin/mknod -m 0666 /dev/null c 1 3
	fi
}

# Copy ISOLINUX_GRUB config to IMG (Legacy)
copy_file "${EFI_IMAGE_GRUB}" "${IMAGE_GRUB}"
/usr/bin/echo -e "\nTHIS IS A DUPLICATE, DO NOT EDIT THIS FILE!" >> "${IMAGE_GRUB}"

# Generate IMG
list_item "Image size: ${img_size} bytes."
list_item "Creating ${IMG_ART}..."
/usr/bin/dd if=/dev/zero of="${IMG_ART}" bs=1024 count="${img_size}" status=progress

## Format partitions
LOOP_DEV="$(/usr/sbin/losetup -f)"
list_item "Using loop device: ${LOOP_DEV}..."
/usr/sbin/losetup "${LOOP_DEV}" "${IMG_ART}"

list_item "Adding GPT to ${IMG_ART}..."
list_item "Formatting loop device..."
/usr/sbin/parted -s -a optimal "${LOOP_DEV}" \
	mklabel gpt -- \
	mkpart primary fat32 0% 50MiB \
	mkpart primary fat32 50MiB 100%

list_item "Formatting loop device..."
list_entry
/usr/sbin/mkfs.vfat -n "EFI" "${LOOP_DEV}p1"
/usr/sbin/mkfs.vfat -n "${FAT_LABEL}" "${LOOP_DEV}p2"

## Inject labels
/usr/sbin/fatlabel "${LOOP_DEV}p1" "EFI"
list_item_pass "Added 'EFI'-label: $(/usr/sbin/fatlabel ${LOOP_DEV}p1)"
/usr/sbin/fatlabel "${LOOP_DEV}p2" "${FAT_LABEL}"
list_item_pass "Added 'BCLD-USB'-label: $(/usr/sbin/fatlabel ${LOOP_DEV}p2)"

## Set flags
list_item "Setting boot flags..."
/usr/sbin/parted -s -a optimal "${LOOP_DEV}" \
	toggle 1 esp \
	toggle 1 hidden

## Setting up mounts
list_item "Generating mount points:"
MOUNT_EFI="$(mktemp --directory --suffix=_${FAT_LABEL}-EFI)"
list_item_pass "	- ${MOUNT_EFI}..."
MOUNT_FS="$(mktemp --directory --suffix=_${FAT_LABEL}-FS)"
list_item_pass "	- ${MOUNT_FS}..."

## Perform mount
list_item "Mounting loop devices..."
/usr/bin/mount "${LOOP_DEV}p1" "${MOUNT_EFI}"
/usr/bin/mount "${LOOP_DEV}p2" "${MOUNT_FS}"

on_completion


# Install GRUB

TAG='IMAGE-GRUB'

list_header "Installing GRUB"

## GRUB Legacy
list_item "Legacy..."
prep_dir "${MOUNT_EFI}/boot/grub"
copy_file "${EFI_IMAGE_GRUB}" "${MOUNT_EFI}/boot/grub/grub.cfg"

### Device map
/usr/bin/echo "(hd0,msdos1)    ${LOOP_DEV}p1" > "${GRUB_DIR}/device.map"
/usr/bin/echo "(hd0,msdos2)    ${LOOP_DEV}p2" >> "${GRUB_DIR}/device.map"

### Warnings can be ignored if it says 'Installation finished. No error reported.'
list_entry
/usr/sbin/grub-install --target=i386-pc --no-floppy --recheck --boot-directory="${MOUNT_EFI}/boot/" --force "${LOOP_DEV}"
list_catch

## GRUB UEFI
list_item "UEFI..."
copy_directory "${EFI_DIR}" "${MOUNT_EFI}"
copy_file "${EFI_IMAGE_GRUB}" "${MOUNT_EFI}/EFI/BOOT/grub.cfg"

## GRUB Windows
list_item 'Microsoft...'
MS_GRUB_DIR="${MOUNT_EFI}/EFI/Microsoft/Boot"
prep_dir "${MS_GRUB_DIR}"
copy_file "${MOUNT_EFI}/EFI/BOOT/grubx64.efi" "${MS_GRUB_DIR}/bootmgfw.efi"

## GRUB Ubuntu
list_item 'Ubuntu...'
UB_GRUB_DIR="${MOUNT_EFI}/EFI/ubuntu"
prep_dir "${UB_GRUB_DIR}"
copy_file "${EFI_IMAGE_GRUB}" "${UB_GRUB_DIR}/grub.cfg"

on_completion

# Copy files

TAG='IMAGE-BUILD'

list_header "Copying files to IMG"

## Copy ISO into IMG
copy_file "${ISO_ART}" "${MOUNT_FS}"

## Copy bcld.cfg template
subst_file "${CONFIG_DIR}/bcld/bcld.cfg" "${ART_DIR}/bcld.cfg"
copy_file "${ART_DIR}/bcld.cfg" "${MOUNT_FS}"

## Copy disk info
## To Legacy
#copy_directory "${CONFIG_DIR}/grub/.disk" ${MOUNT_FS}
## To EFI
copy_directory "${CONFIG_DIR}/grub/.disk" ${MOUNT_EFI}

# Unmount and cleanup loop devices
clear_img_mounts
clear_loop_devs
list_exit

list_header "IMG-artifact created!"

# Check IMG size
check_img_size "${IMG_ART}"

exit
