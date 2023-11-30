
# Operational Notes for Dantewiki


## Security

TODO


## Backup

For backup, we need to have a backup drop site. Possibilities are:
* An ssh drop point
* An Amazon AWS S3 drop point
* An Amazon AWS Glaicer drop point
* ...

### Preparing an ssh drop point

#### Alternative 1: Method using the shell of the user
1. Create a shell script that exits immediately. For example: /bin/nologin_shell.

```
#!/bin/sh
exit 0
```

2. Make the Script Executable: `sudo chmod +x /bin/nologin_shell`

3. Set the shell of the backup user to this shell script:

sudo usermod -s /bin/nologin_shell username

This change means that when the user tries to ssh into the server, the nologin_shell script will execute and immediately exit, effectively preventing an interactive login.

4. Test scp to ensure it still works for the user.

#### Alternative 2: Method using sshd_config

Another method is to use the ForceCommand directive in the sshd_config file. This method is more complex but offers more flexibility. This configuration forces the execution of scp and no other command when the user connects via SSH. Take care not to shut out every user.

1. Edit `/etc/ssh/sshd_config` and add a block for the specific user:

```
Match User <USERNAME-OF-USER>
    ForceCommand /usr/bin/scp
```
2. Restart the SSH service to apply the changes: `sudo systemctl restart sshd`

#### Initiate a dumping procedure




