job "minio" {

   datacenters = [
        {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"
  priority = 70
  
  group "minio" {

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
       

        affinity {
            attribute = "${meta.name}"
            value     = "c01"
            weight    = 100
          }

        network {
          port "access_point" {
            static = "9000"
          }
          port "console" {
            static = "9001"
          }
        }



    task "minio" {
      driver = "docker"
      env {
         MINIO_ROOT_USER="stiletto"
         MINIO_ROOT_PASSWORD="BlackbirdSR71"
	       MINIO_NOTIFY_KAFKA_ENABLE_SMART="on"
	       MINIO_NOTIFY_KAFKA_BROKERS_SMART="kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}:29092"
         #TZ = trimspace(file("/etc/timezone"))
      }


      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/minio:{{key "valerian 1.0/versions/minio"}}"
        args = ["server", "--console-address", ":9001", "/data"]
        mounts = [
            {
                type = "bind"
                target = "/data"
                source = "/root/minio/data"
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

        ports = ["access_point", "console"]
      }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/minio/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/minio/memory"}}
      }


      service {
        name = "minio"
        tags = ["storage", "minIO"]
        port = "access_point"
      }

    }
  }
}
