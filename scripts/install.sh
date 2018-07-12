#!/usr/bin/env bash

set -eu

# PYTHON_VERSION_TAG=3.7.0
PYTHON_VERSION_TAG=3.6.6 # Switch to 3.7 once Tensorflow is out for it
SOURCE_DIR="Python-${PYTHON_VERSION_TAG}"
INSTALL_DIR="${HOME}/${SOURCE_DIR}"

CXX_VERSION="/cvmfs/sft.cern.ch/lcg/external/gcc/6.2.0/x86_64-centos7/bin/gcc"

GCC_PATH="/cvmfs/sft.cern.ch/lcg/external/gcc/6.2.0/x86_64-centos7"
export PATH="${GCC_PATH}/bin:${PATH}"

function check_host_location {
    # Check if on LXPLUS
    if echo "$(hostname)" | grep -q "cern.ch"; then
        echo "CERN"
    else # or elsewhere
        echo "LINUX"
    fi
}

# function clone_cpython () {
#     # 1: the version tag
#     cd ${HOME}
#     git clone https://github.com/python/cpython.git "Python-${1}"
# }

function download_cpython () {
    # 1: the version tag
    printf "\n### Downloading CPython source as Python-${1}.tgz\n"
    cd ${HOME}
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
    # and pip3 to pip
    printf "\n### ln -s python${PYTHON_VERSION_TAG:0:3} python3\n"
    ln -s "python${PYTHON_VERSION_TAG:0:3}" python3
    printf "    ln -s pip${PYTHON_VERSION_TAG:0:3} pip\n"
    ln -s "pip${PYTHON_VERSION_TAG:0:3}" pip
}

check_host_location

NPROC="$(set_num_processors)"

if [[ -d "${INSTALL_DIR}" ]]; then
    rm -rf "${INSTALL_DIR}"
fi

download_cpython "${PYTHON_VERSION_TAG}"

cd "${INSTALL_DIR}"

build_cpython "${INSTALL_DIR}" "${CXX_VERSION}"

# Add the installed version of Python3 to the USER's PATH
if ! grep -q "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# added by HEPML environment installer" >> ~/.bashrc
    echo "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> ~/.bashrc
fi

# symbolic link the installed version of Python3 to python3
cd bin
symlink_installed_to_defaults
