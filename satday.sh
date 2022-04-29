#!/bin/bash

# Перенаправляем вывод в лог
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/barman/cronbackup.log 2>&1

# Формируем дату\время по шаблону
today=`date '+%Y.%m.%d_%H:%M:%S'`;

###### ServerName указываем через пробел
ServName='PGSQL1 PGSQL2 PGQL3 PGSQL4 PGSQL5 PGSQL311 PGSQL334 PGSQL345 PGSQL514'
######

#Читаем строку в массив для перебора
IFS=' ' read -a arr <<< $ServName

# удаляем симлинки дневных бэкапов и создаем  субботние
function remove_daily_symlinks{
for S in ${arr[@]}; do

    echo $today remove simlink to daily backup
    rm /var/lib/barman/$S
    echo $today create simlink to sat backup
    ln -s /mnt/ss02/Saturday/$S /var/lib/barman/$S
done
unset S # освобождаем переменную
}

#переключаем текущую сессию wal для копирования
function switch_wal{
for S in ${arr[@]}; do

    echo $today switching WAL $S
    barman switch-wal $S
done
unset S
}

# удаляем симлинки субботних бэкапов и создаем ежедневные
function remove_sat_symlinks{
for S in ${arr[@]}; do

    echo $today remove sat symlink
    rm /var/lib/barman/$S
    echo $today create daily backup simlink
    ln -s /mnt/ss02/$S /var/lib/barman/$S

done
unset S
}

################################

remove_daily_symlinks
switch_wal
barman backup all
remove_sat_symlinks
switch_wal
