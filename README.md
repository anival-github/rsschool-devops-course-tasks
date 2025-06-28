# K3s Kubernetes Cluster on AWS

This Terraform project sets up a two-node K3s Kubernetes cluster on AWS. The cluster consists of one master node and one worker node running on Ubuntu EC2 instances. A bastion host is also created to provide secure access to the cluster nodes.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed.
- [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials.
- An SSH key pair. If you only have one, you can use the same public key for both the bastion and the Kubernetes nodes.

## Setup

1.  **Navigate to the `terraform` directory**
    ```bash
    cd terraform
    ```

2.  **Create a `terraform.tfvars` file**
    Copy the `terraform.tfvars.example` file to `terraform.tfvars` and fill in the values:

    ```hcl
    # Your SSH public key for the bastion host.
    bastion_public_key = "ssh-rsa AAAA..."

    # Your SSH public key for the Kubernetes nodes.
    k8s_public_key     = "ssh-rsa AAAA..."

    # Your public IP, used to allow API access for local kubectl.
    # Find it by searching "what is my IP" in Google or running `curl ifconfig.me`.
    my_local_ip        = "x.x.x.x"

    # A secret token for the k3s cluster. Choose any secure random string.
    k3s_token          = "your-super-secret-token"
    ```

3.  **Initialize Terraform**
    ```bash
    terraform init
    ```

4.  **Apply the Terraform configuration**
    ```bash
    terraform apply
    ```
    Review the plan and type `yes` to create the resources.

## Verifying the Cluster

### Method 1: From the Bastion Host (Recommended First Step)

1.  **Get the required IP addresses** from the Terraform outputs:
    ```bash
    terraform output bastion_public_ip
    terraform output k8s_master_private_ip
    ```

2.  **Add your private SSH key to your local SSH agent.** This is required for agent forwarding.
    ```powershell
    # On Windows PowerShell
    ssh-add /path/to/your/private_key
    ```
    ```bash
    # On Linux/macOS
    ssh-add /path/to/your/private_key
    ```

3.  **SSH into the bastion host using agent forwarding (`-A`).** Note that the username is `ec2-user`.
    ```bash
    ssh -A ec2-user@<bastion_public_ip>
    ```

4.  **From the bastion, SSH into the master node.** Your forwarded SSH agent will handle authentication automatically.
    ```bash
    ssh ubuntu@<k8s_master_private_ip>
    ```

5.  **On the master node, run this one-time setup** to configure `kubectl` for your user:
    ```bash
    mkdir -p $HOME/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

6.  **Verify that both nodes are ready.** You should see two nodes listed.
    ```bash
    kubectl get nodes
    ```

### Method 2: From Your Local Machine

1.  **Get the required IP addresses** from the Terraform outputs:
    ```bash
    terraform output bastion_public_ip
    terraform output k8s_master_private_ip
    ```

2.  **In a separate terminal, start an SSH tunnel.** This command forwards your local port `16443` to the Kubernetes API server on the master node (port `6443`) via the bastion. Let this terminal run in the background.
    ```bash
    ssh -L 16443:$(terraform output -raw k8s_master_private_ip):6443 ec2-user@$(terraform output -raw bastion_public_ip) -N
    ```

3.  **In another terminal, copy the kubeconfig file** from the master node to your local machine:
    ```bash
    scp -J ec2-user@$(terraform output -raw bastion_public_ip) ubuntu@$(terraform output -raw k8s_master_private_ip):/etc/rancher/k3s/k3s.yaml ~/.kube/config
    ```

4.  **Crucially, edit the `~/.kube/config` file on your local machine.** You need to change the server address to point to the local port you are forwarding.
    *   **Find:** `server: https://127.0.0.1:6443`
    *   **Replace with:** `server: https://localhost:16443`

5.  **Verify you can access the cluster from your local machine:**
    ```bash
    kubectl get nodes
    ```

## Deploying a Workload

Once `kubectl` is working, deploy a simple NGINX pod:
```bash
kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
```

Verify the deployment. You should see `pod/nginx` in the `default` namespace.
```bash
kubectl get all --all-namespaces
```

## Cleanup

To destroy all resources created by this project, run:
```bash
terraform destroy
```
Type `yes` to confirm the destruction.