job "kaizo" {
  datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"
  priority = 70

  group "kaizo" {
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
        args = ["-c", "while ! nc -z kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 29092; do sleep 1; done"]
      }
	}

    task "kaizo" {
      driver = "docker"
      env {
              # TZ = trimspace(file("/etc/timezone"))
              }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/kaizo:{{key "valerian 1.0/versions/kaizo"}}"
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
		          source = "/v/opt/kaizo/config"
                },
				{
                  type = "bind"
                  target = "/opt/logs"
		          source = "/v/logs/kaizo"
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
        cpu    = {{key "valerian 1.0/cluster config/resources/kaizo/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/kaizo/memory"}}
      }
      service {
        name = "kaizo"
        tags = [
                "stream",
                "transformer"
            ]

        check {
            name     = "kafka_alive"
            type     = "script"
            command  = "/bin/sh"
            args     = ["-c", "nc -z kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 29092 && exit 0 || (c=$?; exit 2)"]
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
