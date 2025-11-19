job "metabase" {
  datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"



  group "metabase" {
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
            static = "6655"
	    to = "3000"
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

    task "metabase" {
 
      driver = "docker"
      env {
          MB_DB_TYPE="postgres"
          MB_DB_DBNAME="metabase"
          MB_DB_PORT="5432"
          MB_DB_USER="metabase"
          MB_DB_PASS="password"
          MB_DB_HOST="pg.service.{{ range datacenters }}{{.}}{{end}}.valerian"
          TZ = trimspace(file("/etc/timezone"))
          }

      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/metabase:{{key "valerian 1.0/versions/metabase"}}"
        mounts = [
            {
                type = "bind"
                target = "/metabase-data"
                source = "${meta.DFS}/opt/metabase"
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
        cpu    = {{key "valerian 1.0/cluster config/resources/metabase/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/metabase/memory"}}
      }

      service {
        name = "metabase"
        tags = ["global", "visualization"]
        port = "server"
	check {
            name     = "pg_alive"
            type     = "script"
            command  = "/bin/sh"
	    args     = ["-c", "nc -z pg.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 5432 && exit 0 || (c=$?; exit 2)"]
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


