job "okazas" {
  datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"
  priority = 85

  group "okazas" {
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
			  static = "9560"
		  }
        }

        task "wait-for-mssql" {
            lifecycle {
            hook = "prestart"
            sidecar = false
            }

            driver = "exec"
            config {
            command = "sh"
            args = ["-c", "while ! nc -z mssql.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 1433; do sleep 1; done"]
            }
        }
    task "wait-for-redis" {
        lifecycle {
        hook = "prestart"
        sidecar = false
        }

        driver = "exec"
        config {
        command = "sh"
        args = ["-c", "while ! nc -z redis.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 6379; do sleep 1; done"]
        }
    }
    task "okazas" {
      driver = "docker"
      env {
               #TZ = trimspace(file("/etc/timezone"))
              }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/okazas:{{key "valerian 1.0/versions/okazas"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/app/appsettings.json"
                 source = "${meta.DFS}/opt/okazas/app/appsettings.json"
                },
		        {
                 type = "bind"
                 target = "/app/log4net.config"
                 source = "${meta.DFS}/opt/okazas/app/log4net.config"
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
                    source = "${meta.DFS}/logs/okazas"
                } 
              ]

	    ports = ["http"]

        }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/okazas/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/okazas/memory"}}
      }

      service {
        name = "okazas"
        tags = [
                "okazas"
            ]
               check {
                    name     = "mssql_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "nc -z mssql.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 1433 && exit 0 || (c=$?; exit 2)"]
                    interval = "60s"
                    timeout  = "20s"

                }
		
	        check {
	            name     = "redis_alive"
	            type     = "script"
	            command  = "/bin/sh"
	            args     = ["-c", "nc -z redis.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 6379 && exit 0 || (c=$?; exit 2)"]
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
