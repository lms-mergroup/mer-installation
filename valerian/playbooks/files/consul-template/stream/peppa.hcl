job "peppa" {

  datacenters = [{{ range datacenters }}"{{.}}"{{end}}]


  type = "service"

  group "peppa" {
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
       

		task "wait-for-kafka" {
            lifecycle {
            hook = "prestart"
            sidecar = false
            }

            driver = "exec"
            config {
            command = "sh"
            args = ["-c", "while ! nc -z kafka.service.v.valerian 29092; do sleep 1; done"]
            }
        }

    task "peppa" {
      driver = "docker"
      env {
              # TZ = trimspace(file("/etc/timezone"))
              }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/peppa:{{key "valerian 1.0/versions/peppa"}}"
        args = [
                    "-c",
                    "consul.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}:8500",
                    "-e",
                    "{{key "valerian 1.0/cluster config/kv default prefix"}}"
                ]
        mounts = [
                {
                  type = "bind"
                  target = "/opt/config"
		          source = "/v/opt/peppa/config"
                },
				{
                  type = "bind"
                  target = "/opt/logs"
		          source = "/v/logs/peppa"
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
        }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/peppa/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/peppa/memory"}}
      }

      service {
        name = "peppa"
        tags = [
                "global",
                "discovery"
            ]
			
		check {
				name     = "kafka_alive"
				type     = "script"
				command  = "/bin/sh"
				args     = ["-c", "nc -z kafka.service.v.valerian 29092 && exit 0 || (c=$?; exit 2)"]
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

