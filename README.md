# debian-ns
ns-setup
Simplifying Nightscout setup routine
Упрощение процедуры настройки Nightscout

These scripts are used to make private Nightscout setup as smooth as you could only imagine. It uses docker compose with nightscout itself, traefik for ssl termination and mongodb for your data. The docker-compose.yml is based on original Nightscout's one but modified a bit to make use of parameters entered during install scipt's execution.
Эти скрипты используются для того, чтобы сделать настройку Nightscout настолько простой, насколько вы только можете себе представить.
Скрипт использует docker compose с самим Nightscout, traefik для завершения ssl и mongodb для Ваших данных.
docker-compose.yml основан на оригинальном Nightscout, но немного изменен, в него подягиваюся переменные, введенные во время выполнения install scipt.

Prerequisites
First of all you need your VPS - virtal machine.
Для начала Вам нужно устанвоить Виртуальную машину на хосте, который Вы купили.

You need a domain name registered and attached to your VPS's public IP.
Вам нужно имя домена, котороый Вы прикрепите к своему VPS внешнему IP адресу.
(можно просто брать внешний IP flhtc Вашего VPS типа "ovz6.j69778864.pqj7n.vps.myjino.ru")

Also you need a ssh access to your VPS.
Всё, что Вам осталось, это запустить в крнсоли Вашего VPS скрипт SSH указанный ниже.

During the process, you need to enter the required parameters into the console when prompted.
Во время процесса Вам нужно ввести по запросу требуемые параметры в консоль.

SSH to your VPS

'bash <(wget -qO- https://raw.githubusercontent.com/mo211073bkp/Ubuntu-Docker/main/install.sh)' in console, press enter and follow installation instructions.


Enjoy your private nightscout installation
