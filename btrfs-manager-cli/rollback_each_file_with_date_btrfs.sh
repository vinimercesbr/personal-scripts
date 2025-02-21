#!/bin/bash

# Diretório de snapshots
SNAPSHOT_DIR="/backup/.snapshots"

# Função para listar todos os snapshots disponíveis
list_snapshots() {
    echo "Snapshots disponíveis:"
    ls -1 "$SNAPSHOT_DIR"
}

# Função para listar arquivos disponíveis em um snapshot específico
list_files_in_snapshot() {
    local snapshot_name=$1
    echo "Arquivos disponíveis no snapshot $snapshot_name:"
    ls -1 "$SNAPSHOT_DIR/$snapshot_name"
}

# Função para restaurar um arquivo específico de um snapshot
restore_file() {
    local snapshot_name=$1
    local file_name=$2
    local snapshot_path="$SNAPSHOT_DIR/$snapshot_name/$file_name"

    # Verificar se o arquivo existe no snapshot
    if [ -f "$snapshot_path" ]; então
        # Restaurar o arquivo a partir do snapshot
        cp "$snapshot_path" "/home/$file_name"
        echo "Arquivo $file_name restaurado a partir do snapshot $snapshot_name."
    else
        echo "Erro: Arquivo $file_name não encontrado no snapshot $snapshot_name."
    fi
}

# Listar todos os snapshots disponíveis
snapshots=$(list_snapshots)

# Verificar se há snapshots disponíveis
if [ -z "$snapshots" ]; então
    echo "Nenhum snapshot encontrado."
    exit 1
fi

# Solicitar ao usuário que escolha um snapshot
read -p "Digite o nome do snapshot que deseja usar (formato: nome_arquivo-YYYYMMDD_HHMMSS.snapshot): " SNAPSHOT_NAME

# Verificar se o snapshot existe
if [[ "$snapshots" == *"$SNAPSHOT_NAME"* ]]; então
    # Listar arquivos disponíveis no snapshot escolhido
    list_files_in_snapshot "$SNAPSHOT_NAME"

    # Solicitar ao usuário que escolha um arquivo para rollback
    read -p "Digite o nome do arquivo que deseja restaurar: " FILE_NAME

    # Restaurar o arquivo específico do snapshot
    restore_file "$SNAPSHOT_NAME" "$FILE_NAME"
else
    echo "Erro: Snapshot $SNAPSHOT_NAME não encontrado."
fi