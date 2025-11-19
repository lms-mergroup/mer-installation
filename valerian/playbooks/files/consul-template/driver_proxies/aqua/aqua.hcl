job "aqua" {
  datacenters =   [
     {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"

  group "aqua" {
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
            static = "9113"
          }
        }

    task "aqua" {
      driver = "docker"
      #env {
      #         TZ = trimspace(file("/etc/timezone"))
      #        }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/aqua:{{key "valerian 1.0/versions/aqua"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/app/appsettings.json"
                 source = "${meta.DFS}/opt/aqua/app/appsettings.json"
                },
		            {
                 type = "bind"
                 target = "/app/backupInitData.json"
                 source = "${meta.DFS}/opt/aqua/app/backupInitData.json"
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
                    source = "${meta.DFS}/logs/aqua"
                } 
              ]
		
	      ports = ["http"]

        }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/aqua/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/aqua/memory"}}
      }

      service {
        name = "aqua"
        tags = [
                "aqua"
            ]

         }
    }
  }
}
