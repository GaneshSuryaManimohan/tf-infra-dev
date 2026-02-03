## 🏗️ Infra Architecture

<p align="center">
  <img src="tf-infra-dev.drawio.svg"
       alt="Infrastructure Architecture"
       width="900">
</p>


#### VPC:
* We created a VPC with name **expense-dev-vpc** and inside VPC:
    1. We created 3 subnets:
        - *Public, Private, & Database* subnets in 2 availability zones (us-east-1a & us-east-1b)
    2. We created *Internet Gateway* and attached to VPC
    3. We created route tables:
        - *Public, Private, & Database* and their association
    4. We created a *NAT Gateway*
    5. We created routes for the route tables
    6. Established Peering connection between *expense-dev-vpc* and *default-vpc* and routes are created for peering.

#### Security Groups:

<img src="sg-rules.svg" 
     alt="Infrastructure Architecture"
     width="900">

* We created security groups
    1. *expense-dev-backend*    : Security group for backend servers
    2. *expense-dev-bastion*    : Security group for bastion servers
    3. *expense-dev-db*         : Security group for database servers
    4. *expense-dev-frontend*   : Security group for frontend servers
    5. *expense-dev-vpn*        : Security group for VPN
    6. *expense-dev-web-alb*    : SG for Web ALB Instances
    7. *expense-dev-app-alb*    : Security group for App ALB

* Created security group rules:
    1. *expense-dev-app-alb* : Port: 80, Inbound from `expense-dev-frontend & expense-dev-vpn` ; Outboud: Eveywhere (0.0.0.0/0)
    2. *expense-dev-web-alb* : Port: 80,443, Inbound from everywhere HTTP & HTTPS. Outbound: Everywhere
    3. *expense-dev-vpn*     : Port: 22,443,943,1194. Inbound & Outbound from everywhere 
    4. *expense-dev-frontend* : Port: 22,80. Inbound from `expense-dev-bastion` on port 22 & Outbound:Everywhere
    5. *expense-dev-db*      : Port: 3306, Inbound from `expense-dev-bastion, expense-dev-backend, & expense-dev-vpn`. Outbound: Everywhere
    6. *expense-dev-bastion* : Port: 22, Inbound & Outbound from Everywhere
    7. *expense-dev-backend* : Inbound: `expense-dev-vpn & expense-dev-bastion` on port 22; `expense-dev-app-alb & expense-dev-vpn` on port 8080. Outbound Everywhere.

#### 




    


* For expense-dev-app-alb 2 listener rules:

    1. If Host header (value) = backend.app-dev.surya-devops.site then:
        Forward to target group "expense-dev-backend"
        where we can check http://backend.app-dev.surya-devops.site/health , http://backend.app-dev.surya-devops.site/transaction etc. 
    
    2. Last Default If no other rule applies then it will return fixed response:
        "This is the default response for the application load balancer"


* For expense-dev-web-alb 2 listener rules:
 
    1. If http://web-dev.surya-devops.site/ == on HTTP (port: 80) then it will return fixed response:
        "This is the default response for the WEB ALB"

    2. If https://web-dev.surya-devops.site/ == on HTTPS (port: 443) then it will return fixed response:
        "This is the default response for the WEB ALB HTTPS"
    


