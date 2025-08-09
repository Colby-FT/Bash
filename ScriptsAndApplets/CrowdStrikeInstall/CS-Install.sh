#!/bin/bash

#Assign Variables
CSCID="<CID-HERE>"
rpm09="CS-Falcon-RHEL-9.rpm"
rpm08="CS-Falcon-RHEL-8.rpm"
rpm07="CS-Falcon-RHEL-7.rpm"
rpm06="CS-Falcon-RHEL-6.rpm"
deb01="CS-Falcon-Deb.deb"
deb02="CS-Falcon-Ubuntu.deb"
sles01="CS-Falcon-SLES-15.rpm"
sles02="CS-Falcon-SLES-12.rpm"
sles03="CS-Falcon-SLES-11.rpm"

#Get the OS version
# Try hostnamectl
os=$(hostnamectl | grep "Operating System")

# If empty, try lsb_release -d
if [ -z "$os" ]; then
    os=$(lsb_release -d 2>/dev/null)
fi

# If still empty, exit with error
if [ -z "$os" ]; then
    echo "OS could not be determined"
    exit 1
else
    echo "Detected OS: $os"
    versName=${os#*: }
fi


# Change to the directory where the script is located
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$script_dir"

##Create tmp/WorkDir folder and copy contents of iso to it
dirName='/tmp/WorkDir'
if [ -d "$dirName" ]; then
  rm -rf "$dirName"
fi
mkdir "$dirName"
cp * /tmp/WorkDir/

##Change working directories
cd /tmp/WorkDir/

##Check OS version and determine install package
if [[ "$versName" == *"Red Hat"* ]] && [[ "$versName" == *"9."* ]] || [[ $versName == *"Cent"* ]] && [[ $versName == *"9"* ]]; then
  chmod +x "$rpm09"
  rpm -i "$rpm09"
elif [[ "$versName" == *"Red Hat"* ]] && [[ "$versName" == *"8."* ]] || [[ $versName == *"Cent"* ]] && [[ $versName == *"8"* ]]; then
  chmod +x "$rpm08"
  rpm -i "$rpm08"
elif [[ "$versName" == *"Red Hat"* ]] && [[ "$versName" == *"7."* ]] || [[ $versName == *"Cent"* ]] && [[ $versName == *"7"* ]]; then
  chmod +x "$rpm07"
  rpm -i "$rpm07"
elif [[ "$versName" == *"Red Hat"* ]] && [[ "$versName" == *"6."* ]] || [[ $versName == *"Cent"* ]] && [[ $versName == *"6"* ]]; then
  chmod +x "$rpm06"
  rpm -i "$rpm06"
elif [[ "$versName" == *"Debian"* ]]; then
  chmod +x "$deb01"
  dpkg -i "$deb01"
elif [[ "$versName" == *"Ubuntu"* ]]; then
  chmod +x "$deb02"
  dpkg -i "$deb02"
elif [[ "$versName" == *"Suse"* ]] && [[ "$versName" == *"15"* ]]; then
  chmod +x "$sles01"
  rpm -i "$sles01"
elif [[ "$versName" == *"Suse"* ]] && [[ "$versName" == *"12"* ]]; then
  chmod +x "$sles02"
  rpm -i "$sles02"
elif [[ "$versName" == *"Suse"* ]] && [[ "$versName" == *"11"* ]]; then
  chmod +x "$sles03"
  rpm -i "$sles03"
else
  echo "Install manually for $os"
  return
fi

# Check the return code of rpm for success
if [ $? -ne 0 ]; then
  echo "Error: Failed to install the package."
  exit 1
fi

# Set Token
/opt/CrowdStrike/falconctl -s --cid="$CSCID"

# Start Agent
systemctl start falcon-sensor
service falcon-sensor start

#Verify running
ps -e | grep falcon-sensor

exit 0
