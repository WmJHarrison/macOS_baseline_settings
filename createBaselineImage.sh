#!/bin/sh

# Create Baseline Image
# Make 500 MB disk image
/usr/bin/hdiutil create -type UDIF -size 500m -layout GPTSPUD -fs HFS+J -volname Baseline -uid 0 -gid 0 -mode 1777 Baseline.dmg;
if [ $? -eq 0 ]; then
	/usr/bin/hdiutil attach -owners on Baseline.dmg;
	sourceDevice=$(/usr/sbin/diskutil list | /usr/bin/awk '/Baseline/ { print "/dev/"$NF }');
	/usr/bin/touch /Volumes/Baseline/.com.apple.timemachine.donotpresent; # Don't prompt to use as Time Machine backup
	/usr/bin/touch /Volumes/Baseline/.metadata_never_index; # Disable Spotlight indexing
	/usr/sbin/chown root:wheel /Volumes/Baseline/.*;

	# Copy tools
	workingDirectory=$(/usr/bin/dirname "$0");
	if [ ! -d "/Library/Developer/CommandLineTools/usr/bin/" ]; then /usr/bin/xcode-select --install; fi
	/bin/cp /Library/Developer/CommandLineTools/usr/bin/strings /Volumes/Baseline/strings;
	/bin/cp /Library/Developer/CommandLineTools/usr/bin/otool-classic /Volumes/Baseline/otool;
	/bin/cp /Library/Developer/CommandLineTools/usr/bin/GetFileInfo /Volumes/Baseline/GetFileInfo;

	# Copy script
	/bin/cp "${workingDirectory}/baseline.sh" /Volumes/Baseline/baseline.sh;
	
	# Copy databases
	/bin/cp "${workingDirectory}/reference_data.db" /Volumes/Baseline/reference_data.db;
	/bin/cp "${workingDirectory}/SupportedModels" /Volumes/Baseline/SupportedModels;
	/bin/cp /Volumes/Source/security.db /Volumes/Baseline/security.db;

	# Clear 
	/usr/bin/xattr -c *
	/bin/rm .DS_Store

	# Dismount disk image
	/usr/sbin/diskutil unmount force /Volumes/Baseline;
	/usr/bin/hdiutil detach "${sourceDevice}";
else
	exit 1;
fi
