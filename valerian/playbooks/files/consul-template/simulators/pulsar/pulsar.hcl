job "pulsar" {
    datacenters = [
      {{ range datacenters }}"{{.}}"{{end}}
    ]

    type = "service"

 
    group "pulsar" {
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
          port "pulsar_server" {
            static = "3001"
            to = "3001"
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
 
         task "pulsar" {
             driver = "docker"
             env {
               #TZ = trimspace(file("/etc/timezone"))
              }
 
             config {
               image = "{{key "valerian 1.0/external services/valkyrie/address"}}/pulsar:{{key "valerian 1.0/versions/pulsar"}}"
               mounts = [
                {
                  type = "bind"
                        target = "/usr/app/config"
                        source = "${meta.DFS}/opt/pulsar/config"
                },
                {
                  type = "bind"
                  target = "/usr/app/logs"
                  source = "${meta.DFS}/logs/pulsar"
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
              ports = ["pulsar_server"]
              
         }
          resources {
                  cpu    = {{key "valerian 1.0/cluster config/resources/pulsar/cpu"}}
                  memory = {{key "valerian 1.0/cluster config/resources/pulsar/memory"}}
           }
 
        service {
              name = "pulsar"
              tags = ["urlprefix-:3001 proto=tcp"]
              port = "pulsar_server"
              check {
                  type = "tcp"
                  interval = "10s"
                  timeout = "4s"
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
                    name     = "mssql_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "nc -z mssql.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 1433 && exit 0 || (c=$?; exit 2)"]
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
