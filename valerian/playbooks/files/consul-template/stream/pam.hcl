job "pam" {
  datacenters =  [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"

  group "pam" {
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

    task "pam" {
      driver = "docker"
      env {
              # TZ = trimspace(file("/etc/timezone"))
              }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/pam:{{key "valerian 1.0/versions/pam"}}"
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
		          source = "/v/opt/pam/config"
                },
				{
                  type = "bind"
                  target = "/opt/logs"
		          source = "/v/logs/pam"
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
        cpu    = {{key "valerian 1.0/cluster config/resources/pam/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/pam/memory"}}
      }

      service {
        name = "pam"
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

        check {
            name     = "redis_alive"
            type     = "script"
            command  = "/bin/sh"
            args     = ["-c", "nc -z redis.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 6379 && exit 0 || (c=$?; exit 2)"]
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
