#!/bin/bash
# Script for ShellCheck automation

if [[ -x /usr/bin/shellcheck ]] && [[ -f ./test/00_BCLD-BUILD.bats ]]; then
    SHELL_REPORT='./test/SHELL-REPORT.txt'
    
    /usr/bin/echo 'Starting BCLD ShellCheck'
    
    # Make necessary directories
    /usr/bin/mkdir -p "$(/usr/bin/dirname ${SHELL_REPORT})"
    
    /usr/bin/find . -type f \
        -name "*.sh" \
        -not \( -path './chroot' -o -path './modules' \) \
        -exec shellcheck -S warning {} \; > "${SHELL_REPORT}"

    # Warnings
    SHELL_WARN="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c '(warning)')"

    /usr/bin/echo -e "\n# ShellCheck Warnings: ${SHELL_WARN}" | /usr/bin/tee -a "${SHELL_REPORT}"

    ## If ShellCheck finds warnings...    
    if [[ ${SHELL_WARN} -gt 0 ]]; then
        /usr/bin/echo '# Common warnings found:' | /usr/bin/tee -a "${SHELL_REPORT}"
        
        COMMON_WARNINGS="$(/usr/bin/cat ${SHELL_REPORT} | /usr/bin/grep '(warning)' | /usr/bin/awk '{ print $2 }' | /usr/bin/sort -u)"
        
        for warn in ${COMMON_WARNINGS}; do
            
            description="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep "${warn}" | /usr/bin/grep -v 'https' | /usr/bin/cut -d ':' -f2 | /usr/bin/sort -u)"
            
            /usr/bin/echo "${warn}:${description}"
        done 
    fi
    
    # ERRORS
    SHELL_ERROR="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c '(warning)')"
    
    /usr/bin/echo -e "\n# ShellCheck Errors: ${SHELL_ERROR}" | /usr/bin/tee -a "${SHELL_REPORT}"
    
    ## If ShellCheck finds errors...    
    if [[ ${SHELL_ERROR} -gt 0 ]]; then
        /usr/bin/echo '# Common errors found:' | /usr/bin/tee -a "${SHELL_REPORT}"
        
        COMMON_ERRORS=$(/usr/bin/cat ${SHELL_REPORT} | /usr/bin/grep '(error)' | /usr/bin/awk '{ print $2 }' | /usr/bin/sort -u)
        
        for error in ${COMMON_ERRORS}; do
            
            description="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep "${error}" | /usr/bin/grep -v 'https' | /usr/bin/cut -d ':' -f2 | /usr/bin/awk '{$1=$1};1')"
            
            /usr/bin/echo "${error}: ${description}"
        done

        exit 1    
    fi

    /usr/bin/echo "# ShellCheck report: ${SHELL_REPORT}" | /usr/bin/tee -a "${SHELL_REPORT}"

else
    /usr/bin/echo 'ShellCheck could not be found!'
    exit 1
fi
