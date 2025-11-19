
job "sheldon" {

    datacenters = [
        {{ range datacenters }}"{{.}}"{{end}}
    ]
    type = "service"

    group "sheldon" {
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
          port "app" {
            static = "2203"
            to = "80"
          }
        }

      task "sheldon" {
            driver = "docker"

            config {
                image = "{{key "valerian 1.0/external services/valkyrie/address"}}/sheldon:{{key "valerian 1.0/versions/sheldon"}}"
                labels {
                    group = "sheldon"
                }
                mounts = [
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
                ports = ["app"]
                }
            resources {
                cpu    = {{key "valerian 1.0/cluster config/resources/sheldon/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/sheldon/memory"}}
                }
            service {
             name = "sheldon"
             port = "app"
             tags = ["urlprefix-/actionitems"]
            }
            }
        }
     }




