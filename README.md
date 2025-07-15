# Nomad on Azure

This is an accompanying repository for a series of blog posts I publish on my [blog](https://mattias.engineer).

## Part 1: A first attempt to provision servers

Find the blog post at [mattias.engineer/blog/2025/nomad-on-azure-1](https://mattias.engineer/blog/2025/nomad-on-azure-1).

The source code for this part is available in the directory [part01](./part01/).

## Part 2: The one where we introduce Consul

Find the blog post at [mattias.engineer/blog/2025/nomad-on-azure-2](https://mattias.engineer/blog/2025/nomad-on-azure-2).

The source code for this part is available in the directory [part02](./part02/).

## Part 3: Nomad clients and a first Nomad job

In this part we add **Nomad clients** and run our first **Nomad job** on one of the clients.

Find the blog post at [mattias.engineer/blog/2025/nomad-on-azure-3](https://mattias.engineer/blog/2025/nomad-on-azure-3).

The source code for this part is available in the directory [part03](./part03/).

## Part 4: Nomad UI and Azure Load Balancer

In this part we add an **Azure load balancer** for our Nomad servers and we access the **Nomad UI** through the load balancer.

Find the blog post at [mattias.engineer/blog/2025/nomad-on-azure-4](https://mattias.engineer/blog/2025/nomad-on-azure-4).

The source code for this part is available in the directory [part04](./part04/).

## Part 5: DNS, TLS, and Gossip Encryption

In this part we enable mutual TLS and gossip encryption. We also add a DNS record for the Azure load balancer so that we can reach the Nomad servers through a nice name instead of an IP address.

Find the blog post at [mattias.engineer/blog/2025/nomad-on-azure-5](https://mattias.engineer/blog/2025/nomad-on-azure-5).

The source code for this part is available in the directory [part05](./part05/).

## Part 6: Nomad Enterprise, enable ACLs, and refactor Terraform configurations

In this part we move from Nomad community edition to Nomad Enterprise. We also enable the ACL system and touch on the subject of tokens, policies, and roles. Finally, the Terraform configuration is refactored into separate Terraform configurations for platform components (virtual network), Consul servers, Nomad servers, and Nomad clients.

Find the blog post at [mattias.engineer/blog/2025/nomad-on-azure-6](https://mattias.engineer/blog/2025/nomad-on-azure-6).

The source code for this part is available in the directory [part06](./part06/).

## Part 7:

In this part we strengthen the Consul cluster security by enabling mTLS and gossip encryption. We also provision an Azure private DNS resolver in our shared platform virtual network and make Consul answer DNS queries for the `.consul` domain.

Find the blog post at [mattias.engineer/blog/2025/nomad-on-azure-7](https://mattias.engineer/blog/2025/nomad-on-azure-7).

The source code for this part is available in the directory [part07](./part07/).