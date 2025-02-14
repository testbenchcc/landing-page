# landing-page
Bash-generated index.html page that lists all Docker services currently running on the host."

# Usage
- Used in conjunction with NGINX. This script will generate the index.html file NGINX will serve. In the portainer configuration, we need to add a bind volume:
  ![image](https://github.com/user-attachments/assets/5ce26eec-3801-4740-adc3-a84721918726)
- Then we need to add the script to a chron job using `crontab -e`
  - Every min: `* * * * * ~/get-containers.sh`
  - Every hour: `0 * * * * ~/get-containers.sh`

# Result
![image](https://github.com/user-attachments/assets/c34a2a56-09a2-4acd-af5d-551f62f752ac)
