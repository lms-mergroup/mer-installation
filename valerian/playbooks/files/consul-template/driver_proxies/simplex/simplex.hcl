job "simplex" {
  datacenters =   [
     {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"

  group "simplex" {
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
            static = "9124"
          }
        }


    task "simplex" {
      driver = "docker"
      #env {
      #         TZ = trimspace(file("/etc/timezone"))
      #        }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/simplex:{{key "valerian 1.0/versions/simplex"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/app/appsettings.json"
                 source = "${meta.DFS}/opt/simplex/app/appsettings.json"
                },
		            {
                 type = "bind"
                 target = "/app/backupInitData.json"
                 source = "${meta.DFS}/opt/simplex/app/backupInitData.json"
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
                    source = "${meta.DFS}/logs/simplex"
                },
                 {
                    type = "bind"
                    target = "/app/Files"
                    source = "${meta.DFS}/opt/simplex/app/files"
                }
              ]
		
	      ports = ["http"]

        }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/simplex/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/simplex/memory"}}
      }

      service {
        name = "simplex"
        tags = [
                "simplex"
            ]
         }
    }
  }
}
