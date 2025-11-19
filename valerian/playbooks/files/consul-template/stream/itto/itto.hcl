job "itto" {
  datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"

  group "itto" {
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
			  static = "9099"
		  }
    }
	    
    task "itto" {
      driver = "docker"
      env {
               #TZ = trimspace(file("/etc/timezone"))
              }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/itto:{{key "valerian 1.0/versions/itto"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/app/appsettings.json"
                 source = "${meta.DFS}/opt/itto/app/appsettings.json"
                },
            	{
                 type = "bind"
                 target = "/app/logs"
                 source = "${meta.DFS}/logs/itto"
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
        args = [
                    "port=9099",
                    "consul_url=http://consul.service.{{ range datacenters }}{{.}}{{end}}.valerian:8500/",
                    "consul_section=env/local/itto"
                ]


	    ports = ["http"]

        }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/itto/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/itto/memory"}}
      }

      service {
        name = "itto"
        tags = [
                "itto"
            ]
      }
    }
  }
}
