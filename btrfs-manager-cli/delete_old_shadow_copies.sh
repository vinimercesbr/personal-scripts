#!/bin/bash

# Diretório de snapshots
SNAPSHOT_DIR="/backup/.snapshots"

# Função para excluir snapshots antigos de um arquivo
delete_old_snapshots() {
    local file_name=$1
    # Usar find para buscar arquivos e ordená-los pela data de criação
    local snapshots=$(find "$SNAPSHOT_DIR" -type f -name "*$file_name*" -print0 | xargs -0 ls -1t)
    local snapshots_array=($snapshots)
    local snapshot_count=${#snapshots_array[@]}

    if [ $snapshot_count -gt 3 ]; then
        # Excluir snapshots mais antigos
        local snapshots_to_delete=("${snapshots_array[@]:3}")
        for snapshot in "${snapshots_to_delete[@]}"; do
            sudo btrfs subvolume delete "$snapshot"
            echo "Snapshot excluído: $snapshot"
        done
    fi
}

# Processar cada arquivo de snapshot no diretório de snapshots
for snapshot_path in "$SNAPSHOT_DIR"/*; do
    file_name=$(basename "$snapshot_path" | cut -d'-' -f1)
    delete_old_snapshots "$file_name"
done

echo "Snapshots antigos excluídos com sucesso!"
