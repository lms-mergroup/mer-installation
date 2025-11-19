def runmodule() {

	def valkyriepb = "${ANSIBLE_PREFIX}${INSTALLPACK_PATH}valkyrie/playbooks"
	def cd = "${ANSIBLE_PREFIX}${CUSTDATA_PATH}${CUST_NAME}"
	def user = "${ENV_TYPE}"
	def custdatadir = "${ANSIBLE_PREFIX}${CUSTDATA_PATH}${CUST_NAME}/${ENV_TYPE}/valkyrie"
	
    stage('Valkyrie- change hostname') {
        sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
           docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/change-hostname.yaml --limit valkyrie
        """
    }
    
    stage('Valkyrie - APT install') {
		sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/apt-packages-install.yaml --limit valkyrie
		"""  
    }
	stage('Valkyrie add to Domain') {
        sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/add-to-domain.yaml --limit valkyrie
		"""
    }
    stage('Valkyrie Nexus install') {
        sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/nexus-install.yaml --limit valkyrie
		"""
    }
	stage('Valkyrie Nexus configuration') {
        sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/nexus-configuration.yaml --limit valkyrie
		"""  
    }
	stage('Valkyrie Nexus creat repo') {
        sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/nexus-create-repo.yaml --limit valkyrie
		"""  
    }
	
	stage('Valkyrie copy images tar.gz files') {
        sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/copy-images.yaml --limit valkyrie
		"""  
    }
	
	stage('Valkyrie Nexus upload images') {
        sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/nexus-upload-images.yaml --limit valkyrie
		"""  
    }
	
	stage('Valkyrie upload images  - set completion flag'){
              
               echo "Set flag file for images upload"
               writeFile file: 'Uploaded_images_Status.txt', text: 'true'
               echo "Uploaded_images_Status.txt written"
             
            }
	stage('Valkyrie DNSmasq Config') {
        sh """
          set -e
          docker info >/dev/null
          docker inspect -f '{{.State.Running}}' "ansible_control" | grep -q true || {
            echo "Container ansible_control is not running"; docker ps; exit 1;
          }
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $valkyriepb/dnsmasq-config.yaml --limit valkyrie
		"""  
    }
}

//configure blobs and on is missing
return this