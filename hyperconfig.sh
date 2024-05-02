#!/bin/bash

echo "Script desenvolvido por Emanuel Cascais"

bashrc_config() {
    bashrc_content=$(curl -s https://raw.githubusercontent.com/mirandaemanu/hyper_config/main/bashrc_content);
    mv ~/teste.txt{,-backup};
    echo "$bashrc_content" > ~/teste.txt
    sed -i "s#usuario#$USER#g" ~/teste.txt
}

ssh_keys_config() {
    if [ -d /mnt/c/Users/$USER/.ssh/ ]; then
        mkdir ~/sshteste 2> /dev/null
        rsync -avz /mnt/c/Users/$USER/.ssh/teste* ~/sshteste > /dev/null
        chmod 600 ~/sshteste/*
    else
        echo "ERRO: A chave SSH ainda não foi configurada."
        echo "Para corrigir, gere uma nova chave SSH e configure no IPA, conforme a documentação:"
    fi
}

fix_jump_connection() {
    jump="jump31.pro1.eigbox.com"
    echo "Testando a conexão com o JUMP.."
    if  ping -c 4 $jump > /dev/null 2>&1 ; then
        echo "Conexão bem sucedida"
    else
        echo "Digite a senha do seu usuário (OBS: por questões de segurança, a senha não irá aparecer no terminal)"
        sudo sh -c "sed -i '/# generateHosts = false/a 10.25.73.241   jump1.pro1.eigbox.com/a 10.25.73.242   jump2.pro1.eigbox.com' && chattr +i /etc/hosts"
    fi
}

bashrc_config
ssh_keys_config
fix_jump_connection