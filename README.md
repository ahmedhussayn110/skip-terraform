# skip-terraform
Repo to display the configuration of IaC using Terraform

Dev team can access RDS instance by sshing into the EC2 and using the follwoing command:

Warning: Please do not enter password with this command as it will save in the history, press enter and then paste the passowrd into the prompt.
```
mysql -h <database-endpoint> -P <database-port> -u <db-username> -p
```
Where database-endpoint can be found on RDS -> instance -> endpoint and database-port is 3306 and db-username is skip. Password can be obtained from parameter store with path /skip/pass. 

Please refer architecture and explanation in here:

<img width="816" alt="Screenshot 2023-04-16 at 10 31 25 PM" src="https://user-images.githubusercontent.com/20404165/232389710-d1f26bf1-be37-40f1-9b71-b56f5b205426.png">

Video explanation of the setup:

Part 1 Diagram: https://drive.google.com/file/d/1tAymD_3ZTAvDanggzmWjjLzEgfIrLMG5/view?usp=share_link

Part 2 Script: https://drive.google.com/file/d/11rTyT1smNDFwV9LW9-Pe7HQAaXP-HFlz/view?usp=sharing
