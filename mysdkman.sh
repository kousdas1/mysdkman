#!/bin/bash
#
#   Copyright 2019 Koushik Das
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# Global variables
MYSDKMAN_SERVICE="https://api.sdkman.io/2"
MYSDKMAN_VERSION="1.0.0"
MYSDKMAN_PLATFORM=$(uname)

if [ -z "$MYSDKMAN_DIR" ]; then
    MYSDKMAN_DIR="$HOME/.mysdkman"
fi

# Local variables
mysdkman_bin_folder="${MYSDKMAN_DIR}/bin"
mysdkman_src_folder="${MYSDKMAN_DIR}/src"
mysdkman_tmp_folder="${MYSDKMAN_DIR}/tmp"
mysdkman_stage_folder="${mysdkman_tmp_folder}/stage"
mysdkman_zip_file="${mysdkman_tmp_folder}/mysdkman-${MYSDKMAN_VERSION}.zip"
mysdkman_ext_folder="${MYSDKMAN_DIR}/ext"
mysdkman_etc_folder="${MYSDKMAN_DIR}/etc"
mysdkman_var_folder="${MYSDKMAN_DIR}/var"
mysdkman_archives_folder="${MYSDKMAN_DIR}/archives"
mysdkman_candidates_folder="${MYSDKMAN_DIR}/candidates"
mysdkman_config_file="${mysdkman_etc_folder}/config"
mysdkman_bash_profile="${HOME}/.bash_profile"
mysdkman_profile="${HOME}/.profile"
mysdkman_bashrc="${HOME}/.bashrc"
mysdkman_zshrc="${HOME}/.zshrc"

mysdkman_init_snippet=$( cat << EOF
#THIS MUST BE AT THE END OF THE FILE FOR MYSDKMAN TO WORK!!!
export MYSDKMAN_DIR="$MYSDKMAN_DIR"
[[ -s "${MYSDKMAN_DIR}/bin/mysdkman-init.sh" ]] && source "${MYSDKMAN_DIR}/bin/mysdkman-init.sh"
EOF
)

# OS specific support (must be 'true' or 'false').
cygwin=false;
darwin=false;
solaris=false;
freebsd=false;
case "$(uname)" in
    CYGWIN*)
        cygwin=true
        ;;
    Darwin*)
        darwin=true
        ;;
    SunOS*)
        solaris=true
        ;;
    FreeBSD*)
        freebsd=true
esac

echo ''
echo 'Now attempting installation...'
echo ''

# Sanity checks

echo "Looking for a previous installation of MYSDKMAN..."
if [ -d "$MYSDKMAN_DIR" ]; then
	echo "MYSDKMAN found."
	echo ""
	echo "======================================================================================================"
	echo " You already have MYSDKMAN installed."
	echo " MYSDKMAN was found at:"
	echo ""
	echo "    ${MYSDKMAN_DIR}"
	echo ""
	echo " Please consider running the following if you need to upgrade."
	echo ""
	echo "    $ mysdk selfupdate force"
	echo ""
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for unzip..."
if [ -z $(which unzip) ]; then
	echo "Not found."
	echo "======================================================================================================"
	echo " Please install unzip on your system using your favourite package manager."
	echo ""
	echo " Restart after installing unzip."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for zip..."
if [ -z $(which zip) ]; then
	echo "Not found."
	echo "======================================================================================================"
	echo " Please install zip on your system using your favourite package manager."
	echo ""
	echo " Restart after installing zip."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for curl..."
if [ -z $(which curl) ]; then
	echo "Not found."
	echo ""
	echo "======================================================================================================"
	echo " Please install curl on your system using your favourite package manager."
	echo ""
	echo " Restart after installing curl."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

if [[ "$solaris" == true ]]; then
	echo "Looking for gsed..."
	if [ -z $(which gsed) ]; then
		echo "Not found."
		echo ""
		echo "======================================================================================================"
		echo " Please install gsed on your solaris system."
		echo ""
		echo " MYSDKMAN uses gsed extensively."
		echo ""
		echo " Restart after installing gsed."
		echo "======================================================================================================"
		echo ""
		exit 0
	fi
else
	echo "Looking for sed..."
	if [ -z $(which sed) ]; then
		echo "Not found."
		echo ""
		echo "======================================================================================================"
		echo " Please install sed on your system using your favourite package manager."
		echo ""
		echo " Restart after installing sed."
		echo "======================================================================================================"
		echo ""
		exit 0
	fi
fi


echo "Installing MYSDKMAN scripts..."


# Create directory structure
echo "Create distribution directories..."
mkdir -p "$mysdkman_bin_folder"
mkdir -p "$mysdkman_src_folder"
mkdir -p "$mysdkman_tmp_folder"
mkdir -p "$mysdkman_stage_folder"
mkdir -p "$mysdkman_ext_folder"
mkdir -p "$mysdkman_etc_folder"
mkdir -p "$mysdkman_var_folder"
mkdir -p "$mysdkman_archives_folder"
mkdir -p "$mysdkman_candidates_folder"

echo "Download script archive..."
curl --location --progress-bar "${MYSDKMAN_SERVICE}/broker/download/mysdkman/install/${MYSDKMAN_VERSION}/${MYSDKMAN_PLATFORM}" > "$mysdkman_zip_file"

ARCHIVE_OK=$(unzip -qt "$mysdkman_zip_file" | grep 'No errors detected in compressed data')
if [[ -z "$ARCHIVE_OK" ]]; then
	echo "Downloaded zip archive corrupt. Are you connected to the internet?"
	echo ""
	echo "If problem persists, please ask for help on https://gitter.im/mysdkman/user-issues"
	rm -rf "$MYSDKMAN_DIR"
	exit
fi

echo "Extract script archive..."
if [[ "$cygwin" == 'true' ]]; then
	echo "Cygwin detected - normalizing paths for unzip..."
	mysdkman_zip_file=$(cygpath -w "$mysdkman_zip_file")
	mysdkman_stage_folder=$(cygpath -w "$mysdkman_stage_folder")
fi
unzip -qo "$mysdkman_zip_file" -d "$mysdkman_stage_folder"


echo "Install scripts..."
mv "${mysdkman_stage_folder}/mysdkman-init.sh" "$mysdkman_bin_folder"
mv "$mysdkman_stage_folder"/mysdkman-* "$mysdkman_src_folder"

echo "Set version to $MYSDKMAN_VERSION ..."
echo "$MYSDKMAN_VERSION" > "${MYSDKMAN_DIR}/var/version"


if [[ $darwin == true ]]; then
  touch "$mysdkman_bash_profile"
  echo "Attempt update of login bash profile on OSX..."
  if [[ -z $(grep 'mysdkman-init.sh' "$mysdkman_bash_profile") ]]; then
    echo -e "\n$mysdkman_init_snippet" >> "$mysdkman_bash_profile"
    echo "Added mysdkman init snippet to $mysdkman_bash_profile"
  fi
else
  echo "Attempt update of interactive bash profile on regular UNIX..."
  touch "${mysdkman_bashrc}"
  if [[ -z $(grep 'mysdkman-init.sh' "$mysdkman_bashrc") ]]; then
      echo -e "\n$mysdkman_init_snippet" >> "$mysdkman_bashrc"
      echo "Added mysdkman init snippet to $mysdkman_bashrc"
  fi
fi

echo "Attempt update of zsh profile..."
touch "$mysdkman_zshrc"
if [[ -z $(grep 'mysdkman-init.sh' "$mysdkman_zshrc") ]]; then
    echo -e "\n$mysdkman_init_snippet" >> "$mysdkman_zshrc"
    echo "Updated existing ${mysdkman_zshrc}"
fi

echo -e "\n\n\nAll done!\n\n"

echo "Please open a new terminal, or run the following in the existing one:"
echo ""
echo "    source \"${MYSDKMAN_DIR}/bin/mysdkman-init.sh\""
echo ""
echo "Then issue the following command:"
echo ""
echo "    mysdk help"
echo ""
echo "Enjoy!!!"
