#! /bin/bash
##########################################################################
# Dosbox (Games) Linux Runtime - Utils                                   #
# Debian package creator                                                 #
# Copyright (c) 2016 - 2023 D.A.Tiger <drakarax@seznam.cz>, GNU GPL v.3  #
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
# The script that automates the compilation of a binary, data, or meta deb package from a pre-prepared source directory.
# Using       : deb-creator $SOURCE_DIR $BUILD_DIR
# Dependencies: bash, dpkg, tar, md5sum, kdialog, sudo, askpass


### Promene #######################################################################################
# Projekt #
PROJECT_NAME=""         # Nazev projektu
DEBDIR=debian           # Nazev adresare metadat (tzv. ridici adresar)
REGEX='^debian/.*'      # Regulerni vyraz slouzici k vynechani metadat
SOURCE_REMOVE=false     # Indikace smazani zdojoveho adresare 

# Metadata #
VERSION=""              # Verze baliku
MACHINE=""              # Cilova platforma
TARGET=""               # Plna cesta i s kompletnim nazvem ciloveho baliku

# Dialogy #
DIA_HEAD="DEB-CREATOR"  # Titulek
DIA_TEXT="TEXT"         # Text
SUDO=$( [ -z "$XDG_SESSION_DESKTOP" ] && echo "sudo" || echo "sudo -A" )


### Parametry #####################################################################################
OPTIND=1 # Reset pro pripad ze byl getopt pouzit v shellu 

SOURCE=$1               # Zdojovy adresar, nebo soubor s metadaty
TARGET_DIR=$2           # Cilovy adresar

### Deklarace pomocnych funkci ####################################################################
function Checksum( ) {  
  # Vytvoreni kontrolnich souctu vsech souboru v baliku, mimo obsahu adresare DEBIAN
  find * -type f ! -regex $REGEX -exec md5sum {} \; > ${DEBDIR}/md5sums
  chmod 0644 ${DEBDIR}/md5sums
}

function Checksize( )
{
  SIZE_KEY="Installed-Size"
  SIZE_VALUE=$(($(du -s ${SOURCE} | cut -f1 ) - $(du -s ${DEBDIR} | cut -f1 ))) 
  sed -i "s/\($SIZE_KEY *: *\).*/\1$SIZE_VALUE/" ${DEBDIR}/control
}

function CheckScritArgs( ) {
  # Pokud nejsou zadany vsechny argumenty, script si je vypta pomoci dialogu.
  [ -z "$SOURCE" ] && SOURCE=$( kdialog --title "Vyber adresare s projektem" --getexistingdirectory * )
  [ -z "$TARGET_DIR" ] && TARGET_DIR=$( pwd ) #TARGET_DIR=$( kdialog --title "Vyber ciloveho adresare" --getexistingdirectory * )
}

function CheckProjectData( ) {
  # Pokud nelze zjistit metadata, skript si je vyzada 
  [ -z "$PROJECT_NAME" ] && PROJECT_NAME=$( kdialog --inputbox "Zadejte prosim nazev balicku" )
  [ -z "$VERSION" ] && VERSION=$( kdialog --inputbox "Zadejte prosim verzi balicku" )
  [ -z "$MACHINE" ] && MACHINE=$( kdialog --inputbox "Zadejte prosim platformu balicku" )
}

function CheckMeta( ) {
  # Test zda neni zadan pouze control file - s nejvetsi pravdepodnosti jde o tzv. metabalicek
  # Vytvori potrebnou strukturu a nastavi priznak na uklid
  if [ -f "$SOURCE" ] && [ $( basename $SOURCE ) = "control" ]; then
    TMPNAME=$( mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX" ) 
    mkdir -p $TMPNAME/$DEBDIR
    cp $SOURCE $TMPNAME/$DEBDIR 
    SOURCE=$TMPNAME
    SOURCE_REMOVE=true
  fi
}

function CheckDebdir( ) {
  # Kontrola existence ridiciho adresare a stylu jeho pojmenovani
  local BIG="DEBIAN"

  if [ ! -d "$DEBDIR" ]; then
    if [ -d "$BIG" ]; then 
      DEBDIR="$BIG"
      REGEX='^DEBIAN/.*'
    else
      echo "Nelze najit ridici adresar. Toto je fatalni chyba - koncim"
      exit -1
    fi
  fi 
}

function ReadControlFile( ) {
  # Precte udaje portrebne pro sestaveni baliku z control souboru
  if [ -e "$1" ]; then
    while read KEY VALUE; do
      if [ "$KEY" = "Package:" ]; then
        PROJECT_NAME=$VALUE
      elif [ "$KEY" = "Version:" ]; then
        VERSION=$VALUE
      elif [ "$KEY" = "Architecture:" ]; then
        MACHINE=$VALUE
      fi 
    done <<< $(grep -v "^#" $1 )
  fi
}

function Preparation( ) {  
  # Priprava na sestaveni balicku
  [ -d "$TARGET_DIR" ] || mkdir "$TARGET_DIR"
  TARGET=$TARGET_DIR/$PROJECT_NAME-$VERSION-$MACHINE.deb
  
  [ -e "$TARGET" ] && rm -f "$TARGET"
  find $SOURCE -name "*~*" -exec rm {} \;

  $SUDO chmod -R 'u+rw,go+r' $SOURCE/$DEBDIR    # Spolecna prava vsech souboru
  $SUDO chmod 'ugo+x' $SOURCE/$DEBDIR           # Nastveni prav slozky metadat
  $SUDO chown -hR root:root $SOURCE
}

function Build( ) {  
  # sestaveni deb baliku a jeho kontrola
  echo "Zdroj: $SOURCE"
  echo "CIL  : $TARGET"
  $SUDO dpkg-deb -b "$SOURCE" "$TARGET"
  [ -e "$TARGET" ] && lintian "$TARGET" >> $TARGET_DIR/$(basename $TARGET).lintian
}

function Backup( ) {
  # Provede zalohu projektu do lzma archyvu
  echo -n "Zalohuji projekt..... "
  cd $SOURCE/..
  tar --lzma -cf $TARGET_DIR/$PROJECT_NAME-$VERSION-$MACHINE.tar.lzma $(basename $SOURCE)
  
  if [ $? -eq 0 ]; then
    echo "OK"
  else
    echo "FAILED"
  fi
}

function Clear( ) {   
  # Navraceni projektu do puvodniho stavu, pripadne jeho smazani 
  $SUDO chown -hR $USER:$USER $SOURCE
  $SUDO chown $USER:$USER $TARGET
  if [ $SOURCE_REMOVE = true ]; then
   rm -rf $SOURCE
  fi 
}  

### Main ##########################################################################################
CheckScritArgs
CheckMeta

if [ -d "$SOURCE" ]; then
  cd "$SOURCE"
  CheckDebdir
  ReadControlFile $DEBDIR/control  
  CheckProjectData
  
  Checksum
  Checksize
  Preparation
  Build
  Clear
  
  exit 0
else 
  kdialog --error "Nenalezen zdroj pro tvorbu vaseho baliku: $SOURCE!"
  exit -1
fi
