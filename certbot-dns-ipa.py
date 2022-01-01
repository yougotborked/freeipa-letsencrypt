#!/usr/bin/python3

import os
from dns import resolver
from ipalib import api
from ipapython import dnsutil

certbot_domain = os.environ['CERTBOT_DOMAIN']
certbot_validation = os.environ['CERTBOT_VALIDATION']
if 'CERTBOT_AUTH_OUTPUT' in os.environ:
    command = 'dnsrecord_del'
else:
    command = 'dnsrecord_add'

validation_domain = f'_acme-challenge.{certbot_domain}'
fqdn = dnsutil.DNSName(validation_domain).make_absolute()
zone = dnsutil.DNSName(resolver.zone_for_name(fqdn))
name = fqdn.relativize(zone)

api.bootstrap(context='cli')
api.finalize()
api.Backend.rpcclient.connect()

api.Command[command](zone, name, txtrecord=[certbot_validation], dnsttl=60)