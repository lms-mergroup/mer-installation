job "minio" {
  datacenters = [
     "dev"
    ]
  type = "service"

  group "minio" {
    reschedule {
      attempts       = 5
      interval       = "15m"
      delay          = "1m"
      delay_function = "exponential"
      max_delay      = "5m"
      unlimited      = false
    }

    count = 1

    restart {
      attempts = 3
      interval = "30m"
      delay = "45s"
      mode = "fail"
    }

    ephemeral_disk {
      size = 300
    }

    task "minio" {
      driver = "docker"
	  env {
        MINIO_ROOT_USER="stiletto"
        MINIO_ROOT_PASSWORD="BlackbirdSR71"
		MINIO_NOTIFY_KAFKA_ENABLE_SMART="on"
		MINIO_NOTIFY_KAFKA_BROKERS_SMART="kafka.service.dev.valerian:29092"
    TZ = trimspace(file("/etc/timezone"))
      }
      config {
        image = "valkyrie:8083/minio:RELEASE.2022-10-20T00-55-09Z"
		args = [
          "server",
		  "--console-address",
		  ":9001",
          "/data"
		  
        ]
        mounts = [
            {
                type = "bind"
                target = "/data"
                source = "${meta.DFS}/opt/minio/data"
            }
        ]
		
	    port_map {
          access_point = 9000
		  port2 = 9001
        }

        }

      resources {
        cpu    = 500
        memory = 1024

    	network {
          mbits = 10
          port "access_point" {
              static = "9000"
                      }   
		  port "port2" {
              static = "9001"
                      } 
        }


      }

      service {
        name = "minio"
        tags = ["storage", "minIO"]
        port = "access_point"
		
        }
    }
  }
}
