#!/bin/zsh
# Collect baseline settings
# Copyright 2026 William Harrison
# Version @(#)1.1.2 [2026-09-02]
# William Harrison

set -x;
zmodload zsh/mapfile
export LC_ALL=C;

workingDir=$(/usr/bin/dirname $0);

# Baseline
productName=$(/usr/bin/sw_vers --productName);
productVersion=$(/usr/bin/sw_vers --productVersion);
buildVersion=$(/usr/bin/sw_vers --buildVersion);
iOSSupportVersion=$(/usr/bin/defaults read /System/Library/CoreServices/SystemVersion.plist iOSSupportVersion);
codeName=$(/usr/bin/awk '/SOFTWARE LICENSE AGREEMENT FOR macOS/' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' | /usr/bin/awk -F 'macOS ' '{print $NF}' | /usr/bin/awk '{print substr($0, 0, length($0)-1)}');
kernelVersion=$(/usr/bin/uname -a | /usr/bin/awk '{ print $3 }');
xnuVersion=$(/usr/bin/uname -a | /usr/bin/awk '{ print $14 }' | /usr/bin/awk -F "[-~]" '{ print $2 }');
cfNetworkVersion=$(/usr/bin/defaults read /System/Library/Frameworks/CFNetwork.framework/Versions/Current/Resources/version.plist CFBundleVersion);
baselineFiles="${productVersion}_${buildVersion}_baseline";

sheet="${productName} ${codeName}";
/usr/bin/printf '%s\t%s\n' "Generated" "$(/bin/date "+%Y-%m-%d")" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "${productName} ${codeName}" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "macOS" "${buildVersion} ${codeName}" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Build" "${buildVersion}" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "iOS Support" "${iOSSupportVersion}" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Kernel Version" "${kernelVersion}" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "XNU Version" "${xnuVersion}" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "CFNetwork Version" "${cfNetworkVersion}" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '\n' >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Supported Models" >> ${baselineFiles}_${sheet}.csv;
for modelIdentifier in $(/bin/cat <(/usr/bin/defaults read /System/Library/CoreServices/PlatformSupport.plist SupportedModelProperties | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]') "${workingDir}/SupportedModels" | /usr/bin/sort); do
	/usr/bin/printf '%s\t%s\n' "" "${modelIdentifier}" >> ${baselineFiles}_${sheet}.csv;
done

# Get Local Users
sheet="users";
/bin/echo "Local Users" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\n' "User Name" "Unique ID" "Real Name" "Generated UID" "Shell" "Home Directory" >> ${baselineFiles}_${sheet}.csv;
usersTemp=$(/usr/bin/mktemp -t tmp);
/usr/bin/dscl . -list /Users > "${usersTemp}";
while read userName; do
	guid=$(/usr/bin/dscl . -read /Users/${userName} GeneratedUID | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	homeDirectory=$(/usr/bin/dscl . -read /Users/${userName} NFSHomeDirectory | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	realName=$(/usr/bin/dscl . -read /Users/${userName} RealName | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	shell=$(/usr/bin/dscl . -read /Users/${userName} UserShell | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	uniqueID=$(/usr/bin/dscl . -read /Users/${userName} UniqueID | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${userName}" "${uniqueID}" "${realName}" "${guid}" "${shell}" "${homeDirectory}" >> ${baselineFiles}_${sheet}.csv;
done < "${usersTemp}"

# Get Local Groups
sheet="groups";
/bin/echo "Local Groups" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "Group Name" "Group ID" "Real Name" "Generated UID" "Members" >> ${baselineFiles}_${sheet}.csv;
groupsTemp=$(/usr/bin/mktemp -t tmp);
/usr/bin/dscl . -list /Groups > "${groupsTemp}";
while read groupName; do
	guid=$(/usr/bin/dscl . -read /Groups/${groupName} GeneratedUID | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	groupID=$(/usr/bin/dscl . -read /Groups/${groupName} PrimaryGroupID | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	realName=$(/usr/bin/dscl . -read /Groups/${groupName} RealName | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	members=$(/usr/bin/dscl . -read /Groups/${groupName} GroupMembership 2>/dev/null | /usr/bin/awk -F ": " '{ print $2 }' | /usr/bin/tr -d "\012");
	/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "${groupName}" "${groupID}" "${realName}" "${guid}" "${members}" >> ${baselineFiles}_${sheet}.csv;
done < "${groupsTemp}"

# Get Available Locales
sheet="locales";
/bin/echo "Terminal Supported Locales" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Locale" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/locale -a | /usr/bin/sort >> ${baselineFiles}_${sheet}.csv;

# Get Supported Character Sets
sheet="charactersets";
/bin/echo "Terminal Supported Character Sets" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Character Set" >> ${baselineFiles}_${sheet}.csv;
/usr/libexec/PlistBuddy -c "Print :en:" /System/Library/Frameworks/Foundation.framework/Versions/C/Resources/EncodingNames.loctable | /usr/bin/awk -F " = " '{gsub("^  +","");  print $1 }' | /usr/bin/grep "(" | /usr/bin/sort >> ${baselineFiles}_${sheet}.csv;

# Get Supported Code Sets
sheet="codesets";
/bin/echo "Terminal Supported Code Sets" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Code Set" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/locale -m | /usr/bin/sort >> ${baselineFiles}_${sheet}.csv;

# Get Supported Keyboards
sheet="keyboards";
/bin/echo "Terminal Supported Keyboards" >> ${baselineFiles}_${sheet}.csv;
/usr/libexec/PlistBuddy -c "Print en" /System/Library/Keyboard\ Layouts/AppleKeyboardLayouts.bundle/Contents/Resources/InfoPlist.loctable | /usr/bin/awk -F ' = ' '{ print $NF }' | /usr/bin/sort >> ${baselineFiles}_${sheet}.csv;

# Get Default Registered UTIs
sheet="utis";
/bin/echo "Universal Type Identifiers" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "UTI" >> ${baselineFiles}_${sheet}.csv;
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump -apps -domain system,local,users | /usr/bin/awk -F ":               " '/claimed UTIs:/ { gsub(", ","\n"); print $NF }' | sort -u | grep -v "^dyn" >> ${baselineFiles}_${sheet}.csv;

# Get Spotlight Metadata Attributes
sheet="metadata";
/bin/echo "Spotlight Metadata Attributes" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\n' "Attribute" "Description" "Attribute Key" "Data Type" >> ${baselineFiles}_${sheet}.csv;
metadataTemp=$(/usr/bin/mktemp -t tmp);
/usr/bin/mdimport -X | /usr/bin/awk '/name = kMDItem|name = \"_kMDItem/{ gsub(";",""); print $NF}' | /usr/bin/tr -d "\042" | /usr/bin/sort -u >> "${metadataTemp}";
while read metadataAttribute; do
	declare -a metadata;
	metadata=(${(s:|:)$(/usr/bin/sqlite3 reference_data.db "SELECT * FROM spotlight WHERE attribute_key = \"${metadataAttribute}\";")});
	/usr/bin/printf '%s\t%s\t%s\t%s\n' "${metadata[1]}" "${metadata[2]}" "${metadataAttribute}" "${metadata[4]}" >> ${baselineFiles}_${sheet}.csv;
done < "${metadataTemp}"
/bin/rm -f "${metadataTemp}";

# Get ShareKit Extensions
sheet="sharekit";
/bin/echo "ShareKit Extensions"  >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Extension"  >> ${baselineFiles}_${sheet}.csv;
/usr/bin/defaults read /System/Library/PrivateFrameworks/ShareKit.framework/Versions/A/Resources/SHKServicesOrder.plist displayOrder | /usr/bin/awk -F '\042' '{ print $2 }' >> ${baselineFiles}_${sheet}.csv;

# Get System Settings AppleScript Anchors
# Requires Terminal automatin for System Settings.
# tccutil list -s Automation -b com.apple.Terminal 
sheet="applescript_anchors";
/bin/echo "System Settings AppleScript Anchors" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Pane" "Anchor" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/osascript -e 'tell application "System Settings" to get every anchor of every pane' 2>&1 | /usr/bin/sed 's/, /\n/g' | /usr/bin/sed 's/^anchor //g' | /usr/bin/awk -F " of pane id " '{ printf "%s\t%s\n", $2, $1 }' | /usr/bin/sort -u >> ${baselineFiles}_${sheet}.csv;

# Get Feature Flags
# To set Feature Flags: sudo defaults write "${appDomainPath}" "${appDomainKey}" -dict-add Enabled -bool ${keyValue};
sheet="featureflags";
/bin/echo "Feature Flags"  >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "Subsystem" "Key" "Value" >> ${baselineFiles}_${sheet}.csv;
for appDomainPath in $(/usr/bin/find /System/Library/FeatureFlags -type f -iname '*.plist'); do
	appDomain=$(/usr/bin/basename -s .plist "${appDomainPath}")
	for appDomainKey in $(/usr/bin/defaults read "${appDomainPath}" 2>/dev/null | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.|keys[]' 2>/dev/null); do
		if [ -n "${appDomainKey}" ]; then
			keyValue=$(/usr/bin/defaults read "${appDomainPath}" "${appDomainKey}" | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.Enabled');
			if [ "${keyValue}" = "null" ]; then
				continue;
			else
				/usr/bin/printf '%s\t%s\t%s\n' "${appDomain}" "${appDomainKey}" "${keyValue}" >> ${baselineFiles}_${sheet}.csv;
			fi
		fi
	done
done

# Get CacheData purgable space
sheet="CacheDelete";
/bin/echo "CacheDelete purgable space" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "CACHE_DELETE_ID" "CACHE_DELETE_SERVICES" "CACHE_DELETE_NOTIFICATIONS" "CACHE_DELETE_USER_AGENT" "CACHE_DELETE_DO_NOT_QUERY" >> ${baselineFiles}_${sheet}.csv;
for cacheDelete in $(/usr/bin/find /System/Library/CacheDelete -iname '*.plist'); do
	serviceID=$(/usr/bin/defaults read ${cacheDelete} CACHE_DELETE_ID 2>/dev/null);
	deleteServices=$(/usr/bin/defaults read ${cacheDelete} CACHE_DELETE_SERVICES 2>/dev/null);
	deleteNotifications=$(/usr/bin/defaults read ${cacheDelete} CACHE_DELETE_NOTIFICATIONS 2>/dev/null);
	userAgent=$(/usr/bin/defaults read ${cacheDelete} CACHE_DELETE_USER_AGENT 2>/dev/null);
	doNotQuery=$(/usr/bin/defaults read ${cacheDelete} CACHE_DELETE_DO_NOT_QUERY 2>/dev/null);
	/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "${serviceID}" "${deleteServices}" "${deleteNotifications}" "${userAgent}" "${doNotQuery}" >> ${baselineFiles}_${sheet}.csv;
	unset serviceID deleteServices deleteNotifications userAgent doNotQuery;
done

# Get Installed apps
sheet="applications";
/bin/echo "Applications" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\n' "Application" "Version" "BundleIdentifier" "Path" >> ${baselineFiles}_${sheet}.csv;
for applicationsPaths in /System/Applications /System/Library/CoreServices/Applications /System/Volumes/Preboot/Cryptexes/App/System/Applications; do
appsTemp=$(/usr/bin/mktemp -t tmp);
/usr/bin/find "${applicationsPaths}" -type d -iname "*.app" > "${appsTemp}";
	while read applicationPath; do
		applicationName=$(/usr/bin/defaults read "${applicationPath}/Contents/Info.plist" CFBundleDisplayName);
		if [ -z "${applicationName}" ]; then applicationName=$(/usr/bin/defaults read "${applicationPath}/Contents/Info.plist" CFBundleName); fi
		applicationVersion=$(/usr/bin/defaults read "${applicationPath}/Contents/Info.plist" CFBundleShortVersionString);
		applicationBundleIdentifier=$(/usr/bin/defaults read "${applicationPath}/Contents/Info.plist" CFBundleIdentifier);
		/usr/bin/printf '%s\t%s\t%s\t%s\n' "${applicationName}" "${applicationVersion}" "${applicationBundleIdentifier}" "${applicationPath}" >> ${baselineFiles}_${sheet}.csv;
	done < "${appsTemp}"
	/bin/rm -f "${appsTemp}";
done

# Supported File Systems
sheet="filesystems";
/bin/echo "Supported File Systems" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Format" "$(/usr/sbin/diskutil listFilesystems -plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]|.UserVisibleName' | /usr/bin/tr "\012" "\011")" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "MinimumSize" "$(/usr/sbin/diskutil listFilesystems -plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]|.MinimumSize' | /usr/bin/tr "\012" "\011")" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "MaximumSize" "$(/usr/sbin/diskutil listFilesystems -plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]|.MaximumSize' | /usr/bin/tr "\012" "\011")" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Resizable" "$(/usr/sbin/diskutil listFilesystems -plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]|.SupportsResize' | /usr/bin/tr "\012" "\011")" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Single Volume" "$(/usr/sbin/diskutil listFilesystems -plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]|.RequiresWholeDiskFormat' | /usr/bin/tr "\012" "\011")" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Bootable" "$(/usr/sbin/diskutil listFilesystems -plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]|.Bootable' | /usr/bin/tr "\012" "\011")" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Required Driver" "$(/usr/sbin/diskutil listFilesystems -plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]|.RequiresBooterToBoot' | /usr/bin/tr "\012" "\011")" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Driver" "$(/usr/sbin/diskutil listFilesystems -plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.[]|.BundlePath' | /usr/bin/tr "\012" "\011")" >> ${baselineFiles}_${sheet}.csv;

# File System

# Get No User files
sheet="ownerless";
/bin/echo "Files with out owners" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "File Path" "Ownership" "Permissions" >> ${baselineFiles}_${sheet}.csv;
ownerlessTemp=$(/usr/bin/mktemp);
/usr/bin/find -x / -nouser -print 2>/dev/null | /usr/bin/grep -v "${workingDir}" > "${ownerlessTemp}";
while read fileName; do
	ownership=$(/usr/bin/stat -f "%u:%g" "${fileName}");
	permissions=$(/usr/bin/stat -f "%p" "${fileName}");
	/usr/bin/printf '%s\t%s\t%s\n' "${fileName}" "${ownership}" "${permissions}" >> ${baselineFiles}_${sheet}.csv;
done < "${ownerlessTemp}"
/bin/rm -f "${ownerlessTemp}";

# Get No Group files
sheet="groupless";
/bin/echo "Files with out groups" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "File Path" "Ownership" "Permissions" >> ${baselineFiles}_${sheet}.csv;
grouplessTemp=$(/usr/bin/mktemp);
/usr/bin/find -x / -nogroup -print 2>/dev/null | /usr/bin/grep -v "${workingDir}" >> ${grouplessTemp};
while read fileName; do
	ownership=$(/usr/bin/stat -f "%u:%g" "${fileName}");
	permissions=$(/usr/bin/stat -f "%p" "${fileName}");
	/usr/bin/printf '%s\t%s\t%s\n' "${fileName}" "${ownership}" "${permissions}" >> ${baselineFiles}_${sheet}.csv;
done < ${grouplessTemp}
/bin/rm ${grouplessTemp};

# Get world writable directories
sheet="world_writable";
/bin/echo "Directories with 'Allow write by others'" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "File Path" "Ownership" "Permissions" >> ${baselineFiles}_${sheet}.csv;
worldWritableTemp=$(/usr/bin/mktemp);
/usr/bin/find -x / -type d -perm -002 -print 2>/dev/null | /usr/bin/grep -v -E "^/System/Volumes/Data" >> ${worldWritableTemp};
while read fileName; do
	ownership=$(/usr/bin/stat -f "%u:%g" "${fileName}");
	permissions=$(/usr/bin/stat -f "%p" "${fileName}");
	/usr/bin/printf '%s\t%s\t%s\n' "${fileName}" "${ownership}" "${permissions}" >> ${baselineFiles}_${sheet}.csv;
done < ${worldWritableTemp}
/bin/rm ${worldWritableTemp};

# Get Stickey Bit directories
sheet="stickey_bit";
/bin/echo "Directories with Sticky Bits" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "File Path" "Ownership" "Permissions" >> ${baselineFiles}_${sheet}.csv;
stickeyTemp=$(/usr/bin/mktemp);
/usr/bin/find -x / -type d -perm -1000 -print 2>/dev/null | /usr/bin/grep -v -E "^/System/Volumes/Data" >> ${stickeyTemp};
while read fileName; do
	ownership=$(/usr/bin/stat -f "%u:%g" "${fileName}");
	permissions=$(/usr/bin/stat -f "%p" "${fileName}");
	/usr/bin/printf '%s\t%s\t%s\n' "${fileName}" "${ownership}" "${permissions}" >> ${baselineFiles}_${sheet}.csv;
done < ${stickeyTemp}
/bin/rm ${stickeyTemp};

# Get rootless directories
sheet="rootless";
/bin/echo "Directories with rootless" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "File Path" "Ownership" "Permissions" >> ${baselineFiles}_${sheet}.csv;
rootlessTemp=$(/usr/bin/mktemp);
/usr/bin/find -x / -type d -xattrname com.apple.rootless -print 2>/dev/null | /usr/bin/grep -v -E "^/System/Volumes/Data" > ${rootlessTemp};
while read fileName; do
	ownership=$(/usr/bin/stat -f "%u:%g" "${fileName}");
	permissions=$(/usr/bin/stat -f "%p" "${fileName}");
	/usr/bin/printf '%s\t%s\t%s\n' "${fileName}" "${ownership}" "${permissions}" >> ${baselineFiles}_${sheet}.csv;
done < ${rootlessTemp}
/bin/rm ${rootlessTemp};

# Services

# Get Removable Services
sheet="removable_services";
removableServicesTemp=$(/usr/bin/mktemp);
/bin/echo "Removable Services" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/defaults read /System/Library/Sandbox/com.apple.xpc.launchd.rootless.plist RemovableServices | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.|keys[]' | /usr/bin/sort > "${removableServicesTemp}";
/usr/bin/printf '%s\t%s\n' "Removeable Service" "Status" >> ${baselineFiles}_${sheet}.csv;
while read removableService; do
	serviceStatus=$(/usr/bin/defaults read /System/Library/Sandbox/com.apple.xpc.launchd.rootless.plist RemovableServices | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r --arg service "$removableService" '.[$service]');
	/usr/bin/printf '%s\t%s\n' "${removableService}" "${serviceStatus}" >> ${baselineFiles}_${sheet}.csv;
done < "${removableServicesTemp}"
/bin/rm -f "${removableServicesTemp}";

# Get Background Task Management com.apple.backgroundtaskmanagement
sheet="btm";
/bin/echo "Background Task Management" >> ${baselineFiles}_${sheet}.csv;
btmTemp=$(/usr/bin/mktemp);
uuidTemp=$(/usr/bin/mktemp);
nameTemp=$(/usr/bin/mktemp);
developerNameTemp=$(/usr/bin/mktemp);
typeTemp=$(/usr/bin/mktemp);
flagTemp=$(/usr/bin/mktemp);
dispositionTemp=$(/usr/bin/mktemp);
identifierTemp=$(/usr/bin/mktemp);
urlTemp=$(/usr/bin/mktemp);
/usr/bin/sfltool dumpbtm > "${btmTemp}";

/usr/bin/awk -F ": " '/UUID: / { print $NF }' "${btmTemp}" > "${uuidTemp}";
declare -a uuids=( "${(f)mapfile[${uuidTemp}]}" );
/usr/bin/awk -F ": " '/  Name: / { print $NF }' "${btmTemp}" > "${nameTemp}";
declare -a names=( "${(f)mapfile[${nameTemp}]}" );
/usr/bin/awk -F ": " '/Developer Name: / { print $NF }' "${btmTemp}" > "${developerNameTemp}";
declare -a developerNames=( "${(f)mapfile[${developerNameTemp}]}" );
/usr/bin/awk -F ": " '/Type: / { print $NF }' "${btmTemp}" > "${typeTemp}";
declare -a types=( "${(f)mapfile[${typeTemp}]}" );
/usr/bin/awk -F ": " '/Flags: / { print $NF }' "${btmTemp}" > "${flagTemp}";
declare -a flags=( "${(f)mapfile[${flagTemp}]}" );
/usr/bin/awk -F ": " '/Disposition: / { print $NF }' "${btmTemp}" > "${dispositionTemp}";
declare -a disposition=( "${(f)mapfile[${dispositionTemp}]}" );
/usr/bin/awk -F ": " '/  Identifier: / { print $NF }' "${btmTemp}" > "${identifierTemp}";
declare -a identifier=( "${(f)mapfile[${identifierTemp}]}" );
/usr/bin/awk -F ": " '/URL: / { print $NF }' "${btmTemp}" > "${urlTemp}]}";
declare -a url=( "${(f)mapfile[${urlTemp}]}" );
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "UUID" "Name" "Developer Name" "Type" "Flags" "Disposition" "Identifier" "URL" >> ${baselineFiles}_${sheet}.csv;
ctr=1
while [ "${ctr}" -le "${#uuids[@]}" ]; do
	/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${uuids[$ctr]}" "${names[$ctr]}" "${developerNames[$ctr]}" "${flags[$ctr]}" "${disposition[$ctr]}" "${identifier[$ctr]}" "${url[$ctr]}" >> ${baselineFiles}_${sheet}.csv;
	((ctr++));
done
# MDM Payloads
declare -a mdmPayloads=($(/usr/bin/awk '/MDM Payload UUIDs:/,0' "${btmTemp}" | /usr/bin/awk -v IGNORECASE=1 '$0 ~ /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/ { print $NF }'));
if [ "${#mdmPayloads[@]}" -gt 0 ]; then
	/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "UUID" "Display Name" "Organization" "Type" "Identifier" >> ${baselineFiles}_${sheet}.csv;
fi
mdmCtr=1;
while [ "${mdmCtr}" -le "${#mdmPayloads[@]}" ]; do
	mdmProfilesTemp=$(/usr/bin/mktemp);
	/usr/bin/profiles -C -o stdout-xml | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r --arg uuid "${mdmPayloads[$mdmCtr]}" '._computerlevel[] | select(any(.ProfileItems[]; .PayloadUUID == $uuid))' > "${mdmProfilesTemp}";
	payloadDisplayName=$(/usr/bin/jq -r '.ProfileItems[]|.PayloadDisplayName' "${mdmProfilesTemp}");
	payloadOrganization=$(/usr/bin/jq -r '.ProfileItems[]|.PayloadOrganization' "${mdmProfilesTemp}");
	payloadType=$(/usr/bin/jq -r '.ProfileItems[]|.PayloadType' "${mdmProfilesTemp}");
	payloadIdentifier=$(/usr/bin/jq -r '.ProfileItems[]|.PayloadIdentifier' "${mdmProfilesTemp}");
	/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "${mdmPayloads[$mdmCtr]}" "${payloadDisplayName}" "${payloadOrganization}" "${payloadType}" "${payloadIdentifier}" >> ${baselineFiles}_${sheet}.csv;
	((mdmCtr++));
	/bin/rm -f "${mdmProfilesTemp}";
done
/bin/rm -f "${btmTemp}" "${uuidTemp}" "${nameTemp}" "${developerNameTemp}" "${flagTemp}" "${dispositionTemp}" "${identifierTemp}" "${urlTemp}" "${mdmProfilesTemp}";

# Get Kernel Extensions
sheet="kext";
/bin/echo "Kernel Extensions" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/kmutil showloaded --show all -V kasan | /usr/bin/sed 's/^[[:blank:]]*//' | /usr/bin/sed 's/no UUID/NULL/g' | /usr/bin/awk -F '[<>]' '{ gsub(" ","_",$2); print $1"<"$2">" }' | /usr/bin/awk -v OFS='\t' '{$1=$1}1' >> ${baselineFiles}_${sheet}.csv;

# Get System Extensions
sheet="sysext";
/bin/echo "System Extensions" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "Extension Type" "Team ID" "BundleID" "Version" "Name" >> ${baselineFiles}_${sheet}.csv;
extensionsTemp=$(/usr/bin/mktemp);
/usr/bin/systemextensionsctl list >> "${extensionsTemp}";
while read data; do
	if [[ "${data}" =~ '^[0-9]' ]]; then
		continue;
	elif [[ "${data}" =~ '(version)' ]]; then
		continue;
	elif [[ "${data}" =~ '^---' ]]; then
		extensionType=$(/bin/echo "${data}" | /usr/bin/awk '{ print $2 }');
		continue;
	else
		/bin/echo "$data" | /usr/bin/awk -v type="${extensionType}" '{ printf("%s\t%s\t%s\t%s\t%s\n", type, $3, $4, $5, $6) }' >> ${baselineFiles}_${sheet}.csv;
	fi
done < "${extensionsTemp}"
/bin/rm -f "${extensionsTemp}";

# Get Running Launchd items
/bin/launchctl list | /usr/bin/grep '^[0-9]' | /usr/bin/awk '{ print $NF }' | /usr/bin/grep -v 0x

# Get Disabled Launchd Service
sheet="disableservices";
/bin/echo "Disabled Launchd Service" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Service" "State" >> ${baselineFiles}_${sheet}.csv;
/bin/launchctl print-disabled system | /usr/bin/sed 's/^\t.//' | /usr/bin/awk '/ => / { gsub("\042",""); printf("%s\t%s\n", $1, $NF) }' >> ${baselineFiles}_${sheet}.csv;

# Network

# Get Socket Listeners
sheet="socketlisteners";
/bin/echo "Socket Listeners" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "Service" "Service Name" "LaunchDaemon" >> ${baselineFiles}_${sheet}.csv;
listenersTemp=$(/usr/bin/mktemp -t tmp);
/bin/ls -1 /System/Library/LaunchDaemons/ > ${listenersTemp};
while read launchDaemon; do
	serviceName=$(/usr/libexec/PlistBuddy -c "Print Sockets:Listeners:SockServiceName" /System/Library/LaunchDaemons/${launchDaemon} 2>/dev/null | /usr/bin/grep / | /usr/bin/sed 's/^ *//');
	if [ -n "$serviceName" ]; then
		launchDaemonName=$(/usr/bin/basename -s .plist ${launchDaemon} | /usr/bin/awk -F "." '{ print $NF }');
		service=$(/usr/libexec/PlistBuddy -c "Print ProgramArguments" /System/Library/LaunchDaemons/${launchDaemon} | /usr/bin/grep / | /usr/bin/sed 's/^ *//');
		/usr/bin/printf '%s\t%s\t%s\n' "${service}" "${serviceName}" "${launchDaemonName}" >> ${baselineFiles}_${sheet}.csv;
	fi
done < ${listenersTemp}
/bin/rm "${listenersTemp}";

# Get Open Ports
sheet="openports";
/bin/echo "Open Ports" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\n' "Protocol" "Sent" "Received" "Local Address" "Foreign Address" "State" >> ${baselineFiles}_${sheet}.csv;
/usr/sbin/netstat -an | /usr/bin/egrep "LISTEN|ESTABLISHED" | /usr/bin/awk -v OFS='\t' '{$1=$1}1' >> ${baselineFiles}_${sheet}.csv;

# Get Hostinfo
sheet="hostinfo";
/bin/echo "Hostinfo" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Service" "Port" >> ${baselineFiles}_${sheet}.csv;
/bin/launchctl hostinfo | /usr/bin/sed -e 's/ port//g' -e 's/ unknown//g' | /usr/bin/awk '{ gsub(" = ","\t"); print $0 }' >> ${baselineFiles}_${sheet}.csv;

# Get Network Services
sheet="services";
/bin/echo "Network Services" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "Name" "Protocol" "Port" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/grep -Ev '^#' /private/etc/services | /usr/bin/awk '{ gsub("/"," "); printf "%s\t%s\t%s\n", $1, $3, $2 }' >> ${baselineFiles}_${sheet}.csv;

# Security

# Get PAM Configuration
sheet="PAM";
/bin/echo "Pluggable Authentication Modules" >> ${baselineFiles}_${sheet}.csv;
for MODULE in $(/bin/ls -1 /etc/pam.d); do
/bin/echo ${MODULE} >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\n' "Function Class" "Control Flags" "Module Arguments" >> ${baselineFiles}_${sheet}.csv;
/bin/cat /etc/pam.d/${MODULE} | /usr/bin/awk 'gsub("  +","\t")' >> ${baselineFiles}_${sheet}.csv;
/bin/cat "" >> ${baselineFiles}_${sheet}.csv;
done

# Get System Integrity Protection
sheet="sip";
bin/echo "System Integrity Protection" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Protected items" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\n' "Note" "Path";
/bin/cat /System/Library/Sandbox/rootless.conf | /usr/bin/awk 'sub("\t+","\t")' >> ${baselineFiles}_${sheet}.csv;
/bin/echo "" >> ${baselineFiles}_${sheet}.csv;

sheet="exceptions";
/bin/echo "Hardening Exceptions" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/defaults read /System/Library/Security/HardeningExceptions.plist | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.|keys[]' >> ${baselineFiles}_${sheet}.csv;

# Get Endpoint Security Events
sheet="endpointsecurity";
/bin/echo "Endpoint Security Events" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "Event" "Constant" "Category" "Introduced In" "Description" >> ${baselineFiles}_${sheet}.csv;
for event in $(/usr/bin/eslogger --list-events); do
	constant=$(/bin/echo "ES_EVENT_TYPE_NOTIFY_${event}" | /usr/bin/tr "[:lower:]" "[:upper:]");
	/usr/bin/sqlite3 "${workingDir}/reference_data.db" "SELECT \"${event}\", constant, category, introduced, description FROM endpoint_security WHERE constant = \"${constant}\";" | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;
done
/usr/bin/eslogger --list-events >> ${baselineFiles}_${sheet}.csv;

# Get BSM Audit Configuration
sheet="bsm";
/bin/echo "BSM Audit Configuration" >> ${baselineFiles}_${sheet}.csv;
if [ -f /etc/security/audit_control ]; then
	/bin/cat /etc/security/audit_control | /usr/bin/grep -v '^#' | /usr/bin/tr "\072" "\011" >> ${baselineFiles}_${sheet}.csv;
else
	/bin/cat /etc/security/audit_control.example | /usr/bin/grep -v '^#' | /usr/bin/tr "\072" "\011" >> ${baselineFiles}_${sheet}.csv;
fi

/bin/cat /etc/security/audit_control | /usr/bin/grep -v '^#' | /usr/bin/tr "\072" "\011"

# Get File Download Assessment
sheet="fda";
/bin/echo "File Download Assessment" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Safe File Types">> ${baselineFiles}_${sheet}.csv;
/usr/libexec/PlistBuddy -c "Print LSRiskCategorySafe:LSRiskCategoryContentTypes" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { printf "\t%s\n", $NF }' >> ${baselineFiles}_${sheet}.csv;
/bin/echo "" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Safe File Extensions" >> ${baselineFiles}_${sheet}.csv;
/usr/libexec/PlistBuddy -c "Print LSRiskCategorySafe:LSRiskCategoryExtensions" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { printf "\t%s\n", $NF }' >> ${baselineFiles}_${sheet}.csv;
/bin/echo "" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Potentially Unsafe File Types">> ${baselineFiles}_${sheet}.csv;
/usr/libexec/PlistBuddy -c "Print LSRiskCategoryMayContainUnsafeExecutable:LSRiskCategoryContentTypes" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { printf "\t%s\n", $NF }' >> ${baselineFiles}_${sheet}.csv;
/bin/echo "" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Potentially Unsafe File Extensions" >> ${baselineFiles}_${sheet}.csv;
/usr/libexec/PlistBuddy -c "Print LSRiskCategoryMayContainUnsafeExecutable:LSRiskCategoryExtensions" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { printf "\t%s\n", $NF }' >> ${baselineFiles}_${sheet}.csv;
/bin/echo "" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Unsafe File Types" >> ${baselineFiles}_${sheet}.csv;
/usr/libexec/PlistBuddy -c "Print LSRiskCategoryUnsafeExecutable:LSRiskCategoryContentTypes" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { printf "\t%s\n", $NF }' >> ${baselineFiles}_${sheet}.csv;
/bin/echo "" >> ${baselineFiles}_${sheet}.csv;
/bin/echo "Unsafe File Extensions" >> ${baselineFiles}_${sheet}.csv;
/usr/libexec/PlistBuddy -c "Print LSRiskCategoryUnsafeExecutable:LSRiskCategoryExtensions" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { printf "\t%s\n", $NF }' >> ${baselineFiles}_${sheet}.csv;

# Get Transparency Consent and Control Services
sheet="tcc";
/bin/echo "Transparency Consent and Control Services "  >> ${baselineFiles}_${sheet}.csv;
"${workingDir}/strings" /System/Library/PrivateFrameworks/TCC.framework/Support/tccd| /usr/bin/grep -iEo "^kTCCService.*" | /usr/bin/sort  >> ${baselineFiles}_${sheet}.csv;

# OpenSSH settings
sheet="openssh";
/bin/echo "OpenSSH" >> ${baselineFiles}_${sheet}.csv;
opensshVersion=$(/usr/sbin/sshd -V);
protocolVersion=$(/usr/bin/ssh -Q protocol-version);
/bin/echo "Supported Symmetric Ciphers:" >> ${baselineFiles}_${sheet}.csv;
for cipher in $(/usr/bin/ssh -Q cipher | /usr/bin/sort); do /usr/bin/printf '\t%s\n' ${cipher} >> ${baselineFiles}_${sheet}.csv; done
/bin/echo "Supported Message Integrity Codes:" >> ${baselineFiles}_${sheet}.csv;
for mac in $(/usr/bin/ssh -Q mac | /usr/bin/sort); do /usr/bin/printf '\t%s\n' ${mac} >> ${baselineFiles}_${sheet}.csv; done
/bin/echo "Supported Key Exchange Algorithms:" >> ${baselineFiles}_${sheet}.csv;
for kex in $(/usr/bin/ssh -Q kex | /usr/bin/sort); do /usr/bin/printf '\t%s\n' ${kex} >> ${baselineFiles}_${sheet}.csv; done
/bin/echo "Supported Key Algorithms:" >> ${baselineFiles}_${sheet}.csv;
for keyAlgorithm in $(/usr/bin/ssh -Q key | /usr/bin/sort); do /usr/bin/printf '\t%s\n' ${keyAlgorithm} >> ${baselineFiles}_${sheet}.csv; done
/bin/echo "Supported Signature Algorithms:" >> ${baselineFiles}_${sheet}.csv;
for signatureAlgorithm in $(/usr/bin/ssh -Q sig | /usr/bin/sort); do /usr/bin/printf '\t%s\n' ${signatureAlgorithm} >> ${baselineFiles}_${sheet}.csv; done
/bin/echo "SSH Configuration" >> ${baselineFiles}_${sheet}.csv;
/usr/sbin/sshd -G | /usr/bin/sort | /usr/bin/awk 'sub(" ", "\t")' >> ${baselineFiles}_${sheet}.csv;

# Get sudo settings
sheet="sudo";
/bin/echo "Sudo Configuration" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sudo -l | /usr/bin/sed "s/  +//g" | /usr/bin/tr "\054" "\012" | /usr/bin/awk '{$1=$1;print}' | /usr/bin/grep -Ev '^Matching|^User' >> ${baselineFiles}_${sheet}.csv;

# Get System Roots
sheet="system_roots";
certificatesTempDir=$(/usr/bin/mktemp -d);
/bin/echo "System Roots" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/security export -k /System/Library/Keychains/SystemRootCertificates.keychain -o "${certificatesTempDir}/SystemRoots.pem";
pushd "${certificatesTempDir}"
/usr/bin/split -p "-----BEGIN CERTIFICATE-----" "${certificatesTempDir}/SystemRoots.pem" systemrootca-
/bin/rm "${certificatesTempDir}/SystemRoots.pem";
certTemp=$(/usr/bin/mktemp);
/bin/ls -1 "${certificatesTempDir}" > "${certTemp}";
popd;
/usr/bin/printf '%s\t%s\t%s\t%s\n' "Common Name" "Signature Algorithm" "Key Length" "Expiration Date" >> ${baselineFiles}_${sheet}.csv;
while read certificateFile; do
	certificateName=$(/usr/bin/openssl x509 -in "${certificatesTempDir}/${certificateFile}" -subject -noout | /usr/bin/tr "\057" "\012" | /usr/bin/awk -F '=' '/CN=/ { print $NF }' | /usr/bin/uniq);
	if [ -z "${certificateName}" ]; then
		certificateName=$(/usr/bin/openssl x509 -in "${certificatesTempDir}/${certificateFile}" -subject -noout | /usr/bin/tr "\057" "\012" | /usr/bin/awk -F '=' '/OU=/ { print $NF }' | /usr/bin/uniq);
	fi
	certificateSignatureAlgorithm=$(/usr/bin/openssl x509 -in "${certificatesTempDir}/${certificateFile}" -text -noout | /usr/bin/awk '/Signature Algorithm:/ { o=$NF } END{ print o }');
	keyLength=$(/usr/bin/openssl x509 -in "${certificatesTempDir}/${certificateFile}" -text -noout | /usr/bin/awk -F "[()]" '/Public-Key:/ { print $(NF-1) }');
	expiration=$(/usr/bin/openssl x509 -in "${certificatesTempDir}/${certificateFile}" -enddate -noout | /usr/bin/awk -F "=" '/notAfter/ { print $2 }');
	/usr/bin/printf '%s\t%s\t%s\t%s\n'  "${certificateName}" "${certificateSignatureAlgorithm}" "${keyLength}" "${expiration}" >> ${baselineFiles}_${sheet}.csv;
done < "${certTemp}"
/bin/rm -rf "${certTemp}" "${certificatesTempDir}";

# Get Privacy Settings
sheet="tcc_status";
/bin/echo "Transparency, Consent, and Control" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\n' "Service" "Description" "macOS Support" "Interface" >> ${baselineFiles}_${sheet}.csv;
for service in $(/Volumes/Baseline/strings /System/Library/PrivateFrameworks/TCC.framework/Support/tccd | /usr/bin/grep -iEo "^kTCCService.*" | /usr/bin/sed 's/kTCCService//' | /usr/bin/grep -v "All" | /usr/bin/sort -u | /usr/bin/tr "\012" "\040"); do
	declare -a applicationBundleIDs=("${(f)$(/usr/bin/tccutil list -s ${service} 2>/dev/null | /usr/bin/sort)}");
	if [ "${#applicationBundleIDs[@]}"-gt 1 ]; then
		/bin/echo "Applications granted ${service}" >> ${baselineFiles}_${sheet}.csv;
		for applicationBundleID in "${applicationBundleIDs[@]}"; do
			/usr/bin/printf '\t%s\n' "${applicationBundleID}" >> ${baselineFiles}_${sheet}.csv;
		done
	fi
done

# Executables
sheet="bin";
/bin/echo "/bin" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "filepath" "mode" "fileowner" "filegroup" "cksum" "installdate" "type" "version" "manpage" "source" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db "SELECT * FROM executables WHERE filepath LIKE '/bin%' ORDER BY filepath;" | /usr/bin/tr "\174" "\011"  >> ${baselineFiles}_${sheet}.csv;

sheet="sbin";
/bin/echo "/sbin" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "filepath" "mode" "fileowner" "filegroup" "cksum" "installdate" "type" "version" "manpage" "source" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db "SELECT * FROM executables WHERE filepath LIKE '/sbin%' ORDER BY filepath;" | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;

sheet="usrbin";
/bin/echo "/usr/bin" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "filepath" "mode" "fileowner" "filegroup" "cksum" "installdate" "type" "version" "manpage" "source" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db "SELECT * FROM executables WHERE filepath LIKE '/usr/bin%' ORDER BY filepath;" | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;

sheet="usrsbin";
/bin/echo "/usr/sbin" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "filepath" "mode" "fileowner" "filegroup" "cksum" "installdate" "type" "version" "manpage" "source" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db "SELECT * FROM executables WHERE filepath LIKE '/usr/sbin%' ORDER BY filepath;" | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;

sheet="usrlibexec";
/bin/echo "/usr/libexec" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "filepath" "mode" "fileowner" "filegroup" "cksum" "installdate" "type" "version" "manpage" "source" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db "SELECT * FROM executables WHERE filepath LIKE '/usr/libexec%' ORDER BY filepath;" | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;

# Authorization Services
sheet="authorizationservices";
/bin/echo "Authorization Services"  >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "type" "name" "allow-root" "authenticate-user" "class" "comment" "created" "default-button" "default-prompt" "entitled" "entitled-group" "extract-password" "group" "identifier" "k-of-n" "mechanisms" "modified" "password-only" "require-apple-signed" "requirement" "rule" "session-owner" "shared" "timeout" "tries" "version" "vpn-entitled-group" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db "SELECT type, name, [allow-root], [authenticate-user], class, comment, created, [default-button], [default-prompt], entitled, [entitled-group], [extract-password], [group], identifier, [k-of-n], mechanisms, modified, [password-only], [require-apple-signed], requirement, rule, [session-owner], shared, timeout, tries, version, [vpn-entitled-group]  FROM authorization ORDER BY type, name;" | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;

# Application Firewall
sheet="alf";
/bin/echo "Application Firewall"  >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\n' "Application" "Alias" "BundleIdentifier" "State" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db 'SELECT * FROM alf' | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;

# Critical Files
sheet="critical";
/bin/echo "Critical Files"  >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "Path" "Permissions" "Owner" "Group" "Hash" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db 'SELECT * FROM criticalfiles' | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;

# Set User ID on Execute
sheet="suid";
/bin/echo "Set User ID on Execute"  >> ${baselineFiles}_${sheet}.csv;
/usr/bin/printf '%s\t%s\t%s\t%s\t%s\n' "File" "Hash" "Owner" "Description" >> ${baselineFiles}_${sheet}.csv;
/usr/bin/sqlite3 /Volumes/Baseline/security.db 'SELECT * FROM suid' | /usr/bin/tr "\174" "\011" >> ${baselineFiles}_${sheet}.csv;

exit 0;