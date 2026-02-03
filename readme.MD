* In This we are




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
    


