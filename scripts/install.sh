#!/usr/bin/env bash

set -eu

# PYTHON_VERSION_TAG=3.7.0
PYTHON_VERSION_TAG=3.6.6 # Switch to 3.7 once Tensorflow is out for it

function print_usage {
    cat 1>&2 <<EOF
USAGE:
    installer [FLAGS] [OPTIONS]

FLAGS:
    -h, --help              Print help information
    -d, --defaults          Print default install and configuration options
                            If passed last after OPTIONS then shows with OPTIONS applied
    -y, --yes-to-all        Accept defaults and disable confirmation prompt
                            If passed along with OPTIONS then OPTIONS will be applied as defaults
    -q, --quiet             Print minimal information

OPTIONS:
        --gcc <gcc>                                Select a path to a gcc version
        --install-dir <install-dir>                Select a path to for the install
        --overwrite                                Install Python3 possibly overwriting others
                                                   c.f. https://docs.python.org/3/using/unix.html#building-python
        --enable-optimizations                     Run ./configure with --enable-optimizations
        --no-bashrc-append                         Write to a setup script instead of appending to ~/.bashrc
        --no-tab-complete                          Turn off addition of tab completion
EOF
}

function print_help_menu {
    cat 1>&2 <<EOF
Installer for HEPML-env:
https://github.com/matthewfeickert/HEPML-env

Setting up a machine learning environment has gotten easier recently,
but there are at times still problems that arise from time to time.
HEPML-env allows for easily setting up a standard machine learning Python
environment that should allow you to get to work with HEP data immediately.
It should be machine agnostic, such that it can setup an identical environment
on your laptop or on LXPLUS.

EOF
    print_usage
}

function notify() {
    if [[ "${IS_QUIET}" == false ]]; then
        printf "${1}"
    fi
}

function check_cmd_valid() {
    # http://pubs.opengroup.org/onlinepubs/009696899/utilities/command.html
    command -v "$1" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        printf "\n    ERROR: $1 is not being recongized as a valid command\n"
        printf "\n    Exiting installer\n"
        exit 1
    fi
}

function check_if_valid_path() {
    if [[ ! -z "${2+x}" ]]; then
        if [[ ! -e "${1}" ]]; then
            printf "\n    "${2}" ERROR: "${1}" is not a valid path\n\n"
            exit 1
        fi
    else
        if [[ ! -e "${1}" ]]; then
            printf "\n    ERROR: "${1}" is not a valid path\n\n"
            exit 1
        fi
    fi
}

function remove_from_array () {
    local delete=($1)
    local array=($2)

    for target in "${delete[@]}"; do
        for i in "${!array[@]}"; do
            if [[ ${array[i]} = "${delete[0]}" ]]; then
                unset 'array[i]'
            fi
        done
    done
    echo "${array[@]}"
}

function check_for_cvmfs {
    if [[ -d "/cvmfs/sft.cern.ch" ]]; then
        HAS_CVMFS=true
    else
        HAS_CVMFS=false
    fi
}

function determine_OS {
    # https://askubuntu.com/a/459425/781671
    # Determine OS platform
    local UNAME=$(uname | tr "[:upper:]" "[:lower:]")
    # If Linux, try to determine specific distribution
    if [ "${UNAME}" == "linux" ]; then
        if [[ -f /etc/os-release ]]; then
            local DISTRO="$(awk -F= '/^NAME/{print $2}' /etc/os-release)"
            # Remove quotes
            DISTRO=${DISTRO%\"}
            DISTRO=${DISTRO#\"}
        elif [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
            # If available, use LSB to identify distribution
            local DISTRO="$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)"
            # Otherwise, use release info file
        else
            local DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
        fi
    fi
    # For everything else (or if above failed), just use generic identifier
    [ "${DISTRO}" == "" ] && local DISTRO="${UNAME}"

    local supported_distros=("Ubuntu" "CentOS Linux" "ScientificCERNSLC")
    if [[ ! "${supported_distros[@]}" =~ "${DISTRO}" ]]; then
        printf "\n### ${DISTRO} is not a supproted distribution for the installer.\n"
        printf "    Please install manually or file an Issue: https://github.com/matthewfeickert/HEPML-installer/blob/master/CONTRIBUTING.md\n"
        printf "\n    Exiting installer\n"
        exit 1
    fi
    echo "${DISTRO}"
}

function check_if_installed () {
    if [[ "${SYSTEM_OS}" = "Ubuntu" ]]; then
        check_cmd_valid dpkg
        dpkg -s $1 &> /dev/null
    elif [[ "${SYSTEM_OS}" = "CentOS Linux" ]] || [[ "${SYSTEM_OS}" = "ScientificCERNSLC" ]]; then
        yum list installed "$1" &>/dev/null
    fi
    # if not installed return package name
    if [[ $? -ne 0 ]]; then
        echo "${1}"
    fi
}

function check_if_superuser {
    sudo -v
    if [[ $? -ne 0 ]]; then
        printf "\n    sudo privlages not granted\n"
        printf "\n    Exiting installer\n"
        exit 1
    fi
}

function install_with_package_manager () {
    # https://unix.stackexchange.com/a/183648/275785
    local missing_packages="$1"
    if [[ "${SYSTEM_OS}" = "Ubuntu" ]]; then
        check_cmd_valid apt-get
        echo ""
        if [[ ! -z "${2+x}" ]]; then
            if [[ "$2" = "sudo" ]]; then
                printf "### sudo apt-get update\n\n"
                sudo apt-get -y -qq update
                echo "### sudo apt-get install ${missing_packages[@]}"
                sudo apt-get -y -qq install ${missing_packages[@]} &> apt_install.log
            fi
        else
            printf "### apt-get update\n\n"
            apt-get -y -qq update
            echo "### apt-get install ${missing_packages[@]}"
            apt-get -y -qq install ${missing_packages[@]} &> apt_install.log
        fi
    elif [[ "${SYSTEM_OS}" = "CentOS Linux" ]] || [[ "${SYSTEM_OS}" = "ScientificCERNSLC" ]]; then
        check_cmd_valid yum
        echo ""
        if [[ ! -z "${2+x}" ]]; then
            if [[ "$2" = "sudo" ]]; then
                printf "### sudo yum update\n\n"
                sudo yum -y -q update
                echo ""
                echo "### sudo yum install ${missing_packages[@]}"
                sudo yum -y -q install ${missing_packages[@]} &> apt_install.log
            fi
        else
            printf "### yum update\n\n"
            yum -y -q update
            echo ""
            echo "### yum install ${missing_packages[@]}"
            yum -y -q install ${missing_packages[@]} &> apt_install.log
        fi
    fi
}

function check_for_requirements {
    if [[ "${SYSTEM_OS}" = "Ubuntu" ]]; then
        local GNU_required_packages=(gcc g++ git zlibc zlib1g-dev libssl-dev wget make)
    elif [[ "${SYSTEM_OS}" = "CentOS Linux" ]] || [[ "${SYSTEM_OS}" = "ScientificCERNSLC" ]]; then
        local GNU_required_packages=(gcc gcc-c++ git zlib-devel openssl-devel wget make)
    fi
    local GNU_missing_packages=()

    for package in "${GNU_required_packages[@]}"; do
        GNU_missing_packages+=($(check_if_installed "${package}"))
    done

    # CVMFS supplies gcc, so if CVMFS present don't require it
    if [[ ! -z "${GNU_missing_packages[@]+x}" ]] && [[ "${HAS_CVMFS}" == true ]]; then
        if [[ "${GNU_missing_packages[@]}" =~ "gcc" ]]; then
            GNU_missing_packages=($(remove_from_array "gcc" "$(echo ${GNU_missing_packages[@]})"))
        fi
    fi

    if [[ "${#GNU_missing_packages[@]}" -ne 0 ]]; then
        if [[ "${GNU_missing_packages[@]}" =~ "gcc" ]]; then
            # CXX_VERSION will need to get reset by set_globals after check_for_requirements finishes
            unset CXX_VERSION
        fi
        while true; do
            printf "\n### The following required pacakges are missing:\n\n"
            echo "    ${GNU_missing_packages[@]}"

            if [[ "${DID_ACCEPT_DEFAULTS}" != true ]]; then
                echo ""
                read -p "    Would you like them to be installed now? [Y/n/q] " ynq
                case $ynq in
                    [Yy]* )
                        echo ""
                        read -p "    Do you require sudo powers on this machine to install software? [Y/n/q] " ynq
                        case $ynq in
                            [Yy]* )
                                check_if_superuser
                                install_with_package_manager "$(echo ${GNU_missing_packages[@]})" sudo
                                echo "" ;;
                            [Nn]* )
                                install_with_package_manager "$(echo ${GNU_missing_packages[@]})"
                                echo "" ;;
                            [Qq]* )
                                printf "\n    Exiting installer\n"
                                exit 0 ;;
                        esac
                        break ;;
                    [Nn]* )
                        printf "\n### Please run the followling install command:\n\n"
                        echo "    apt-get install ${GNU_missing_packages[@]}"
                        printf "\n    Exiting installer\n"
                        exit 0 ;;
                    [Qq]* )
                        printf "\n    Exiting installer\n"
                        exit 0 ;;
                    * )
                        clear
                        printf "\n    Please answer Yes or No.\n" ;;
                esac
            else
                install_with_package_manager "$(echo ${GNU_missing_packages[@]})"
                break
            fi
        done
    fi
}

function get_host_location {
    # Check if on LXPLUS
    if echo "$(hostname)" | grep -q "cern.ch"; then
        HOST_LOCATION="CERN"
    else # or elsewhere
        HOST_LOCATION="$(hostname)"
    fi
}

function set_globals () {
    if [[ -z ${SYSTEM_OS+x} ]]; then
        SYSTEM_OS="$(determine_OS)"
    fi
    check_for_cvmfs
    get_host_location

    # If CVMFS is available use it for greater portability
    if [[ "${HAS_CVMFS}" == true ]]; then
        if [[ -z ${CXX_VERSION+x} ]]; then
            CXX_VERSION="/cvmfs/sft.cern.ch/lcg/external/gcc/6.2.0/x86_64-centos7/bin/gcc"
        fi
    else
        if [[ -z ${CXX_VERSION+x} ]]; then
            CXX_VERSION="$(which gcc)"
        fi
    fi

    if [[ "${HOST_LOCATION}" = "CERN" ]]; then
        if [[ -z ${BASE_DIR+x} ]]; then
            BASE_DIR="${HOME/user/work}"
        fi
    else
        if [[ -z ${BASE_DIR+x} ]]; then
            BASE_DIR="${HOME}"
        fi
    fi
    INSTALL_DIR="${BASE_DIR}/Python-${PYTHON_VERSION_TAG}"

    if [[ -z ${APPENDED_BASHRC+x} ]]; then
        APPENDED_BASHRC=true
    fi
    if [[ -z ${ADD_TAB_COMPLETE+x} ]]; then
        ADD_TAB_COMPLETE=true
    fi
    if [[ -z ${ENABLE_OPTIMIZATIONS+x} ]]; then
        ENABLE_OPTIMIZATIONS=false
    fi
    if [[ -z ${ENABLE_OVERWRITE+x} ]]; then
        ENABLE_OVERWRITE=false
    fi
}

function print_defaults {
    set_globals

    local configure_options_string="  --prefix=${INSTALL_DIR}"$'\n'
    if [[ "${ENABLE_OPTIMIZATIONS}" == true ]]; then
        configure_options_string+="  --enable-optimizations"$'\n'
    fi
    configure_options_string+="  --with-cxx-main=${CXX_VERSION}"

    cat 1>&2 <<EOF
Defaults for given architecture:

Operating system: ${SYSTEM_OS}
CPython version: ${PYTHON_VERSION_TAG}
Installation directory: ${BASE_DIR}
sudo powers required: No
gcc: ${CXX_VERSION}

./configure options:
${configure_options_string}

EOF
}

function set_base_directory {
    if [[ -z ${BASE_DIR+x} ]]; then
        # Select the home directory as the default base directory
        BASE_DIR="${HOME}"
        if [[ "${HOST_LOCATION}" = "CERN" ]]; then
            BASE_DIR="${HOME/user/work}"
        fi
    fi

    while true; do
        if [[ "${IS_QUIET}" == false ]]; then
            if [[ "${HOST_LOCATION}" = "CERN" ]]; then
                printf "\n### N.B.:\n"
                printf "    In addition to Python3 the installed packages for the ML environment\n"
                printf "    take up multiple gigabytes of storage. It is suggested that the installation\n"
                printf "    directory be set to someplace with a large amount of storage rather than the\n"
                printf "    USER home area, such as the AFS work partition: ${HOME/user/work}\n\n"
                printf "\n### Python3 will be installed by default in the AFS work partition: ${BASE_DIR}\n\n"
            else
                printf "\n### Python3 will be installed by default in \${HOME}: ${HOME}\n\n"
            fi
        fi

        if [[ "${DID_ACCEPT_DEFAULTS}" != true ]]; then
            read -p "    Would you like Python3 to be installed in a DIFFERENT directory? [Y/n/q] " ynq
            case $ynq in
                [Yy]* )
                    # Check if path is empty string
                    echo ""
                    read -r -e -p "    Enter the full file path of the directory: " BASE_DIR
                    if [[ -z "${BASE_DIR}" ]]; then
                        printf "\n    ERROR: The path entered is an empty string.\n\n"
                        exit 1
                    fi
                    # Check if path does not exist
                    if [[ ! -e "${BASE_DIR}" ]]; then
                        printf "\n    ERROR: The path does not exist.\n\n"
                        exit 1
                    fi
                    # The "/" will be added later
                    if [[ ${#BASE_DIR} -gt 1 ]] && [[ "${BASE_DIR: -1}" = "/" ]]; then
                        BASE_DIR="${BASE_DIR:0:${#BASE_DIR} - 1}"
                    fi
                    # Confirm
                    HAVE_ALREADY_CONFIRMED=false
                    if [[ "${HAVE_ALREADY_CONFIRMED}" ]]; then
                        while true; do
                            printf "\n### Python3, pipenv, and all Python libraries will be installed under: ${BASE_DIR}\n\n"
                            if [[ -x "$(command -v fs)" ]]; then
                                # Use AFS's fs_listquota tool if available
                                printf "    Current use of storage on partion housing ${BASE_DIR}\n\n"
                                cd "${BASE_DIR}"
                                fs lq -human
                                cd - &> /dev/null
                                echo ""
                            fi
                            read -p "    Is this all okay? [Y/n/q] " ynq
                            case $ynq in
                                [Yy]* )
                                    # Being installation
                                    echo ""; break ;;
                                [Nn]* )
                                    HAVE_ALREADY_CONFIRMED=true
                                    clear
                                    BASE_DIR="${HOME}"
                                    set_base_directory ;;
                                [Qq]* )
                                    printf "\n    Exiting installer\n"
                                    exit 0 ;;
                                * )
                                    clear
                                    printf "\n    Please answer Yes or No.\n" ;;
                            esac
                        done
                    fi; break ;;
                [Nn]* ) break ;;
                [Qq]* )
                    printf "\n    Exiting installer\n"
                    exit 0 ;;
                * )
                    clear
                    printf "\n    Please answer Yes or No.\n" ;;
            esac
        else
            # Did accept defaults
            break
        fi
    done
}

# function clone_cpython () {
#     # 1: the version tag
#     cd ${BASE_DIR}
#     git clone https://github.com/python/cpython.git "Python-${1}"
# }

function download_cpython () {
    # 1: the version tag
    notify "\n### Downloading CPython source as Python-${1}.tgz\n"
    cd ${BASE_DIR}
    if [[ ! -f "Python-${1}.tgz" ]]; then
        check_cmd_valid wget
        wget "https://www.python.org/ftp/python/${1}/Python-${1}.tgz" &> /dev/null
    else
        echo "Python-${1}.tgz already exists. Using this version."
    fi
    check_cmd_valid tar
    tar -xvzf "Python-${1}.tgz" > /dev/null
    rm "Python-${1}.tgz"
}

function set_num_processors {
    # Set the number of processors used for build
    # to be 1 less than are available
    if [[ -f "$(which nproc)" ]]; then
        NPROC="$(nproc)"
    else
        NPROC="$(grep -c '^processor' /proc/cpuinfo)"
    fi
    echo `expr "${NPROC}" - 1`
}

function build_cpython {
    # https://docs.python.org/3/using/unix.html#building-python
    notify "\n### ./configure\n"
    if [[ "${CXX_VERSION}" = "" ]]; then
        printf "\n    ERROR: --with-cxx-main is found to be set to empty space\n"
        printf "\n    Exiting installer\n"
        exit 1
    fi
    if [[ "${ENABLE_OPTIMIZATIONS}" == true ]]; then
        ./configure --prefix="${INSTALL_DIR}" \
            --enable-optimizations \
            --with-cxx-main="${CXX_VERSION}" \
            CXX="${CXX_VERSION}" &> cpython_configure.log
    else
        ./configure --prefix="${INSTALL_DIR}" \
            --with-cxx-main="${CXX_VERSION}" \
            CXX="${CXX_VERSION}" &> cpython_configure.log
    fi
    check_cmd_valid make
    notify "\n### make -j${NPROC}\n"
    make -j${NPROC} &> cpython_build.log
    if [[ "${ENABLE_OVERWRITE}" == true ]]; then
        notify "\n### make install\n"
        make install &> cpython_install.log
    else
        notify "\n### make altinstall\n"
        make altinstall &> cpython_install.log
    fi
}

function symlink_installed_to_defaults {
    # symbolic link the installed versions of Python3 to python3
    notify "\n### ln -s python${PYTHON_VERSION_TAG:0:3} python3\n"
    if [[ -f "python${PYTHON_VERSION_TAG:0:3}" ]]; then
        ln -s "python${PYTHON_VERSION_TAG:0:3}" python3
    else
        printf "\n    ERROR: python${PYTHON_VERSION_TAG:0:3} was not found (probably not built)\n"
        printf "\n    Exiting installer\n"
        exit 1
    fi
    # pipenv will overwrite any symlink to pip3, but that's okay
    if [[ -f "pip${PYTHON_VERSION_TAG:0:3}" ]]; then
        ln -s "pip${PYTHON_VERSION_TAG:0:3}" pip3
    else
        printf "\n    ERROR: pip${PYTHON_VERSION_TAG:0:3} was not found (probably not built)\n"
        printf "\n    Exiting installer\n"
        exit 1
    fi
}

function append_to_bashrc {
    if ! grep -q "# added by HEPML environment installer" ~/.bashrc; then
        local bashrc_string=$'\n'
        bashrc_string+="# added by HEPML environment installer"$'\n'

        if [[ "${HOST_LOCATION}" = "CERN" ]]; then
            bashrc_string+="# only setup PATH if on CentOS 7"$'\n'
            bashrc_string+="if [[ \$(grep 'release 7' /etc/*-release) ]]; then"$'\n'
            bashrc_string+="    export PATH=${INSTALL_DIR}/bin:\$PATH"$'\n'
            if [[ "${ADD_TAB_COMPLETE}" == true ]]; then
                bashrc_string+="    eval \"\$(pipenv --completion)\" # tab completion"$'\n'
            fi
            if [[ "${BASE_DIR}" != "${HOME}" ]]; then
                # Have large (cache and venv) files exist in the install and project areas
                mkdir -p "${BASE_DIR}/.cache/pip"
                bashrc_string+="    export PIP_CACHE_DIR=${BASE_DIR}/.cache/pip"$'\n'
                mkdir -p "${BASE_DIR}/.cache/pipenv"
                bashrc_string+="    export PIPENV_CACHE_DIR=${BASE_DIR}/.cache/pipenv"$'\n'
                bashrc_string+="    export PIPENV_VENV_IN_PROJECT=true"$'\n'
            else
                bashrc_string+="    export PATH=${HOME}/.local/bin:\$PATH"$'\n'
            fi
            bashrc_string+="fi"
        else
            if [[ "${SYSTEM_OS}" = "Ubuntu" ]]; then
                bashrc_string+="export LC_ALL=C.UTF-8"$'\n'
                bashrc_string+="export LANG=C.UTF-8"$'\n'
            else
                bashrc_string+="export LC_ALL=en_US.UTF-8"$'\n'
                bashrc_string+="export LANG=en_US.UTF-8"$'\n'
            fi
            bashrc_string+="export PATH=${INSTALL_DIR}/bin:\$PATH"$'\n'
            bashrc_string+="export PATH=${HOME}/.local/bin:\$PATH"$'\n'
            if [[ "${ADD_TAB_COMPLETE}" == true ]]; then
                bashrc_string+="eval \"\$(pipenv --completion)\""
            fi
        fi

        if [[ "${DID_ACCEPT_DEFAULTS}" != true ]]; then
            printf "\n\n### The following should be added to your ~/.bashrc\n"
            printf "    (tab completion is optional)\n"
            printf "\n    If you chose to not append to your ~/.bashrc a setup script will be generated\n"
            printf "~~~\n"
            printf "${bashrc_string}\n"
            printf "~~~\n"

            while true; do
                printf "\n"
                read -p "    Do you give permission to write to your ~/.bashrc? [Y/n] " yn
                case $yn in
                    [Yy]* )
                        echo "${bashrc_string}" >> ~/.bashrc
                        APPENDED_BASHRC=true
                        break
                        ;;
                    [Nn]* )
                        echo "#!/usr/bin/env bash" > ${BASE_DIR}/setup_HEPML-env.sh
                        echo "${bashrc_string}" >> ${BASE_DIR}/setup_HEPML-env.sh
                        printf "\n    Generated ${BASE_DIR}/setup_HEPML-env.sh\n"
                        printf "\n    Source setup_HEPML-env.sh as needed.\n"
                        APPENDED_BASHRC=false
                        break
                        ;;
                    * )
                        clear
                        printf "\n    Please answer Yes or No.\n" ;;
                esac
            done
        else
            # defaults accepted
            if [[ "${APPENDED_BASHRC}" == true ]]; then
                echo "${bashrc_string}" >> ~/.bashrc
            else
                echo "#!/usr/bin/env bash" > ${BASE_DIR}/setup_HEPML-env.sh
                echo "${bashrc_string}" >> ${BASE_DIR}/setup_HEPML-env.sh
            fi
        fi
    fi
}

function main() {
    # Get command line options
    DID_ACCEPT_DEFAULTS=false
    IS_QUIET=false
    while [[ $# -gt 0 ]]; do
        arg="${1}"
        case "${arg}" in
            -h|--help)
                print_help_menu
                exit 0
                ;;
            -d|--defaults)
                print_defaults
                exit 0
                ;;
            -y|--yes-to-all)
                # accept defaults and skip prompt
                DID_ACCEPT_DEFAULTS=true
                if [[ -z ${APPENDED_BASHRC+x} ]]; then
                    APPENDED_BASHRC=true
                fi
                shift
                ;;
            -q|--quiet)
                IS_QUIET=true
                shift
                ;;
                # Additional options
            --gcc)
                check_if_valid_path "${2}" --gcc
                CXX_VERSION="${2}"
                shift
                shift
                ;;
            --install-dir)
                check_if_valid_path "${2}" --install-dir
                BASE_DIR="${2}"
                shift
                shift
                ;;
            --enable-optimizations)
                ENABLE_OPTIMIZATIONS=true
                shift
                ;;
            --overwrite)
                ENABLE_OVERWRITE=true
                shift
                ;;
            --no-bashrc-append)
                APPENDED_BASHRC=false
                shift
                ;;
            --no-tab-complete)
                ADD_TAB_COMPLETE=false
                shift
                ;;
            *)
                printf "\n    Invalid option: ${1}\n\n"
                print_usage
                exit 1
                ;;
        esac
    done

    get_host_location

    if [[ "${HOST_LOCATION}" = "CERN" ]]; then
        if [[ ! $(grep 'release 7' /etc/*-release) ]]; then
            echo "### A modern CentOS 7 architecture is expected."
            echo "    Please use LXPLUS7 instead: ssh ${USER}@lxplus7.cern.ch -CX"
            exit 1
            # else USER is on an LXPLUS7 node
        fi
    fi

    if [[ -z ${BASE_DIR+x} ]]; then
        set_base_directory
    fi

    SYSTEM_OS="$(determine_OS)"
    set_globals
    check_for_requirements
    # reset globals as requirements such as gcc may have been missing
    set_globals

    if [[ "${HOST_LOCATION}" = "CERN" ]]; then
        GCC_PATH="/cvmfs/sft.cern.ch/lcg/external/gcc/6.2.0/x86_64-centos7"
        export PATH="${GCC_PATH}/bin:${PATH}"
    fi

    NPROC="$(set_num_processors)"

    if [[ -d "${INSTALL_DIR}" ]]; then
        rm -rf "${INSTALL_DIR}"
    fi

    download_cpython "${PYTHON_VERSION_TAG}"

    cd "${INSTALL_DIR}"

    build_cpython

    if [[ "${ENABLE_OVERWRITE}" == false ]]; then
        # create symbolic links
        cd bin
        symlink_installed_to_defaults
    fi

    # Add the install locations to the USER's PATH for use below
    export "PATH=${INSTALL_DIR}/bin:$PATH"
    if [[ "${BASE_DIR}" != "${HOME}" ]]; then
        mkdir -p "${BASE_DIR}/.cache/pip"
        export PIP_CACHE_DIR="${BASE_DIR}/.cache/pip"
    else
        export "PATH=${HOME}/.local/bin:$PATH"
    fi

    # Update pip, setuptools, and wheel
    check_cmd_valid pip3
    notify "\n### pip install --upgrade pip setuptools wheel\n"
    pip3 install --upgrade --quiet pip setuptools wheel

    # Install pipenv
    notify "\n### pip install pipenv\n"
    pip3 install --quiet pipenv

    append_to_bashrc

    notify "\n### Finished installation!\n"
    if [[ "${APPENDED_BASHRC}" == true ]]; then
        notify "    source ~/.bashrc to start using the environment\n"
    else
        notify "    source ${BASE_DIR}/setup_HEPML-env.sh to start using the environment\n"
    fi
}

main "$@" || exit 1
