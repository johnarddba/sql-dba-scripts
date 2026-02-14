provider "null" {}

resource "null_resource" "run_ansible" {

    provisioner "local-exec" {
        command = "ansible-playbook -i inventory.ini playbook.yml"
    }
}