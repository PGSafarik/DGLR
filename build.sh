#! /bin/bash
# Selfexecute archive build script v  1.0 
# (C) 2019 - 2020 D.A.Tiger GNU GPL v3

### DIRECTORIES ###
WORK="$(pwd)"                          # Work point for this skript
TOOLS_DIR="${WORK}/utils"              # Directory for scprits and other tools using in build.sh
BUILD_DIR="${WORK}/build"              # Output directory 
SOURCE_DIR="${WORK}/project/selfexec"  # Source directory for selfexecutable archive
DATA_DIR="${SOURCE_DIR}/Data"          # Source directory for data archive
METADATA_DIR=".metadata"               # Directory name for save metadata in runable package 

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

### Pomocne funkce ###

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
  source "${SOURCE_DIR}/utils.sh"
  source "${SOURCE_DIR}/configure.sh"
 
  Header
  [ -z "$( which tar )" ] && fatal "Nenalezen program tar! Prosim nainstalujte jej..." 
  nl

  EXEC_NAME=${GAME_ID}.${PA_EXP}
}

function Clean
{
  message "Clean ${GAME_ID} ..."
  #rm ${ARCHIVE_NAME}
  #rm ${EXEC_NAME}
  rm *.${PR_EXP} *.${PA_EXP} *.${DEB_EXP} *.${LI_EXP}
  
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
    cd $WORK
  fi  
}

function Make_exec
{  
  message "Make ${GAME_ID} executable"
  if [ -e "${BUILD_DIR}/$ARCHIVE_NAME" ]; then
    message "Join the archive with a decompression script..."
    cat ${SOURCE_DIR}/configure.sh ${UTILS_DIR}/utils.sh ${SOURCE_DIR}/decompress.sh ${BUILD_DIR}/$ARCHIVE_NAME > ${BUILD_DIR}/${EXEC_NAME}
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
  if [ -e $EXEC_NAME ]; then
    INSTALL_NAME="${EXEC_NAME}"
    if [ ! -z "$IN_EXP" ]; then 
      INSTALL_NAME="${GAME_ID}.${IN_EXP}"
    fi  
    rm ${WORK}/package/usr/games/${INSTALL_NAME}
    cp $EXEC_NAME ${WORK}/package/usr/games/${INSTALL_NAME} 
  fi
  deb-creator.sh ${WORK}/package
  nl
  
  if [[ REINSTALL -eq 1 ]]; then
    message "Uninstall ${GAME_ID} DEB Package"
    sudo apt remove ${GAME_ID}
    nl
  fi
  if [[ INSTALL -eq 1 ]]; then
     message "Install ${GAME_ID} DEB Package"
    sudo apt install ./*.deb
    nl
  fi
}

### MAIN ########################################
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
      WORK=$1
    ;;
    
    --deb)
      PACKAGE=${DEB_EXP}
    ;;
    
    --install|-i)
      INSTALL=1
    ;;
    
    --reinstal|-r)
      REINSTALL=1
      INSTALL=1
    ;;  
#    *)
#      NEXT+=( "$1" )
#    ;;
  esac 
  shift
done 

Initialize
Header

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
