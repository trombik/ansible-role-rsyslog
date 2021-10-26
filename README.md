# `trombik.rsyslog`

The role manages `rsyslog`.

# Notes for Ubuntu users

The `systemd` unit file for `rsyslog` on Ubuntu does not read
`/etc/default/rsyslog`. Therefor, `rsyslog_flags` has no effects.

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `rsyslog_user` | User name of `rsyslog` | `{{ __rsyslog_user }}` |
| `rsyslog_group` | Group name of `rsyslog` | `{{ __rsyslog_group }}` |
| `rsyslog_log_dir` | Log directory | `/var/log` |
| `rsyslog_service` | Service name of `rsyslog` | `{{ __rsyslog_service }}` |
| `rsyslog_package` | Package name of `rsyslog` | `{{ __rsyslog_package }}` |
| `rsyslog_extra_packages` | A list of extra packages to install | `[]` |
| `rsyslog_work_dir` | Path to `$WorkDirectory` | `{{ __rsyslog_work_dir }}` |
| `rsyslog_conf_dir` | Path to config directory | `{{ __rsyslog_conf_dir }}` |
| `rsyslog_conf_file` | Path to configuration file | `{{ rsyslog_conf_dir }}/rsyslog.conf` |
| `rsyslog_conf_d_dirs` | A list of directories for `rsyslog_config_flagments`. Usually, the directories are `included` in `rsyslog.conf`. | `{{ __rsyslog_conf_d_dirs }}` |
| `rsyslog_config` | Content of `rsyslog_conf_file` | `""` |
| `rsyslog_config_flagments` | See below | `[]` |
| `rsyslog_flags` | Flags for `rsyslog` service | `""` |

## `rsyslog_config_flagments`

This variable is a list of dict. The following keys are accepted.

| Key | Description | Mandatory? |
|-----|-------------|------------|
| `path` | Path to the file | yes |
| `state` | State of the file. The file is created when `present`, removed when `absent` | yes |
| `mode` | Permission of the file. Default is `0644` | no |
| `content` | Content of the file | yes when `state` is `present`, no when `absent` |

# Dependencies

None

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - ansible-role-rsyslog
  vars:
    os_rsyslog_config:
      Debian: |
        # /etc/rsyslog.conf configuration file for rsyslog
        #
        # For more information install rsyslog-doc and see
        # /usr/share/doc/rsyslog-doc/html/configuration/index.html
        #
        # Default logging rules can be found in /etc/rsyslog.d/50-default.conf


        #################
        #### MODULES ####
        #################

        module(load="imuxsock") # provides support for local system logging
        #module(load="immark")  # provides --MARK-- message capability

        # provides UDP syslog reception
        module(load="imudp")
        input(type="imudp" port="514")

        # provides TCP syslog reception
        module(load="imtcp")
        input(type="imtcp" port="514")

        # provides kernel logging support and enable non-kernel klog messages
        module(load="imklog" permitnonkernelfacility="on")

        ###########################
        #### GLOBAL DIRECTIVES ####
        ###########################

        #
        # Use traditional timestamp format.
        # To enable high precision timestamps, comment out the following line.
        #
        $ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

        # Filter duplicated messages
        $RepeatedMsgReduction on

        #
        # Set the default permissions for all log files.
        #
        $FileOwner syslog
        $FileGroup adm
        $FileCreateMode 0640
        $DirCreateMode 0755
        $Umask 0022
        $PrivDropToUser syslog
        $PrivDropToGroup syslog

        #
        # Where to place spool and state files
        #
        $WorkDirectory {{ rsyslog_work_dir }}

        #
        # Include all config files in /etc/rsyslog.d/
        #
        $IncludeConfig /etc/rsyslog.d/*.conf
      RedHat: |
        # rsyslog configuration file

        # For more information see /usr/share/doc/rsyslog-*/rsyslog_conf.html
        # If you experience problems, see http://www.rsyslog.com/doc/troubleshoot.html

        #### MODULES ####

        # The imjournal module bellow is now used as a message source instead of imuxsock.
        $ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
        $ModLoad imjournal # provides access to the systemd journal
        #$ModLoad imklog # reads kernel messages (the same are read from journald)
        #$ModLoad immark  # provides --MARK-- message capability

        # Provides UDP syslog reception
        $ModLoad imudp
        $UDPServerRun 514

        # Provides TCP syslog reception
        $ModLoad imtcp
        $InputTCPServerRun 514


        #### GLOBAL DIRECTIVES ####

        # Where to place auxiliary files
        $WorkDirectory {{ rsyslog_work_dir }}

        # Use default timestamp format
        $ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

        # File syncing capability is disabled by default. This feature is usually not required,
        # not useful and an extreme performance hit
        #$ActionFileEnableSync on

        # Include all config files in /etc/rsyslog.d/
        $IncludeConfig /etc/rsyslog.d/*.conf

        # Turn off message reception via local log socket;
        # local messages are retrieved through imjournal now.
        $OmitLocalLogging on

        # File to store the position in the journal
        $IMJournalStateFile imjournal.state


        #### RULES ####

        # Log all kernel messages to the console.
        # Logging much else clutters up the screen.
        #kern.*                                                 /dev/console

        # Log anything (except mail) of level info or higher.
        # Don't log private authentication messages!
        *.info;mail.none;authpriv.none;cron.none                /var/log/messages

        # The authpriv file has restricted access.
        authpriv.*                                              /var/log/secure

        # Log all the mail messages in one place.
        mail.*                                                  -/var/log/maillog


        # Log cron stuff
        cron.*                                                  /var/log/cron

        # Everybody gets emergency messages
        *.emerg                                                 :omusrmsg:*

        # Save news errors of level crit and higher in a special file.
        uucp,news.crit                                          /var/log/spooler

        # Save boot messages also to boot.log
        local7.*                                                /var/log/boot.log


        # ### begin forwarding rule ###
        # The statement between the begin ... end define a SINGLE forwarding
        # rule. They belong together, do NOT split them. If you create multiple
        # forwarding rules, duplicate the whole block!
        # Remote Logging (we use TCP for reliable delivery)
        #
        # An on-disk queue is created for this action. If the remote host is
        # down, messages are spooled to disk and sent when it is up again.
        #$ActionQueueFileName fwdRule1 # unique name prefix for spool files
        #$ActionQueueMaxDiskSpace 1g   # 1gb space limit (use as much as possible)
        #$ActionQueueSaveOnShutdown on # save messages to disk on shutdown
        #$ActionQueueType LinkedList   # run asynchronously
        #$ActionResumeRetryCount -1    # infinite retries if host is down
        # remote host is: name/ip:port, e.g. 192.168.0.1:514, port optional
        #*.* @@remote-host:514
        # ### end of the forwarding rule ###

    rsyslog_extra_packages: []
    rsyslog_config: "{{ os_rsyslog_config[ansible_os_family] }}"
    os_rsyslog_flags:
      Debian: ""
      RedHat: |
        # Options for rsyslogd
        # Syslogd options are deprecated since rsyslog v3.
        # If you want to use them, switch to compatibility mode 2 by "-c 2"
        # See rsyslogd(8) for more details
        SYSLOGD_OPTIONS=""
    rsyslog_flags: "{{ os_rsyslog_flags[ansible_os_family] }}"
    os_rsyslog_config_flagments:
      RedHat:
        - path: "{{ rsyslog_conf_d_dirs[0] }}/foo.conf"
          mode: "0775"
          state: present
          content: |
            # empty
      Debian:
        - path: "{{ rsyslog_conf_d_dirs[0] }}/foo.conf"
          mode: "0775"
          state: present
          content: |
            # empty
    rsyslog_config_flagments: "{{ os_rsyslog_config_flagments[ansible_os_family] }}"
    os_rsyslog_extar_packages:
      Debian: []
      RedHat: []
    rsyslog_extar_packages: "{{ os_rsyslog_extar_packages[ansible_os_family] }}"
```

# License

```
Copyright (c) 2021 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
