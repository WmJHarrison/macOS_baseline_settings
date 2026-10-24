#!/bin/sh
# macOS Deep Inspection
# Copyright 2013-2025 William Harrison
# Version @(#)11.0.12 [2026-10-17]
# William Harrison

export LC_ALL=C;

bittest() {
	LIST_TMP="$1";
	TYPE=$2;
	shift;
	shift;
	EXCLUDE=($@);
	case ${TYPE} in
		suid) ID="user"; ID_COMMAND='/bin/echo $st_uid' ;;
		sgid) ID="group"; ID_COMMAND='/bin/echo $st_gid' ;;
	esac
	while read THIS_FILE; do
		if [ -e "${THIS_FILE}" ]; then
			if [[ "${EXCLUDE[@]}" =~ "$THIS_FILE" ]]; then
				continue;
			else
				eval $(/usr/bin/stat -s "${THIS_FILE}");
				ID_VALUE=$(eval ${ID_COMMAND});
				CHK=$(/usr/bin/shasum -a 256 ${THIS_FILE} 2>/dev/null | /usr/bin/awk '{ print $1 }');
				reason=$(/usr/bin/whatis "$(/usr/bin/basename ${THIS_FILE})" 2>&1 | /usr/bin/grep -v "nothing appropriate" | /usr/bin/awk  -F " - " -v command="$(/usr/bin/basename ${THIS_FILE})" '$0 ~ "^" command { print $NF; exit }')
				/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT OR REPLACE INTO ${TYPE} ('file','chk',\"${ID}\",'reason') VALUES (\"${THIS_FILE}\",\"${CHK}\",\"${ID_VALUE}\",\"${reason}\");";
			fi
		fi
	done < "${LIST_TMP}"
}

typeFromSheBang() {
	INTERPRETER=$(/usr/bin/head -n 1 "${FILE_PATH}" | /usr/bin/awk -F " -" '/^#!/ { print $1 }' | /usr/bin/sed 's/#!//');
	case $INTERPRETER in
		/bin/bash) UTI="public.bash-script" ;;
		/bin/csh) UTI="public.csh-script" ;;
		/bin/dash) UTI="public.dash-script" ;;
		/bin/ksh) UTI="public.ksh-script" ;;
		/bin/sh) UTI="public.shell-script" ;;
		/bin/tcsh) UTI="public.tcsh-script" ;;
		/bin/zsh) UTI="public.zsh-script" ;;
		/usr/bin/perl) UTI="public.perl-script" ;;
		/usr/bin/php) UTI="public.php-script" ;;
		/usr/bin/python) UTI="public.python-script" ;;
		/usr/bin/ruby) UTI="public.ruby-script" ;;
		"/usr/bin/env nickle") UTI="public.nickle-script" ;;
		"/usr/bin/env xcrun swift") UTI="public.swift-script" ;;
		*) UTI="unknown" ;;
	esac
}

typeFromSuffix() {
	SUFFIX=$(/bin/echo "${FILE_PATH}" | /usr/bin/awk -F "." '{ print "."$NF }');
	case "$SUFFIX" in
		".applescript") UTI="com.apple.applescript.text" ;; # RxT
		".awk") UTI="public.awk-script" ;; # rxT
		".bash") UTI="public.bash-script" ;; # RXT
		".bat") UTI="com.microsoft.dos.bat" ;; # rxT
		".ccl") UTI="public.source-code" ;; # RxT #Connection Control Language
		".classdescription") UTI="public.source-code" ;; # RxT
		".codes") UTI="public.source-code" ;; # RxT
		".command"|".tool") UTI="com.apple.terminal.shell-script" ;; # RXT
		".conf"|".config"|".dist") FILE_INFO=$(/usr/bin/file "${FILE_PATH}" | /usr/bin/awk -F ":[ \t]" '{ print $NF }');
				case $FILE_INFO in
					"ASCII c program text") UTI="public.source-code" ;; # RxT
					"ASCII C++ program text") UTI="public.source-code" ;; # RxT
					"ASCII "*"text"*|"UTF-8 Unicode"*) UTI="public.plain-text" ;; # RxT
					"Lisp/Scheme program text") UTI="public.source-code" ;; # RxT
					"POSIX shell script text executable") UTI="public.shell-script" ;; # RXT
					"Apple binary property list") UTI="com.apple.binary-property-list" ;; # Rxt
					"XML document text") UTI="public.xml" ;; # Rxt
					*) UTI="unknown" ;;
				esac
				;;
		".d") UTI="public.dtrace-script" ;; # RXT
		".ddx") UTI="com.apple.xml-property-list" ;; # RxT
		".dict") UTI="public.data" ;; # Rxt
		".dll") UTI="com.microsoft.windows-dynamic-link-library" ;; # RxT
		".groovy") UTI="public.groovy-script" ;; # RXT
		".hook") UTI="public.shell-script" ;; # RXT
		".jar") UTI="com.sun.java-archive" ;; # RxT
		".jnlp") UTI="com.sun.java-web-start" ;; # RxT
		".js") UTI="com.netscape.javascript-source" ;; # RxT
		".keylayout") UTI="public.xml" ;; # RxT
		".manifest") UTI="public.xml" ;; # RxT
		".moduleLayout") UTI="public.xml" ;; # RxT
		".mp3") UTI="public.mp3" ;; # Rxt
		".pblangspec") UTI="public.utf8-plain-text " ;; # RxT
		".phar") UTI="public.php-script" ;; # rxT
		".php") UTI="public.php-script" ;; # rxT
		".pl") UTI="public.perl-script" ;; # RXT
		".pm") UTI="public.perl-script" ;; # RXT
		".png") UTI="public.png" ;; # Rxt
		".pod") UTI="" ;; # rxt
		".py") UTI="public.python-script" ;; # rxT
		".pyc") UTI="public.python-script" ;; # rxT # Python compiled script
		".pyo") UTI="public.python-script" ;; # rxT # Python optimized script
		".pyw") UTI="public.source-code" ;; # rxT # Python window file
		".qtz") UTI="com.apple.quartz-composer-composition" ;; # RxT
		".ru") UTI="public.ruby-rails-config" ;; # rxt # Rails configuration
		".scpt") UTI="com.apple.applescript.script" ;; # RxT
		".scriptSuite") UTI="com.apple.applescript.scriptsuite" ;; # rxt
		".scriptTerminology") UTI="com.apple.xml-property-list" ;; # Rxt
		".searchTerms") UTI="com.apple.xml-property-list" ;; # Rxt
		".sed") UTI="public.source-code" ;; # RxT
		".sh") UTI="public.shell-script" ;; # RXT
		".shook") UTI="public.shell-script" ;; # RXT
		".sis") UTI="" ;; # rxt # Symbian installation file
		".sl") UTI="" ;; # rxT # PA-RISC2.0 shared library (HP-UNIX)
		".slideSaver") UTI="com.apple.systempreference.screen-saver" ;; # rxt
		".so") UTI="public.shared-library" ;;
		".srz") UTI="public.plain-text" ;; #Rxt
		".swift") UTI="public.swift-script" ;;
		".xotcl") UTI="public.script" ;; # RxT # Extended Object TCL
		".yp") UTI="public.source-code" ;; # RxT
		*) typeFromSheBang ;;
	esac
	# R = , r =
	# X = execute bit set, x = execute bit not required
	# T = track file , t = file not tracked 
}

getLibInfo() {
	EXECUTABLE_PATH=$1;
	ARCHITECTURES=$(/usr/bin/file "${EXECUTABLE_PATH}" | /usr/bin/awk '/for architecture/ { print $NF }' | /usr/bin/tr "\012" "\40");
	if [ -z "$ARCHITECTURES" ]; then
		# single architecture
		ARCHITECTURES=$(/usr/bin/file "${EXECUTABLE_PATH}" | /usr/bin/awk '{ print $NF }');
	fi
	for ARCH in ${ARCHITECTURES}; do
		LINKEDLIBS=$(/usr/bin/mktemp -t tmp);
		/Volumes/Source/otool -arch ${ARCH} -L "${EXECUTABLE_PATH}" | /usr/bin/grep -v '^/' | /usr/bin/awk -F "(" '{ print $1 }' | /usr/bin/tr -d "\011" > "${LINKEDLIBS}";
		if [ -s "$LINKEDLIBS" ]; then
			while read LIB_INFO; do
				if [ "$LIB_INFO" = "$EXECUTABLE_PATH" ]; then
					continue;
				else
					LIBNAME=$(/usr/bin/basename "${LIB_INFO}");
					LIBVERSION=$(/Volumes/Source/otool -arch ${ARCH} -L "${EXECUTABLE_PATH}" | /usr/bin/grep -v ^/ | /usr/bin/grep -a "${LIB_INFO}" | /usr/bin/awk -F "version " '{ print $3 }' | /usr/bin/tr -d "\051");
					if [[ "$LIB_INFO" =~ '@executable_path/..' ]]; then
						REAL_PATH=$(/usr/bin/dirname "$(/usr/bin/dirname "${EXECUTABLE_PATH}")");
						LIB_INFO=$(/bin/echo "${LIB_INFO}" | /usr/bin/sed "s|@executable_path/..|${REAL_PATH}|");
					fi
					if [ -n "${LIBNAME}" ] && [ -n "${LIBVERSION}" ]; then
						/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT OR REPLACE INTO libusage VALUES ('${EXECUTABLE_PATH}','${LIB_INFO}','${LIBNAME}','${LIBVERSION}','${ARCH}')";
					fi
				fi
			done < "${LINKEDLIBS}"
		fi
		/bin/rm "${LINKEDLIBS}";
	done
}

pushParentPerm() {
	PARENT_PERM_ARRAY=( "${PARENT_PERM_ARRAY[@]}" "$1" ); # top = ${PARENT_PERM_ARRAY[${#PARENT_PERM_ARRAY[@]}-1]}
}

pushParentOwner() {
	PARENT_OWNER_ARRAY=( "${PARENT_OWNER_ARRAY[@]}" "$1" ); # top = ${PARENT_OWNER_ARRAY[${#PARENT_OWNER_ARRAY[@]}-1]}
}

pushParentGroup() {
	PARENT_GROUP_ARRAY=( "${PARENT_GROUP_ARRAY[@]}" "$1" ); # top = ${PARENT_GROUP_ARRAY[${#PARENT_GROUP_ARRAY[@]}-1]}
}

popParentPerm() {
	unset PARENT_PERM[${#PARENT_PERM[@]}-1];
}

popParentOwner() {
	unset PARENT_OWNER[${#PARENT_OWNER[@]}-1];
}

popParentGroup() {
	unset PARENT_GROUP[${#PARENT_GROUP[@]}-1];
}

getObjectData() {
	FILE_SYSTEM_OBJECT=$1;
	if [ -e "${FILE_SYSTEM_OBJECT}" ]; then
		eval $(/usr/bin/stat -s "${FILE_SYSTEM_OBJECT}");
		MODE=$(/bin/echo $st_mode);
		OWNER=$(/bin/echo $st_uid);
		GROUP=$(/bin/echo $st_gid);
		FINDER_ATTRIBUTES=$(/Volumes/Source/GetFileInfo "${FILE_SYSTEM_OBJECT}" 2>/dev/null | /usr/bin/awk '/attributes/ { print $NF }');
		if [ "${FINDER_ATTRIBUTES}" = "avbstclinmedz" ]; then
			FINDER_ATTRIBUTES=""; # No flags set
		fi
		PARENT_DIR=$(/usr/bin/dirname "${FILE_SYSTEM_OBJECT}");
		FILESYS_OBJ=$(/usr/bin/basename "${FILE_SYSTEM_OBJECT}");
		ACL=$(/bin/ls -ale "${PARENT_DIR}" | /usr/bin/grep -A 1 "${FILESYS_OBJ}" | /usr/bin/awk -F ":" '/^ [0-9]+:/ { print $NF }' | /usr/bin/tr "\012" "\073");
	fi
}

processFileSystemObjects() {
	FILE_SYSTEM_OBJECTS=$1;
	while read FILE_SYSTEM_OBJECT; do
		getObjectData "${FILE_SYSTEM_OBJECT}";
		# Find subdirectories with different permissions
		ENTRY_TYPE=$(/bin/echo $st_mode | /usr/bin/rev | /usr/bin/cut -c 5);
		if [ "${ENTRY_TYPE}" -eq 4 ]; then
			/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT INTO filesystem VALUES ('${FILE_SYSTEM_OBJECT}','${MODE}','${OWNER}','${GROUP}','${FINDER_ATTRIBUTES}','${ACL}',NULL,NULL);";
			SUB_OBJECTS=$(/usr/bin/mktemp -t tmp);
			BASE_PERM=$(/bin/echo $st_mode | /usr/bin/cut -c 4-);
			/usr/bin/find "${FILE_SYSTEM_OBJECT}" -type d \! \( -perm ${BASE_PERM} -uid ${OWNER} -gid ${GROUP} \) 2>/dev/null > "${SUB_OBJECTS}";
			/usr/bin/find "${FILE_SYSTEM_OBJECT}" -type f \! \( -uid ${OWNER} -gid ${GROUP} \) 2>/dev/null > "${SUB_OBJECTS}";
			# Finder Flags
			FINDER_FLAGS=$(/usr/bin/mktemp -t tmp);
			/usr/bin/mdfind -onlyin "${FILE_SYSTEM_OBJECT}" "kMDItemFSInvisible == 1" > "${FINDER_FLAGS}"; # Find invisible Finder Flag
			/usr/bin/mdfind -onlyin "${FILE_SYSTEM_OBJECT}" "kMDItemFSIsExtensionHidden == 1" >> "${FINDER_FLAGS}"; # Find Hide Extension Flag
			/usr/bin/mdfind -onlyin "${FILE_SYSTEM_OBJECT}" "kMDItemFSHasCustomIcon == 1" >> "${FINDER_FLAGS}"; # Find Custom Icons
			/usr/bin/mdfind -onlyin "${FILE_SYSTEM_OBJECT}" "kMDItemFSIsStationery == 1" >> "${FINDER_FLAGS}"; # Find Custom Icons
			if [ -s "$SUB_OBJECTS" ] || [ -s "$FINDER_FLAGS" ]; then
				SUB_OBJECTS_COMBO=$(/usr/bin/mktemp -t tmp);
				/bin/cat "${FINDER_FLAGS}" "${SUB_OBJECTS}" | /usr/bin/sort -u > "${SUB_OBJECTS_COMBO}";
				pushParentPerm ${PERM};
				pushParentOwner ${OWNER};
				pushParentGroup ${GROUP};
				processFileSystemObjects "${SUB_OBJECTS}";
				popParentPerm;
				popParentOwner;
				popParentGroup;
				/bin/rm "${SUB_OBJECTS}" "${FINDER_FLAGS}" "${SUB_OBJECTS_COMBO}";
			else
				/bin/rm "${SUB_OBJECTS}" "${FINDER_FLAGS}";
			fi
		else
			# This is a file. Test for standard file attributes: owner:group = parent owner:group, No Finder Flags, No ACL
			if [ "$OWNER" -ne "${PARENT_OWNER_ARRAY[${#PARENT_OWNER_ARRAY[@]}-1]}" ] || [ "$GROUP" -ne "${PARENT_GROUP_ARRAY[${#PARENT_GROUP_ARRAY[@]}-1]}" ] || [ -n "$FINDER_ATTRIBUTES" ] || [ -n "$ACL" ]; then
				if [ "$OWNER" -ne 0 ] && ( [ "$BASE_PERM" != "0755" ] || [ "$BASE_PERM" != "0644" ] ); then
					/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT INTO filesystem  VALUES ('${FILE_SYSTEM_OBJECT}','$st_mode','$st_uid','$st_gid','${FINDER_ATTRIBUTES}','${ACL}',NULL,NULL);";
				fi
			fi
		fi
	done < "${FILE_SYSTEM_OBJECTS}"
}

getFileSystemObjects() {
	ROOT_OBJ=$1;
	FS_OBJS_TEMP=$(/usr/bin/mktemp -t tmp);
	eval $(/usr/bin/stat -s "${ROOT_OBJ}");
	pushParentPerm $(/bin/echo $st_mode | /usr/bin/cut -c 3-);
	pushParentOwner $(/bin/echo $st_uid);
	pushParentGroup $(/bin/echo $st_gid);
	/usr/bin/find -x "${ROOT_OBJ}" -type d -d 1 2>/dev/null > "${FS_OBJS_TEMP}"; # Find all subdirectories
	processFileSystemObjects "${FS_OBJS_TEMP}"
	/bin/rm "${FS_OBJS_TEMP}";
}

sectionBreakSP() {
	/bin/echo "" >> ${SYSTEM_PROFILE};
	/bin/echo "________________________________________________________________________________" >> ${SYSTEM_PROFILE};
}

sectionBreak() {
	/bin/echo "" >> ${baseSettingsFile};
	/bin/echo "________________________________________________________________________________" >> ${baseSettingsFile};
}

##### MAIN #####
scriptVolume=$(/usr/bin/dirname $0 | /usr/bin/sed 's|/Volumes/||');
externalMedia=$(/usr/sbin/diskutil list -plist external virtual | /usr/bin/plutil -convert json -r -o - -- - | /usr/bin/jq -r '.VolumesFromDisks[]'); # Note external media volume name to remount at the end of the script
for externalVolume in $externalMedia; do
if [ "${externalVolume}" != "${scriptVolume}" ]; then
	/usr/sbin/diskutil quiet unmount "/Volumes/${externalVolume}";
fi
done

productName=$(/usr/bin/sw_vers --productName);
productVersion=$(/usr/bin/sw_vers --productVersion);
buildVersion=$(/usr/bin/sw_vers --buildVersion);
iOSSupportVersion=$(/usr/bin/defaults read /System/Library/CoreServices/SystemVersion.plist iOSSupportVersion);
codeName=$(/usr/bin/awk '/SOFTWARE LICENSE AGREEMENT FOR macOS/' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' | /usr/bin/awk -F 'macOS ' '{print $NF}' | /usr/bin/awk '{print substr($0, 0, length($0)-1)}');
kernelVersion=$(/usr/bin/uname -a | /usr/bin/awk '{ print $3 }');
xnuVersion=$(/usr/bin/uname -a | /usr/bin/awk '{ print $14 }' | /usr/bin/awk -F "[-~]" '{ print $2 }');
cfNetworkVersion=$(/usr/bin/defaults read /System/Library/Frameworks/CFNetwork.framework/Versions/Current/Resources/version.plist CFBundleVersion);

SYSTEM_PROFILE="$PWD/$(/usr/bin/sw_vers -productVersion)_$(/usr/bin/sw_vers -buildVersion)_system_profile";

/bin/echo "________________________________________________________________________________" >> ${SYSTEM_PROFILE};
/bin/echo "Deep Inspection Report " >> ${SYSTEM_PROFILE};
/bin/echo "" >> ${SYSTEM_PROFILE};
/bin/echo "Generated: $(/bin/date "+%Y-%m-%d")" >> ${SYSTEM_PROFILE};
/bin/echo "" >> ${SYSTEM_PROFILE};
/bin/echo "${productName} ${codeName} ${buildVersion} Build: ${buildVersion}" >> ${SYSTEM_PROFILE};
/bin/echo "iOS Support: ${iOSSupportVersion}" >> ${SYSTEM_PROFILE};
/bin/echo "Kernel Version: ${kernelVersion}" >> ${SYSTEM_PROFILE};
/bin/echo "XNU Version: ${xnuVersion}" >> ${SYSTEM_PROFILE};
/bin/echo "CFNetwork Version: ${cfNetworkVersion}" >> ${SYSTEM_PROFILE};
/bin/echo "________________________________________________________________________________" >> ${SYSTEM_PROFILE};

# Get System Profiles

/bin/echo "" >> ${SYSTEM_PROFILE};
/bin/echo "System Profile:" >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPSoftwareDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPApplicationsDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPDeveloperToolsDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPExtensionsDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPFrameworksDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPPrefPaneDataType 2>/dev/null >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPStartupItemDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPManagedClientDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPFontsDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPPrintersDataType >> ${SYSTEM_PROFILE};
if [ $(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F "." '{ print $2 }') -eq 7 ]; then
	sectionBreakSP;
	/usr/sbin/system_profiler SPPrintersSoftwareDataType >> ${SYSTEM_PROFILE};
	sectionBreakSP;
	/usr/sbin/system_profiler SPComponentDataType >> ${SYSTEM_PROFILE};
	sectionBreakSP;
	/usr/sbin/system_profiler SPConfigurationProfileDataType >> ${SYSTEM_PROFILE};
fi
sectionBreakSP;
/usr/sbin/system_profiler -xml SPUniversalAccessDataType >> ${SYSTEM_PROFILE};
sectionBreakSP;
/usr/sbin/system_profiler -xml SPLogsDataType >> ${SYSTEM_PROFILE};

baseSettingsFile="$PWD/$(/usr/bin/sw_vers -productVersion)_$(/usr/bin/sw_vers -buildVersion)_base_settings";

/bin/echo "________________________________________________________________________________" >> ${baseSettingsFile};
/bin/echo "Deep Inspection Report " >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Generated: $(/bin/date "+%Y-%m-%d")" >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "${productName} ${codeName} ${buildVersion} Build: ${buildVersion}" >> ${baseSettingsFile};
/bin/echo "iOS Support: ${iOSSupportVersion}" >> ${baseSettingsFile};
/bin/echo "Kernel Version: ${kernelVersion}" >> ${baseSettingsFile};
/bin/echo "XNU Version: ${xnuVersion}" >> ${baseSettingsFile};
/bin/echo "CFNetwork Version: ${cfNetworkVersion}" >> ${baseSettingsFile};
/bin/echo "________________________________________________________________________________" >> ${baseSettingsFile};

/bin/echo "Supported Models:" >> ${baseSettingsFile};
/usr/bin/defaults read /System/Library/CoreServices/PlatformSupport.plist SupportedModelProperties | /usr/bin/awk -F "\042" '{ print $2 }' >> ${baseSettingsFile};
/bin/cat /Volumes/Source/SupportedModels >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Supported Board IDs:" >> ${baseSettingsFile};
/usr/bin/defaults read /System/Library/CoreServices/PlatformSupport.plist SupportedBoardIds | /usr/bin/awk -F "\042" '{ print $2 }' >> ${baseSettingsFile};

# Filesystem Information

sectionBreak;
/bin/echo "File System Directory Structure" >> ${baseSettingsFile};
/usr/bin/find -x / -type d -exec stat -f "%N%t%p%t%u:%g%t%f" {} \; 2>/dev/null | /usr/bin/sed -e 's;[^/]*/;|____;g;s;____|; |;g' | /usr/bin/grep -Ev '.lproj|.rftd|LC_MESSAGES|_CodeSignature|MacOS|Contents|Resources' >> ${baseSettingsFile};

# Get No User files
sectionBreak;
/bin/echo "Files with out owners" >> ${baseSettingsFile};
/usr/bin/find -x / -nouser -print 2>/dev/null | /usr/bin/grep -v "/Volumes/Source" >> ${baseSettingsFile};

# Get No Group files
sectionBreak;
/bin/echo "Files with out groups" >> ${baseSettingsFile};
/usr/bin/find -x / -nogroup -print 2>/dev/null | /usr/bin/grep -v "/Volumes/Source" >> ${baseSettingsFile};

# Get world writable directories
sectionBreak;
/bin/echo "Directories with 'Allow write by others'" >> ${baseSettingsFile};
/usr/bin/find -x / -type d -perm -002 -print 2>/dev/null | /usr/bin/grep -v -E "^/System/Volumes/Data" >> ${baseSettingsFile};

# Get Stickey Bit directories
sectionBreak;
/bin/echo "Directories with Sticky Bits" >> ${baseSettingsFile};
/usr/bin/find -x / -type d -perm -1000 -print 2>/dev/null | /usr/bin/grep -v -E "^/System/Volumes/Data" >> ${baseSettingsFile};

# Get rootless directories
sectionBreak;
/bin/echo "Directories with rootless" >> ${baseSettingsFile};
/usr/bin/find -x / -type d -xattrname com.apple.rootless -print 2>/dev/null | /usr/bin/grep -v -E "^/System/Volumes/Data" >> ${baseSettingsFile};

export PATH="$PATH:/Volumes/Source";
export TAB=$(/bin/echo "" | /usr/bin/tr "\012" "\011");

# System Services

# Kernel
sectionBreak;
/bin/echo "Kernel State" >> ${baseSettingsFile};
/usr/sbin/sysctl -A >> ${baseSettingsFile};

# Get Running Processes
sectionBreak;
/bin/echo "Running Processes" >> ${baseSettingsFile};
/bin/ps -axlww >> ${baseSettingsFile};

# Check Kext
sectionBreak;
/bin/echo "Kernel Extensions" >> ${baseSettingsFile};
/usr/bin/kmutil showloaded --show all -V kasan >> ${baseSettingsFile};

# Check System Extensions
sectionBreak;
/bin/echo "System Extensions" >> ${baseSettingsFile};
/usr/bin/systemextensionsctl list >> ${baseSettingsFile};

# Check Launchd
sectionBreak;
/bin/echo "Launch Items" >> ${baseSettingsFile};
for LAUNCH_DIR in /System/Library/LaunchAgents /System/Library/LaunchDaemons /Library/LaunchAgents /Library/LaunchDaemons; do
	/bin/echo "${LAUNCH_DIR}:" >> ${baseSettingsFile};
	for LAUNCH_ITEM in $(ls -1 ${LAUNCH_DIR}); do
		PROGRAM=$(/usr/bin/defaults read ${LAUNCH_DIR}/${LAUNCH_ITEM} Program 2>/dev/null);
		if [ -z "${PROGRAM}" ]; then
			PROGRAM=$(/usr/bin/defaults read ${LAUNCH_DIR}/${LAUNCH_ITEM} ProgramArguments 2>/dev/null | /usr/bin/awk -F "\042" '{ print $2 }' | /usr/bin/tr "\012" "\040" | /usr/bin/sed 's/ +/ /g');
		fi;
		DISABLED_TYPE=$(/usr/bin/defaults read-type ${LAUNCH_DIR}/${LAUNCH_ITEM} Disabled 2>/dev/null);
		if [ "${DISABLED_TYPE}" = "Type is boolean" ]; then
			DISABLED=$(/usr/bin/defaults read ${LAUNCH_DIR}/${LAUNCH_ITEM} Disabled 2>/dev/null);
			if [ -z "${DISABLED}" ]; then
				LABEL=$(/usr/bin/defaults read ${LAUNCH_DIR}/${LAUNCH_ITEM} Label 2>/dev/null);
				if [ -z "${LABEL}" ]; then continue; fi
				DISABLED=$(/usr/bin/defaults read /private/var/db/com.apple.xpc.launchd/disabled.plist ${LABEL} 2>/dev/null);
			fi
		else
			# Check Feature Flags
			DISABLED_DICT=$(/usr/bin/defaults read ${LAUNCH_DIR}/${LAUNCH_ITEM} Disabled 2>/dev/null | /usr/bin/tr -d "\043");
			FEATURE_FLAG_DOMAIN=$(/bin/echo "${DISABLED_DICT}" | /usr/bin/awk -F "\042" '/IfFeatureFlag/ { print $4 }' | /usr/bin/awk -F "/" '{ print $1".plist" }');
			FEATURE_FLAG_KEY=$(/bin/echo "${DISABLED_DICT}" | /usr/bin/awk -F "\042" '/IfFeatureFlag/ { print $4 }' | /usr/bin/awk -F "/" '{ print $2 }');
			FEATURE_FLAG_TYPE=$(/bin/echo "${DISABLED_DICT}" | /usr/bin/awk -F "\042" '/IfFeatureFlag/ { print $2 }');
			FEATURE_FLAG_STATUS=$(/usr/libexec/PlistBuddy -c "Print ${FEATURE_FLAG_KEY}:Enabled" /System/Library/FeatureFlags/Domain/${FEATURE_FLAG_DOMAIN} 2>/dev/null);
			FEATURE_FLAG_ELSE=$(/bin/echo "${DISABLED_DICT}" | /usr/bin/awk '/Else/ { gsub(";",""); print $NF }');
			FEATURE_FLAG_THEN=$(/bin/echo "${DISABLED_DICT}" | /usr/bin/awk '/Then/ { gsub(";",""); print $NF }');
			if [ "${FEATURE_FLAG_TYPE}" = "IfFeatureFlagEnabled" ]; then
				if [ "${FEATURE_FLAG_STATUS}" = "true" ]; then 
					DISABLED="${FEATURE_FLAG_THEN}";
				else
					DISABLED="${FEATURE_FLAG_ELSE}";
				fi
			elif [ "${FEATURE_FLAG_TYPE}" = "IfFeatureFlagDisabled" ]; then
				if [ "${FEATURE_FLAG_STATUS}" = "false" ]; then
					DISABLED="${FEATURE_FLAG_THEN}";
				else
					DISABLED="${FEATURE_FLAG_ELSE}";
				fi
			fi
		fi
		if [ -n "${DISABLED}" ] && [ "${DISABLED:=0}" -eq 1 ]; then
			/bin/echo "${LAUNCH_ITEM}: ${PROGRAM}: Disabled" >> ${baseSettingsFile};
		else
			/bin/echo "${LAUNCH_ITEM}: ${PROGRAM}" >> ${baseSettingsFile};
		fi;
	done
done

sectionBreak;
/bin/echo "Running Launch Items" >> ${baseSettingsFile};
/bin/launchctl list | /usr/bin/grep ^[0-9] | /usr/bin/awk '{ print $NF }' | /usr/bin/grep -v 0x >> ${baseSettingsFile};

# Get Socket Listeners
sectionBreak;
/bin/echo "Socket Listeners" >> ${baseSettingsFile};
LISTENERS_TMP=$(/usr/bin/mktemp -t tmp);
/bin/ls -1 /System/Library/LaunchDaemons/ > ${LISTENERS_TMP};
while read LAUNCH_DAEMON; do
	SERVICE_NAME=$(/usr/libexec/PlistBuddy -c "Print Sockets:Listeners:SockServiceName" /System/Library/LaunchDaemons/${LAUNCH_DAEMON} 2>/dev/null | /usr/bin/grep / | /usr/bin/sed 's/^ *//');
	if [ -n "$SERVICE_NAME" ]; then
		LAUNCH_DAEMON_NAME=$(/usr/bin/basename -s .plist ${LAUNCH_DAEMON} | /usr/bin/awk -F "." '{ print $NF }');
		SERVICE=$(/usr/libexec/PlistBuddy -c "Print ProgramArguments" /System/Library/LaunchDaemons/${LAUNCH_DAEMON} | /usr/bin/grep / | /usr/bin/sed 's/^ *//');
		/bin/echo "${SERVICE}${TAB}${SERVICE_NAME}${TAB}${LAUNCH_DAEMON_NAME}" >> ${baseSettingsFile};
	fi
done < ${LISTENERS_TMP}

# Get Open Ports
sectionBreak;
/bin/echo "Open ports" >> ${baseSettingsFile};
/usr/sbin/netstat -an | /usr/bin/egrep "LISTEN|ESTABLISHED" >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Launch Services Cache" >> ${baseSettingsFile};
/bin/launchctl print-cache >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Disabled Launch Services" >> ${baseSettingsFile};
/bin/launchctl print-disabled system >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Launchd System Domain" >> ${baseSettingsFile};
/bin/launchctl print system >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Launchd User Domain" >> ${baseSettingsFile};
# Get User IDs with running processes
ctr="1";
ACTIVE_USER_IDS=($(/bin/ps -axl | /usr/bin/awk '/[:blank:][0-9]/{ print $1 }' | /usr/bin/sort -un));
until [ "${ctr}" -ge "${#ACTIVE_USER_IDS[@]}" ]; do
	RECORD_NAME=$(/usr/bin/dscl . -search /Users UniqueID ${ACTIVE_USER_IDS[${ctr}]} | /usr/bin/awk '{ print $1; exit }');
	if [ "${RECORD_NAME}" != "nobody" ]; then
		/bin/echo "User: ${RECORD_NAME}; User ID: ${ACTIVE_USER_IDS[$ctr]}" >> ${baseSettingsFile};
		/bin/launchctl print user/${ACTIVE_USER_IDS[$ctr]} >> ${baseSettingsFile};
	fi
	ctr=$((ctr + 1));
done

# Users and groups

# Get Local Users
sectionBreak;
/bin/echo "Local Users" >> ${baseSettingsFile};
/bin/echo "User Name${TAB}Unique ID${TAB}Real Name${TAB}Generated UID${TAB}Shell${TAB}Home Directory" >> ${baseSettingsFile};
USERS_TMP=$(/usr/bin/mktemp -t tmp);
/usr/bin/dscl . -list /Users > "${USERS_TMP}";
while read USER_NAME; do
	GUID=$(/usr/bin/dscl . -read /Users/${USER_NAME} GeneratedUID | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	HOME_DIRECTORY=$(/usr/bin/dscl . -read /Users/${USER_NAME} NFSHomeDirectory | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	REAL_NAME=$(/usr/bin/dscl . -read /Users/${USER_NAME} RealName | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	SHELL=$(/usr/bin/dscl . -read /Users/${USER_NAME} UserShell | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	UNIQUE_ID=$(/usr/bin/dscl . -read /Users/${USER_NAME} UniqueID | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	/bin/echo "${USER_NAME}${TAB}${UNIQUE_ID}${TAB}${REAL_NAME}${TAB}${GUID}${TAB}${SHELL}${TAB}${HOME_DIRECTORY}" >> ${baseSettingsFile};
done < "${USERS_TMP}"

#Get Local Groups
sectionBreak;
/bin/echo "Local Groups" >> ${baseSettingsFile};
/bin/echo "Group Name${TAB}Group ID${TAB}Real Name${TAB}Generated UID${TAB}Members" >> ${baseSettingsFile};
GROUPS_TMP=$(/usr/bin/mktemp -t tmp);
/usr/bin/dscl . -list /Groups > "${GROUPS_TMP}";
while read GROUP_NAME; do
	GUID=$(/usr/bin/dscl . -read /Groups/${GROUP_NAME} GeneratedUID | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	GROUP_ID=$(/usr/bin/dscl . -read /Groups/${GROUP_NAME} PrimaryGroupID | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	REAL_NAME=$(/usr/bin/dscl . -read /Groups/${GROUP_NAME} RealName | /usr/bin/tail -n 1 | /usr/bin/awk -F ":" '{ print $NF }' | /usr/bin/sed 's/^ *//g');
	MEMBERS=$(/usr/bin/dscl . -read /Groups/${GROUP_NAME} GroupMembership 2>/dev/null | /usr/bin/awk -F ": " '{ print $2 }' | /usr/bin/tr -d "\012");
	/bin/echo "${GROUP_NAME}${TAB}${GROUP_ID}${TAB}${REAL_NAME}${TAB}${GUID}${TAB}${MEMBERS}" >> ${baseSettingsFile};
done < "${GROUPS_TMP}"

# System Configuration

# TTY Settings
sectionBreak;
/bin/echo "TTY Settings" >> ${baseSettingsFile};
/bin/stty -a >> ${baseSettingsFile};

# Environment Variables
sectionBreak;
/bin/echo "Environment Variables" >> ${baseSettingsFile};
/usr/bin/printenv >> ${baseSettingsFile};

/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Configuration Files:" >> ${baseSettingsFile};

# Get Energy Settings
sectionBreak;
/bin/echo "Energy Settings" >> ${baseSettingsFile};
/usr/bin/pmset -g everything >> ${baseSettingsFile};

# Security Configuration

sectionBreak;
/bin/echo "Sudo Configuration" >> ${baseSettingsFile};
/usr/bin/sudo -l | /usr/bin/sed "s/  +//g" | /usr/bin/grep -Ev ":" | /usr/bin/tr "\054" "\012" | /usr/bin/awk '{$1=$1;print}' >> ${baseSettingsFile};

sectionBreak;
/bin/echo "sudoers" >> ${baseSettingsFile};
/bin/cat /etc/sudoers >> ${baseSettingsFile};

sectionBreak;
/bin/echo "OpenSSH Configuration" >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo -n "OpenSSH version: " >> ${baseSettingsFile};
/usr/sbin/sshd -V 2>> ${baseSettingsFile};
/bin/echo "SSH Protocol version $(/usr/bin/ssh -Q protocol-version)" >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Supported Symmetric Ciphers:" >> ${baseSettingsFile};
/usr/bin/ssh -Q cipher | /usr/bin/sort >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Supported Message Integrity Codes:" >> ${baseSettingsFile};
/usr/bin/ssh -Q mac | /usr/bin/sort >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Supported Key Exchange Algorithms:" >> ${baseSettingsFile};
/usr/bin/ssh -Q kex | /usr/bin/sort >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Supported Key Algorithms:" >> ${baseSettingsFile};
/usr/bin/ssh -Q key | /usr/bin/sort >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Supported Signature Algorithms:" >> ${baseSettingsFile};
/usr/bin/ssh -Q sig | /usr/bin/sort >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "SSH Configuration" >> ${baseSettingsFile};
/usr/sbin/sshd -G >> ${baseSettingsFile};

sectionBreak;
/bin/echo "ssh configuration" >> ${baseSettingsFile};
/bin/cat /etc/ssh/ssh_config >> ${baseSettingsFile};

sectionBreak;
/bin/echo "sshd configuration" >> ${baseSettingsFile};
/bin/cat /etc/ssh/sshd_config >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Pluggable Authentication Module Configurations" >> ${baseSettingsFile};
for MODULE in $(/bin/ls -1 /etc/pam.d); do
	/bin/echo "" >> ${baseSettingsFile};
	/bin/echo ${MODULE} >> ${baseSettingsFile};
	/bin/echo "" >> ${baseSettingsFile};
	/bin/cat /etc/pam.d/${MODULE} >> ${baseSettingsFile};
	/bin/echo "________________________________________________________________________________" >> ${baseSettingsFile};
 done

sectionBreak;
/bin/echo "system log configuration" >> ${baseSettingsFile};
/usr/bin/log config --status >> ${baseSettingsFile};
/bin/cat /etc/asl.conf >> ${baseSettingsFile};
/bin/cat /etc/newsyslog.conf >> ${baseSettingsFile};
/bin/cat /etc/newsyslog.d/*.conf >> ${baseSettingsFile};
/bin/cat /etc/syslog.conf >> ${baseSettingsFile};

/bin/echo "Log archive configurations" >> ${baseSettingsFile};
/usr/sbin/newsyslog -vv >> ${baseSettingsFile};
/bin/echo "Unified Log" >> ${baseSettingsFile};
/usr/bin/log config --status >> ${baseSettingsFile};
/bin/echo "Unified Log subsystems" >> ${baseSettingsFile};
/usr/bin/find /Library/Preferences/Logging/Subsystems -type f -iname '*.plist' -print -exec /usr/bin/defaults read {} \; >> ${baseSettingsFile};
/usr/bin/find /System/Library/Preferences/Logging/Subsystems -type f -iname '*.plist' -print -exec /usr/bin/defaults read {} \; >> ${baseSettingsFile}; # /Library/Apple/System/Library/Preferences/Logging/Subsystems

#for subsystem in $(/usr/bin/find /System/Library/Preferences/Logging/Subsystems -type f -iname '*.plist'); do
#	level=$(/usr/libexec/PlistBuddy -c "Print DEFAULT-OPTIONS:Level:Enable" "${subsystem}" 2>/dev/null);
#	persist=$(/usr/libexec/PlistBuddy -c "Print DEFAULT-OPTIONS:Level:Persist" "${subsystem}" 2>/dev/null);
#	/usr/bin/printf "%-45s %-10s %-10s\n" "$(/usr/bin/basename -s .plist ${subsystem})" "${level}" "${persist}";
#done

/bin/echo "Apple System Log configuration" >> ${baseSettingsFile};
/usr/bin/syslog -module >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Endpoint Security Events" >> ${baseSettingsFile};
/usr/bin/eslogger --list-events >> ${baseSettingsFile};

sectionBreak;
/bin/echo "LDAP configuration" >> ${baseSettingsFile};
/bin/cat /etc/openldap/ldap.conf >> ${baseSettingsFile};

sectionBreak;
/bin/echo "System Integrity Protection" >> ${baseSettingsFile};
/bin/echo "Protected items" >> ${baseSettingsFile};
/bin/cat /System/Library/Sandbox/rootless.conf >> ${baseSettingsFile};
/bin/echo "Removable Services" >> ${baseSettingsFile};
/usr/bin/defaults read /System/Library/Sandbox/com.apple.xpc.launchd.rootless.plist RemovableServices >> ${baseSettingsFile};
#/bin/echo "Hardening Exceptions" >> ${baseSettingsFile};
#/usr/bin/defaults read /System/Library/Security/HardeningExceptions.plist >> ${baseSettingsFile};
/bin/echo "Compatibility Notifications" >> ${baseSettingsFile};
/usr/bin/defaults read /Library/Apple/Library/Bundles/IncompatibleAppsList.bundle/Contents/Resources/IncompatibleAppsList.plist >> ${baseSettingsFile};

/usr/bin/security export -k /System/Library/Keychains/SystemRootCertificates.keychain -o /Users/Shared/SystemRoots.pem 2>/dev/null;
/bin/mkdir -m 775 -p /Users/Shared/certs;
cd /Users/Shared/certs
split -p "-----BEGIN CERTIFICATE-----" /Users/Shared/SystemRoots.pem systemrootca-
CERT_TEMP=$(/usr/bin/mktemp);
/bin/ls -1 /Users/Shared/certs > "${CERT_TEMP}";
while read CERT_FILE; do
	CERT_NAME=$(/usr/bin/openssl x509 -in "/Users/Shared/certs/${CERT_FILE}" -subject -noout | /usr/bin/tr "\057" "\012" | /usr/bin/awk -F '=' '/CN=|OU=/ { print $NF }' | /usr/bin/tr "\012" "\072");
	CERT_SIG_A=$(/usr/bin/openssl x509 -in "/Users/Shared/certs/${CERT_FILE}" -text -noout | /usr/bin/awk '/Signature Algorithm:/ { o=$NF } END{ print o }');
	KEY_LENGTH=$(/usr/bin/openssl x509 -in "/Users/Shared/certs/${CERT_FILE}" -text -noout | /usr/bin/awk -F "[()]" '/Public-Key:/ { print $(NF-1) }');
	EXPIRATION=$(/usr/bin/openssl x509 -in "/Users/Shared/certs/${CERT_FILE}" -enddate -noout | /usr/bin/awk -F "=" '/notAfter/ { print $2 }');
	/bin/echo "${CERT_NAME}: ${CERT_SIG_A}: ${KEY_LENGTH}": ${EXPIRATION} >> ${baseSettingsFile};
done < "${CERT_TEMP}"
/bin/rm -rf "${CERT_TEMP}" /Users/Shared/certs /Users/Shared/SystemRoots.pem;

sectionBreak;
/bin/echo "System Roots" >> ${baseSettingsFile};
TAB=$(/bin/echo "" | /usr/bin/tr "\012" "\011");
/usr/bin/security export -k /System/Library/Keychains/SystemRootCertificates.keychain -o /Users/Shared/SystemRoots.pem
/bin/mkdir -m 775 -p /Users/Shared/certs;
cd /Users/Shared/certs
split -p "-----BEGIN CERTIFICATE-----" /Users/Shared/SystemRoots.pem systemrootca-
CERT_TEMP=$(/usr/bin/mktemp);
/bin/ls -1 /Users/Shared/certs > "${CERT_TEMP}";
/bin/echo "Common Name${TAB}Signature Algorithm${TAB}Key Length${TAB}Expiration Date" >> ${baseSettingsFile};
while read CERT_FILE; do
	CERT_NAME=$(/usr/bin/openssl x509 -in "/Users/Shared/certs/${CERT_FILE}" -subject -noout | /usr/bin/tr "\057" "\012" | /usr/bin/awk -F '=' '/CN=|OU=/ { print $NF }');
	CERT_SIG_A=$(/usr/bin/openssl x509 -in "/Users/Shared/certs/${CERT_FILE}" -text -noout | /usr/bin/awk '/Signature Algorithm:/ { o=$NF } END{ print o }');
	KEY_LENGTH=$(/usr/bin/openssl x509 -in "/Users/Shared/certs/${CERT_FILE}" -text -noout | /usr/bin/awk -F "[()]" '/Public-Key:/ { print $(NF-1) }');
	EXPIRATION=$(/usr/bin/openssl x509 -in "/Users/Shared/certs/${CERT_FILE}" -enddate -noout | /usr/bin/awk -F "=" '/notAfter/ { print $2 }');
	/bin/echo "${CERT_NAME}${TAB}${CERT_SIG_A}${TAB}${KEY_LENGTH}${TAB}${EXPIRATION}" >> ${baseSettingsFile};
done < "${CERT_TEMP}"
/bin/rm -rf "${CERT_TEMP}" /Users/Shared/certs /Users/Shared/SystemRoots.pem;

sectionBreak;
/bin/echo "Local Preferences" >> ${baseSettingsFile};
for PLIST in $(/bin/ls -a1 /Library/Preferences/ | /usr/bin/grep .plist$); do
	/bin/echo "${PLIST}" >> ${baseSettingsFile};
	/usr/libexec/PlistBuddy -c "Print" /Library/Preferences/${PLIST} >> ${baseSettingsFile};
done

sectionBreak;
/bin/echo "Boot Tasks" >> ${baseSettingsFile};
/Volumes/Source/otool -X -s __TEXT __config /sbin/launchd | /usr/bin/awk '{print $2 $3 $4 $5}' | /usr/bin/xxd -r -p | /usr/bin/hexdump -v -e '1/4 "%08x"' -e '"\n"' | /usr/bin/xxd -r -p >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Host Info" >> ${baseSettingsFile};
/bin/launchctl hostinfo >> ${baseSettingsFile};

sectionBreak;
/bin/echo "NSServices Restrictions" >> ${baseSettingsFile};
/bin/echo "Restricted:" >> ${baseSettingsFile};
/usr/bin/defaults read /System/Library/CoreServices/com.apple.NSServicesRestrictions.plist NSRestricted >> ${baseSettingsFile};
/bin/echo "Unrestricted:" >> ${baseSettingsFile};
/usr/bin/defaults read /System/Library/CoreServices/com.apple.NSServicesRestrictions.plist NSUnrestricted >> ${baseSettingsFile};

sectionBreak;
/bin/echo "BSM Audit Configuration" >> ${baseSettingsFile};
if [ -f /etc/security/audit_control ]; then
	/bin/cat /etc/security/audit_control >> ${baseSettingsFile};
else
	/bin/cat /etc/security/audit_control.example >> ${baseSettingsFile};
fi

sectionBreak;
/bin/echo "File Download Assessment" >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Safe File Types" >> ${baseSettingsFile};
/usr/libexec/PlistBuddy -c "Print LSRiskCategorySafe:LSRiskCategoryContentTypes" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Safe File Extensions" >> ${baseSettingsFile};
/usr/libexec/PlistBuddy -c "Print LSRiskCategorySafe:LSRiskCategoryExtensions" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Potentially Unsafe File Types" >> ${baseSettingsFile};
/usr/libexec/PlistBuddy -c "Print LSRiskCategoryMayContainUnsafeExecutable:LSRiskCategoryContentTypes" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Potentially Unsafe File Extensions" >> ${baseSettingsFile};
/usr/libexec/PlistBuddy -c "Print LSRiskCategoryMayContainUnsafeExecutable:LSRiskCategoryExtensions" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Unsafe File Types" >> ${baseSettingsFile};
/usr/libexec/PlistBuddy -c "Print LSRiskCategoryUnsafeExecutable:LSRiskCategoryContentTypes" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' >> ${baseSettingsFile};
/bin/echo "" >> ${baseSettingsFile};
/bin/echo "Unsafe File Extensions" >> ${baseSettingsFile};
/usr/libexec/PlistBuddy -c "Print LSRiskCategoryUnsafeExecutable:LSRiskCategoryExtensions" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/System 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Transparency Consent Services" >> ${baseSettingsFile};
/Volumes/Source/strings /System/Library/PrivateFrameworks/TCC.framework/Support/tccd | /usr/bin/grep -E "^kTCCService" | /usr/bin/sort -u >> ${baseSettingsFile};

sectionBreak;
/bin/echo "SSH Server configuration" >> ${baseSettingsFile};
/usr/sbin/sshd -G  >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Privacy Database" >> ${baseSettingsFile};
/usr/bin/sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db '.dump' >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Transparency Consent and Control Services " >> ${baseSettingsFile};
/Volumes/Source/strings /System/Library/PrivateFrameworks/TCC.framework/Support/tccd | /usr/bin/grep -iEo "^kTCCService.*" | /usr/bin/sort >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Security-Keychain Diagnostics" >> ${baseSettingsFile};
/usr/libexec/security-sysdiagnose >> ${baseSettingsFile};

sectionBreak;
/bin/echo "System Statistics" >> ${baseSettingsFile};
/usr/sbin/systemstats --dump >> ${baseSettingsFile};

# Localization

sectionBreak;
/bin/echo "Terminal Supported Locales" >> ${baseSettingsFile};
locale -a  >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Supported Character sets" >> ${baseSettingsFile};
/usr/libexec/PlistBuddy -c "Print :en:" /System/Library/Frameworks/Foundation.framework/Versions/C/Resources/EncodingNames.loctable | /usr/bin/awk -F " = " '{gsub("^  +","");  print $1 }' | /usr/bin/grep "(" | /usr/bin/sort >> ${baseSettingsFile};

# Miscellaneous Information

sectionBreak;
/bin/echo "Header files" >> ${baseSettingsFile};
/usr/bin/find -x / -type f -iname '*.h' 2>/dev/null | /usr/bin/grep -v -E "^/System/Volumes/Data" 2>/dev/null >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Registered UTIs" >> ${baseSettingsFile};
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump -apps -domain system,local,users 2>/dev/null | /usr/bin/awk -F ":               " '/claimed UTIs:/ { gsub(", ","\n"); print $NF }' | sort -u | grep -v "^dyn" >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Spotlight Metadata Attributes" >> ${baseSettingsFile};
/usr/bin/mdimport -X | /usr/bin/awk '/name = kMDItem|name = \"_kMDItem/{ gsub(";",""); print $NF}' | /usr/bin/sort -u >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Supported URL Schemes" >> ${baseSettingsFile};
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump URLSchemeBinding >> ${baseSettingsFile};

sectionBreak;
/bin/echo "System Settings AppleScript Anchors" >> ${baseSettingsFile};
/usr/bin/osascript -e 'tell application "System Settings" to get every anchor of every pane' 2>&1 | /usr/bin/tr '\054' '\012' | /usr/bin/tee >> ${baseSettingsFile};

sectionBreak;
/bin/echo "Feature Flags" >> ${baseSettingsFile};
/usr/bin/find /System/Library/FeatureFlags -type f -iname '*.plist' -print -exec defaults read {} \; 2>/dev/null >> ${baseSettingsFile};

sectionBreak;
/bin/echo "ShareKit Extensions" >> ${baseSettingsFile};
/usr/bin/defaults read /System/Library/PrivateFrameworks/ShareKit.framework/Versions/A/Resources/SHKServicesOrder.plist displayOrder | /usr/bin/awk -F '\042' '{ print $2 }' >> ${baseSettingsFile};

# Create Security database
/usr/bin/sqlite3 /Volumes/Source/security.db "CREATE TABLE alf ('applications' TEXT, 'alias' TEXT, 'bundleid' TEXT, 'state' INTEGER);";
/usr/bin/sqlite3 /Volumes/Source/security.db "CREATE TABLE authorization (ROWID INTEGER PRIMARY KEY AUTOINCREMENT, 'type' TEXT, 'name' TEXT, 'allow-root' TEXT, 'authenticate-user' TEXT, 'class' TEXT, 'comment' TEXT, 'created' REAL, 'default-button' TEXT, 'default-prompt' TEXT, 'entitled' TEXT, 'entitled-group' TEXT, 'extract-password' TEXT, 'group' TEXT, 'identifier' TEXT, 'k-of-n' INTEGER, 'mechanisms' TEXT, 'modified' REAL, 'password-only' TEXT, 'require-apple-signed' TEXT, 'requirement' TEXT, 'rule' TEXT, 'session-owner' TEXT, 'shared' TEXT, 'timeout' INTEGER, 'tries' INTEGER, 'version' INTEGER, 'vpn-entitled-group' TEXT, 'source' TEXT, 'active' TEXT, 'set' TEXT, 'priority' INTEGER);";
/usr/bin/sqlite3 /Volumes/Source/security.db "CREATE TABLE criticalfiles ('path' TEXT UNIQUE, 'perms' TEXT, 'owner' TEXT, 'group' TEXT, 'cksum' TEXT);";
/usr/bin/sqlite3 /Volumes/Source/security.db "CREATE TABLE executables ('filepath' TEXT UNIQUE, 'mode' TEXT, 'fileowner' TEXT, 'filegroup' TEXT, 'cksum' TEXT, 'installdate' TEXT, 'type' TEXT, 'version' TEXT, 'manpage' TEXT, 'source' TEXT);";
/usr/bin/sqlite3 /Volumes/Source/security.db "CREATE TABLE filesystem ('path' TEXT UNIQUE, 'perms' TEXT, 'owner' TEXT, 'group' TEXT, 'finder_flags' TEXT, 'acl' TEXT, 'required' TEXT, 'description' TEXT);";
/usr/bin/sqlite3 /Volumes/Source/security.db "CREATE TABLE libusage ('binarypath' TEXT, 'librarypath' TEXT, 'libraryname' TEXT, 'libraryversion' TEXT, 'architecture' TEXT);";
/usr/bin/sqlite3 /Volumes/Source/security.db "CREATE TABLE sgid ('file' TEXT, 'chk' TEXT, 'group' TEXT, 'reason' TEXT);";
/usr/bin/sqlite3 /Volumes/Source/security.db "CREATE TABLE suid ('file' TEXT, 'chk' TEXT, 'user' TEXT, 'reason' TEXT);";

/bin/echo "Registering base applications" >> ${baseSettingsFile};
declare -r BUNDLE_EXECUTABLES=(acroplugin action aplmodel app assistant backend bblm bkplugin brailledriver brailletable bundle caction calcview CharPalettePlugin component crplugin csutil daplug datadetectors dcplugin diagramGraphLayouter diagramTool discovery docktileplugin driver dsclext dsplug dumodule EventHandler Fax filter framework frappliance growlView IAPlugin ibplugin ilmbplugin impreferencepane imservice jdk kext lib loginPlugin mailbundle mdimporter menu monitor monitorPanel mpp mwbplugin osax pbplugin phoneplugin plugin PMMUG pmp ppp prefPane PrintJobMgr proofingtool propPane qldisplay qlgenerator qlstream saver scpt scripting seplugin service sfxplugin sourcebundle SpeechRecognizer SpeechSynthesizer spreporter SxPlugin syncdevice syncschema task tokend transcriptstyle transport vpn wdgtTemplate webplugin widgetplugin woa xcodeplugin xcplugin xdplugin xtra);
pushd / 1>/dev/null;

# Get Application Firewall
FIREWALL_DATA_TMP=$(/usr/bin/mktemp -t tmp);
/usr/libexec/ApplicationFirewall/socketfilterfw --listapps | /usr/bin/awk -F " : " '/^[0-9]/ { print $NF }' > "${FIREWALL_DATA_TMP}";
declare -a appState; appState=($(/usr/libexec/ApplicationFirewall/socketfilterfw --listapps | /usr/bin/awk '/  +/ { gsub("\\(",""); print $1 }'));
while read APP_DATA; do
	APP=$(/usr/bin/basename "${APP_DATA}");
	if [ -e "${APP_DATA}" ]; then
		APP_TYPE=$(/usr/bin/stat -f "%HT" "${APP_DATA}");
	else
		APP_TYPE="No such file";
	fi
	case "${APP_TYPE}" in
		Directory) ALIAS="${APP_DATA}"; BUNDLE_IDENTIFIER=$(/usr/bin/defaults read "${APP_DATA}/Contents/Info.plist" CFBundleIdentifier) ;;
		"Regular File") ALIAS="${APP_DATA}"; BUNDLE_IDENTIFIER=$(/usr/bin/codesign -dv --verbose "${APP_DATA}" 2>&1 | /usr/bin/awk -F "=" '/^Identifier=/ { print $NF }') ;;
		"Symbolic Link") ALIAS=$(/usr/bin/whereis -bq "${APP_DATA}"); BUNDLE_IDENTIFIER=$(/usr/bin/codesign -dv --verbose "${ALIAS}" 2>&1 | /usr/bin/awk -F "=" '/^Identifier=/ { print $NF }') ;;
	esac
	((stateCtr++));
	if [ "${appState[${stateCtr}]}" = "Allow" ]; then STATE="1"; else STATE="0"; fi
	/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT INTO alf VALUES ('${APP}','${ALIAS}','${BUNDLE_IDENTIFIER}','${STATE}');";
done < "${FIREWALL_DATA_TMP}"
/bin/rm "${FIREWALL_DATA_TMP}";

#/usr/libexec/ApplicationFirewall/socketfilterfw --getallowsigned 

# Catalog File System
#/bin/echo "Cataloging file system";
getFileSystemObjects /;

# Get Authorization
RULES_TMP=$(/usr/bin/mktemp -t tmp);
RIGHTS_TMP=$(/usr/bin/mktemp -t tmp);
AUTH_TEMP_DIR=$(/usr/bin/mktemp -d -t tmp);
pushd ${AUTH_TEMP_DIR} 1>/dev/null;

/usr/bin/sqlite3 /private/var/db/auth.db "SELECT name FROM rules WHERE type is 1 ORDER BY name" > ${RULES_TMP};
/usr/bin/sqlite3 /private/var/db/auth.db "SELECT name FROM rules WHERE type is 2 ORDER BY name" > ${RIGHTS_TMP};
ID=1;
SOURCE="'$(/usr/bin/sw_vers -productName)'";
ACTIVE="'Yes'";
case $(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{ print $1"."$2 }') in
	10.9) COLLECTION="'mavericks_base'" ;;
	10.10) COLLECTION="'yosemite_base'" ;;
	10.11) COLLECTION="'el_capitan_base'" ;;
	10.12) COLLECTION="'sierra_base'" ;;
	10.13) COLLECTION="'high_sierra_base'" ;;
	10.14) COLLECTION="'mojave_base'" ;;
	10.15) COLLECTION="'yosemite_base'" ;;
	11.[0-7]) COLLECTION="'big_sur_base'" ;;
	12.[0-7]) COLLECTION="'monterey_base'" ;;
	13.[0-7]) COLLECTION="'ventura_base'" ;;
	14.[0-7]) COLLECTION="'sonoma_base'" ;;
	15.[0-7]) COLLECTION="'sequoia_base'" ;;
	26.[0-7]) COLLECTION="'tahoe_base'" ;;
	27.[0-7]) COLLECTION="'golden_gate_base'" ;;
	*) COLLECTION="$(/bin/echo -n ${codeName} | /usr/bin/tr "[:upper:]" "[:lower:]" | /usr/bin/tr "\040" "\137")_base" ;;
esac
PRIORITY="0";
while read NAME; do
	/usr/bin/security authorizationdb read "${NAME}" 2>/dev/null > "${NAME}.plist";
	TYPE="'right'";
	ALLOW_ROOT=$(/usr/libexec/PlistBuddy -c "Print allow-root" "${NAME}.plist" 2>/dev/null); if [ -z "${ALLOW_ROOT}" ]; then ALLOW_ROOT="NULL"; else ALLOW_ROOT="'${ALLOW_ROOT}'"; fi # boolean true | false
	AUTHENTICATE_USER=$(/usr/libexec/PlistBuddy -c "Print authenticate-user" "${NAME}.plist" 2>/dev/null); if [ -z "${AUTHENTICATE_USER}" ]; then AUTHENTICATE_USER="NULL"; else AUTHENTICATE_USER="'${AUTHENTICATE_USER}'"; fi # boolean true | false
	CLASS=$(/usr/libexec/PlistBuddy -c "Print class" "${NAME}.plist" 2>/dev/null); if [ -z "${CLASS}" ]; then CLASS="NULL"; else CLASS="'${CLASS}'"; fi # string
	COMMENT=$(/usr/libexec/PlistBuddy -c "Print comment" "${NAME}.plist" 2>/dev/null | /usr/bin/tr "\012" "\040" | /usr/bin/sed -E 's/\t+//g' | /usr/bin/sed -E 's/ +/ /g' | /usr/bin/sed "s/'/$(echo -ne '\u2019')/g"); if [ -z "${COMMENT}" ]; then COMMENT="NULL"; else COMMENT="'${COMMENT}'"; fi # string (URL encoded)
	CREATED="'$(/usr/libexec/PlistBuddy -c "Print created" "${NAME}.plist")'";# float
	DEFAULT_BUTTON=$(/usr/libexec/PlistBuddy -c "Print default-button" "${NAME}.plist" 2>/dev/null | /usr/bin/tr "\012" "\073"); if [ -z "${DEFAULT_BUTTON}" ]; then DEFAULT_BUTTON="NULL"; else DEFAULT_BUTTON="'${DEFAULT_BUTTON}'"; fi # string (URL encoded)
	DEFAULT_PROMPT=$(/usr/libexec/PlistBuddy -c "Print default-prompt" "${NAME}.plist" 2>/dev/null | /usr/bin/tr "\012" "\073"); if [ -z "${DEFAULT_PROMPT}" ]; then DEFAULT_PROMPT="NULL"; else DEFAULT_PROMPT="'${DEFAULT_PROMPT}'"; fi # string (URL encoded)
	ENTITLED=$(/usr/libexec/PlistBuddy -c "Print entitled" "${NAME}.plist" 2>/dev/null); if [ -z "${ENTITLED}" ]; then ENTITLED="NULL"; else ENTITLED="'${ENTITLED}'"; fi # boolean true | false
	ENTITLED_GROUP=$(/usr/libexec/PlistBuddy -c "Print entitled-group" "${NAME}.plist" 2>/dev/null); if [ -z "${ENTITLED_GROUP}" ]; then ENTITLED_GROUP="NULL"; else ENTITLED_GROUP="'${ENTITLED_GROUP}'"; fi # boolean true | false
	EXTRACT_PASSWORD=$(/usr/libexec/PlistBuddy -c "Print extract-password" "${NAME}.plist" 2>/dev/null); if [ -z "${EXTRACT_PASSWORD}" ]; then EXTRACT_PASSWORD="NULL"; else EXTRACT_PASSWORD="'${EXTRACT_PASSWORD}'"; fi # boolean true | false
	GROUP=$(/usr/libexec/PlistBuddy -c "Print group" "${NAME}.plist" 2>/dev/null | /usr/bin/tr "\012" "\073"); if [ -z "${GROUP}" ]; then GROUP="NULL"; else GROUP="'${GROUP}'"; fi # string
	IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print identifier" "${NAME}.plist" 2>/dev/null); if [ -z "${IDENTIFIER}" ]; then IDENTIFIER="NULL"; else IDENTIFIER="'${IDENTIFIER}'"; fi # string
	K_OF_N=$(/usr/libexec/PlistBuddy -c "Print k-of-n" "${NAME}.plist" 2>/dev/null); if [ -z "${K_OF_N}" ]; then K_OF_N="NULL"; fi # integer
	MECHANISMS=$(/usr/libexec/PlistBuddy -c "Print mechanisms" "${NAME}.plist" 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' | /usr/bin/tr "\012" "\073" | /usr/bin/awk '{print substr($0, 0, length($0)-1)}'); if [ -z "${MECHANISMS}" ]; then MECHANISMS="NULL"; else MECHANISMS="'${MECHANISMS}'"; fi # array of strings
	MODIFIED="'$(/usr/libexec/PlistBuddy -c "Print modified" "${NAME}.plist")'";# float
	PASSWORD_ONLY=$(/usr/libexec/PlistBuddy -c "Print password-only" "${NAME}.plist" 2>/dev/null); if [ -z "${PASSWORD_ONLY}" ]; then PASSWORD_ONLY="NULL"; else PASSWORD_ONLY="'${PASSWORD_ONLY}'"; fi # boolean true | false
	REQUIRE_APPLE_SIGNED=$(/usr/libexec/PlistBuddy -c "Print require-apple-signed" "${NAME}.plist" 2>/dev/null); if [ -z "${REQUIRE_APPLE_SIGNED}" ]; then REQUIRE_APPLE_SIGNED="NULL"; else REQUIRE_APPLE_SIGNED="'${REQUIRE_APPLE_SIGNED}'"; fi # boolean true | false
	REQUIREMENT=$(/usr/libexec/PlistBuddy -c "Print requirement" "${NAME}.plist" 2>/dev/null); if [ -z "${REQUIREMENT}" ]; then REQUIREMENT="NULL"; else REQUIREMENT="'${REQUIREMENT}'"; fi # string
	RULE_TYPES=$(/usr/libexec/PlistBuddy -c "Print rule" "${NAME}.plist" 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' | /usr/bin/tr "\012" "\073" | /usr/bin/awk '{print substr($0, 0, length($0)-1)}'); if [ -z "${RULE_TYPES}" ]; then RULE_TYPES="NULL"; else RULE_TYPES="'${RULE_TYPES}'"; fi # array of strings
	SESSION_OWNER=$(/usr/libexec/PlistBuddy -c "Print session-owner" "${NAME}.plist" 2>/dev/null); if [ -z "${SESSION_OWNER}" ]; then SESSION_OWNER="NULL"; else SESSION_OWNER="'${SESSION_OWNER}'"; fi # boolean true | false
	SHARED=$(/usr/libexec/PlistBuddy -c "Print shared" "${NAME}.plist" 2>/dev/null); if [ -z "${SHARED}" ]; then SHARED="NULL"; else SHARED="'${SHARED}'"; fi # boolean true | false
	TIMEOUT=$(/usr/libexec/PlistBuddy -c "Print timeout" "${NAME}.plist" 2>/dev/null); if [ -z "${TIMEOUT}" ]; then TIMEOUT="NULL"; fi # integer
	TRIES=$(/usr/libexec/PlistBuddy -c "Print tries" "${NAME}.plist" 2>/dev/null); if [ -z "${TRIES}" ]; then TRIES="NULL"; fi # integer
	VERSION=$(/usr/libexec/PlistBuddy -c "Print version" "${NAME}.plist" 2>/dev/null); if [ -z "${VERSION}" ]; then VERSION="NULL"; fi # integer
	VPN_ENTITLED_GROUP=$(/usr/libexec/PlistBuddy -c "Print vpn-entitled-group" "${NAME}.plist" 2>/dev/null); if [ -z "${VPN_ENTITLED_GROUP}" ]; then VPN_ENTITLED_GROUP="NULL"; else VPN_ENTITLED_GROUP="'${VPN_ENTITLED_GROUP}'"; fi # boolean true | false
	/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT INTO 'authorization' VALUES (${ID},${TYPE},'${NAME}',${ALLOW_ROOT},${AUTHENTICATE_USER},${CLASS},${COMMENT},${CREATED},${DEFAULT_BUTTON},${DEFAULT_PROMPT},${ENTITLED},${ENTITLED_GROUP},${EXTRACT_PASSWORD},${GROUP},${IDENTIFIER},${K_OF_N},${MECHANISMS},${MODIFIED},${PASSWORD_ONLY},${REQUIRE_APPLE_SIGNED},${REQUIREMENT},${RULE_TYPES},${SESSION_OWNER},${SHARED},${TIMEOUT},${TRIES},${VERSION},${VPN_ENTITLED_GROUP},${SOURCE},${ACTIVE},${COLLECTION},${PRIORITY});"
	ID="$((${ID} + 1 ))";
done < ${RULES_TMP}

while read NAME; do
	/usr/bin/security authorizationdb read "${NAME}" 2>/dev/null > "${NAME}.plist";
	TYPE="'rule'";
	ALLOW_ROOT=$(/usr/libexec/PlistBuddy -c "Print allow-root" "${NAME}.plist" 2>/dev/null); if [ -z "${ALLOW_ROOT}" ]; then ALLOW_ROOT="NULL"; else ALLOW_ROOT="'${ALLOW_ROOT}'"; fi # boolean true | false
	AUTHENTICATE_USER=$(/usr/libexec/PlistBuddy -c "Print authenticate-user" "${NAME}.plist" 2>/dev/null); if [ -z "${AUTHENTICATE_USER}" ]; then AUTHENTICATE_USER="NULL"; else AUTHENTICATE_USER="'${AUTHENTICATE_USER}'"; fi # boolean true | false
	CLASS=$(/usr/libexec/PlistBuddy -c "Print class" "${NAME}.plist" 2>/dev/null); if [ -z "${CLASS}" ]; then CLASS="NULL"; else CLASS="'${CLASS}'"; fi # string
	COMMENT=$(/usr/libexec/PlistBuddy -c "Print comment" "${NAME}.plist" 2>/dev/null | /usr/bin/tr "\012" "\040" | /usr/bin/sed -E 's/\t+//g' | /usr/bin/sed -E 's/ +/ /g' | /usr/bin/sed "s/'/$(echo -ne '\u2019')/g"); if [ -z "${COMMENT}" ]; then COMMENT="NULL"; else COMMENT="'${COMMENT}'"; fi # string (URL encoded)
	CREATED="'$(/usr/libexec/PlistBuddy -c "Print created" "${NAME}.plist")'";# float
	DEFAULT_BUTTON=$(/usr/libexec/PlistBuddy -c "Print default-button" "${NAME}.plist" 2>/dev/null | /usr/bin/tr "\012" "\073"); if [ -z "${DEFAULT_BUTTON}" ]; then DEFAULT_BUTTON="NULL"; else DEFAULT_BUTTON="'${DEFAULT_BUTTON}'"; fi # string (URL encoded)
	DEFAULT_PROMPT=$(/usr/libexec/PlistBuddy -c "Print default-prompt" "${NAME}.plist" 2>/dev/null | /usr/bin/tr "\012" "\073"); if [ -z "${DEFAULT_PROMPT}" ]; then DEFAULT_PROMPT="NULL"; else DEFAULT_PROMPT="'${DEFAULT_PROMPT}'"; fi # string (URL encoded)
	ENTITLED=$(/usr/libexec/PlistBuddy -c "Print entitled" "${NAME}.plist" 2>/dev/null); if [ -z "${ENTITLED}" ]; then ENTITLED="NULL"; else ENTITLED="'${ENTITLED}'"; fi # boolean true | false
	ENTITLED_GROUP=$(/usr/libexec/PlistBuddy -c "Print entitled-group" "${NAME}.plist" 2>/dev/null); if [ -z "${ENTITLED_GROUP}" ]; then ENTITLED_GROUP="NULL"; else ENTITLED_GROUP="'${ENTITLED_GROUP}'"; fi # boolean true | false
	EXTRACT_PASSWORD=$(/usr/libexec/PlistBuddy -c "Print extract-password" "${NAME}.plist" 2>/dev/null); if [ -z "${EXTRACT_PASSWORD}" ]; then EXTRACT_PASSWORD="NULL"; else EXTRACT_PASSWORD="'${EXTRACT_PASSWORD}'"; fi # boolean true | false
	GROUP=$(/usr/libexec/PlistBuddy -c "Print group" "${NAME}.plist" 2>/dev/null | /usr/bin/tr "\012" "\073"); if [ -z "${GROUP}" ]; then GROUP="NULL"; else GROUP="'${GROUP}'"; fi # string
	IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print identifier" "${NAME}.plist" 2>/dev/null); if [ -z "${IDENTIFIER}" ]; then IDENTIFIER="NULL"; else IDENTIFIER="'${IDENTIFIER}'"; fi # string
	K_OF_N=$(/usr/libexec/PlistBuddy -c "Print k-of-n" "${NAME}.plist" 2>/dev/null); if [ -z "${K_OF_N}" ]; then K_OF_N="NULL"; fi # integer
	MECHANISMS=$(/usr/libexec/PlistBuddy -c "Print mechanisms" "${NAME}.plist" 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' | /usr/bin/tr "\012" "\073" | /usr/bin/awk '{print substr($0, 0, length($0)-1)}'); if [ -z "${MECHANISMS}" ]; then MECHANISMS="NULL"; else MECHANISMS="'${MECHANISMS}'"; fi # array of strings
	MODIFIED="'$(/usr/libexec/PlistBuddy -c "Print modified" "${NAME}.plist")'";# float
	PASSWORD_ONLY=$(/usr/libexec/PlistBuddy -c "Print password-only" "${NAME}.plist" 2>/dev/null); if [ -z "${PASSWORD_ONLY}" ]; then PASSWORD_ONLY="NULL"; else PASSWORD_ONLY="'${PASSWORD_ONLY}'"; fi # boolean true | false
	REQUIRE_APPLE_SIGNED=$(/usr/libexec/PlistBuddy -c "Print require-apple-signed" "${NAME}.plist" 2>/dev/null); if [ -z "${REQUIRE_APPLE_SIGNED}" ]; then REQUIRE_APPLE_SIGNED="NULL"; else REQUIRE_APPLE_SIGNED="'${REQUIRE_APPLE_SIGNED}'"; fi # boolean true | false
	REQUIREMENT=$(/usr/libexec/PlistBuddy -c "Print requirement" "${NAME}.plist" 2>/dev/null); if [ -z "${REQUIREMENT}" ]; then REQUIREMENT="NULL"; else REQUIREMENT="'${REQUIREMENT}'"; fi # string
	RULE_TYPES=$(/usr/libexec/PlistBuddy -c "Print rule" "${NAME}.plist" 2>/dev/null | /usr/bin/awk '/^ / { print $NF }' | /usr/bin/tr "\012" "\073" | /usr/bin/awk '{print substr($0, 0, length($0)-1)}'); if [ -z "${RULE_TYPES}" ]; then RULE_TYPES="NULL"; else RULE_TYPES="'${RULE_TYPES}'"; fi # array of strings
	SESSION_OWNER=$(/usr/libexec/PlistBuddy -c "Print session-owner" "${NAME}.plist" 2>/dev/null); if [ -z "${SESSION_OWNER}" ]; then SESSION_OWNER="NULL"; else SESSION_OWNER="'${SESSION_OWNER}'"; fi # boolean true | false
	SHARED=$(/usr/libexec/PlistBuddy -c "Print shared" "${NAME}.plist" 2>/dev/null); if [ -z "${SHARED}" ]; then SHARED="NULL"; else SHARED="'${SHARED}'"; fi # boolean true | false
	TIMEOUT=$(/usr/libexec/PlistBuddy -c "Print timeout" "${NAME}.plist" 2>/dev/null); if [ -z "${TIMEOUT}" ]; then TIMEOUT="NULL"; fi # integer
	TRIES=$(/usr/libexec/PlistBuddy -c "Print tries" "${NAME}.plist" 2>/dev/null); if [ -z "${TRIES}" ]; then TRIES="NULL"; fi # integer
	VERSION=$(/usr/libexec/PlistBuddy -c "Print version" "${NAME}.plist" 2>/dev/null); if [ -z "${VERSION}" ]; then VERSION="NULL"; fi # integer
	VPN_ENTITLED_GROUP=$(/usr/libexec/PlistBuddy -c "Print vpn-entitled-group" "${NAME}.plist" 2>/dev/null); if [ -z "${VPN_ENTITLED_GROUP}" ]; then VPN_ENTITLED_GROUP="NULL"; else VPN_ENTITLED_GROUP="'${VPN_ENTITLED_GROUP}'"; fi # boolean true | false
	/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT INTO 'authorization' VALUES (${ID},${TYPE},'${NAME}',${ALLOW_ROOT},${AUTHENTICATE_USER},${CLASS},${COMMENT},${CREATED},${DEFAULT_BUTTON},${DEFAULT_PROMPT},${ENTITLED},${ENTITLED_GROUP},${EXTRACT_PASSWORD},${GROUP},${IDENTIFIER},${K_OF_N},${MECHANISMS},${MODIFIED},${PASSWORD_ONLY},${REQUIRE_APPLE_SIGNED},${REQUIREMENT},${RULE_TYPES},${SESSION_OWNER},${SHARED},${TIMEOUT},${TRIES},${VERSION},${VPN_ENTITLED_GROUP},${SOURCE},${ACTIVE},${COLLECTION},${PRIORITY});"
	ID="$((${ID} + 1 ))";
done < ${RIGHTS_TMP}
popd 1>/dev/null;
/bin/rm -rf ${AUTH_TEMP_DIR};
/bin/rm ${RULES_TMP} ${RIGHTS_TMP};

# Record Critical Files
for CRITICAL_FILE in zshrc krb5.keytab autofs.conf sudoers rc.common ttys asl.conf pf.conf rtadvd.conf bashrc zprofile hosts csh.cshrc profile shells csh.login syslog.conf paths networks ntp_opendirectory.conf hosts.equiv pam.d/authorization pam.d/authorization_aks pam.d/authorization_ctk pam.d/authorization_la pam.d/authorization_lacont pam.d/checkpw pam.d/chkpasswd pam.d/cups pam.d/login pam.d/login.term pam.d/other pam.d/passwd pam.d/screensaver pam.d/screensaver_aks pam.d/screensaver_ctk pam.d/screensaver_la pam.d/screensaver_new pam.d/screensaver_new_aks pam.d/screensaver_new_ctk pam.d/screensaver_new_la pam.d/smbd pam.d/sshd pam.d/su pam.d/sudo pam.d/sudo_local.template paths.d/10-cryptex racoon/psk.txt racoon/racoon.conf security/audit_class security/audit_control.example security/audit_event security/audit_user security/audit_warn ssh/crypto/fips.conf ssh/crypto/apple.conf ssh/moduli ssh/ssh_config ssh/sshd_config ssh/ssh_config.d/100-macos.conf ssh/sshd_config.d/100-macos.conf ssl/cert.pem ssl/openssl.cnf ssl/x509v3.cnf; do
CRITICAL_FILE_PATH="/private/etc/${CRITICAL_FILE}";
if [ -f "${CRITICAL_FILE_PATH}" ]; then
	eval "$(/usr/bin/stat -s ${CRITICAL_FILE_PATH})";
	MODE="${st_mode}";
	OWNER="${st_uid}";
	GROUP="${st_gid}";
	SHA256=$(/usr/bin/shasum -a 256 ${CRITICAL_FILE_PATH} 2>/dev/null | /usr/bin/awk '{ print $1 }');
	/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT OR REPLACE INTO criticalfiles VALUES ('${CRITICAL_FILE_PATH}','${MODE}','${OWNER}','${GROUP}','${SHA256}');"; #(path,perms,owner,group,hash)
fi
done

# Get SUID SGID bits
SUID_LIST_TMP=$(/usr/bin/mktemp -t tmp);
SGID_LIST_TMP=$(/usr/bin/mktemp -t tmp);
SUID_EXCLUDE=(/bin/rcp /usr/bin/rlogin /usr/bin/rsh /usr/libexec/dumpemacs);
SGID_EXCLUDE=(/usr/bin/procmail /usr/bin/wall /usr/bin/write /usr/sbin/postdrop /usr/sbin/postqueue);
/usr/bin/find -x / -perm -4000 2>/dev/null > "${SUID_LIST_TMP}";
/usr/bin/find -x / -perm -2000 2>/dev/null > "${SGID_LIST_TMP}";
bittest "${SUID_LIST_TMP}" suid ${SUID_EXCLUDE[@]};
bittest "${SGID_LIST_TMP}" sgid ${SGID_EXCLUDE[@]};
/bin/rm "${SUID_LIST_TMP}" "${SGID_LIST_TMP}";

BOM_FILE=/Volumes/Source/macOS.bom;
pushd / 1>/dev/null;
APP_TEMP=$(/usr/bin/mktemp -t tmp);

# Find executable files
/usr/bin/lsbom -p Mugcf "${BOM_FILE}" | /usr/bin/grep -e '^-[r-][w-][s,x]' | /usr/bin/tr "\011" "\174" >> ${APP_TEMP};

# Find scripts without executable bits
/usr/bin/lsbom -p Mugcf "${BOM_FILE}" | /usr/bin/tr "\011" "\174" | /usr/bin/egrep "\.applescript$|\.awk$|\.class$|\.jar$|\.jnlp$|\.js$|\.php$|\.pyc$|\.pyo$|\.rb$|\.scpt$|\.war$" >> ${APP_TEMP};
if [ -s "$APP_TEMP" ]; then
	while read EXECUTABLE ; do
		FILE_PATH=$(/bin/echo "${EXECUTABLE}" | /usr/bin/awk -F "\174" '{ print $5 }' | /usr/bin/sed "s|^\.\/|/|");
		if [ -f "${FILE_PATH}" ]; then
			FILE_NAME=$(/usr/bin/basename "${FILE_PATH}");
			FILE_MODE=$(/bin/echo "${EXECUTABLE}" | /usr/bin/awk -F "\174" '{ print $1 }');
			FILE_OWNER=$(/bin/echo "${EXECUTABLE}" | /usr/bin/awk -F "\174" '{ print $2 }');
			FILE_GROUP=$(/bin/echo "${EXECUTABLE}" | /usr/bin/awk -F "\174" '{ print $3 }');
			CRC32=$(/bin/echo "${EXECUTABLE}" | /usr/bin/awk -F "\174" '{ print $4 }');
			INSTALL_DATE=$(/bin/date -j -f "%s" $(/usr/bin/stat -f "%B" /"${FILE_PATH}") "+%Y-%m-%d %T");
			if [ -e "${FILE_PATH}" ]; then
				BUNDLE_TYPE=$(/bin/echo "${FILE_PATH}" | /usr/bin/awk -F . '{ print $NF }' | /usr/bin/awk -F "/" '{ print $1 }');
				if [ "$BUNDLE_TYPE" = "scpt" ]; then
					BUNDLE_PATH=$(/bin/echo "${FILE_PATH}" | /usr/bin/awk -F "/" '{ for (i=2; i<=(NF-4); i++) printf "/%s", $i }');
				else
					BUNDLE_PATH=$(/bin/echo "${FILE_PATH}" | /usr/bin/awk -F "/" '{ for (i=2; i<=(NF-3); i++) printf "/%s", $i }');
				fi
			else
				BUNDLE_TYPE="";
			fi
			if [[ "${BUNDLE_EXECUTABLES[@]}" =~ "$BUNDLE_TYPE" ]]; then
				# This is a bundle
				SUFFIX=$(/usr/bin/basename "${BUNDLE_PATH}" | /usr/bin/awk -F "." '{ print $NF }');
				BUNDLE_NAME=$(/usr/bin/basename -s .${SUFFIX} "${BUNDLE_PATH}");
				if [ -f "${BUNDLE_PATH}/Contents/Info.plist" ]; then
					VERSION=$(/usr/bin/defaults read "${BUNDLE_PATH}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null);
					if [ -z "$VERSION" ]; then
						VERSION=$(/usr/bin/defaults read "${BUNDLE_PATH}/Contents/Info.plist" CFBundleVersion 2>/dev/null);
					fi
				elif [ -f "${BUNDLE_PATH}/Contents/version.plist" ]; then
					VERSION=$(/usr/bin/defaults read "${BUNDLE_PATH}/Contents/version.plist" CFBundleShortVersionString 2>/dev/null);
				elif [ "$BUNDLE_TYPE" = "framework" ]; then
					FRAMEWORK_PATH=$(/usr/bin/dirname "${FILE_PATH}");
					if [ -f "${FRAMEWORK_PATH}/Resources/version.plist" ]; then
						VERSION=$(/usr/bin/defaults read "${FRAMEWORK_PATH}/Resources/version.plist" CFBundleShortVersionString 2>/dev/null);
						if [ -z "$VERSION" ]; then
							VERSION=$(/usr/bin/defaults read "${FRAMEWORK_PATH}/Resources/version.plist" CFBundleVersion 2>/dev/null);
							if [ -z "$VERSION" ]; then
								if [ -f "${FRAMEWORK_PATH}/Resources/Info.plist" ]; then
									if [ -z "$VERSION" ]; then
										VERSION=$(/usr/bin/defaults read "${FRAMEWORK_PATH}/Resources/Info.plist" CFBundleShortVersionString 2>/dev/null);
										if [ -z "$VERSION" ]; then
											VERSION=$(/usr/bin/defaults read "${FRAMEWORK_PATH}/Resources/Info.plist" CFBundleVersion 2>/dev/null);
										else
											VERSION="NULL";
										fi
									fi
								fi
							fi
						fi
					fi
				elif [ "$SUFFIX" = "dylib" ]; then
					VERSION=$(/Volumes/Source/otool -m -L "${FILE_PATH}" | /usr/bin/awk -v path="${DYLIB}" -F "current version " '$0 ~ path { print $2 }' | /usr/bin/tail -n 1 | /usr/bin/tr -d "\051");
				else
					VERSION="NULL";
				fi
				if [ -z "$VERSION" ]; then
					VERSION="NULL";
				fi
				UTI_PATH="${BUNDLE_PATH}";
			else
				# This is a binary file or script
				SUFFIX=$(/usr/bin/basename "${FILE_PATH}" | /usr/bin/awk -F "." '/\./ { print $NF }');
				VERSION="";
				if [ "$SUFFIX" = "dylib" ]; then
					DYLIB=$(/usr/bin/basename "${FILE_PATH}" | /usr/bin/awk -F "." '{ print $1 }');
					VERSION=$(/Volumes/Source/otool -m -L "${FILE_PATH}" | /usr/bin/awk -v path="${DYLIB}" -F "current version " '$0 ~ path { print $2 }' | /usr/bin/tail -n 1 | /usr/bin/tr -d "\051");
				elif [ "$SUFFIX" = "jar" ]; then
					PARENT_DIR=$(/usr/bin/dirname "${FILE_PATH}");
					pushd "${PARENT_DIR}" 1>/dev/null;
					/usr/bin/jar xf ${FILE_NAME} META-INF/MANIFEST.MF;
					VERSION=$(/bin/cat META-INF/MANIFEST.MF | /usr/bin/awk '/Manifest-Version:/ { print $NF }' | /usr/bin/tr -d "\015");
					if [ -z "$VERSION" ]; then
						VERSION="NULL";
					fi
					/bin/rm -R META-INF/MANIFEST.MF;
					popd 1>/dev/null;
				else
					# Try getting version
					if [ -z "$SUFFIX" ]; then
						VERSION=$(/usr/bin/what "${FILE_PATH}" | /usr/bin/awk -F "-" '/PROGRAM/ { print $NF; exit }');
						if [ -z "$VERSION" ]; then
							VERSION=$(/usr/bin/awk '/^# Version/ { print $NF }' "${FILE_PATH}");
							if [ -z "$VERSION" ]; then
								VERSION="NULL";
							fi
						fi
					elif [ "$SUFFIX" = "sh" -o "hook" ]; then
						VERSION=$(/usr/bin/awk '/^# Version/ { print $NF }' "${FILE_PATH}");
					fi
				fi
				UTI_PATH="${FILE_PATH}";
			fi
			UTI=$(/usr/bin/mdls -name kMDItemContentType "${UTI_PATH}" | /usr/bin/awk -F "= " '{ print $2 }' | /usr/bin/tr -d "\042"); # mdls -name kMDItemKind, kMDItemVersion
			set +x;
			OLD_IFS=$IFS;
			IFS=$'\n';
			set -x
			FILE_INFO=($(/usr/bin/file "${FILE_PATH}" | /usr/bin/awk -F ":[ \t]" '{ print $NF }'));
			if [ "${#FILE_INFO[@]}" -gt 1 ]; then
				FILE_TYPE=$(/usr/bin/file "${FILE_PATH}" 2>/dev/null | /usr/bin/awk -F ': *' '/arm64e/ {a = $NF} END{ print a }' | /usr/bin/tr -d '\011');
				if [ -z "$FILE_TYPE" ]; then
					FILE_TYPE=$(/usr/bin/file "${FILE_PATH}" 2>/dev/null | /usr/bin/awk -F ': *' '/arm64/ {a = $NF} END{ print a }' | /usr/bin/tr -d '\011');
					if [ -z "$FILE_TYPE" ]; then
						FILE_TYPE=$(/usr/bin/file "${FILE_PATH}" 2>/dev/null | /usr/bin/awk -F ': *' '/x86_64/ {a = $NF} END{ print a }' | /usr/bin/tr -d '\011');
						if [ -z "$FILE_TYPE" ]; then
							FILE_TYPE=$(/usr/bin/file "${FILE_PATH}" 2>/dev/null | /usr/bin/awk -F ': *' '/i386/ {a = $NF} END{ print a }' | /usr/bin/tr -d '\011');
							if [ -z "$FILE_TYPE" ]; then
								FILE_TYPE=$(/usr/bin/file "${FILE_PATH}" 2>/dev/null | /usr/bin/awk -F ': *' '/ppc/ {a = $NF} END{ print a }' | /usr/bin/tr -d '\011');
								if [ -z "$FILE_TYPE" ]; then
									FILE_TYPE=$(/usr/bin/file "${FILE_PATH}" 2>/dev/null | /usr/bin/awk -F ': *' '/ppc64/ {a = $NF} END{ print a }' | /usr/bin/tr -d '\011');
								fi
							fi
						fi
					fi
				fi
			else
				FILE_TYPE=${FILE_INFO[0]};
			fi
			set +x;
			IFS=$OLD_IFS;
			set -x;
			if [ -z "$UTI" ] || [[ "$UTI" =~ ^"dyn" ]] || [ "$UTI" = "(null)" ] || [ "$UTI" = "public.folder" ]; then
				case ${FILE_TYPE} in
					"a /usr/bin/perl script text executable") UTI="public.perl-script" ;;
					"a /usr/local/bin/python script text executable") UTI="public.python-script" ;;
					"a ruby script text executable") UTI="public.ruby-script" ;;
					"Bourne-Again shell script text executable") UTI="public.bash-script" ;;
					"C shell script text executable") UTI="public.csh-script" ;;
					"header for PowerPC PEF executable") UTI="com.apple.application-file" ;;
					"Mach-O 64-bit bundle arm64") UTI="public.unix-executable" ;;
					"Mach-O 64-bit bundle arm64e.x1") UTI="public.unix-executable" ;;
					"Mach-O 64-bit bundle arm64e") UTI="public.unix-executable" ;;
					"Mach-O 64-bit bundle x86_64") UTI="public.unix-executable" ;;
					"Mach-O 64-bit dynamically linked shared library arm64") UTI="com.apple.mach-o-dylib" ;;
					"Mach-O 64-bit dynamically linked shared library arm64e.x1") UTI="com.apple.mach-o-dylib" ;;
					"Mach-O 64-bit dynamically linked shared library arm64e") UTI="com.apple.mach-o-dylib" ;;
					"Mach-O 64-bit dynamically linked shared library ppc64") UTI="com.apple.mach-o-dylib" ;;
					"Mach-O 64-bit dynamically linked shared library x86_64") UTI="com.apple.mach-o-dylib" ;;
					"Mach-O 64-bit executable arm64") UTI="public.unix-executable" ;;
					"Mach-O 64-bit executable arm64e.x1") UTI="public.unix-executable" ;;
					"Mach-O 64-bit executable arm64e") UTI="public.unix-executable" ;;
					"Mach-O 64-bit executable x86_64") UTI="public.unix-executable" ;;
					"Mach-O 64-bit kext bundle x86_64") UTI="com.apple.mach-o-object" ;;
					"Mach-O bundle i386") UTI="com.apple.mach-o-bundle" ;;
					"Mach-O bundle ppc") UTI="com.apple.mach-o-bundle" ;;
					"Mach-O dynamically linked shared library i386") UTI="com.apple.mach-o-dylib" ;;
					"Mach-O dynamically linked shared library ppc") UTI="com.apple.mach-o-dylib" ;;
					"Mach-O executable i386") UTI="public.unix-executable" ;;
					"Mach-O object i386") UTI="com.apple.mach-o-object" ;;
					"Paul Falstad's zsh script text executable") UTI="public.zsh-script" ;;
					"POSIX shell script text executable") typeFromSuffix ;;
					"POSIX shell script text executable") UTI="public.shell-script" ;;
					"python script text executable") UTI="public.python-script" ;;
					*) typeFromSuffix ;;
				esac
			fi
			if [[ "$FILE_TYPE" =~ "Mach-O" ]]; then
				getLibInfo "${FILE_PATH}";
			fi
			# Get Man pages
			manualPage=$(/usr/bin/whatis "${FILE_NAME}" 2>&1 | /usr/bin/awk -v command="${FILE_NAME}" '$0 ~ "^" command { print $1; exit }' | /usr/bin/sed 's/,//g' | /usr/bin/grep -v ":");
			# Get Source
			executableCommand=$(/usr/bin/basename "${FILE_PATH}");
			source=$(/usr/bin/sqlite3 /Volumes/Source/reference_data.db "SELECT project FROM cmds_src WHERE command = \"${executableCommand}\";")
			if [ -z "${source}" ]; then
				source="NULL";
			else
				source="https://github.com/apple-oss-distributions/${source}";
			fi
			/usr/bin/sqlite3 /Volumes/Source/security.db "INSERT OR REPLACE INTO executables VALUES ('${FILE_PATH}','${FILE_MODE}','${FILE_OWNER}','${FILE_GROUP}','${CRC32}','${INSTALL_DATE}','${UTI}','${VERSION}','${manualPage}', '${source}');";
		fi
	done < "${APP_TEMP}"
/bin/rm "${APP_TEMP}";
fi

# Completed Security Database acquisition

# Collect system-wide diagnostic information
outputFile="$(/usr/bin/sw_vers -productVersion)_$(/usr/bin/sw_vers -buildVersion)_diag"
/usr/bin/sysdiagnose -f /Volumes/Source -A "${outputFile}" -b -u;

# Conclusion
identifier=$(/usr/sbin/diskutil list | /usr/bin/awk -v volume="${externalMedia}" '$0 ~ volume { print $NF }');
/usr/sbin/diskutil mount /dev/${identifier};
/bin/mkdir -p "/Volumes/${externalMedia}/${productVersion}_${buildVersion}";
/bin/cp /Volumes/Source/*_system_profile "/Volumes/${externalMedia}/${productVersion}_${buildVersion}/.";
/bin/cp /Volumes/Source/*_base_settings "/Volumes/${externalMedia}/${productVersion}_${buildVersion}/.";
/bin/cp /Volumes/Source/*_diag.tar.gz "/Volumes/${externalMedia}/${productVersion}_${buildVersion}/.";
/bin/cp /Volumes/Source/security.db "/Volumes/${externalMedia}/${productVersion}_${buildVersion}/.";
/bin/cp -R /private/etc "/Volumes/${externalMedia}/${productVersion}_${buildVersion}/.";
/bin/cp -R /private/var/root "/Volumes/${externalMedia}/${productVersion}_${buildVersion}/.";
/bin/cp /Library/Apple/System/Library/Receipts/com.apple.files.data-template.bom "/Volumes/${externalMedia}/${productVersion}_${buildVersion}/.";
/usr/bin/touch /private/var/db/.AppleSetupDone;
/sbin/shutdown -r now;
exit 0
