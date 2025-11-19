job "zabbix" {
  datacenters =   [
     {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"

  group "zabbix" {
    count = 1

        restart {
            attempts = 5
            interval = "30m"
            delay = "20s"
            mode = "fail"
          }


        reschedule {
            attempts       = 15
            interval       = "1h"
            delay          = "30s"
            delay_function = "exponential"
            max_delay      = "120s"
            unlimited      = false
        }
       

        network {
          port "http" {
            static = "9111"
          }
        }

  	
    task "wait-for-zabbix" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["-c", "while ! nc -z zabbix-server.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 10051; do sleep 1; done"]
      }
    }

    task "zabbix" {
      driver = "docker"
      #env {
      #         TZ = trimspace(file("/etc/timezone"))
      #        }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/zabbix.proxy:{{key "valerian 1.0/versions/zabbix"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/app/appsettings.json"
                 source = "${meta.DFS}/opt/zabbix/app/appsettings.json"
                },
		            {
                 type = "bind"
                 target = "/app/backupInitData.json"
                 source = "${meta.DFS}/opt/zabbix/app/backupInitData.json"
                },
                {
                    type = "bind"
                    target = "/etc/timezone"
                    source = "/etc/timezone"
                },
                {
                    type = "bind"
                    target = "/etc/localtime"
                    source = "/etc/localtime"
                },
                {
                    type = "bind"
                    target = "/app/logs"
                    source = "${meta.DFS}/logs/zabbix"
                } 
              ]
		
	      ports = ["http"]

        }

      resources {
        cpu    = "{{key "valerian 1.0/cluster config/resources/zabbix/cpu"}}"
        memory = "{{key "valerian 1.0/cluster config/resources/zabbix/memory"}}"
      }

      service {
        name = "zabbix"
        tags = [
                "zabbix"
            ]
        check {
            name     = "zabbix-server_alive"
            type     = "script"
            command  = "/bin/sh"
            args     = ["-c", "nc -z zabbix-server.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 10051 && exit 0 || (c=$?; exit 2)"]
            interval = "60s"
            timeout  = "20s"

        }

        check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false

        }
      }
    }
  }
}
