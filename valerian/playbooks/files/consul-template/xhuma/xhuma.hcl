job "xhuma" {
  datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"

  group "xhuma" {
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
			  static = "3009"
		  }
        }

        task "wait-for-kafka" {
            lifecycle {
            hook = "prestart"
            sidecar = false
            }

            driver = "exec"
            config {
            command = "sh"
            args = ["-c", "while ! nc -z kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 29092; do sleep 1; done"]
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
    task "wait-for-magos" {
        lifecycle {
        hook = "prestart"
        sidecar = false
        }

        driver = "exec"
        config {
        command = "sh"
        args = ["-c", "while ! nc -z magos.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 9117; do sleep 1; done"]
        }
    }
    task "xhuma" {
      driver = "docker"
      env {
              # TZ = trimspace(file("/etc/timezone"))
              }

      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/xhuma:{{key "valerian 1.0/versions/xhuma"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/app/appsettings.json"
                 source = "${meta.DFS}/opt/xhuma/app/appsettings.json"
                },
		        {
                 type = "bind"
                 target = "/app/log4net.config"
                 source = "${meta.DFS}/opt/xhuma/app/log4net.config"
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
                    source = "${meta.DFS}/logs/xhuma"
                } 
              ]

	    ports = ["http"]

        }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/xhuma/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/xhuma/memory"}}
      }

      service {
        name = "xhuma"
        tags = [
                "xhuma"
            ]

                check {
                    name     = "kafka_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "nc -z kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 29092 && exit 0 || (c=$?; exit 2)"]
                    interval = "60s"
                    timeout  = "20s"

                }

               check {
                    name     = "mssql_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "nc -z mssql.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 1433 && exit 0 || (c=$?; exit 2)"]
                    interval = "60s"
                    timeout  = "20s"

                }
		
	        check {
	            name     = "magos_alive"
	            type     = "script"
	            command  = "/bin/sh"
	            args     = ["-c", "nc -z magos.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 9117 && exit 0 || (c=$?; exit 2)"]
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
