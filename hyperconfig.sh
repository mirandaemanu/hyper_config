#!/bin/bash

cor_vermelha='\033[0;31m'
cor_verde='\033[0;32m'
reset='\033[0m'
usuario=$(echo $SUDO_USER)
usuario_windows=$(/mnt/c/Windows/System32/cmd.exe /C whoami 2> /dev/null | tr -d '\r' | cut -d\\ -f2 2> /dev/null) 
current_time=$(date +%s)
generated_new_keys=false
parametro=$1

if [ $EUID -ne 0 ]; then
    echo -e "${cor_vermelha}ERRO:${reset} O script deve ser executado com o usuário root. \nPor gentileza, execute novamente utilizando o comando sudo."
    exit 1
fi

echo -e "${cor_verde}
╔╗─╔╗────────────╔═══╗─────╔═╗───────────╔╗───────
║║─║║────────────║╔═╗║─────║╔╝──────────╔╝╚╗──────
║╚═╝╠╗─╔╦══╦══╦═╗║║─╚╬══╦═╦╝╚╦╦══╦╗╔╦═╦═╩╗╔╬╦══╦═╗
║╔═╗║║─║║╔╗║║═╣╔╝║║─╔╣╔╗║╔╬╗╔╬╣╔╗║║║║╔╣╔╗║║╠╣╔╗║╔╗╗
║║─║║╚═╝║╚╝║║═╣║─║╚═╝║╚╝║║║║║║║╚╝║╚╝║║║╔╗║╚╣║╚╝║║║║
╚╝─╚╩═╗╔╣╔═╩══╩╝─╚═══╩══╩╝╚╩╝╚╩═╗╠══╩╝╚╝╚╩═╩╩══╩╝╚╝
────╔═╝║║║────────────────────╔═╝║────────────────
────╚══╝╚╝────────────────────╚══╝────────────────"
echo -e "Script desenvolvido por Emanuel Cascais${reset}\n"

generate_new_keys() {
    generated_new_keys=true
    ssh_keys_path="/home/$usuario"
    if [ -z "$usuario" ]  || [ $usuario == 'root' ]; then ssh_keys_path="/root"; fi
    mkdir $ssh_keys_path/.ssh 2> /dev/null
    if ls $ssh_keys_path/.ssh | grep -cq "id_rsa"; then
        mkdir $ssh_keys_path/.ssh/bkp-$current_time 2> /dev/null
        mv $ssh_keys_path/.ssh/id_rsa* $ssh_keys_path/.ssh/bkp-$current_time 2> /dev/null
    fi
    if [ ! $usuario == 'root' ]; then
        su -c "ssh-keygen -b 4096 -t rsa -f $ssh_keys_path/.ssh/id_rsa -q -N ''" $usuario
        sed -i "s#root#$usuario#g" $ssh_keys_path/.ssh/id_rsa 
        sed -i "s#root#$usuario#g" $ssh_keys_path/.ssh/id_rsa.pub
        chown $usuario:$usuario $ssh_keys_path/.ssh/id_*
        return
    fi
     ssh-keygen -b 4096 -t rsa -f $ssh_keys_path/.ssh/id_rsa -q -N ""
}

bashrc_config() {
    bashrc_content=$(curl -s https://raw.githubusercontent.com/mirandaemanu/hyper_config/main/bashrc_content)
    bashrc_path="/home/$usuario"
    [ -z "$usuario" ] && bashrc_path="/root";
    [ "$usuario" == 'root' ] && bashrc_path="/root"
    mv $bashrc_path/.bashrc{,-$current_time}
    echo "$bashrc_content" > $bashrc_path/.bashrc
    sed -i "s#usuario#$usuario_windows#g" $bashrc_path/.bashrc
    chown $usuario:$usuario $bashrc_path/.bashrc
    source $bashrc_path/.bashrc
    echo -e "Arquivo .bashrc configurado: ${cor_verde}OK${reset}"
}

ssh_keys_config() {

    if [ "$parametro" == "new_key" ]; then
        generate_new_keys
        echo -e "Chave SSH configurada: ${cor_verde}OK${reset}"
        return
    fi

    ssh_keys_path="/home/$usuario"
    [ -z "$usuario" ] && ssh_keys_path="/root" 
    [ "$usuario" == 'root' ] && ssh_keys_path="/root" 

    if ! ls "/mnt/c/Users/$usuario_windows/.ssh" | grep -cq id_rsa 2> /dev/null && ! ls "$ssh_keys_path/.ssh" | grep -cq id_rsa 2> /dev/null ; then
        echo -e "${cor_vermelha}ERRO:${reset} Chave SSH não encontrada."
        read -p "Deseja gerar uma nova chave?(s/n) " resposta
        resposta=$(echo $resposta | tr '[:upper:]' '[:lower:]')
        if [ "$resposta" == "s" ] || [ "$resposta" == "sim" ]; then
            generate_new_keys
        else
            exit 1
        fi 
    fi
    if ls "/mnt/c/Users/$usuario_windows/.ssh" | grep -cq 'id_rsa' 2> /dev/null ; then
        mkdir $ssh_keys_path/.ssh 2> /dev/null
        rsync -avz /mnt/c/Users/$usuario_windows/.ssh/id* $ssh_keys_path/.ssh > /dev/null
        chmod 600 $ssh_keys_path/.ssh/*
        chown $usuario:$usuario $ssh_keys_path/.ssh $ssh_keys_path/.ssh/*
    fi
    echo -e "Chave SSH configurada: ${cor_verde}OK${reset}"
    
}

fix_jump_connection() {
    jump="jump1.pro1.eigbox.com"
    echo -e "Testando a conexão com o JUMP.."
    if ! ping -c 4 "$jump" > /dev/null 2>&1 && ! grep -cq "eigbox" /etc/hosts; then
        chattr -i /etc/hosts
        sed -i "/# generateHosts = false/a 10.25.73.241   jump1.pro1.eigbox.com\n10.25.73.242   jump2.pro1.eigbox.com" /etc/hosts 2> /dev/null
        chattr +i /etc/hosts
    fi
    echo -e "${cor_verde}Conexão bem sucedida ${reset}"
}

set_hyper_config() {
    if [ ! -d /mnt/c/Users/$usuario_windows/AppData/Roaming/Hyper ]; then
        echo -e "\n\n${cor_vermelha}ERRO:${reset} o Hyper não foi encontrado. Para baixar, acesse o link:\n${cor_verde}https://hyper.is/#installation${reset}\n\n${cor_verde}COMO CORRIGIR:${reset} Se a instalação já foi realizada, acesse o link a seguir e copie todo o conteúdo.\nEm seguida abra o Hyper e pressione CTRL + ',' para acessar as configurações. Substitua toda a configuração existente pelo conteúdo copiado do link:\n${cor_verde}https://raw.githubusercontent.com/mirandaemanu/hyper_config/main/hyper_config${reset}"
        echo -e "\nApós substituir a configuração, o Hyper estará configurado. Para acessar, basta abri-lo e executar um dos comandos abaixo:\neig1\neig2"
        exit 1
    fi
    hyper_config=$(curl -s https://raw.githubusercontent.com/mirandaemanu/hyper_config/main/hyper_config)
    mv /mnt/c/Users/$usuario_windows/AppData/Roaming/Hyper/.hyper.js{,-$current_time}
    echo "$hyper_config" > /mnt/c/Users/$usuario_windows/AppData/Roaming/Hyper/.hyper.js
    echo -e "Configurações do hyper ajustadas: ${cor_verde}OK${reset}"
    done_message
}

done_message() {

    echo -e "\n${cor_verde}O Hyper foi configurado com sucesso!${reset}\n"
    if $generated_new_keys; then
        ssh_keys_path="/home/$usuario"
        [ -z "$usuario" ] && ssh_keys_path="/root" 
        echo -e "Para que consiga acessar, será necessário apenas subir a nova chave no IPA:\n"
        echo -e "1 - Copie o conteúdo da sua chave SSH abaixo:\n"
        cat $ssh_keys_path/.ssh/id_rsa.pub
        echo -e "\n2- Acesse o IPA:\nhttps://ipa.eigbox.com/ipa/ui/"
        echo -e "\n3 - Se necessário, siga as duas primeiras etapas da documentação: ${cor_verde}Alterando a senha tempororária${reset} e ${cor_verde}Gerando a Chave SSH\nLINK DA DOCUMENTAÇÃO:${reset} https://confluence.newfold.com/display/HGBZK/%5BJump%5DNovo+eigSH"
        echo -e "\n${cor_verde}ATENÇÃO:${reset} Como a chave já foi gerada, não será necessário gerar uma nova chave SSH conforme consta na documentação. Apenas resete a senha do IPA, caso seja seu primeiro acesso, entre na plataforma e configure a chave fornecida anteriormente.\n"
        else
        echo -e "Para acessar, basta abrir o hyper e executar um dos comandos a seguir:\neig1\neig2"
    fi
    

}



fix_jump_connection
bashrc_config
ssh_keys_config
set_hyper_config