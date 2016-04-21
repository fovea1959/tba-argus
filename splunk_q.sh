#!/bin/bash

curl -v -0 -k -u wegscd \
	-x "" \
	-o 20160404.csv \
	-d search='search earliest="04/04/2016:00:00:00" latest_time="04/04/2016:24:00:00" sourcetype=LdapAuditLog host=adcldapp3 OR host=adcldapp4 ldapaudit_verb=Search | rex "scope: (?<scope>.*)" | rex "base: (?<base>.*)" | rex "timeOnWorkQ: (?<timeOnWorkQ>.*)" | rex "rdbmLockWaitTime: (?<rdbmLockWaitTime>.*)" | rex "clientIOTime: (?<clientIOTime>.*)" | rex "filter: (?<filter>.*)" | rex "numberOfEntriesReturned: (?<numberOfEntriesReturned>.*)" | table _time ldapaudit_userid ldapaudit_clientip ldapaudit_operationresponsetime timeOnWorkQ rdbmLockWaitTime clientIOTime numberOfEntriesReturned filter base scope' \
	-d output_mode=csv \
	https://adculsplunkp2.whirlpool.com:8089/servicesNS/admin/search/search/jobs/export

curl -v -0 -k -u wegscd \
	-x "" \
	-o 20160411.csv \
	-d search='search earliest="04/11/2016:00:00:00" latest_time="04/11/2016:24:00:00" sourcetype=LdapAuditLog host=adcldapp3 OR host=adcldapp4 ldapaudit_verb=Search | rex "scope: (?<scope>.*)" | rex "base: (?<base>.*)" | rex "timeOnWorkQ: (?<timeOnWorkQ>.*)" | rex "rdbmLockWaitTime: (?<rdbmLockWaitTime>.*)" | rex "clientIOTime: (?<clientIOTime>.*)" | rex "filter: (?<filter>.*)" | rex "numberOfEntriesReturned: (?<numberOfEntriesReturned>.*)" | table _time ldapaudit_userid ldapaudit_clientip ldapaudit_operationresponsetime timeOnWorkQ rdbmLockWaitTime clientIOTime numberOfEntriesReturned filter base scope' \
	-d output_mode=csv \
	https://adculsplunkp2.whirlpool.com:8089/servicesNS/admin/search/search/jobs/export

curl -v -0 -k -u wegscd \
	-x "" \
	-o 20160418.csv \
	-d search='search earliest="04/18/2016:00:00:00" latest_time="04/18/2016:24:00:00" sourcetype=LdapAuditLog host=adcldapp3 OR host=adcldapp4 ldapaudit_verb=Search | rex "scope: (?<scope>.*)" | rex "base: (?<base>.*)" | rex "timeOnWorkQ: (?<timeOnWorkQ>.*)" | rex "rdbmLockWaitTime: (?<rdbmLockWaitTime>.*)" | rex "clientIOTime: (?<clientIOTime>.*)" | rex "filter: (?<filter>.*)" | rex "numberOfEntriesReturned: (?<numberOfEntriesReturned>.*)" | table _time ldapaudit_userid ldapaudit_clientip ldapaudit_operationresponsetime timeOnWorkQ rdbmLockWaitTime clientIOTime numberOfEntriesReturned filter base scope' \
	-d output_mode=csv \
	https://adculsplunkp2.whirlpool.com:8089/servicesNS/admin/search/search/jobs/export
