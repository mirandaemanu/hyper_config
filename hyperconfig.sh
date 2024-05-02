#!/bin/bash

cor_vermelha='\033[0;31m'
cor_verde='\033[0;32m'
reset='\033[0m'

echo -e "Script desenvolvido por Emanuel Cascais\n"

bashrc_config() {
    bashrc_content=$(curl -s https://raw.githubusercontent.com/mirandaemanu/hyper_config/main/bashrc_content);
    mv ~/teste.txt{,-backup};
    echo "$bashrc_content" > ~/teste.txt
    sed -i "s#usuario#$USER#g" ~/teste.txt
    echo -e "Arquivo .bashrc configurado: ${cor_verde}OK${reset}";
}

ssh_keys_config() {
    if [ -d /mnt/c/Users/$USER/.ssh/ ]; then
        mkdir ~/.ssh 2> /dev/null
        rsync -avz /mnt/c/Users/$USER/.ssh/id* ~/.ssh > /dev/null
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
    if  ping -c 4 $jump > /dev/null 2>&1 ; then
        echo -e "${cor_verde}Conexão bem sucedida ${reset}"
    else
        echo "Digite a senha do seu usuário (OBS: por questões de segurança, a senha não irá aparecer no terminal)"
        sudo sh -c "sed -i '/# generateHosts = false/a 10.25.73.241   jump1.pro1.eigbox.com/a 10.25.73.242   jump2.pro1.eigbox.com' && chattr +i /etc/hosts"
        echo -e "${cor_verde}Conexão bem sucedida ${reset}"
    fi
}

set_hyper_config() {
    hyper_config=$(curl -s https://raw.githubusercontent.com/mirandaemanu/hyper_config/main/hyper_config)
    echo "$hyper_config" > /mnt/c/Users/ecascais/AppData/Roaming/Hyper/.hyper
    echo -e "Configurações do hyper ajustadas: ${cor_verde}OK${reset}"
}

done_message() {
    echo -e "\n${cor_verde}O Hyper foi configurado com sucesso!${reset}\nPara acessar, basta abrir o hyper e digitar um dos comandos a seguir:\neig1\neig2${reset}"

}

bashrc_config
ssh_keys_config
set_hyper_config
fix_jump_connection
done_message