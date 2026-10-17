#!/bin/sh

bom_from_dmg() {
	installerVolumePath=$(/usr/bin/hdiutil attach "${installImage}" | /usr/bin/awk -F "  +" '/Apple_HFS/ { print $3 }' | /usr/bin/xargs);
	installerVolume=$(/bin/echo "${installerVolumePath}" | /usr/bin/awk -F "/" '{ print $NF }');
	installerDevice=$(/usr/sbin/diskutil list | /usr/bin/awk -v volname="${installerVolume:0:23}" '$0 ~ volname { print "/dev/"$NF }');
	sharedSupportVolumePath=$(/usr/bin/find "/Volumes/${installerVolume}" -type f -iname 'SharedSupport.dmg' -exec /usr/bin/hdiutil attach {} \; | /usr/bin/awk -F "  +" '/Apple_HFS/ { print $3 }' | /usr/bin/xargs);
	sharedSupportVolume=$(/bin/echo "${sharedSupportVolumePath}" | /usr/bin/awk -F "/" '{ print $NF }');
	sharedSupportDevice=$(/usr/sbin/diskutil list | /usr/bin/awk -v volname="${sharedSupportVolume:0:23}" '$0 ~ volname { print "/dev/"$NF }');
	assetDataArchive=$(/usr/bin/find "${sharedSupportVolumePath}" -type f -iname '*.zip' | /usr/bin/grep -v 'MacUpdateBrain');
	assetDataDir=$(/usr/bin/basename -s .zip "${assetDataArchive}");
	/bin/mkdir "${assetDataDir}";
	/usr/bin/unzip -X "${assetDataArchive}" -d "${assetDataDir}";
	/bin/cp $(/usr/bin/find "${assetDataDir}" -name post.bom) /Volumes/Source/macOS.bom;
	/usr/bin/defaults read "$PWD/${assetDataDir}/AssetData/boot/BuildManifest.plist" SupportedProductTypes SupportedProductTypes | /usr/bin/awk -F "\042" '{ print $2 }' >> /Volumes/Source/SupportedModels;
	/bin/rm -rf "${assetDataDir}";
	/usr/sbin/diskutil unmount force "${sharedSupportVolumePath}";
	/usr/bin/hdiutil detach "${sharedSupportDevice}";
	/usr/sbin/diskutil unmount force "${installerVolumePath}";
	/usr/bin/hdiutil detach "${installerDevice}";
}

bom_from_ipsw() {
	/bin/mkdir InstallComponents;
	pushd InstallComponents;
	/usr/bin/unzip "${installImage}";
	restorePropertyList=$(/usr/bin/find . -depth 1 -name Restore.plist  -exec /usr/bin/basename {} \;);
	systemImageAEA=$(/usr/bin/defaults read "$PWD/${restorePropertyList}" SystemRestoreImageFileSystems | /usr/bin/awk -F '"' '/APFS/ { print $2 }' | tail -n 1);
	/usr/sbin/diskutil image attach --readOnly "${systemImageAEA}"
	systemImageDevice=$(/usr/sbin/diskutil list | /usr/bin/awk -v RS= '/Macintosh HD/ {a=$NF} END{ print a }');
	# verify image is mounted
	if [ -d /Volumes/Macintosh\ HD\ 1 ]; then
		/usr/bin/mkbom /Volumes/Macintosh\ HD\ 1 /Volumes/Source/macOS.bom;
		buildManifestPropertyList=$(/usr/bin/find . -depth 1 -name 'BuildManifest.plist');
		/usr/bin/defaults read "$PWD/${buildManifestPropertyList}" SupportedProductTypes | /usr/bin/awk -F "\042" '{ print $2 }' >> /Volumes/Source/SupportedModels;
		/usr/sbin/diskutil unmount force /Volumes/Macintosh\ HD\ 1;
		/usr/bin/hdiutil detach "${systemImageDevice}";
		popd
		/bin/rm -rf InstallComponents;
	else
		/bin/echo "Mount failed";
		exit 1;
	fi
}

bom_from_package() {
	installerPath=$(/usr/sbin/pkgutil --payload-files "${installImage}" | /usr/bin/grep -E '.app$' | /usr/bin/cut -c 2-);
	/usr/sbin/installer -target / -pkg "${installImage}";
	if [ $? -eq 0 ]; then
		sharedSupportVolumePath=$(/usr/bin/hdiutil attach -noverify "${installerPath}/Contents/SharedSupport/SharedSupport.dmg" | /usr/bin/awk -F "  +" '/Apple_HFS/ { print $3 }' | /usr/bin/xargs);
		sharedSupportVolume=$(/bin/echo "${sharedSupportVolumePath}" | /usr/bin/awk -F "/" '{ print $NF }');
		sharedSupportDevice=$(/usr/sbin/diskutil list | /usr/bin/awk -v volname="${sharedSupportVolume:0:23}" '$0 ~ volname { print "/dev/"$NF }');
		assetDataArchive=$(/usr/bin/find "${sharedSupportVolumePath}" -type f -iname '*.zip' | /usr/bin/grep -v 'MacUpdateBrain');
		assetDataDir=$(/usr/bin/basename -s .zip "${assetDataArchive}");
		/bin/mkdir "${assetDataDir}";
		/usr/bin/unzip -X "${assetDataArchive}" -d "${assetDataDir}";
		/bin/cp $(/usr/bin/find "${assetDataDir}" -name post.bom) /Volumes/Source/macOS.bom;
		/usr/bin/defaults read "$PWD/${assetDataDir}/AssetData/boot/BuildManifest.plist" SupportedProductTypes SupportedProductTypes | /usr/bin/awk -F "\042" '{ print $2 }' >> /Volumes/Source/SupportedModels;
		/bin/rm -rf "${assetDataDir}";
		/usr/sbin/diskutil unmount force "${sharedSupportVolumePath}";
		/usr/bin/hdiutil detach "${sharedSupportDevice}";
		/bin/rm -rf "${installerPath}";
	fi
}

installImage=$1;

if [ -n "${installImage}" ]; then
	installerType=$(/bin/echo "${installImage}" | /usr/bin/awk -F "." '{ print $NF }');
else
	/bin/echo "No Installer supplied.";
	/bin/echo "Usage: /bin/sh createSourceImage.sh <Install Image>";
	exit 1;
fi

# Create Source Image
# Make 500 MB disk image
/usr/bin/hdiutil create -type UDIF -size 500m -layout GPTSPUD -fs HFS+J -volname Source -uid 0 -gid 0 -mode 1777 Source.dmg;
if [ $? -eq 0 ]; then
	/usr/bin/hdiutil attach -owners on Source.dmg;
	sourceDevice=$(/usr/sbin/diskutil list | /usr/bin/awk '/Source/ { print "/dev/"$NF }');
	/usr/bin/touch /Volumes/Source/.com.apple.timemachine.donotpresent; # Don't prompt to use as Time Machine backup
	/usr/bin/touch /Volumes/Source/.metadata_never_index; # Disable Spotlight indexing
	/usr/sbin/chown root:wheel /Volumes/Source/.*;

	# Copy tools
	workingDirectory=$(/usr/bin/dirname "$0");
	if [ ! -d "/Library/Developer/CommandLineTools/usr/bin/" ]; then /usr/bin/xcode-select --install; fi
	/bin/cp /Library/Developer/CommandLineTools/usr/bin/strings /Volumes/Source/strings;
	/bin/cp /Library/Developer/CommandLineTools/usr/bin/otool-classic /Volumes/Source/otool;
	/bin/cp /Library/Developer/CommandLineTools/usr/bin/GetFileInfo /Volumes/Source/GetFileInfo;
	# Copy script
	/bin/cp "${workingDirectory}/macOSDeepInspection.sh" /Volumes/Source/macOSDeepInspection.sh;
	
	# Copy Reference Database
	/bin/cp "${workingDirectory}/reference_data.db /Volumes/Source/reference_data.db;
	
	# Copy Bom file
	case $installerType in
		dmg) bom_from_dmg ;;
		ipsw) bom_from_ipsw ;;
		pkg) bom_from_package ;;
		*) /bin echo "Unsupported file type."; exit 1 ;;
	esac

	# Copy ReadMe.rtf
	/bin/cp "${workingDirectory}/macOS Deep Inspection.md" /Volumes/Source/ReadMe.md;
	/bin/chmod 644 /Volumes/Source/ReadMe.md;

	# Clear 
	/usr/bin/xattr -c *
	/bin/rm .DS_Store

	# Dismount disk image
	/usr/sbin/diskutil unmount force /Volumes/Source;
	/usr/bin/hdiutil detach "${sourceDevice}";
else
	exit 1;
fi
