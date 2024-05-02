#!/bin/bash

cor_vermelha='\033[0;31m'
cor_verde='\033[0;32m'
reset='\033[0m'

echo "Digite o nome do seu usuário: "
read usuario

if [ "$EUID" -ne 0 ]; then
    echo -e "${cor_vermelha}ERRO: Este script precisa ser executado como root. Por favor, execute-o com sudo.${reset}"
    exit 1
fi

echo -e "Script desenvolvido por Emanuel Cascais\n"

check_user() {
    if [ ! ls -l /mnt/c/Users | grep $usuario ]; then
        echo -e "O usuário informado não existe. \nPor favor, execute o script novamente e informe o usuário do seu computador."
        exit 1
    fi
}

bashrc_config() {
    bashrc_content=$(curl -s https://raw.githubusercontent.com/mirandaemanu/hyper_config/main/bashrc_content);
    mv ~/.bashrc{,-backup};
    echo "$bashrc_content" > ~/.bashrc
    sed -i "s#usuario#$usuario#g" ~/.bashrc
    echo -e "Arquivo .bashrc configurado: ${cor_verde}OK${reset}";
}

ssh_keys_config() {
    if [ -d /mnt/c/Users/$usuario/.ssh/ ]; then
        mkdir ~/.ssh 2> /dev/null
        rsync -avz /mnt/c/Users/$usuario/.ssh/id* ~/.ssh > /dev/null
        chmod 600 ~/.ssh/*
        echo -e "Chave SSH configurada: ${cor_verde}OK${reset}"
    else
        echo -e "${cor_vermelha}ERRO: A chave SSH ainda não foi configurada.${reset}"
        echo "Para corrigir, gere uma nova chave SSH e configure no IPA, conforme a documentação:"
        exit 1
    fi
}

fix_jump_connection() {
    jump="jump1.pro1.eigbox.com"
    echo -e "\nTestando a conexão com o JUMP.."
    if  ! ping -c 4 "$jump" > /dev/null 2>&1  ; then
        sed -i "/# generateHosts = false/a 10.25.73.241   jump1.pro1.eigbox.com\n10.25.73.242   jump2.pro1.eigbox.com\n185.199.108.133   raw.githubusercontent.com" /etc/hosts 2> /dev/null
        chattr +i /etc/hosts
    fi
    echo -e "${cor_verde}Conexão bem sucedida ${reset}"
}

set_hyper_config() {
    hyper_config=$(curl -s https://raw.githubusercontent.com/mirandaemanu/hyper_config/main/hyper_config)
    echo "$hyper_config" > /mnt/c/Users/$usuario/AppData/Roaming/Hyper/.hyper
    echo -e "Configurações do hyper ajustadas: ${cor_verde}OK${reset}"
}

done_message() {
    echo -e "\n${cor_verde}O Hyper foi configurado com sucesso!${reset}\nPara acessar, basta abrir o hyper e digitar um dos comandos a seguir:\neig1\neig2${reset}"

}

fix_jump_connection
bashrc_config
ssh_keys_config
set_hyper_config
done_message