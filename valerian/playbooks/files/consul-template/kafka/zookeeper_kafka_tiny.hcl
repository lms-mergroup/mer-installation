
job "kafka-zookeeper" {
    datacenters = [
        {{ range datacenters }}"{{.}}"{{end}}
    ]

    type = "service"
    priority = 100

    group "kafka-zookeeper" {

        # define the number of times the tasks need to be executed
        # for us to be able and work with confluentic control center on out network
        # when implementing in HA env change this to 3 or more.
        count = 1

        restart {
            attempts = 5
            interval = "30m"
            delay = "20s"
            mode = "delay"
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
		  mode = "host"
          port "zooport" {
            static = "2181"
          }
          port "zoopeer1" {
            static = "2888"
          }
          port "zoopeer2" {
            static = "3888"
          }
          port "kafport" {
            static = "29092"
          }
        }
		
      task "zookeeper" {
            driver = "docker"
            env { 
                ZOO_CONF_DIR = "/conf"
                #TZ = trimspace(file("/etc/timezone"))

            }
           
            config {
                image = "{{key "valerian 1.0/external services/valkyrie/address"}}/zookeeper:{{key "valerian 1.0/versions/zookeeper"}}" 
                labels {
                    group = "zk-docker"
                }
               network_mode = "host"
               ports = ["zooport", "zoopeer1", "zoopeer2"]
	        mounts = [
                {
                  type = "bind"
                  target = "/conf"
		          source = "/v/opt/zookeeper/config"
                },
		        {
                  type = "bind"
                  target = "/tmp/zookeeper"
		          source = "/opt/zookeeper/datadir"
		        },
				{
                  type = "bind"
                  target = "/logs"
		          source = "/v/logs/zookeeper/${attr.unique.consul.name}"
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
                cpu    = {{key "valerian 1.0/cluster config/resources/zookeeper/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/zookeeper/memory"}}
                }
            service {
             name = "zookeeper"
             port = "zooport"
            }
            }
        task "kafka" {
            driver = "docker"
            env { 
	          KAFKA_ZOOKEEPER_CONNECT="${NOMAD_ADDR_zooport}"                 
              KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://${attr.unique.network.ip-address}:29092"
              KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
              #TZ = trimspace(file("/etc/timezone"))
			  #KAFKA_DEFAULT_REPLICATION_FACTOR=3
            }
        
            config {
                image = "{{key "valerian 1.0/external services/valkyrie/address"}}/kafka:{{key "valerian 1.0/versions/kafka"}}"
                labels {
                    group = "kafka-docker"
                }
                #network_mode = "host"
                ports = ["kafport"]
	        mounts = [
                 {
                  type = "bind"
                  target = "/var/lib/kafka/data"
                  source = "/var/lib/kafka/data"
                },
				{
                  type = "bind"
                  target = "/etc/confluent/docker/log4j.properties.template"
                  source = "/v/opt/kafka/config/log4j.properties.template"
                },
				{
                  type = "bind"
                  target = "/var/log/kafka"
                  source = "/v/logs/kafka/${attr.unique.consul.name}"
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
                cpu    = {{key "valerian 1.0/cluster config/resources/kafka/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/kafka/memory"}}
                }
            service {
                name = "kafka"
                tags = ["urlprefix-:29092 proto=tcp"]
            }
        }
    }
}




