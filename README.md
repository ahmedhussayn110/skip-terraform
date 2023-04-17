# skip-terraform
Repo to display the configuration of IaC using Terraform

Dev team access RDS instance by sshing into the EC2 and using the follwoing command:

Warning: Please do not enter password with this command as it will save in the history, press enter and then paste the passowrd into the prompt.
```
mysql -h <database-endpoint> -P <database-port> -u <db-username> -p
```
Where database-endpoint can be found on RDS -> instance -> endpoint and database-port is 3306 and db-username is skip. Password can be obtained from parameter store with path /skip/pass. 

Please refer architecture here: https://docs.google.com/document/d/1nFaPm7H95fwrPYgLzG42GEF33K7XoOYH7qQDvOep4Yw/edit?usp=sharing
