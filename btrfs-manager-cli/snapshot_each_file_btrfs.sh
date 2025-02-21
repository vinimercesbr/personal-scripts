#!/bin/bash

# Diretório de origem
SOURCE_DIR="/home"

# Diretório de destino para snapshots
SNAPSHOT_DIR="/backup/user/.snapshots"

# Criar diretório de snapshots se não existir
mkdir -p "$SNAPSHOT_DIR"

# Função para criar snapshot de um arquivo
create_snapshot() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    local snapshot_name="$SNAPSHOT_DIR/$file_name-$(date +%Y%m%d_%H%M%S).snapshot"
    
    # Criar uma cópia do arquivo
    if sudo btrfs subvolume snapshot "$file_path" "$snapshot_name"; then
        echo "Snapshot criado para $file_path em $snapshot_name"
    else
        echo "Erro ao criar snapshot para $file_path"
    fi
}

# Processar cada arquivo no diretório de origem
for file_path in "$SOURCE_DIR"/*; do
    if [ -f "$file_path" ]; then
        create_snapshot "$file_path"
    fi
done

echo "Todos os snapshots foram criados com sucesso!"
