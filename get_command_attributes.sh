#!/bin/sh
section=$(/bin/pwd) 
for FILE in $(ls -1); do
COMMAND=$(/usr/bin/basename -s .${section[-1]} ${FILE});
HAS_FILES=$(/usr/bin/man ${COMMAND} 2>/dev/null | /bin/cat | /usr/bin/grep -E '^[A-Z]' | /usr/bin/grep "FILES");
HAS_ENV=$(/usr/bin/man ${COMMAND} 2>/dev/null | /bin/cat | /usr/bin/grep -E '^[A-Z]' | /usr/bin/grep "ENVIRONMENT");
if [ ! -z ${HAS_FILES} ] || [ ! -z ${HAS_ENV} ]; then
/bin/echo "${COMMAND} ${HAS_FILES} ${HAS_ENV}";
fi
done
