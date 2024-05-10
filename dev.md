
### Misc supervisor 
```
# Add alias to avoid having to specify the configuration file each time
echo "export SUPERVISOR_CONF=\$HOME'/conf/supervisord.conf'" >> $HOME/.bashrc
echo "alias supervisord='supervisord -c \$SUPERVISOR_CONF'" >> $HOME/.bashrc
echo "alias supervisorctl='supervisorctl -c \$SUPERVISOR_CONF'" >> $HOME/.bashrc

source ~/.bashrc

# Start supervisord on boot
(crontab -l 2>/dev/null; echo "@reboot supervisord -c $HOME/conf/supervisord.conf") | crontab -
# sudo -u username bash -c '(crontab -l 2>/dev/null; echo "@reboot supervisord -c $HOME/conf/supervisord.conf") | crontab -'

# Supervisor

supervisorctl -c $SUPERVISOR_CONF reread
supervisorctl -c $SUPERVISOR_CONF update
supervisorctl -c $SUPERVISOR_CONF start "laravel-worker:*"
supervisorctl -c $SUPERVISOR_CONF start all
supervisorctl -c $SUPERVISOR_CONF status


supervisord -c $SUPERVISOR_CONF
supervisorctl -c $SUPERVISOR_CONF status



## bashrc
export SUPERVISOR_CONF=/home/toolbox/conf/supervisord.conf

alias supervisorctl='supervisorctl -c /home/toolbox/conf/supervisord.conf'
```

### Uberspace sample supervisor conf
```
# UBERSPACE
# supervisord config for each user's supervisord instance.

[unix_http_server]
file=/run/supervisord/%(ENV_USER)s/supervisor.sock
username = dummy
password = dummy

[supervisorctl]
serverurl=unix:///run/supervisord/%(ENV_USER)s/supervisor.sock
username = dummy
password = dummy

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisord]
logfile=%(ENV_HOME)s/logs/supervisord.log
logfile_maxbytes=20MB
logfile_backups=3
loglevel=debug
pidfile=/dev/null
childlogdir=%(ENV_HOME)s/tmp
directory=%(ENV_HOME)s
identifier=supervisor_%(ENV_USER)s
nodaemon=true
strip_ansi=true
environment=PATH="/home/%(ENV_USER)s/bin:/home/%(ENV_USER)s/.local/bin:/opt/uberspace/etc/%(ENV_USER)s/binpaths/ruby$

[include]
files = %(ENV_HOME)s/etc/services.d/*.ini
```
