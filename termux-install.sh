#!/usr/bin/env bash

if ! command -v termux-setup-storage; then
  echo This script can be executed only on Termux
  exit 1
fi

termux-wake-lock

# Update packages with default "N" (no)
echo "Updating package lists..."
pkg update

echo "Do you want to upgrade packages? [y/N]"
read -r -p "> " upgrade_answer

if [[ $upgrade_answer =~ ^[Yy]$ ]]; then
  echo "Upgrading packages..."
  pkg update && pkg upgrade -y && pkg install python3 git clang ffmpeg wget libjpeg-turbo libcrypt ndk-sysroot zlib openssl python-psutil -y -o Dpkg::Options::="--force-confold" || exit 2
else
  echo "Skipping package upgrade"
fi

# Install required packages
echo "Installing required packages..."
pkg install python3 git clang ffmpeg 

# Check if already installed
if [[ -f ".env" ]] && [[ -f "my_account.session" ]]; then
  echo "It seems that Moon-Userbot is already installed. Exiting..."
  exit
fi

# Create virtual environment with system site packages
echo "Creating virtual environment with system site packages..."
python3 -m venv --system-site-packages venv || exit 2

# Activate venv for the rest of the script
source venv/bin/activate

# Upgrade pip in venv
pip install --upgrade pip

# Install Pillow with flags using venv's pip
LDFLAGS="-L${PREFIX}/lib/" CFLAGS="-I${PREFIX}/include/" pip install --upgrade pillow

# First install requirements.txt normally
echo "Installing requirements from Moon-Userbot..."
pip install -U -r requirements.txt || exit 2

# Fix dependency conflicts by pinning correct versions
echo "Fixing dependency conflicts..."
pip install 'dnspython==2.7.0' 'pymongo==4.13.0' --force-reinstall --no-deps

echo
echo "Enter API_ID and API_HASH"
echo "You can get it here -> https://my.telegram.org/apps"
echo "Leave empty to use defaults  (please note that default keys significantly increases your ban chances)"
read -r -p "API_ID > " api_id

if [[ $api_id = "" ]]; then
  api_id="2040"
  api_hash="b18441a1ff607e10a989891a5462e627"
else
  read -r -p "API_HASH > " api_hash
fi

echo
echo "SET PM PERMIT warn limit"
read -r -p "PM_LIMIT warn limit > " pm_limit

if [[ $pm_limit = "" ]]; then
  pm_limit="3"
  echo "limit not provided by user set to default"
fi

echo
echo "Enter APIFLASH_KEY for webshot plugin"
echo "You can get it here -> https://apiflash.com/dashboard/access_keys"
read -r -p "APIFLASH_KEY > " apiflash_key

if [[ $apiflash_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use .webshot plugin"
fi

echo
echo "Enter RMBG_KEY for remove background module"
echo "You can get it here -> https://www.remove.bg/dashboard#api-key"
read -r -p "RMBG_KEY > " rmbg_key

if [[ $rmbg_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use remove background modules"
fi

echo
echo "Enter GEMINI_KEY if you want to use AI"
echo "NOTE: Don't Use unless you've enough storage in your device"
echo "MIN. REQ. STORAGE: 128GB"
echo "You can get it here -> https://makersuite.google.com/app/apikey"
read -r -p "GEMINI_KEY > " gemini_key

if [[ $gemini_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use Gemini AI modules"
fi

echo
echo "Enter COHERE_KEY if you want to use AI"
echo "You can get it here -> https://dashboard.cohere.com/api-keys"
read -r -p "COHERE_KEY > " cohere_key

if [[ $cohere_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use Coral AI modules"
fi

echo
echo "Enter VT_KEY for VirusTotal"
echo "You can get it here -> https://www.virustotal.com/"
read -r -p "VT_KEY > " vt_key

if [[ $vt_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use VirusTotal module"
fi

printf "If you wish to use a different PORT for the web ui, enter it here\n"
printf "Leave empty to use default (8080)\n"
read -r -p "PORT > " port

if [[ $port = "" ]]; then
  port=8000
fi

echo "Choose database type:"
echo "[1] MongoDB (your url)"
echo "[2] Sqlite"
read -r -p "> " db_type

if [[ $db_type = 1 ]]; then
  echo "Please enter db_url"
  echo "You can get it here -> https://telegra.ph/How-to-get-Mongodb-URL-and-login-in-telegram-08-01"
  read -r -p "> " db_url
  db_name=Moon_Userbot
  db_type=mongodb
else
  db_name=db.sqlite3
  db_type=sqlite3
fi

cat >.env <<EOL
API_ID=${api_id}
API_HASH=${api_hash}

STRINGSESSION=

# sqlite/sqlite3 or mongo/mongodb
DATABASE_TYPE=${db_type}
# file name for sqlite3, database name for mongodb
DATABASE_NAME=${db_name}

# only for mongodb
DATABASE_URL=${db_url}

APIFLASH_KEY=${apiflash_key}
RMBG_KEY=${rmbg_key}
VT_KEY=${vt_key}
GEMINI_KEY=${gemini_key}
COHERE_KEY=${cohere_key}
PM_LIMIT=${pm_limit}
EOL

# Run install.py with venv's python
python install.py 3 || exit 3

echo
echo "============================"
echo "Great! Moon-Userbot installed successfully!"
echo "Start with: source venv/bin/activate && python main.py"
echo "Or directly: ./venv/bin/python main.py"
echo "============================"
