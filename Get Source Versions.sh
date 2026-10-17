# Get Source

activeNetworkServices=$(/usr/bin/mktemp -t tmp);
/usr/sbin/networksetup -listallnetworkservices | /usr/bin/grep -v '*' > "${activeNetworkServices}";
while read service; do
	interface=$(/usr/sbin/networksetup -listallhardwareports | /usr/bin/grep -A 1 "${service}" | /usr/bin/awk '/^Device:/ { print $NF }');
	interfaceStatus=$(/sbin/ifconfig -v "${interface}" | /usr/bin/awk '/status:/ { print $NF }');
	if [ "${interfaceStatus}" = "active" ]; then
		proxyServer=$(/usr/sbin/networksetup -getsecurewebproxy "${service}" | /usr/bin/awk '/^Server:/ { print $NF }');
		proxyPort=$(/usr/sbin/networksetup -getsecurewebproxy "${service}" | /usr/bin/awk '/^Port:/ { print $NF }');
		webProxy="${proxyServer}:${proxyPort}";
		break;
	fi
done < "${activeNetworkServices}"
/bin/rm -f "${activeNetworkServices}";

executableCommand=$(/usr/bin/basename "${FILE_PATH}");
source="https://github.com/apple-oss-distributions/$(/usr/bin/sqlite3 /Volumes/Source/reference_data.db "SELECT project FROM cmds_src WHERE command = \"${executableCommand}\";")";
if [ -z "${source}" ]; then
	source="NULL";
fi


	#/usr/bin/curl -x "${webProxy}" --proxy-negotiate -U : https://raw.githubusercontent.com/apple-oss-distributions/distribution-macOS/refs/heads/rel/macOS-26/release.json -O;

	# Verify release version
	#releaseVersion=$(/usr/bin/jq -r ".release" release.json | /usr/bin/awk '{ print $NF }');

	#https://github.com/apple-oss-distributions/distribution-macOS/tree/macos-"${osVersion}"

	#for project in $(/usr/bin/jq -r ".projects[]|.project" /Users/Shared/release.json); do
		#projectVersion=$(/usr/bin/jq -r '.tag' <<< $(/usr/bin/jq -r --arg project "${project}" '.projects[]| select(.project == $project)' release.json) | /usr/bin/awk -F "-" '{ print $NF }');
	#	/usr/bin/curl -x "${webProxy}" --proxy-negotiate -U : https://github.com/apple-oss-distributions/${project}
	#done
