#! /bin/bash
##########################################################################
# Dosbox (Games) Linux Runtime - Selfexecutable game launcher            #
# Secondary launcher                                                     #
# Copyright (c) 2020 - 2023 D.A.Tiger <drakarax@seznam.cz>, GNU GPL v.3  #
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

### Operations ##############################
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
EXIT
EOF
}

function dosbox_run( )
{
  autoexec_gen "$1"
  
  export SDL_MOUSE_RELATIVE=1
  $DOSBOX_EXEC -conf "$DOSBOX_BASE" -conf "$DOSBOX_AUTOEXEC"
  wait $!
  
  rm "$DOSBOX_AUTOEXEC"
  unset SDL_MOUSE_RELATIVE
}

function dosbox_conf( )
{
  check_editor
  
  if [ ! -z "$_EDITOR" ]; then
    $_EDITOR "$DOSBOX_BASE"
    proc_cont
  else
    fatal "Not found a text editor. Set You text editor in environment value \'VISUAL\' or \'EDITOR\', or instal nano editor."
  fi

}

function game_run( )
{
  if [ $STORAGE_LOAD_G -eq 0 ] && [ "$GAME_CONFIG_FILE" ]; then
     dosbox_run "$CONFIG_EXEC_FILE" 
  fi   
  dosbox_run "$GAME_EXEC"
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
  --configure or -c   Run the game configurator (if it exists)
  --info or -i        Start the game manual application (if it exists)
  --play  or -p       Starting this game.
END_ARGS
}

### MAIN ########################################
[ -z "$DOSBOX_BASE" ] && DOSBOX_BASE="${GAME_ROOT}/${DRIVE_DIR}/dosbox.conf"
[ -z "$DOSBOX_AUTOEXEC" ] && DOSBOX_AUTOEXEC="${GAME_ROOT}/autoexec.conf"

case "$1" in
    --help|-h)
      help
    ;;
    
    --setup|-s)
      dosbox_conf
    ;;

    --configure|-c)
      if [ "$CONFIG_EXEC_FILE" ]; then
        dosbox_run "$CONFIG_EXEC_FILE" 
      else
        message "Unsupported request - No known configuration utility"
      fi
        proc_cont 	
    ;;

    --info|-i)
      if [ "$GAME_UTILITY_MANUAL" ]; then
        dosbox_run "$GAME_UTILITY_MANUAL"
      else
        message "Unsupported request - No known manual utility"
      fi
        proc_cont 	
    ;;
    
    --play|*)
      game_run	
    ;;
esac

### END #########################################
