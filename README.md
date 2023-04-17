# skip-terraform
Repo to display the configuration of IaC using Terraform

Dev team can access RDS instance by sshing into the EC2 and using the follwoing command:

Warning: Please do not enter password with this command as it will save in the history, press enter and then paste the passowrd into the prompt.
```
mysql -h <database-endpoint> -P <database-port> -u <db-username> -p
```
Where database-endpoint can be found on RDS -> instance -> endpoint and database-port is 3306 and db-username is skip. Password can be obtained from parameter store with path /skip/pass. 

Please refer architecture here:
<img width="798" alt="Screenshot 2023-04-16 at 9 49 40 PM" src="https://user-images.githubusercontent.com/20404165/232381066-c7405322-ab5c-48fe-9d02-d0a5d15fb8b6.png">


