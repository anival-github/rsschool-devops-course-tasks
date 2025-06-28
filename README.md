# K3s Kubernetes Cluster on AWS

This Terraform project sets up a K3s Kubernetes cluster on AWS. The cluster consists of one master node and one worker node, both running on Ubuntu 20.04 EC2 instances. A bastion host is also created to provide secure access to the cluster nodes.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed.
- [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials.
- An SSH key pair. You will need to provide the public key for the bastion and the Kubernetes nodes.

## Setup

1.  **Clone the repository**

2.  **Navigate to the `terraform` directory**
    ```bash
    cd terraform
    ```

3.  **Create a `terraform.tfvars` file**
    Create a file named `terraform.tfvars` and add the following content:

    ```hcl
    bastion_public_key = "ssh-rsa ..."
    k8s_public_key     = "ssh-rsa ..."
    my_local_ip        = "x.x.x.x"
    k3s_token          = "your-secret-token"
    ```

    - `bastion_public_key`: Your SSH public key for the bastion host.
    - `k8s_public_key`: Your SSH public key for the Kubernetes nodes.
    - `my_local_ip`: Your public IP address. This is used to allow `kubectl` access from your local machine. You can find it by running `curl ifconfig.me`.
    - `k3s_token`: A secret token for the k3s cluster. Choose a secure random string.

4.  **Initialize Terraform**
    ```bash
    terraform init
    ```

5.  **Apply the Terraform configuration**
    ```bash
    terraform apply
    ```
    This will provision the necessary AWS resources. Note the outputs, especially `bastion_public_ip` and `kubeconfig_command`.

## Accessing the Cluster

### From your local machine

1.  **Get the kubeconfig file**
    Run the `kubeconfig_command` from the Terraform output. You will need to replace `<path_to_k8s_private_key>` with the path to your private SSH key that corresponds to the `k8s_public_key`.

    ```bash
    eval "$(terraform output -raw kubeconfig_command)" > kubeconfig.yaml
    ```

2.  **Update the kubeconfig**
    The kubeconfig file will have the private IP of the master node. You need to replace it with the public IP of the bastion host and configure an SSH tunnel.

    A better way is to set up port forwarding from your local machine to the master node via the bastion.

    Open a new terminal and run:
    ```bash
    BASTION_IP=$(terraform output -raw bastion_public_ip)
    MASTER_IP=$(terraform output -raw k8s_master_private_ip)
    ssh -i <path_to_k8s_private_key> -L 6443:${MASTER_IP}:6443 ubuntu@${BASTION_IP} -N
    ```
    This command will forward local port 6443 to the master's port 6443.

3.  **Configure kubectl**
    Now, get the `kubeconfig` again, but this time, save it and modify it.
    ```bash
    terraform output -raw kubeconfig_command | sed "s/${MASTER_IP}/127.0.0.1/" > kubeconfig.yaml
    ```

4.  **Use kubectl**
    You can now use `kubectl` with this configuration file.
    ```bash
    export KUBECONFIG=./kubeconfig.yaml
    kubectl get nodes
    ```

### From the bastion host

1.  **SSH into the bastion host**
    ```bash
    ssh -i <path_to_bastion_private_key> ubuntu@<bastion_public_ip>
    ```

2.  **SSH into the master node**
    From the bastion, you can SSH into the master node using its private IP.
    ```bash
    ssh -i <path_to_k8s_private_key> ubuntu@<k8s_master_private_ip>
    ```

3.  **Use kubectl on the master node**
    The `kubeconfig` is located at `/etc/rancher/k3s/k3s.yaml`.
    ```bash
    sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get nodes
    ```

## Deploying a Workload

Deploy a simple NGINX pod:
```bash
kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
```

Verify the deployment:
```bash
kubectl get pods --all-namespaces
```

## Cleanup

To destroy the resources created by Terraform, run:
```bash
terraform destroy
```