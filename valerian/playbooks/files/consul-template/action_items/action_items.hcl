
job "action_items" {

    # Specify Datacenter
    datacenters = [
        {{ range datacenters }}"{{.}}"{{end}}
    ]
    # Specify job type
    type = "service"
    priority = 85

    # Run tasks in serial or parallel (1 for serial)

    # define group
    group "action_items" {

        # define the number of times the tasks need to be executed
        count = 1

        # define job constraints

        # specify the number of attemtps to run the job within the specified interval
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
          port "action_items_server" {
            static = "8088"
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

        task "wait-for-mongo" {
            lifecycle {
                hook = "prestart"
                sidecar = false
            }

            driver = "exec"
            config {
                command = "sh"
                args = ["-c", "while ! nc -z mongodb.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 27017; do sleep 1; done"]
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

      task "action_items" {
            driver = "docker"
            #env {
            #   TZ = trimspace(file("/etc/timezone"))
            #  }

            config {
                image = "{{key "valerian 1.0/external services/valkyrie/address"}}/action-items:{{key "valerian 1.0/versions/action_items"}}"
                labels {
                    group = "action_items"
                }
				
				mounts = [
                {
                  type = "bind"
                  target = "/usr/app/logs"
                  source = "${meta.DFS}/logs/action_items/"
                },
                {
                  type = "bind"
                  target = "/usr/app/config/winston.js"
                  source = "${meta.DFS}/opt/action_items/config/winston.js"
                },
                {
                  type = "bind"
                  target = "/usr/app/config/config.json"
                  source = "${meta.DFS}/opt/action_items/config/config.json"
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
				
                ports = ["action_items_server"]

                #args = ["npm", "start", "service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}"]
                }
            resources {
                cpu    = {{key "valerian 1.0/cluster config/resources/action_items/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/action_items/memory"}}
                }
                
            service {
             name = "actionitems"
             port = "action_items_server"
             tags = ["urlprefix-/actionitems"]

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
                    name     = "mongo_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "nc -z mongodb.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 27017 && exit 0 || (c=$?; exit 2)"]
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




