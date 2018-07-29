#!/usr/bin/env bash

set -eu

# PYTHON_VERSION_TAG=3.7.0
PYTHON_VERSION_TAG=3.6.6 # Switch to 3.7 once Tensorflow is out for it

function check_host_location {
    # Check if on LXPLUS
    if echo "$(hostname)" | grep -q "cern.ch"; then
        echo "CERN"
    else # or elsewhere
        echo "$(hostname)"
    fi
}

function set_base_directory {
    # Select the home directory as the default base directory
    BASE_DIR="${HOME}"
    while true; do
        if [[ "${HOST_LOCATION}" = "CERN" ]]; then
            printf "\n### N.B.:\n"
            printf "    In addition to Python3 the installed packages for the ML environment\n"
            printf "    take up multiple gigabytes of storage. It is suggested that the installation\n"
            printf "    directory be set to someplace with a large amount of storage rather than the\n"
            printf "    USER home area, such as the AFS work partition: /afs/cern.ch/work/${USER:0:1}/${USER}\n\n"
        fi
        printf "\n### Python3 will be installed by default in \${HOME}: ${HOME}\n\n"
        read -p "    Would you like Python3 to be installed in a DIFFERENT directory? [Y/n] " yn
        case $yn in
            [Yy]* )
                # Check if path is empty string
                echo ""
                read -r -e -p "    Enter the full file path of the directory: " BASE_DIR
                if [[ -z "${BASE_DIR}" ]]; then
                    printf "\n    ERROR: The path entered is an empty string.\n\n"
                    exit
                fi
                # Check if path does not exist
                if [[ ! -e "${BASE_DIR}" ]]; then
                    printf "\n    ERROR: The path does not exist.\n\n"
                    exit
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
                        read -p "    Is this all okay? [Y/n] " yn
                        case $yn in
                            [Yy]* )
                                # Being installation
                                echo ""; break ;;
                            [Nn]* )
                                HAVE_ALREADY_CONFIRMED=true
                                clear
                                set_base_directory ;;
                            * )
                                clear
                                printf "\n    Please answer Yes or No.\n" ;;
                        esac
                    done
                fi; break ;;
            [Nn]* ) break ;;
            * )
                clear
                printf "\n    Please answer Yes or No.\n" ;;
        esac
    done
}

# function clone_cpython () {
#     # 1: the version tag
#     cd ${BASE_DIR}
#     git clone https://github.com/python/cpython.git "Python-${1}"
# }

function download_cpython () {
    # 1: the version tag
    printf "\n### Downloading CPython source as Python-${1}.tgz\n"
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

function build_cpython () {
    # 1: the prefix to be passed to configure
    # 2: the path to the version of gcc to be used

    # https://docs.python.org/3/using/unix.html#building-python
    printf "\n### ./configure\n"
    # Need to solve issue with unbound variable catch
    # if [[ -z "${1}" ]]; then
    #     ./configure --enable-optimizations
    # else
    #     ./configure --prefix="${1}" --enable-optimizations
    # fi
    # ./configure --prefix="${1}" \
        # --enable-optimizations \
        # --with-cxx-main="${2}" \
        # CXX="${2}" &> cpython_configure.log
    ./configure --prefix="${1}" \
        --with-cxx-main="${2}" \
        CXX="${2}" &> cpython_configure.log
    printf "\n### make -j${NPROC}\n"
    make -j${NPROC} &> cpython_build.log
    printf "\n### make altinstall\n"
    make altinstall &> cpython_install.log
}

function symlink_installed_to_defaults {
    # symbolic link the installed versions of Python3 to python3
    printf "\n### ln -s python${PYTHON_VERSION_TAG:0:3} python3\n"
    ln -s "python${PYTHON_VERSION_TAG:0:3}" python3
    # pipenv will overwrite any symlink to pip3, but that's okay
    ln -s "pip${PYTHON_VERSION_TAG:0:3}" pip3
}

function append_to_bashrc {
    if ! grep -q "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# added by HEPML environment installer" >> ~/.bashrc

        if [[ "${HOST_LOCATION}" = "CERN" ]]; then
            echo "# only setup PATH if on CentOS 7" >> ~/.bashrc
            echo "if [[ \$(grep 'release 7' /etc/*-release) ]]; then" >> ~/.bashrc
            echo "    export PATH=${INSTALL_DIR}/bin:\$PATH" >> ~/.bashrc
            echo "    eval \"\$(pipenv --completion)\"" >> ~/.bashrc
            if [[ "${BASE_DIR}" != "${HOME}" ]]; then
                # Have large (cache and venv) files exist in the install and project areas
                mkdir -p "${BASE_DIR}/.cache/pip"
                echo "    export PIP_CACHE_DIR=${BASE_DIR}/.cache/pip" >> ~/.bashrc
                mkdir -p "${BASE_DIR}/.cache/pipenv"
                echo "    export PIPENV_CACHE_DIR=${BASE_DIR}/.cache/pipenv" >> ~/.bashrc
                echo "    export PIPENV_VENV_IN_PROJECT=true" >> ~/.bashrc
            else
                echo "    export PATH=${HOME}/.local/bin:\$PATH" >> ~/.bashrc
            fi
            echo "fi" >> ~/.bashrc
        else
            echo "export PATH=${INSTALL_DIR}/bin:\$PATH" >> ~/.bashrc
            echo "export PATH=${HOME}/.local/bin:\$PATH" >> ~/.bashrc
            echo "eval \"\$(pipenv --completion)\"" >> ~/.bashrc
        fi
    fi
}

### main

HOST_LOCATION="$(check_host_location)"

if [[ "${HOST_LOCATION}" = "CERN" ]]; then
    if [[ ! $(grep 'release 7' /etc/*-release) ]]; then
        echo "### A modern CentOS 7 architecture is expected."
        echo "    Please use LXPLUS7 instead: ssh ${USER}@lxplus7.cern.ch -CX"
        exit 1
    else
        # USER is on an LXPLUS7 node
        CXX_VERSION="/cvmfs/sft.cern.ch/lcg/external/gcc/6.2.0/x86_64-centos7/bin/gcc"

        GCC_PATH="/cvmfs/sft.cern.ch/lcg/external/gcc/6.2.0/x86_64-centos7"
        export PATH="${GCC_PATH}/bin:${PATH}"
    fi
fi

# Sets "${BASE_DIR}"
set_base_directory
INSTALL_DIR="${BASE_DIR}/Python-${PYTHON_VERSION_TAG}"

NPROC="$(set_num_processors)"

if [[ -d "${INSTALL_DIR}" ]]; then
    rm -rf "${INSTALL_DIR}"
fi

download_cpython "${PYTHON_VERSION_TAG}"

cd "${INSTALL_DIR}"

build_cpython "${INSTALL_DIR}" "${CXX_VERSION}"

# create symbolic links
cd bin
symlink_installed_to_defaults

# Add the install locations to the USER's PATH for use below
export "PATH=${INSTALL_DIR}/bin:$PATH"
if [[ "${BASE_DIR}" != "${HOME}" ]]; then
    mkdir -p "${BASE_DIR}/.cache/pip"
    export PIP_CACHE_DIR="${BASE_DIR}/.cache/pip"
else
    export "PATH=${HOME}/.local/bin:$PATH"
fi

# Update pip, setuptools, and wheel
printf "\n### pip install --upgrade pip setuptools wheel\n"
pip3 install --upgrade --quiet pip setuptools wheel

# Install pipenv
printf "\n### pip install pipenv\n"
pip3 install --quiet pipenv

append_to_bashrc

printf "\n### Finished installation!\n"
printf "    source ~/.bashrc to start using the environment\n"
