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
                            If called last after OPTIONS then shows with OPTIONS applied
    -y, --yes-to-all        Accept defaults and disable confirmation prompt
    -q, --quiet             Print minimal information

OPTIONS:
        --gcc <gcc>                                Select a path to a gcc version
        --install-dir <install-dir>                Select a path to for the install
        --overwrite                                Install Python3 possibly overwriting others
                                                   c.f. https://docs.python.org/3/using/unix.html#building-python
        --enable-optimizations                     Run ./configure with --enable-optimizations
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
    if [[ "${IS_QUIET}" != true ]]; then
        printf "${1}"
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

function check_for_cvmfs {
    if [[ -d "/cvmfs/sft.cern.ch" ]]; then
        HAS_CVMFS=true
    else
        HAS_CVMFS=false
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

CPython version: ${PYTHON_VERSION_TAG}
Installation directory: ${BASE_DIR}
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
        if [[ "${IS_QUIET}" != true ]]; then
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
                    if [[ "${BASE_DIR: -1}" = "/" ]]; then
                        BASE_DIR="${BASE_DIR:0:${#BASE_DIR} - 1}"
                    fi
                    # Confirm
                    HAVE_ALREADY_CONFIRMED=false
                    if [[ "${HAVE_ALREADY_CONFIRMED}" ]]; then
                        while true; do
                            printf "\n### Python3, pipenv, and all Python libraries will be installed under: ${BASE_DIR}\n\n"
                            printf "    Current use of storage on partion housing ${BASE_DIR}\n\n"
                            cd "${BASE_DIR}"
                            fs lq -human
                            cd - &> /dev/null
                            echo ""
                            read -p "    Is this all okay? [Y/n/q] " ynq
                            case $ynq in
                                [Yy]* )
                                    # Being installation
                                    echo ""; break ;;
                                [Nn]* )
                                    HAVE_ALREADY_CONFIRMED=true
                                    clear
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
        wget "https://www.python.org/ftp/python/${1}/Python-${1}.tgz" &> /dev/null
    else
        echo "Python-${1}.tgz already exists. Using this version."
    fi
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
    ln -s "python${PYTHON_VERSION_TAG:0:3}" python3
    # pipenv will overwrite any symlink to pip3, but that's okay
    ln -s "pip${PYTHON_VERSION_TAG:0:3}" pip3
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
            bashrc_string+="export LC_ALL=C.UTF-8"$'\n'
            bashrc_string+="export LANG=C.UTF-8"$'\n'
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
            echo "${bashrc_string}" >> ~/.bashrc
        fi
    fi
}

function main() {
    # Get command line options
    DID_ACCEPT_DEFAULTS=false
    IS_QUIET=false
    for arg in "$@"; do
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
                APPENDED_BASHRC=true
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
