job "grafana" {
  datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"



  group "grafana" {
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
            static = "3000"
          }
        }


    task "grafana" {
 
      driver = "docker"

      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/grafana-oss:{{key "valerian 1.0/versions/grafana"}}"
        mounts = [
          {
                type = "bind"
                target = "/var/lib/grafana"
                source = "${meta.DFS}/opt/grafana"
          },
          {
                type = "bind"
                target = "/usr/share/grafana/conf/defaults.ini"
                source = "${meta.DFS}/opt/grafana/conf/defaults.ini"
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
        cpu    = {{key "valerian 1.0/cluster config/resources/grafana/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/grafana/memory"}}
      }

      service {
        name = "grafana"
        tags = ["visualization"]
  
      }

    }
  }
}


