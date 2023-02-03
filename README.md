# Django site

Докеризированный сайт на Django для экспериментов с Kubernetes.

Внутри конейнера Django запускается с помощью Nginx Unit, не путать с Nginx. Сервер Nginx Unit выполняет сразу две функции: как веб-сервер он раздаёт файлы статики и медиа, а в роли сервера-приложений он запускает Python и Django. Таким образом Nginx Unit заменяет собой связку из двух сервисов Nginx и Gunicorn/uWSGI. [Подробнее про Nginx Unit](https://unit.nginx.org/).

## Как запустить dev-версию

Запустите базу данных и сайт:

```shell-session
$ docker-compose up
```

В новом терминале не выключая сайт запустите команды для настройки базы данных:

```shell-session
$ docker-compose run web ./manage.py migrate  # создаём/обновляем таблицы в БД
$ docker-compose run web ./manage.py createsuperuser
```

Для тонкой настройки Docker Compose используйте переменные окружения. Их названия отличаются от тех, что задаёт docker-образа, сделано это чтобы избежать конфликта имён. Внутри docker-compose.yaml настраиваются сразу несколько образов, у каждого свои переменные окружения, и поэтому их названия могут случайно пересечься. Чтобы не было конфликтов к названиям переменных окружения добавлены префиксы по названию сервиса. Список доступных переменных можно найти внутри файла [`docker-compose.yml`](./docker-compose.yml).

## Переменные окружения

Образ с Django считывает настройки из переменных окружения:

`SECRET_KEY` -- обязательная секретная настройка Django. Это соль для генерации хэшей. Значение может быть любым, важно лишь, чтобы оно никому не было известно. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#secret-key).

`DEBUG` -- настройка Django для включения отладочного режима. Принимает значения `TRUE` или `FALSE`. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#std:setting-DEBUG).

`ALLOWED_HOSTS` -- настройка Django со списком разрешённых адресов. Если запрос прилетит на другой адрес, то сайт ответит ошибкой 400. Можно перечислить несколько адресов через запятую, например `127.0.0.1,192.168.0.1,site.test`. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#allowed-hosts).

`DATABASE_URL` -- адрес для подключения к базе данных PostgreSQL. Другие СУБД сайт не поддерживает. [Формат записи](https://github.com/jacobian/dj-database-url#url-schema).


## Как задеплоить в Kubernetes 

#### 1. Чтобы сделать это локально, вам потребуется установить
- [Docker](https://docs.docker.com/engine/install/)
- [Kubernetes (kubectl)](https://kubernetes.io/ru/docs/tasks/tools/install-kubectl/) 
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [Virtualbox](https://www.virtualbox.org/wiki/Downloads)

#### 2. Запустите minikube
```shell
minikube start --driver=virtualbox
minikube addons enable ingress
```

#### 3. Создайте образ приложения
Будучи в корне проекта выполните команду:
```shell
make build
```

#### 4. Настройте базу данных и запустите в K8s
В файле `k8s/dj_app_postgres_config.yml` для PostgreSQL запишите свои значения:
```shell
data:
  POSTGRES_DB: ***
  POSTGRES_USER: ***
  POSTGRES_PASSWORD: ***
```
Запустите командой
```shell
make deploy-db
```


#### 5. Настройте и запустите Django в K8s
Для начала узнайте IP(далее DATABASE_URL), в котором живет БД. Выполните команду:
```shell
k get pod postgres --template '{{.status.podIP}}
```

Заполните файл `k8s/dj_app_config.yml` для Django:

```shell
SECRET_KEY: ***
DATABASE_URL: "postgres://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{DATABASE_URL}:5432/{POSTGRES_DB}"
```

Деплоим командой:
```shell
make deploy-app
```

В кластере крутится CronJob'a, которая раз в месяц чистит сессии в Django. Если необходимо запустить принудительно,
 то используем команду:
```shell
make clear-sessions
```