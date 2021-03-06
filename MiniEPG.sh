#!/bin/bash

# Download http://epgadmin.tvblob.com/api/services
# Loop in keys and get EPG

[ -f services.xml ] || wget -O services.xml http://epgadmin.tvblob.com/api/services
[ -f epg.v2.sqlite.zip ] || wget http://epgadmin.tvblob.com/static/epg.v2.sqlite.zip
unzip -o epg.v2.sqlite.zip

python xml2json.py -t xml2json --pretty -o services.json services.xml

echo "-- SQL per EPG BBox" > MiniEPG-prima.sql
echo "-- Operazioni Preliminari" >> MiniEPG-prima.sql
echo "-- " >> MiniEPG-prima.sql

echo "DROP INDEX 'show_idx' ;"        >> MiniEPG-prima.sql
echo "DELETE FROM show ;"             >> MiniEPG-prima.sql
echo "-- PRAGMA journal_mode = MEMORY; " >> MiniEPG-prima.sql
echo "-- BEGIN TRANSACTION; "            >> MiniEPG-prima.sql
sqlite3 epg.v2.sqlite < MiniEPG-prima.sql

grep key services.json | tr -d '",' | while read Key Channel
do
#    echo $Channel
    wget -q -O $Channel.0.xml http://epgadmin.tvblob.com/api/$Channel/programmes/schedules/today
    [ -f $Channel.0.xml  ] && python xml2json.py -t xml2json -o $Channel.0.json $Channel.0.xml
    [ -f $Channel.0.json ] && python MiniEPG.py $Channel.0.json
    wget -q -O $Channel.1.xml http://epgadmin.tvblob.com/api/$Channel/programmes/schedules/tomorrow
    [ -f $Channel.1.xml  ] && python xml2json.py -t xml2json -o $Channel.1.json $Channel.1.xml
    [ -f $Channel.1.json ] && python MiniEPG.py $Channel.1.json

done

echo "-- SQL per EPG BBox" > MiniEPG-dopo.sql
echo "-- Operazioni di Conclusione" >> MiniEPG-dopo.sql
echo "-- " >> MiniEPG-dopo.sql
echo "UPDATE show SET is_premiere=0, is_hd=0, is_premium=0, is_live=0, is_lis=0, is_subtitled=0 ;" >> MiniEPG-dopo.sql
echo "-- END TRANSACTION; "              >> MiniEPG-dopo.sql
echo 'CREATE INDEX "show_idx" ON show (channel ASC, end_date ASC, type ASC);' >> MiniEPG-dopo.sql
sqlite3 epg.v2.sqlite < MiniEPG-dopo.sql


zip -u epg.v2.sqlite.zip epg.v2.sqlite





# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

