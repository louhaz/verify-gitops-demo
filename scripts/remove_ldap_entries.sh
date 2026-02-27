#!/bin/bash

# Use below command to find any other entries
# idsldapsearch -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 -D cn=root -w <password> -b "secAuthority=Default" cn=* cn

if [ -z "$1" ]; then
    echo "Add cn=root password as argument"
    exit 1
fi

idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Subdomains,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Resources,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=ResourceGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Default,cn=Policies,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=SecurityGroup,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=SecurityGroup,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=ivacld-servers,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=ivacld-servers,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=remote-acl-users,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=remote-acl-users,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=SecurityMaster,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Policy,cn=Policies,principalName=sec_master,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Policy,cn=Policies,principalName=ivmgrd/master,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Policy,cn=Policies,principalName=default-webseald/ivia-config,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Policies,principalName=sec_master,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Policies,principalName=ivmgrd/master,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Policies,principalName=default-webseald/ivia-config,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Policies,principalName=test-webseald/ivia-config,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=ivmgrd-servers,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=ivmgrd-servers,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=iv-admin,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=iv-admin,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=secmgrd-servers,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=secmgrd-servers,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=webseal-servers,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=webseal-servers,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=webseal-mpa-servers,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=webseal-mpa-servers,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=su-excluded,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=su-excluded,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=su-admins,cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=su-admins,cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=ivmgrd/master,cn=SecurityDaemons,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=default-webseald/ivia-config,cn=SecurityDaemons,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 principalName=ivmgrd/master,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 principalName=sec_master,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 principalName=default-webseald/ivia-config,cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Users,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Groups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=SecurityGroups,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=Policies,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 cn=SecurityDaemons,secAuthority=Default
idsldapdelete -D cn=root -w $1 -Z -K /home/idsldap/idsslapd-idsldap/etc/server.kdb -h 127.0.0.1 -p 9636 secAuthority=Default