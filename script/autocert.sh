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
# BCLD AutoCert
# Script for automatically selecting the right certificate (WFT instead of Facet).
#
# Skip entire execution unless WFT
if [[ "${BCLD_VENDOR}" == 'wft' ]]; then
	
	source '/bin/log_tools.sh'

	CHROME_CERT='/etc/chromium/policies/managed/auto_select_certificate.json'


	# When RELEASE, use different INPUT_STRING
	if [[ "${BCLD_MODEL}" == 'release' ]]; then
		INPUT_STRING='{ "AutoSelectCertificateForUrls": ["{\"pattern\":\"juno.optimumassessment.com/:443\",\"filter\":{\"CN\":\"KPN PKIoverheid Private Services CA - G1\"}}"] }'
	else
		INPUT_STRING='{ "AutoSelectCertificateForUrls": ["{\"pattern\":\"juno-acc.optimumassessment.com/:443\",\"filter\":{\"CN\":\"KPN PKIoverheid Private Services CA - G1\"}}"] }'
	fi

	# Update autocerts if wft
	log_line 'Updating autocert for WFT...'
	/usr/bin/echo "${INPUT_STRING}" | /usr/bin/sudo /usr/bin/tee "${CHROME_CERT}" &> /dev/null
fi
