def runmodule() {
	def iispb = "${ANSIBLE_PREFIX}${INSTALLPACK_PATH}iis/playbooks"
	def cd = "${ANSIBLE_PREFIX}${CUSTDATA_PATH}${CUST_NAME}"
	def user = "${ENV_TYPE}"
	def custdatadir = "${ANSIBLE_PREFIX}${CUSTDATA_PATH}${CUST_NAME}/${ENV_TYPE}/"
	def installpack = "${ANSIBLE_PREFIX}${INSTALLPACK_PATH}"
	
    stage('Check WinRM status') {
      
        sh """
          set -e
          docker exec ansible_control ansible -i $cd/$user/common/ansible-connection.yaml iis -m win_ping
          """
      
    }
	stage('Delete flags') {
     
        sh """
        if [ -f CopyWinScrDone_Status.txt ]; then
            rm CopyWinScrDone_Status.txt
            echo "CopyWinScrDone_Status.txt deleted"
        else
            echo "CopyWinScrDone_Status.txt not found"
        fi

        if [ -f IISfeaturesDone_Status.txt ]; then
            rm IISfeaturesDone_Status.txt
            echo "IISfeaturesDone_Status.txt deleted"
        else
            echo "IISfeaturesDone_Status.txt not found"
        fi
		
		if [ -f CopySMNGDone_Status.txt ]; then
            rm CopySMNGDone_Status.txt
            echo "CopySMNGDone_Status.txt deleted"
        else
            echo "CopySMNGDone_Status.txt not found"
        fi
		
		if [ -f CopyDotnetDone_Status.txt ]; then
            rm CopyDotnetDone_Status.txt
            echo "CopyDotnetDone_Status.txt deleted"
        else
            echo "CopyDotnetDone_Status.txt not found"
        fi
     
        if [ -f ExtractSMNG_Status.txt ]; then
            rm ExtractSMNG_Status.txt
            echo "ExtractSMNG_Status.txt deleted"
        else
            echo "ExtractSMNG_Status.txt not found"
        fi
        """
    
}
      stage('Change hostname and add to domain') {
      
          sh """
            set -e
            docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/change-host-add-to-domain.yaml
              """
      
    }
	stage ('Parallel work') {
       parallel (
	     "Copy Install Scripts": {
		  
           stage('Copy Windows install scripts') {
            
             sh """
                set -e
                docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/copy-win-install-dir.yaml
                """
             
            }
			stage('copy Windows install scripts - set completion flag'){
             
              echo "Set flag file for SQL ISO copy completion"
              writeFile file: 'CopyWinScrDone_Status.txt', text: 'true'
              echo "Flag CopyWinScrDone_Status.txt written"
             
           
		   }
		  },
		   "Copy SMNG Zip": {
			 stage('Wait for IISfeaturesDone_Status.txt') {
              
               script {
                 waitUntil {
                   echo "Waiting for done.txt in ${env.WORKSPACE}..."
                 return fileExists('IISfeaturesDone_Status.txt')
                 }
                 echo "IISfeaturesDone is here!"
               
              }
             }
             stage('Copy SMNG scripts') {
              
                sh """
                   set -e
                   docker exec ansible_control ansible-playbook -vvv -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/copy-smng-software.yaml
                   """
                
             }
			 stage('copy SMNG  - set completion flag'){
              
               echo "Set flag file for SQL ISO copy completion"
               writeFile file: 'CopySMNGDone_Status.txt', text: 'true'
               echo "CopySMNGDone_Status.txt written"
             
            }
		  },
		 "Copy DotNet": {
     		  stage('Copy dotnet install files') {
               
                sh """
                   set -e
                   docker exec ansible_control ansible-playbook -vvv  -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/copy-dotnet-install-files.yaml
                   """
				   
		      }
			  stage('copy DotNet  - set completion flag'){
               
                echo "Set flag file for SQL ISO copy completion"
                writeFile file: 'CopyDotnetDone_Status.txt', text: 'true'
                echo "Flag CopyDotnetDone written"
			   
			  }
		  },
         "Main": {
           stage('Add firewall rules') {
            
             sh """
                set -e
                docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis-add-firewall-rules.yaml
                """
              
             }
	       stage('Add DevServiceUser to Admin group') {
            
             sh """
                set -e
                docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/add-domain-user-to-admin-group.yaml
                """
            
           }
		
	      stage('Wait for CopyWinScrDone_Status.txt') {
           
            script {
              waitUntil {
                echo "Waiting for done.txt in ${env.WORKSPACE}..."
                return fileExists('CopyWinScrDone_Status.txt')
              }
              echo "done.txt is here!"
             }
            
           }
          stage('Install IIS features') {
           script{

                 sh """
                  set -e
                  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e     "customer_data_dir=$custdatadir" $iispb/iis_install_features.yaml
                    """
           } 
          }
		  stage('IIS features  - set completion flag'){
               
                echo "Set flag file for IIS features copy completion"
                writeFile file: 'IISfeaturesDone_Status.txt', text: 'true'
                echo "IISfeaturesDone_Status.txt written"
			   
			  }
		  
		  stage('Update IIS pools') {
           
            sh """
               set -e
               docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis-create-app-pools.yaml
               """
           
          }
		  stage('Set credentials for SMNG data pools ') {
           
            sh """
               set -e
               docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/set-credentials-on-data-pool.yaml
               """
            }
             
		   			
			stage('Wait for CopySMNGDone_Status.txt') {
             
              script {
                waitUntil {
                echo "Waiting for done.txt in ${env.WORKSPACE}..."
                return fileExists('CopySMNGDone_Status.txt')
                 }
                 echo "done.txt is here!"
              }
             }
		   
		    
		     stage('Extract SMNG.zip') {
              
               sh """
                  set -e
                  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis-extract-smng.yaml
                  """
              
             }
			 stage('Extract SMNG  - set completion flag'){
               
                echo "Set flag file for Extract SMNG completion"
                writeFile file: 'ExtractSMNG_Status.txt', text: 'true'
                echo "ExtractSMNG_Status.txt written"
			   
			  }

		   stage('IIS import WEB sites definitions ') {
            
               sh """
                  set -e
                  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis_import_web_sites.yaml
                  """
            
				} 
				
			  stage('IIS config: Self-Signed Certificate and binding ') {
            
                 sh """
                    set -e
                    docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis_create_self_signed_cert.yaml
                    """
              
            }
             stage('IIS set default WEB site SSL settings Accept  ') {
            
                sh """
                   set -e
                   docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis_default_web_site_ssl_accept.yaml
                   """
            
				} 
			  
			 stage('IIS update WEB config file ') {
              
               sh """
                  set -e
                  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis_update_web_config_file.yaml
                  """
              
             }
    
             stage('IIS update GIS WEB config file ') {
              
               sh """
                  set -e
                  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis_update_gis_web_config_file.yaml
                  """
                
              }
			  
			  stage('IIS update Notification WEB config file ') {
              
               sh """
                  set -e
                  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/iis_update_notification_web_config_file.yaml
                  """
                
              }
       
             stage('Install dotnets') {
              
               sh """
                  set -e
                  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $iispb/install-dot-nets.yaml
                  """
               
               }
              }
		    )
			 }
		    }
return this