job "snitch" {
  
  datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"
  priority = 85

  group "snitch" {



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
		  port "server" {
			  static = "6699"
		  }
        }
		
	task "wait-for-pg" {
		lifecycle {
		  hook = "prestart"
		  sidecar = false
		}

		driver = "exec"
		config {
		  command = "sh"
		  args = ["-c", "while ! nc -z pg.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 5432; do sleep 1; done"]
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
  
    task "snitch" {
      driver = "docker"
      env {
               #TZ = trimspace(file("/etc/timezone"))
              }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/snitch:{{key "valerian 1.0/versions/snitch"}}"

        #args = ["-config=/conf/config.json"]
        args = [
          "-c=consul.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}:8500",
          "-e={{key "valerian 1.0/cluster config/kv default prefix"}}"
        ]
	      mounts = [
            {
                type = "bind"
                target = "/logs"
                source = "${meta.DFS}/logs/snitch/"
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
        ports = ["server"]
      }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/snitch/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/snitch/memory"}}
      }

      service {
        name = "snitch"
        tags = ["global", "discovery"]
        port = "server"
        check {
          name     = "alive"
          type     = "http"
          path     = "/vizceral"
          interval = "60s"
          timeout  = "20s"
        }
		
		check {
          name     = "pg_alive"
          type     = "script"
          command  = "/bin/sh"
		      args     = ["-c", "nc -z pg.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 5432 && exit 0 || (c=$?; exit 2)"]
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

