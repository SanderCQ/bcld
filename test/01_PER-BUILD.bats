#
# Copyright © 2023 Quintor B.V.
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
# Copyright © 2023 Quintor B.V.
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
# Per-build Bash tests
# Build a TEST image and check if all TAGs are being marked.
# Check if Grub was installed on the image.
#
# Setup
setup() {
	load 'common-setup'
    _common_setup
}

# Functions
## Function to check if a stage has been succesful
tag_check() {
	
    refute_output --partial "${1} FAILED!!!"
	assert_output --partial "${1} COMPLETE!"
}

# Tests
## Test if ISO Builder can execute
@test 'TagCheck (building in background)...' {

    run ./ISO-builder.sh
    tag_check "ISO-INIT"
    tag_check "ISO-PRECLEAN"
    tag_check "ISO-PREP"
    tag_check "ISO-BOOTSTRAP"
    tag_check "ISO-PRECONF"
    tag_check "ISO-CROS"
    tag_check "ISO-MOUNT"
    tag_check "ISO-CHROOT"
    tag_check "ISO-POSTCONF"
    tag_check "ISO-INITRAMFS"
    tag_check "ISO-REPO"
    tag_check "ISO-SQUASHFS"
    tag_check "ISO-GRUB"
    tag_check "ISO-GEN"
}

## Test if ISO Builder can execute
@test 'GRUB Monitor' {
	run ./IMG-builder.sh
    refute_output --partial 'ISO-artifact missing!'
    assert_output --partial 'Installation finished. No error reported.'
    assert_output --partial "Added 'EFI'-label: EFI"
    assert_output --partial "Added 'BCLD-USB'-label: BCLD-USB"
    tag_check "IMAGE-INIT"
    tag_check "IMAGE-GRUB"
    tag_check "IMAGE-BUILD"
}
