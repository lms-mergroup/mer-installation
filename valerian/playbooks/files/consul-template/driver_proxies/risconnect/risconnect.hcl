job "risconnect" {
  datacenters =   [
     {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"
  

  group "risconnect" {
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
            static = "9100"
          }
        }
	
    task "risconnect" {
      driver = "docker"
      #env {
      #         TZ = trimspace(file("/etc/timezone"))
      #        }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/risconnect:{{key "valerian 1.0/versions/risconnect"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/app/appsettings.json"
                 source = "${meta.DFS}/opt/risconnect/app/appsettings.json"
                },
		{
                 type = "bind"
                 target = "/app/backupInitData.json"
                 source = "${meta.DFS}/opt/risconnect/app/backupInitData.json"
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
                    source = "${meta.DFS}/logs/risconnect"
                } 
              ]
		
	      ports = ["http"]

        }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/risconnect/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/risconnect/memory"}}
      }

      service {
        name = "risconnect"
        tags = [
                "risconnect"
            ]

         }
    }
  }
}
