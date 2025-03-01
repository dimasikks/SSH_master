#!/bin/bash

echo -e "\nWelcome to SSH_master - script that makes ssh operations without sspass!"

if [ $(grep ssh_master ~/.bashrc | wc -l) -eq 0 ]; then
    echo "alias ssh_master='bash $(pwd)/ssh_master.sh'" >> ~/.bashrc
fi

source ~/.bashrc
source init.env

hosts=""

echo -e "\nCHOICE: (1) hosts file is configured\n\t(2) manually input"
read -p "REQUEST: option: " choice

if [ $choice -eq 1 ]; then
    hosts_file="$hosts_file"

    if [ ! -f "$hosts_file" ]; then
        echo -e "\n\033[31mERROR:\033[0m hosts file not found"
        exit 1
    fi

    hosts=($(<"$hosts_file"))
fi

if [ $choice -eq 2 ]; then
    echo -e "\nREQUEST: enter your hosts, ex: 1.1.1.1 192.160.10.10 200.200.10.10"
    read -p "REQUEST: hosts: " hosts
fi

echo -e "\nINFO: your hosts now:\n"
i=0
for host in "${hosts[@]}"; do
    ((i++))
    echo -e "$i \t=>\t $host"
done

echo -e "\nTotal: $i"

echo -e "\nCHOICE: (1) check the network availability of machines via ping\n\t(2) skip"
read -p "REQUEST: option: " choice

if [ $choice -eq 1 ]; then
    count_problem_hosts=0
    problem_hosts=()
    for host in "${hosts[@]}"; do
        echo -e "\nINFO: trying $host"

        ping -c 1 "$host" > /dev/null

        if [ $(echo $?) -ne 0 ]; then
            echo -e "\033[32mWARNING:\033[0m problem with $host"
            ((count_problem_hosts++))
            problem_hosts+=("$host")
        else 
            echo -e "INFO: \033[33mSUCCESS\033[0m"
        fi
    done

    if [ $count_problem_hosts -ne 0 ]; then
        echo -e "\n\033[31mERROR:\033[0m some hosts have problems"
        echo -e "\nProblem hosts: "
        for host in "${problem_hosts[@]}"; do
            echo "$host"
        done
        echo -e "\nTotal: $count_problem_hosts"
        exit 1
    else
        echo -e "INFO: all hosts are available"
    fi
fi

echo -e "\nCHOICE: (1) - login with ssh to hosts for make something\n\t(2) - exec with ssh some commands at hosts\n\t(3) - copy with ssh-copy-id ssh keys to hosts\n\t(4) - copy files with scp from your host to other hosts"
read -p "REQUEST: option: " choice

export SSH_ASKPASS="$path_to_generate_pass/.ssh"
export DISPLAY="YOUDOINGITWRONG"
pswd_path="$path_to_generate_pass/.ssh"

if [ $choice -eq 1 ]; then
    user="$user"
    password="$password"

    for host in "${hosts[@]}"; do
        if [[ -z "$user" && -z "$password" ]]; then
            echo -e "\nREQUEST: enter user and password, ex: admin 1234"
            read -p "REQUEST: user: " user 
            read -sp "REQUEST: password: " password
            echo -e "\n"           
        fi
        
        echo "echo $password" > "$pswd_path" && chmod +x "$pswd_path"

        echo -e "\nINFO: connecting to $host"
        setsid ssh -o StrictHostKeyChecking=no -q "$user@$host"
    done
fi

if [ $choice -eq 2 ]; then
    user="$user"
    password="$password"

    echo -e "\nREQUST: enter command to execute at hosts, ex: hostname"
    read -p "REQUEST: command: " command

    for host in "${hosts[@]}"; do
        if [[ -z "$user" && -z "$password" ]]; then
            echo -e "\nREQUEST: enter user and password, ex: admin 1234"
            read -p "REQUEST: user: " user 
            read -sp "REQUEST: password: " password
            echo -e "\n"           
        fi

        echo "echo $password" > "$pswd_path" && chmod +x "$pswd_path"

        echo -e "\n\nINFO: result of $host\n"
        setsid ssh -o StrictHostKeyChecking=no -q "$user@$host" "$command"
    done
fi

if [ $choice -eq 3 ]; then
    user="$user"
    password="$password"

    echo -e "\nINFO: creating new ssh-key"
    rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -q -N "" > /dev/null
    if [ $(echo $?) -ne 0 ]; then
        echo -e "\033[31mERROR:\033[0m ssh-key was not created"
        exit 1
    else 
        echo -e "INFO: \033[33mSUCCESS\033[0m"
    fi

    error_count=0

    for host in "${hosts[@]}"; do
        if [[ -z "$user" && -z "$password" ]]; then
            echo -e "\nREQUEST: enter user and password, ex: admin 1234"
            read -p "REQUEST: user: " user 
            read -sp "REQUEST: password: " password
            echo -e "\n"           
        fi

        echo "echo $password" > "$pswd_path" && chmod +x "$pswd_path"

        echo -e "\nINFO: copying ssh-key to $host"
        setsid ssh-copy-id -o StrictHostKeyChecking=no "$user@$host" > /dev/null 2>&1

        if [ $(echo $?) -ne 0 ]; then
            echo -e "\033[32mWARNING:\033[0m something is wrong with $host. Key was not delivered"
            ((error_count++))
        else
            echo -e "INFO: \033[33mSUCCESS\033[0m"
        fi
    done

    if [ $error_count -eq 0 ]; then
        echo -e "\nINFO: all keys have been successfully delivered to all hosts"
    else
        echo -e "\nINFO: several errors occurred during execution: $error_count. Check the machines above that are having problems"
    fi
fi

if [ $choice -eq 4 ]; then
    user="$user"
    password="$password"

    echo -e "\nCHOICE: (1) same path for copying on the local machine and the same path on the hosts all times\n\t(2) individual manually input paths each time"
    read -p "REQUEST: option: " choice

    if [ "$choice" -eq 1 ]; then
        echo -e "\nREQUEST: enter path at localhost, ex: /home/user/somefile.txt /tmp/files/anotherfile.env "
        read -p "REQUEST: local_path: " local_path
        echo -e "REQUEST: enter remote path at all hosts, ex: /home/user/"
        read -p "REQUEST: remote_path: " remote_path

        for host in "${hosts[@]}"; do
            if [[ -z "$user" && -z "$password" ]]; then
                echo -e "\nREQUEST: enter user and password, ex: admin 1234"
                read -p "REQUEST: user: " user 
                read -sp "REQUEST: password: " password
                echo -e "\n"           
            fi

            echo "echo $password" > "$pswd_path" && chmod +x "$pswd_path"

            echo -e "\nINFO: copying files to $host"
            setsid scp -r -o StrictHostKeyChecking=no -q "$local_path" "$user@$host:$remote_path"
        done
    fi

    if [ "$choice" -eq 2 ]; then
        for host in "${hosts[@]}"; do
            if [[ -z "$user" && -z "$password" ]]; then
                echo -e "\nREQUEST: enter user and password, ex: admin 1234"
                read -p "REQUEST: user: " user 
                read -sp "REQUEST: password: " password
                echo -e "\n"           
            fi

            echo -e "\nREQUEST: enter path at localhost, ex: /home/user/somefile.txt /tmp/files/anotherfile.env "
            read -p "REQUEST: local_path: " local_path
            echo -e "REQUEST: enter remote path for $host, ex: /home/user/"
            read -p "REQUEST: remote_path: " remote_path

            echo "echo $password" > "$pswd_path" && chmod +x "$pswd_path"

            echo -e "\nINFO: copying files to $host"
            setsid scp -r -o StrictHostKeyChecking=no -q "$local_path" "$user@$host:$remote_path"

            if [ $(echo $?) -ne 0 ]; then
                echo -e "\033[32mWARNING:\033[0m something is wrong with $host. Files were not copied."
                ((error_count++))
            else
                echo -e "INFO: SUCCESS"
            fi
        done
    fi
fi

if [ -f "$pswd_path" ]; then
    rm "$pswd_path"
fi