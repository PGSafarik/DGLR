#! /bin/bash
DOSBOX_EXEC=$(which dosbox)
DOSBOX_BASE=${GAME_ROOT}/${DRIVE_DIR}/dosbox.conf
DOSBOX_AUTOEXEC=${GAME_ROOT}/autoexec.conf

GAME_EXEC="DEFAULT.EXE"
GAME_CONFIG=""

### Pomocne funkce ###
source .scripts/utils.sh

function autoexec_gen( )
{
  cat > "$DOSBOX_AUTOEXEC" << EOF
[autoexec]
# This file is generated automaticaly with game starting
# Please, DONT EDIT THIS!

@ECHO OFF
MOUNT C $DRIVE_DIR
C:
CLS
$1
EXIT
EOF

}

function dosbox_run( )
{
  autoexec_gen $1
  dosbox -conf $DOSBOX_BASE -conf $DOSBOX_AUTOEXEC
  wait $!
  
  rm $DOSBOX_AUTOEXEC 
}

function proc_cont( )
{
     message "Press [c] and [ENTER] to continue or only [ENTER] for quit"

   read INP
   if [ "$INP" ==  "c" ]; then
     dosbox_run "$GAME_EXEC"
   else
     exit
   fi
}

### MAIN ###
[ -z "$GAME_EXEC" ] && fatal "Toto je chyba vyvoje: NENASTAVEN SPUSTITELNY SOUBOR HRY!"

case "$1" in
    settings) 
      if [ -z "$GAME_CONFIG" ]; then
         message "Tato hra nenabizi zadnou vlastni konfiguraci"
      else
       dosbox_run "$GAME_CONFIG"
      fi
      proc_cont
    ;;
    setup)
      [ -z "$EDITOR" ] && EDITOR=/bin/nano
       $EDITOR $DOSBOX_BASE
       proc_cont
    ;;
    play|*)	
      dosbox_run "$GAME_EXEC"
    ;;
esac


