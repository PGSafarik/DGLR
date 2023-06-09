#! /bin/bash
##########################################################################
# Dosbox (Games) Linux Runtime - Selfexecutable archive builder          #
# Copyright (c) 2019 - 2023 D.A.Tiger <drakarax@seznam.cz>, GNU GPL v.3  #
#                                                                        #
# This program is free software: you can redistribute it and/or modify   #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# This program is distributed in the hope that it will be useful,        #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with this program.  If not, see <https://www.gnu.org/licenses/>. #
##########################################################################

### DIRECTORIES ###
BASE_DIR="$(pwd)"                          # Work point for this skript
TOOLS_DIR="${BASE_DIR}/utils"              # Directory for scprits and other tools using in build.sh
BUILD_DIR="${BASE_DIR}/build"              # Output directory 
SOURCE_DIR="${BASE_DIR}/project/selfexec"  # Source directory for selfexecutable archive
PACKAGE_DIR="${BASE_DIR}/project/package"  # Source directory for package
DATA_DIR="${SOURCE_DIR}/Data"              # Source directory for data archive
METADATA_DIR=".metadata"                   # Directory name for save metadata in runable package 

### PRODUCTS EXPONENTS ###
PR_EXP="tar.xz"    # Exponent for data archive
PA_EXP="xz.run"    # Exponent for selfexecutable archive
DEB_EXP="deb"      # Exponent for deb package file
LI_EXP="lintian"   # Exponent for linitian logs 
IN_EXP="run"       # Expoment for final executable file

### BUILD OPTIONS ###
REUSE=0     # Indikate for data archive - if exist used it. Else make new                        
CLEAN=0     # Indikate clean project
PACKAGE=""  # Indikate build instalation package. String value define he's type.
INSTALL=0   # Indikate instaltion   - if is build package
REINSTALL=0 # Indikate remove and instaltion - if is build package

### SELFEXECUTABLE OPTINS ###
EXEC_NAME=""                  # Complete name for selfexecutable archive
ARCHIVE_NAME="data.${PR_EXP}" # Complete name for data archive


### INCLUDE SUBSCRIPTS ###
source "${TOOLS_DIR}/utils.sh"
source "${SOURCE_DIR}/configure.sh"


### Operations ####################################################################################
function Header
{
  message "          W E L C O M E !"
  message "  DGLR: Selfextract package creator"
  message "  Copyright 2020 D.A.Tiger GNU/GPL v3"
  pl
  message "  Game name: $GAME_NAME"
  message "  Game ID:   $GAME_ID"
  nl
}

function Initialize
{  
  
  Header
  [ -z "$( which tar )" ] && fatal "Nenalezen program tar! Prosim nainstalujte jej..." 
  nl
  [ -e "$BUILD_DIR" ] || mkdir "$BUILD_DIR"
  EXEC_NAME=${GAME_ID}.${PA_EXP}
}

function Clean
{
  message "Clean ${GAME_ID} ..."
  #rm ${ARCHIVE_NAME}
  #rm ${EXEC_NAME}
  if [ -e "${BUILD_DIR}" ]; then 
    #rm *.${PR_EXP} *.${PA_EXP} *.${DEB_EXP} *.${LI_EXP}
    rm "$BUILD_DIR/*"
  fi  
  
  message "OK"
  exit 0
}

function Make_product
{
  
  if [[ REUSE -eq 0 ]] || [ ! -e "${BUILD_DIR}/${ARCHIVE_NAME}" ]; then
    message "Make ${GAME_ID} archive"
    cd "${DATA_DIR}"
    pwd
    
    [ -d "${METADATA_DIR}" ] || mkdir ${METADATA_DIR} 
    find . -type f ! -regex '^\./\.metadata/.*' -exec md5sum {} \; > "${METADATA_DIR}/checksum.md5" 
      # Write desription metadata
      cat > "${METADATA_DIR}/info.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>    
<Info name="${GAME_GAME_ID}" ext="run" section="games">
  <Value key="Description">Selfexecutable archive of DOSBox (Games) Linux Runtime.</Value>
  <Value key="Mime">application/x-xz-compressed-tar</Value> 
  <Value key="Categories">$GAME_CATEGORY</Value> 
  <Value key="Game">${GAME_NAME}</Value> 
  <Value key="Orig">${PA_EXP}</Value>
  <Value key="Build">$(date '+%D %T')</Value>
  <Value key="User">${HOSTNAME}:${USER}</Value>
</Info>
EOF

    tar -cvf - . | xz -9 -c - > "${BUILD_DIR}/${ARCHIVE_NAME}"
    nl
    cd "$BASE_DIR"
  fi  
}

function Make_exec
{  
  message "Make ${GAME_ID} executable"
  if [ -e "${BUILD_DIR}/$ARCHIVE_NAME" ]; then
    message "Join the archive with a decompression script..."
    cat "${SOURCE_DIR}/configure.sh" "${TOOLS_DIR}/utils.sh" "${SOURCE_DIR}/decompress.sh" "${BUILD_DIR}/$ARCHIVE_NAME" > "${BUILD_DIR}/${EXEC_NAME}"
    if [ -e "${BUILD_DIR}/${EXEC_NAME}" ]; then
      chmod +x "${BUILD_DIR}/${EXEC_NAME}"
      info "selfexecutable package ${EXEC_NAME} is created"
    fi
    if [[ REUSE -eq 0 ]]; then
      message "clearing..."
      rm "${BUILD_DIR}/$ARCHIVE_NAME"
    fi  
  else 
    fatal "Tar process failed! $ARCHIVE_NAME does not exist"
  fi
  nl
}

function Make_deb
{
  message "Create ${GAME_ID} DEB Package"
  if [ -e "${BUILD_DIR}/$EXEC_NAME" ]; then
    INSTALL_NAME="${EXEC_NAME}"
    if [ ! -z "$IN_EXP" ]; then 
      INSTALL_NAME="${GAME_ID}.${IN_EXP}"
    fi  
    rm "${PACKAGE_DIR}/usr/games/${INSTALL_NAME}"
    cp "${BUILD_DIR}/$EXEC_NAME" "${PACKAGE_DIR}/usr/games/${INSTALL_NAME}" 
  fi
  
  CONTROL_FILE="${PACKAGE_DIR}/DEBIAN/control"
  if [ -e "$CONTROL_FILE" ]; then
    writen "Package" "$GAME_ID" "$CONTROL_FILE"
    ${TOOLS_DIR}/deb-creator.sh "$PACKAGE_DIR" "$BUILD_DIR"
  
    if [[ REINSTALL -eq 1 ]]; then
      message "Uninstall ${GAME_ID} DEB Package"
      sudo apt remove ${GAME_ID}
      nl
    fi
    if [[ INSTALL -eq 1 ]]; then
      message "Install ${GAME_ID} DEB Package"
      cd "$BUILD_DIR"
      sudo apt install ./*.deb
      nl
    fi
  fi  
  cd "$BASE_DIR"
}

### MAIN ##########################################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) 
      PRINT_HELP=1
    ;;
    
    --clean|-c)
      CLEAN=1   
    ;;
  
    --verbrose|-v)
      VERBROSE=1
    ;;
  
    --reuse )
      REUSE=1
    ;;
  
    --workdir|-w)
      shift
      BASE_DIR=$1
    ;;
    
    --deb)
      PACKAGE=${DEB_EXP}
    ;;
    
    --install|-i)
      INSTALL=1
    ;;
    
    --reinstall|-r)
      REINSTALL=1
      INSTALL=1
    ;;  
  esac 
  shift
done 

Initialize

if [[ $CLEAN -eq 1 ]]; then
  Clean
else  
  Make_product
  Make_exec
  
  if [ "$PACKAGE" == "$DEB_EXP" ]; then
    Make_deb
  fi  
fi

exit 0

### END ###########################################################################################
