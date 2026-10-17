# macOS Deep Inspection process

1. Boot into Recovery mode

- Hold down the power button and wait for "Continue holding for startup options…" ->  "Loading startup options…" 
- Select Options, then click Continue.
- Select Language
- Open Terminal from the Utilities menu (Shift + Command + T)

2. In Terminal run:

    `dscl -f /Volumes/Macintosh\ HD/private/var/db/dslocal/nodes/Default localhost -passwd /Local/Default/Users/root`

    Enter New Password

3. Reboot

    `shutdown -r now`

4. Click the Continue button and select Language, then select Region

5. Invoke the Terminal with hot keys Control + Option + Command + T once Language Choose exits.

6. Enable Automation for Terminal

- Switch to the root user account
	
    `su root`

- In Terminal enter: `/usr/bin/osascript -e 'tell application "System Settings"' -e 'activate' -e 'reveal pane id "com.apple.settings.PrivacySecurity.extension"' -e 'get anchor of pane "Privacy & Security"' -e 'end tell' 2>/dev/null`
- Click the Allow button in the "Terminal" wants access to control "System Settings" window.

7. Add Terminal to the Full Disk Access

- Select Full Disk Access
- Click the + button
- Enter root credentials
- Click the Modify Settings button
- Navigate to /Application/Utilities and select Terminal.app
- Click the Open button
- Click Quit and Reopen Terminal

# Add app management?
# Add File & Folders Terminal Removable Volumes or just use Full Disk Access

9. Open Terminal

10. Switch to the root user account
	
    `su root`

    Enter the password for root

11. Insert USB drive with the Deep Inspection disk image and mount it

    `diskutil list`

    Note the disk number and slice number for the USB drive and mount the device

    <code>diskutil mount /dev/disk<i>n</i>s<i>n</i></code>

12. 
Open System Settings

<code>open /Volumes/Macintosh\ HD/System/Applications/System\ Settings.app</code>

Load the profile

<code>/usr/bin/open /Volumes/<i>USBdrive</i>/com.apple.logging.ManagedClient.mobileconfig</code>

Profile Downloaded click the OK button

Select Device Management from the General pane of System Settings 

Under downloaded, double click Enable Unified Log Private Data

Click the install button

At the Are you sure you want to install… click the Install button

Enter root credentials

8. Quit System Settings.


    
12. Copy the disk image

    <code>cp /Volumes/<i>USBdrive</i>/Source.dmg /Users/Shared/Source.dmg</code>

13. Mount the disk image

    `diskutil image attach /Users/Shared/Source.dmg`

14. Change working directory to the Source volume

    `cd /Volumes/Source`

15. Run the Deep Inspection script

    `/bin/sh macOSDeepInspection.sh`

    `/bin/sh -x macOSDeepInspection.sh 2>&1 | tee /Users/Shared/macOSDeepInspection.log`


    The Mac will reboot when the script completes

16. Reset Mac when the Mac reboots

- Run through setup until network then select My Mac does not connect to Network
- Force Quit Finder
- Run System Settings -> General -> Transfer or Reset -> Erase All Content and Settings
- Authenticate with root credentials



File System Directory Structure
Files with out owners
Files with out groups
Directories with 'Allow write by others'
Directories with Sticky Bits
Directories with rootless
Kernel State
Running Processes
Kernel Extensions
System Extensions
Launch Items
Running Launch Items
Socket Listeners
Open ports
Launch Services Cache
Disabled Launch Services
Launchd System Domain
Launchd User Domain
Local Users
Local Groups
Environment Variables
Environment Variables
Energy Settings
Sudo Configuration
sudoers
OpenSSH Configuration
ssh configuration
sshd configuration
Pluggable Authentication Module Configurations
system log configuration
Endpoint Security Events
LDAP configuration
System Integrity Protection
System Roots
Local Preferences
Boot Tasks
Host Info
NSServices Restrictions
BSM Audit Configuration
File Download Assessment
Transparency Consent Services
SSH Server configuration
Privacy Database
Transparency Consent and Control Services 
Security-Keychain Diagnostics
System Statistics
Terminal Supported Locales
Supported Character sets
Header files
Registered UTIs
Spotlight Metadata Attributes
Supported URL Schemes
System Settings AppleScript Anchors
Feature Flags
ShareKit Extensions
