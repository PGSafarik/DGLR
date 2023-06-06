### Operations ######################################
# Print application using
function help 
{
  message "\$ $(basename $THIS) {command}"
  nl
  message "Comand list:"  
  $LAUNCHER --help

  cat << END_ARGS
  --verbrose or -v    Print decompress and commpress content of user storage
  --clean             Delete user storage for this game (if-any) and exit
  --help or -h        Output this help-text and based informations of this game and exit
  --yes or -y         Automatic answer to all launcher questions yes
  --no or -n          Automatic answer to all launcher questions no   
END_ARGS
}

# Decompression and prepare user storage. 
function storage_init
{
  # Check user storage pathname
  if [ -z "$USER_GAME_STORAGE" ]; then
    STORAGE="${HOME}/.local/share/games" 
  else
    STORAGE="${HOME}/$USER_GAME_STORAGE"  
  fi
  [ -e "$STORAGE" ] ||  mkdir -p "$STORAGE"
  STORAGE="${STORAGE}/${GAME_ID}.save"  
  vmessage "User's data storage: $STORAGE"

  if [ $STORAGE_ACTIVE -eq 1 ]; then
    
    # Prepare directories for OverlayFS
    mkdir "$UPPER_DIR"
    mkdir "$WORK_DIR"
    mkdir "$DRIVE_DIR"
  
    # Users data decompreesion
    # Pokud nexistuje soubor uloziste, tato cast funkce neprovede nic, pouze zustane predpripravena
    # plna cesta i s nazvem archivu user storage v STORAGE. Pokud byl archiv nalezen bude rozbalen a
    # nastavi se patricne hodnota indikacni promene - hlavne pro pozdejsi pripadne pouziti prevazne v 
    # scripts/go.sh skriptu
  
    if [ -e "$STORAGE" ]; then
      message "Unpack user storage"
      tar $(Checkverb "-xf" "-xvf") "$STORAGE" -C "${GAME_ROOT}/${UPPER_DIR}"  
      STORAGE_LOAD_G=1
  
      # Control files integrity
      if [ -e "${UPPER_DIR}/.metadata/checksum.md5" ]; then     
        message "Check user storage files integrity"
        cd "$UPPER_DIR"
        md5sum $(Checkverb "--quiet -c" "-c") ".metadata/checksum.md5"
        cd ..
      fi  
    fi  
  
    message "Extraction finised."
    nl
  
    # Fuse OverlayFS mount
    message "Mounting the OverlayFS"
    fuse-overlayfs -o lowerdir="${GAME_ROOT}/${LOWER_DIR}",upperdir="${GAME_ROOT}/${UPPER_DIR}",workdir="${GAME_ROOT}/${WORK_DIR}" "${GAME_ROOT}/${DRIVE_DIR}"    
  else
    message "Extraction finised."
  fi
}

# Comprimation all changed files and directories on user storage
function storage_sync
{
  # Checking if the storage dir is not empty
  if [ -z $(find "${UPPER_DIR}" -prune -empty ) ]; then 
    cd "$UPPER_DIR"    
      
    # insert checksums for data consistenci control
    if [ ! -e ".metadata" ]; then 
      mkdir ".metadata"
    fi

    # Write control checksums
    find * -type f ! -regex '^\.metadata/.*' -exec md5sum {} \; > ".metadata/~checksum.md5"
    
    # Control modifications
    CHANGE=1
    if [ -e ".metadata/checksum.md5" ]; then
      CMPOUT=$(cmp ".metadata/checksum.md5" ".metadata/~checksum.md5") 
      vmessage "$CMPOUT"
      if [ "$CMPOUT" ]; then 
        rm ".metadata/checksum.md5"
        mv ".metadata/~checksum.md5" ".metadata/checksum.md5"
      else 
         rm ".metadata/~checksum.md5"
         CHANGE=0
      fi
    else
      mv ".metadata/~checksum.md5" ".metadata/checksum.md5"
    fi
    
    
    if [ $CHANGE -eq 1 ]; then
      message "User store synchronization" 
      
      # Write desription metadata
      cat > ".metadata/info.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>    
<Info name="${GAME_ID}" ext="save" section="games">
  <Value key="Description">Archive, contains user data of DOSBox (Games) Linux Runtime.</Value>
  <Value key="Mime">application/x-xz-compressed-tar</Value> 
  <Value key="Categories">$GAME_CATEGORY</Value> 
  <Value key="Game">${GAME_NAME}</Value> 
  <Value key="Executable">$(basename $THIS)</Value>
  <Value key="Modify">$(date '+%D %T')</Value>
  <Value key="User">${HOSTNAME}:${USER}</Value>
</Info>
EOF
         
      # Comprime users data 
      #tar --lzma $(Checkverb "-cf" "-cvf") "$STORAGE" .
      tar $(Checkverb "-cf" "-cvf") - . | xz -9 -c - > "$STORAGE"
      
    fi
  fi
}

function storage_delete
{
  question "This action delete user storage for this game. Continue?"
  if [ $? == 1 ]; then  
    rm $(Checkverb "--verbose" "") "$STORAGE"
    if [ $? -eq 0 ]; then
      message "User game storage deleted."
    else
      message "FAILED of deleting process for user game storage."
    fi  
  fi
}

# Initialize the user data storage and prepare the game root dir 
function Initialize
{  
  [ -z "$GAME_ID" ] && fatal "Developer fatal error: GAME ID MUST BE DEFINED, DUDE!!!"
 
  # Unpack game archive
  message "Game data extraction. This operation may take some time, please wait..."
  GAME_ROOT=$( mktemp -d "${EXTRACT_DIR}/${GAME_ID}.XXXXXX" )
  vmessage "Game directory: $GAME_ROOT"

  SCRIPT_SIZE=$( awk '/^__DATA__/ {print NR + 1; exit 0; }' "$THIS" )
  tail -n +$SCRIPT_SIZE "$THIS" | tar --lzma $(Checkverb "-xC" "-xvC") "$GAME_ROOT"
  chmod go-rwx "$GAME_ROOT"  # To be sure - no one, apart from the owner and root, has anything to look at!
  cd "$GAME_ROOT"
  
  # check game data integrity
  if [ -e ".metadata/checksum.md5" ]; then
    message "Check runtime files integrity"
    md5sum $(Checkverb "--quiet -c" "-c") ".metadata/checksum.md5" 
  fi  
     
  storage_init    
}

# Synchronize user data storage and remove the game root dir
function Quit
{  
  if [ $STORAGE_ACTIVE -eq 1 ]; then
    # FUSE OveralyFS unmount
    message "Unmounting the OvelayFS."
    cd "$GAME_ROOT"
    fusermount3 -u "${GAME_ROOT}/${DRIVE_DIR}"

    # Packing user data
    storage_sync
  fi
  
  # Clean
  message "Cleaning"
  cd "$BACK_DIR"
  rm $(Checkverb "-rf" "-vrf") "$GAME_ROOT"
  nl
  message "BYE!"
}

### MAIN #########################################
PrintHead
info "Prepare..."

# Zpracovani argumentu
NEXT=( )

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) 
      PRINT_HELP=1
      STORAGE_ACTIVE=0
    ;;
    
    --clean)
      CLEAN_STORAGE=1   
      STORAGE_ACTIVE=0	
    ;;
  
    --verbrose|-v)
      VERBROSE=1
    ;;
  
    --yes|-y)
      AUTO_ANSWER="y"
    ;;
  
    --no|-n)
      AUTO_ANSWER="n"
    ;;
   
    *)
      NEXT+=( "$1" )
    ;;
  esac 
  shift
done 


Initialize
pl

if [ $PRINT_HELP -eq 1 ]; then
  info "Using..."
  help
  
elif [ $CLEAN_STORAGE -eq 1 ]; then
  info "Delete user storage..."
  storage_delete
else
  info "Starting..."
  source $LAUNCHER ${NEXT[*]}
fi
pl

info "Exiting..."
Quit
pl

exit 0

__DATA__
