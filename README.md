# docker-radicale
The Radicale CalDAV/CardDAV server as a Docker container.

## Quickstart
Create the radicale data directory containing a minimal configuraion. We assume the directory _/srv/radicale/data_.

Minimal configuration _/srv/radicale/data/config.ini_:
```ini
[auth]
type = htpasswd
# note: that's a path inside the container
htpasswd_filename = /var/radicale/users
# encryption method used in the htpasswd file
htpasswd_encryption = bcrypt

[server]
hosts = 0.0.0.0:8000

[storage]
filesystem_folder = /var/radicale/collections
```

Run the docker image, and connect it to the HTTP port 80:
```shell
docker run  -v /srv/radicale/data:/var/radicale -p80:8000  -n radicale xlrl/radicale
```

Create some users:
```shell
# Create a new htpasswd file with the user "user1"
docker exec -ti radicale htpasswd -B -c /var/radicale/users user1
New password:
Re-type new password:
# Add another user
docker exec -ti radicale htpasswd -B -c /var/radicale/users user2
New password:
Re-type new password:
```

Now point your web browser to the address of the docker server. You should
be presented with the Radicale login.

## Configuration using docker-compose

To launch your container with docker-compose you can use this sample :
```
version: '3.8'

services: 
  radicale:
    build: .
    container_name: radicale
    environment: 
      - GIT_REPOSITORY=https://user:password@github.com/user/repo
      - GIT_USERNAME=username
      - GIT_EMAIL=usermail@mail.com
      - RADICALE_USER=username
      - RADICALE_PASS=userpassword
    ports: 
      - "8000:8000"
    volumes: 
      - /tmp/radicale:/var/radicale
```
Environment variables :
|Variable|Descriptions|
|------|------|
|GIT_REPOSITORY| Your git repo with your username or your password if it's a private repo |
|GIT_USERNAME|Your name for the git signature|
|GIT_EMAIL|Your mail for the git signature|
|RADICALE_USER|Your radicale user|
|RADICALE_PASS|The password for your user|


## Versioning
Version the changes to your __radicale__ data your changes using __GIT__.

Create a _.gitignore_ file in _srv/radicale/data:
```
.Radicale.cache
.Radicale.lock
.Radicale.tmp-*
```

Configure the __GIT__ hook in _/srv/radicale/data/config.ini_:
```ini
[storage]
filesystem_folder = /var/radicale/collections
hook = git add -A && (git diff --cached --quiet || git commit -m "Changes by "%(user)s)
```

Initialize the __GIT__ repository:
```shell
docker@myhost ~ # cd /srv/radicale/data
docker@myhost /srv/radicale/data # git init
Initialized empty Git repository in /srv/radicale/data/.git/
docker@myhost /srv/radicale/data # git add .
docker@myhost /srv/radicale/data # git commit -m "Initial commit."
[master (root-commit) abcdefab] Initial commit.
 5 files changed, 17 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 config.ini
 create mode 100644 users
