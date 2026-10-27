#!/bin/sh
# vim:sw=4:ts=4:et
#
# Make sure nginx.conf loads the PageSpeed dynamic module, so that `pagespeed`
# directives work even when a custom nginx.conf without a load_module line is
# mounted into the container. Set NGINX_PAGESPEED_AUTOLOAD=0 to disable.

set -e

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

ME=$(basename "$0")
CONF_FILE="/etc/nginx/nginx.conf"
MODULE="modules/ngx_pagespeed_module.so"

if [ "${NGINX_PAGESPEED_AUTOLOAD:-1}" = "0" ]; then
    entrypoint_log "$ME: info: NGINX_PAGESPEED_AUTOLOAD=0, not touching $CONF_FILE"
    exit 0
fi

if [ ! -f "/etc/nginx/$MODULE" ]; then
    entrypoint_log "$ME: info: /etc/nginx/$MODULE not found"
    exit 0
fi

if [ ! -f "$CONF_FILE" ]; then
    entrypoint_log "$ME: info: $CONF_FILE is not a file or does not exist"
    exit 0
fi

# already loaded (image default, container restart, or user-provided config)
if grep -Eq '^[[:space:]]*load_module[[:space:]]+.*ngx_pagespeed_module\.so' "$CONF_FILE"; then
    entrypoint_log "$ME: info: PageSpeed module already loaded in $CONF_FILE"
    exit 0
fi

# check if the file can be modified, e.g. not on a r/o filesystem or :ro bind mount
touch "$CONF_FILE" 2>/dev/null || {
    entrypoint_log "$ME: warn: can not modify $CONF_FILE (read-only?); add 'load_module $MODULE;' to it yourself"
    exit 0
}

# write in place: a bind-mounted file can not be replaced by rename (sed -i)
TMP=$(mktemp)
{ echo "load_module $MODULE;"; cat "$CONF_FILE"; } > "$TMP"
cat "$TMP" > "$CONF_FILE"
rm -f "$TMP"

entrypoint_log "$ME: info: Enabled 'load_module $MODULE;' in $CONF_FILE"

exit 0
