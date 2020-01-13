#!/bin/bash

/etc/init.d/postgresql start

runuser -l postgres -c 'createuser -DRS root'
runuser -l postgres -c 'createdb -O root gvmd'
runuser -l postgres -c 'psql gvmd -c "create role dba with superuser noinherit;"'
runuser -l postgres -c 'psql gvmd -c "grant dba to root;"'
runuser -l postgres -c 'psql gvmd -c "create extension \"uuid-ossp\";"'
