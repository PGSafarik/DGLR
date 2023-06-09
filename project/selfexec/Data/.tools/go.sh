#! /bin/bash

#DOSBOX_EXEC=$(which dosbox)
DOSBOX_BASE=${GAME_ROOT}/${DRIVE_DIR}/dosbox.conf
DOSBOX_AUTOEXEC=${GAME_ROOT}/autoexec.conf

# GAME_EXEC_FILE="DEFAULT.EXE"
# GAME_CONFIG_FILE="CONFIGURE.EXE"
# MANUAL_EXEC_FILE="MAUAL.EXE"

#_EDITOR=""

### Pomocne funkce ###
function check_editor( )
{
  if [ -n "$VISUAL" ]; then
    _EDITOR=$VISUAL
  else
    if [ -n "$EDITOR" ]; then    
      _EDITOR=$EDITOR
    else
      _EDITOR=$(which nano)   
   fi	
 fi
   
 vmessage "Detect text editor: $_EDITOR"
   
}

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
# EXIT
EOF
}

function dosbox_run( )
{
  autoexec_gen $1
  
  export SDL_MOUSE_RELATIVE=1
  $DOSBOX_EXE dosbox -conf $DOSBOX_BASE -conf $DOSBOX_AUTOEXEC
  wait $!
  
  rm $DOSBOX_AUTOEXEC
  unset SDL_MOUSE_RELATIVE
}

function dosbox_conf( )
{
  check_editor
  
  if [ ! -z "$_EDITOR" ]; then
    $_EDITOR $DOSBOX_BASE
    proc_cont
  else
    fatal "Not found a text editor. Set You text editor in environment value \'VISUAL\' or \'EDITOR\', or instal nano editor."
  fi

}

function game_run( )
{
  if [ $STORAGE_LOAD_G -eq 0 ] && [ "$GAME_CONFIG_FILE" ]; then
     dosbox_run $CONFIG_EXEC_FILE 
  fi   
  dosbox_run $GAME_EXEC_FILE
}

function proc_cont( )
{
   question "Run $GAME_NAME now?"
   if [[ $? -eq 1 ]]; then
     game_run
   fi  
}

function help 
{
cat << END_ARGS
  No arguments        This same like --play
  --setup or -s       Edit primary Dosbox configurations
  --configure or -c   Lauch the game configurator
  --play  or -p       Starting this game.
END_ARGS
}

### MAIN ###


case "$1" in
    --help|-h)
      help
    ;;
    
    --setup|-s)
      dosbox_conf
    ;;

    --configure|-c)
      dosbox_run $CONFIG_EXEC_FILE 
      proc_cont 	
    ;;

#    --info|-i)
#      dosbox_run $MANUAL_EXEC_FILE 
#      proc_cont 	
#    ;;
    
    --play|*)
      game_run	
    ;;
esac

### END ###
