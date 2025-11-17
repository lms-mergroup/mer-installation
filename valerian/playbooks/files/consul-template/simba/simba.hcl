
job "simba" {

    datacenters = [{{ range datacenters }}"{{.}}"{{end}}]


    type = "service"
    priority = 85


    group "simba" {

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
          port "simba_server" {
            static = "8089"
            to = "8080"
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

         

        task "wait-for-gisserver" {
            lifecycle {
            hook = "prestart"
            sidecar = false
            }

            driver = "exec"
            config {
            command = "sh"
            args = ["-c", "while ! wget -O /dev/null  http://{{key "valerian 1.0/external services/gis server/address"}}/GISServer/Web/GeoService.svc; do sleep 1; done"]
            }
        }         

        task "wait-for-notifications" {
            lifecycle {
            hook = "prestart"
            sidecar = false
            }

            driver = "exec"
            config {
            command = "sh"
            args = ["-c", "while ! wget --spider -S http://signalr.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}/SMNG/NotificationServer/; do sleep 1; done"]
            }
        } 



      task "simba" {
            driver = "docker"
            env {
               #TZ = trimspace(file("/etc/timezone"))
              }

            config {
                image = "{{key "valerian 1.0/external services/valkyrie/address"}}/simba:{{key "valerian 1.0/versions/simba"}}"
                labels {
                    group = "simba"
                }

	        mounts = [
                {
                  type = "bind"
                  target = "/usr/app/config"
                  source = "${meta.DFS}/opt/simba/config"
                },
				{
                  type = "bind"
                  target = "/usr/app/logs"
                  source = "${meta.DFS}/logs/simba"
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
                } 
                            
                ]

                ports = ["simba_server"]
                }
            resources {
                cpu    = {{key "valerian 1.0/cluster config/resources/simba/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/simba/memory"}}
                }
            service {
                name = "simba"
                port = "simba_server"
                tags = ["urlprefix-/simba"]

                check {
                    name     = "mssql_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "nc -z mssql.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 1433 && exit 0 || (c=$?; exit 2)"]
                    interval = "60s"
                    timeout  = "20s"

                }

                check {
                    name     = "kafka_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "nc -z kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 29092 && exit 0 || (c=$?; exit 2)"]
                    interval = "60s"
                    timeout  = "20s"

                }


                check {
                    name     = "gis_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "wget -O /dev/null http://{{key "valerian 1.0/external services/gis server/address"}}/GISServer/Web/GeoService.svc&& exit 0 || (c=$?; exit 2)"]
                    interval = "60s"
                    timeout  = "20s"

                }

                check {
                    name     = "notifications_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "wget --spider -S http://signalr.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}/SMNG/NotificationServer/ && exit 0 || (c=$?; exit 2)"]
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




