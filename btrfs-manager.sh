#!/bin/bash

# Diretórios
DIR_MOUNT="/mnt"

# Função para listar os usuários
list_users() {
    echo "Usuários disponíveis no sistema:"
    cut -d: -f1 /etc/passwd
    echo
}

# Função para obter o diretório home do usuário
get_user_home() {
    while true; do
        echo -n "Digite o nome do usuário para determinar o diretório home (ou 'sair' para cancelar): "
        read USERNAME

        if [[ "$USERNAME" == "sair" ]]; then
            return 1
        fi

        DIR_HOME=$(eval echo ~$USERNAME)

        # Verificar se o diretório home existe
        if [ ! -d "$DIR_HOME" ]; then
          echo "Erro: O usuário '$USERNAME' não existe ou o diretório home não foi encontrado!"
        else
          echo "Diretório home do usuário $USERNAME é $DIR_HOME"
          return 0
        fi
    done
}

# Função para criar um sistema de arquivos Btrfs
create_filesystem() {
    lsblk -f | grep sd
    echo -n "Digite o dispositivo para criar o sistema de arquivos (ex: /dev/sda1): "
    read DEVICE

    # Verificar se o dispositivo existe
    if [ ! -b "$DEVICE" ]; then
        echo "Erro: O dispositivo '$DEVICE' não foi encontrado ou não é um dispositivo de bloco!"
        return 1
    fi

    echo "Criando sistema de arquivos Btrfs em $DEVICE..."
    if ! sudo mkfs.btrfs -f $DEVICE; then
        echo "Erro ao criar o sistema de arquivos em $DEVICE!"
        return 1
    fi
    echo "Sistema de arquivos criado com sucesso em $DEVICE."
}

# Função para montar um sistema de arquivos Btrfs
mount_filesystem() {
    echo -n "Digite o dispositivo para montar o sistema de arquivos (ex: /dev/sda1): "
    read DEVICE

    # Verificar se o dispositivo existe
    if [ ! -b "$DEVICE" ]; then
        echo "Erro: O dispositivo '$DEVICE' não foi encontrado ou não é um dispositivo de bloco!"
        return 1
    fi

    echo "Montando sistema de arquivos Btrfs em $DIR_MOUNT..."
    if ! sudo mount $DEVICE $DIR_MOUNT; then
        echo "Erro ao montar o sistema de arquivos em $DEVICE!"
        return 1
    fi
    echo "Sistema de arquivos montado em $DIR_MOUNT."
}

# Função para criar um subvolume
create_subvolume() {
    echo -n "Digite o nome do subvolume a ser criado: "
    read SUBVOLUME_NAME

    # Verificar se o subvolume já existe
    if [ -d "$DIR_MOUNT/$SUBVOLUME_NAME" ]; then
        echo "Erro: O subvolume '$SUBVOLUME_NAME' já existe!"
        return 1
    fi

    echo "Criando subvolume $SUBVOLUME_NAME..."
    if ! sudo btrfs subvolume create $DIR_MOUNT/$SUBVOLUME_NAME; then
        echo "Erro ao criar o subvolume!"
        return 1
    fi
    echo "Subvolume $SUBVOLUME_NAME criado com sucesso."
}

# Função para listar subvolumes
list_subvolumes() {
    echo "Listando subvolumes..."
    sudo btrfs subvolume list $DIR_MOUNT
}

# Função para criar um snapshot
create_snapshot() {
    if [ ! -d "$DIR_HOME/.snapshots" ]; then
        mkdir -p $DIR_HOME/.snapshots
    fi
    SNAPSHOT_NAME=$(date +%Y-%m-%d_%H-%M-%S)
    echo "Criando snapshot $SNAPSHOT_NAME..."
    if ! sudo btrfs subvolume snapshot $DIR_HOME $DIR_HOME/.snapshots/$SNAPSHOT_NAME; then
        echo "Erro ao criar snapshot!"
        return 1
    fi
    echo "Snapshot $SNAPSHOT_NAME criado com sucesso."
}

# Função para listar snapshots
list_snapshots() {
    echo "Listando snapshots..."
    sudo btrfs subvolume list $DIR_HOME/.snapshots
}

# Função para restaurar um snapshot
restore_snapshot() {
    echo "Snapshots disponíveis:"
    list_snapshots

    while true; do
        echo -n "Digite o nome do snapshot a ser restaurado (ou 'sair' para cancelar): "
        read SNAP_NAME

        if [[ "$SNAP_NAME" == "sair" ]]; then
            return 1
        fi

        if [ ! -d "$DIR_HOME/.snapshots/$SNAP_NAME" ]; then
            echo "Erro: O snapshot '$SNAP_NAME' não foi encontrado!"
        else
            if ! sudo btrfs subvolume set-default $DIR_HOME/.snapshots/$SNAP_NAME; then
                echo "Erro ao restaurar o snapshot!"
                return 1
            fi
            echo "Snapshot restaurado: $SNAP_NAME"
            return 0
        fi
    done
}

# Função para verificar integridade (scrub)
scrub_filesystem() {
    echo "Iniciando verificação de integridade..."
    if ! sudo btrfs scrub start $DIR_MOUNT; then
        echo "Erro ao iniciar verificação de integridade!"
        return 1
    fi
    echo "Verificação de integridade iniciada com sucesso."
}

# Função para balancear dados (balance)
balance_filesystem() {
    echo "Iniciando rebalanceamento de dados..."
    if ! sudo btrfs balance start $DIR_MOUNT; then
        echo "Erro ao iniciar rebalanceamento de dados!"
        return 1
    fi
    echo "Rebalanceamento de dados iniciado com sucesso."
}

# Função para verificar o sistema de arquivos
check_filesystem() {
    echo -n "Digite o dispositivo para verificar o sistema de arquivos (ex: /dev/sda1): "
    read DEVICE

    # Verificar se o dispositivo existe
    if [ ! -b "$DEVICE" ]; then
        echo "Erro: O dispositivo '$DEVICE' não foi encontrado ou não é um dispositivo de bloco!"
        return 1
    fi

    echo "Verificando o sistema de arquivos em $DEVICE..."
    if ! sudo btrfs check $DEVICE; then
        echo "Erro ao verificar o sistema de arquivos em $DEVICE!"
        return 1
    fi
    echo "Sistema de arquivos verificado com sucesso."
}

# Menu
list_users  # Lista os usuários antes de qualquer outra opção

while true; do
    echo "Escolha uma opção:"
    echo "1. Criar sistema de arquivos Btrfs"
    echo "2. Montar sistema de arquivos Btrfs"
    echo "3. Criar subvolume"
    echo "4. Listar subvolumes"
    echo "5. Criar snapshot"
    echo "6. Listar snapshots"
    echo "7. Restaurar snapshot"
    echo "8. Verificação de integridade (scrub)"
    echo "9. Rebalancear dados (balance)"
    echo "10. Verificar sistema de arquivos"
    echo "0. Sair"
    echo -n "Opção: "
    read OPTION

    case $OPTION in
        1)
            create_filesystem
            ;;
        2)
            mount_filesystem
            ;;
        3)
            create_subvolume
            ;;
        4)
            list_subvolumes
            ;;
        5)
            if get_user_home; then
                create_snapshot
            fi
            ;;
        6)
            if get_user_home; then
                list_snapshots
            fi
            ;;
        7)
            if get_user_home; then
                restore_snapshot
            fi
            ;;
        8)
            scrub_filesystem
            ;;
        9)
            balance_filesystem
            ;;
        10)
            check_filesystem
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
done
