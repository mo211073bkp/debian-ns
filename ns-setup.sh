#!/bin/bash
get update
apt-get install -y ca-certificates

GREEN='\033[0;32m'
NORMAL='\033[0m'
YELLOW='\033[0;33m'

function checkIt()
{
systemctl -q is-active $1  && echo -e $1 $GREEN good $NORMAL || echo -e $1 $YELLOW fail $NORMAL
}

echo -e $GREEN Запуск установки пакетов для работы Nightscout на сервере Debian 10, NodeJs 12 $NORMAL 


read -p "Обновляем и доустанавливаем программы для работы сервера? ([y/Y] для выполнения)"$'\n'  -n 1 -r
echo -e "\n"
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo -e $GREEN Обновление и доустановка ПО $NORMAL 
apt-get update &> /dev/null
apt-get install -y sudo curl mc nano git mongo-tools &> /dev/null
fi


read -p "Собираем Nightscout, устанавливаем пакеты для работы Nightscout? Время выполнения 5-7минут! ([y/Y] для выполнения)"$'\n' -n 1 -r
echo -e "\n"
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo -e $YELLOW ждите, все работает, не зависло... $NORMAL  
cd /opt 
mkdir nightscout
cd nightscout
mkdir cgm-remote-monitor
git clone https://github.com/nightscout/cgm-remote-monitor.git -b dev &> /dev/null
cd cgm-remote-monitor
npm install --unsafe-perm &> /dev/null
npm audit fix &> /dev/null
npm install jsdom &> /dev/null
fi

read -p "Настройка монго, создание и запуск сервисов, конфигурации и тп. Пропустите, если нужен только импорт из старой базы  ([y/Y] для выполнения)"$'\n' -n 1 -r
echo -e "\n"
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo -e "$GREEN ЗАПОЛНИТЕ ДАННЫЕ ДЛЯ ЭТОГО СЕРВЕРА. ЗАПИШИТЕ ИХ. $NORMAL" 

read -p "$( echo -e $YELLOW Имя пользователя базы данных MONGO: $NORMAL)"  MONGO_DB_USER
read -p "$( echo -e $YELLOW Пароль пользователя базы данных MONGO: $NORMAL)"  MONGO_DB_USER_PASS
read -p "$( echo -e $YELLOW Название базы данных MONGO \( Nightscout \): $NORMAL)" MONGO_DB_NAME
read -p "$( echo -e $YELLOW API_SECRET - пароль для работы Nightscout, минимум 12 символов!: $NORMAL)" MONGO_API_SECRET
read -p "$( echo -e $YELLOW Доменное имя, по которому будет доступен Nightscout: $NORMAL)" BASE_URL_USER

touch /opt/nightscout/cgm-remote-monitor/start.sh
echo -n > /opt/nightscout/cgm-remote-monitor/start.sh

echo -e $GREEN Создаем файл начальной конфигурации nightscout $NORMAL
echo "#!/bin/bash
export DISPLAY_UNITS="mmol"
export MONGO_CONNECTION="mongodb://$MONGO_DB_USER:$MONGO_DB_USER_PASS@localhost:27017/$MONGO_DB_NAME"
export PORT=1337
export API_SECRET="$MONGO_API_SECRET"
export PUMP_FIELDS="reservoir battery status"
export DEVICESTATUS_ADVANCED=true
export ENABLE="careportal basal cage sage boluscalc rawbg iob bwp bage mmconnect bridge openaps pump iob maker"
export TIME_FORMAT=24
export BASE_URL="$BASE_URL_USER"
export INSECURE_USE_HTTP=true

export ALARM_HIGH=off
export ALARM_LOW=off
export ALARM_TIMEAGO_URGENT=off
export ALARM_TIMEAGO_URGENT_MINS=30
export ALARM_TIMEAGO_WARN=off
export ALARM_TIMEAGO_WARN_MINS=15
export ALARM_TYPES=simple
export ALARM_URGENT_HIGH=off
export ALARM_URGENT_LOW=off
export AUTH_DEFAULT_ROLES=denied
export BG_HIGH=10
export BG_LOW=4
export BG_TARGET_BOTTOM=4
export BG_TARGET_TOP=10
export BRIDGE_MAX_COUNT=1
export BRIDGE_PASSWORD=
export BRIDGE_SERVER=EU
export BRIDGE_USER_NAME=
export CUSTOM_TITLE=Nightscout
export DISABLE=
export MONGO_COLLECTION=entries
export NIGHT_MODE=on
export OPENAPS_ENABLE_ALERTS=true
export OPENAPS_FIELDS='status-symbol status-label iob meal-assist rssi'
export OPENAPS_RETRO_FIELDS='status-symbol status-label iob meal-assist rssi'
export OPENAPS_URGENT=60
export OPENAPS_WARN=20
#export PAPERTRAIL_API_TOKEN=some_token
export PUMP_ENABLE_ALERTS=true
export PUMP_FIELDS='battery reservoir clock status'
export PUMP_RETRO_FIELDS='battery reservoir clock status'
export PUMP_URGENT_BATT_V=1.3
export PUMP_URGENT_CLOCK=30
export PUMP_URGENT_RES=10
export PUSHOVER=
export SHOW_FORECAST=openaps
export SHOW_PLUGINS='openaps pump iob sage cage careportal'
export SHOW_RAWBG=noise
export THEME=colors
export LANGUAGE=ru

node server.js" >> /opt/nightscout/cgm-remote-monitor/start.sh

sudo chmod +x start.sh

echo -e Файл конфигурации nightscout - /opt/nightscout/cgm-remote-monitor/start.sh
echo -e Строка подключения - mongodb://$MONGO_DB_USER:$MONGO_DB_USER_PASS@$BASE_URL_USER:27017/$MONGO_DB_NAME

echo -e $GREEN Создаем начальную конфигурацию базы MONGO $NORMAL


mongo <<EOF 
    use $MONGO_DB_NAME
    db.createUser({user: "$MONGO_DB_USER", pwd: "$MONGO_DB_USER_PASS", roles: ["readWrite"]})
    db.createCollection("entries")
    quit()
EOF


MONGO_DB_ADMIN="NightscoutMongoAdmin"

read -p "$( echo -e $YELLOWПароль администратора базы данных \(не пользователя\): $NORMAL)" MONGO_DB_ADMIN_PASS
mongo <<EOF 
    use admin
    db.createUser({user: "$MONGO_DB_ADMIN", pwd: "$MONGO_DB_ADMIN_PASS", roles:[{ role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]})
    quit()
EOF

sText="authorization: enabled"
if ! grep -q "$sText" /etc/mongod.conf
then
echo "security:
  authorization: enabled" >> /etc/mongod.conf
echo 'Авторизация включена в конфигурации монго'

fi

systemctl enable mongod
systemctl restart mongod

touch /etc/systemd/system/nightscout.service
echo -n > /etc/systemd/system/nightscout.service

echo "[Unit]
Description=Nightscout Service      
After=network.target
[Service]
Type=simple
WorkingDirectory=/opt/nightscout/cgm-remote-monitor
ExecStart=/opt/nightscout/cgm-remote-monitor/start.sh
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/nightscout.service

#systemctl daemon-reload
systemctl enable nightscout.service
systemctl start nightscout.service 

fi

echo -e "\n"
echo -e "\n"
read -p "Если нужно импортировать старую базу в новую ([y/Y] для выполнения)"$'\n' -n 1 -r
echo -e "\n"
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo -e $GREEN Попробуем перенести старую базу данных в новую, нужны старые данные $NORMAL

read -p "Путь к старой базе данных MONGO ( типа _some_adress_from_env.mlab.com): " OLD_MONGO_DB_PATH
read -p "Порт старой базы данных MONGO : " OLD_MONGO_DB_PORT
read -p "Название старой базы данных MONGO: " OLD_MONGO_DB_NAME
read -p "Пользователь старой базы: " OLD_MONGO_USER
read -p "Пароль пользователя старой базы (не SECRET_API, а пароль пользователя): " OLD_MONGO_USER_PASS

if [[ ! $MONGO_DB_NAME ]]; then
read -p "Название НОВОЙ базы данных MONGO (в которую переносим): " OLD_MONGO_DB_NAME
fi
#экспортируем старую базу данных
mongodump -h $OLD_MONGO_DB_PATH --port $OLD_MONGO_DB_PORT -d $OLD_MONGO_DB_NAME  -u $OLD_MONGO_USER -p $OLD_MONGO_USER_PASS
mongorestore -d $MONGO_DB_NAME dump/$OLD_MONGO_DB_NAME
fi

#systemctl daemon-reload
checkIt "mongod.service"
checkIt "nightscout.service"
