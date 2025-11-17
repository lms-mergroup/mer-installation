job "zabbix_server" {
        datacenters = [
             {{ range datacenters }}"{{.}}"{{end}}
        ]

  type = "service"
 
  group "zabbix_server" {
    count = 1
    
    restart {
      attempts = 5
      interval = "30m"
      delay = "20s"
      mode = "fail"
    }
    
    reschedule {
      delay          = "3m"
      delay_function = "exponential"
      max_delay      = "1h"
      unlimited      = false
      attempts = 3
      interval = "30m"
    }
	
    network {
      mode = "cni/zabbix-net"
      port "udp" {
        static = "1162"
        to = "162"
      }
      port "server_http" {
        static = "10051"
      }
      port "zoopeer2" {
        static = "3888"
      }
      port "http"{
        static = "8080"
        to = "80"
      }
      port "https"{
        static = "8443"
        to = "443"
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
     
    task "zabbix-snmptraps" {
      driver = "docker" 
      env {
               TZ = trimspace(file("/etc/timezone"))
              }
      config {
        #image = "valkyrie:8083/zabbix-snmptraps:latest"
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/zabbix-snmptraps:{{key "valerian 1.0/versions/zabbix-snmptraps"}}"
	ports=["udp"]
        mounts = [
          {
            type = "bind"
            target = "/zbx_instance/snmptraps"
            source = "${meta.DFS}/opt/zabbix/snmptraps"
          },
          {
            type = "bind"
            target = "/var/lib/zabbix/mibs"
            source = "${meta.DFS}/opt/zabbix/share/snmp/mibs"
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
        cpu    = {{key "valerian 1.0/cluster config/resources/zabbix-snmptraps/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/zabbix-snmptraps/memory"}}
      }
      service {
        name = "zabbix-snmptraps"
      }
    }
  
    task "zabbix-server" {
      driver = "docker" 
      env {
        "DB_SERVER_HOST" = "pg.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}"             
        "DB_SERVER_PORT" = 5432             
        "POSTGRES_USER" = "postgres"               
        "POSTGRES_PASSWORD" = "password"               
        "POSTGRES_DB" = "zabbix"               
        "ZBX_ENABLE_SNMP_TRAPS" = "true"   
        TZ = trimspace(file("/etc/timezone"))            
      } 
      config {
        #image = "valkyrie:8083/zabbix-server-deploy:6.2.3"
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/zabbix-server-deploy:{{key "valerian 1.0/versions/zabbix-server"}}"
        ports = ["server_http"]
        mounts = [
          {
            type = "bind"
            target = "/usr/lib/zabbix/alertscripts"
            source = "${meta.DFS}/opt/zabbix/alertscripts"
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
        cpu    = {{key "valerian 1.0/cluster config/resources/zabbix-server/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/zabbix-server/memory"}}
      }
      service {
        name = "zabbix-server"
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
    

    task "zabbix-web" {
      driver = "docker" 
      env {
        "ZBX_SERVER_HOST" = "zabbix-server.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}"         
        "DB_SERVER_HOST" = "pg.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}"             
        "DB_SERVER_PORT" = 5432             
        "POSTGRES_USER" = "postgres"               
        "POSTGRES_PASSWORD" = "password"               
        "POSTGRES_DB" = "zabbix"  
        TZ = trimspace(file("/etc/timezone"))             
      } 
      config {
        #image = "valkyrie:8083/zabbix-web-apache-pgsql:6.2.3"
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/zabbix-web-apache-pgsql:{{key "valerian 1.0/versions/zabbix-web-apache-pgsql"}}"

         ports = ["http", "https"]
        mounts = [
          {
            type = "bind"
            target = "/etc/ssl/apache2"
            source = "${meta.DFS}/opt/zabbix/etc/ssl/apache2"
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
        cpu    = {{key "valerian 1.0/cluster config/resources/zabbix-web-apache-pgsql/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/zabbix-web-apache-pgsql/memory"}}
      }
      service {
        name = "zabbix-web"
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

