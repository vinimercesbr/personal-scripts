#!/usr/bin/env bash
# Diretórios de trabalho
TARGET_DIR="/mnt/btrfs"

# Diretório para o subvolume
DATA_SUBVOLUME="$TARGET_DIR/data_files"
SNAPSHOT_DIR="$TARGET_DIR/snapshots"

# Arquivo de log para registrar ações
LOG_FILE="$HOME/btrfs_operations.log"

# Função para criar subvolumes se não existirem
create_subvolume_if_not_exists() {
    local subvolume_path="$1"
    if [ ! -d "$subvolume_path" ]; then
        echo "Subvolume não encontrado: $subvolume_path. Criando..."
        btrfs subvolume create "$subvolume_path"
        if [ $? -ne 0 ]; then
          echo "Erro ao criar subvolume: $subvolume_path"
          exit 1
        fi
    else
        echo "Subvolume já existe: $subvolume_path."
    fi
}

# Função para mover arquivos para o subvolume
move_files_to_subvolume() {
    local directory="$1"
    local subvolume_path="$2"
    local file_type="$3"
    
    # Encontrar arquivos e mover para o subvolume
    echo "Movendo arquivos de $file_type de $directory para $subvolume_path..."
    find "$directory" -type f -print0 | xargs -0 -I {} mv -i {} "$subvolume_path/"
    
    # Log de operação
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Movido: $file_type de $directory para $subvolume_path" >> "$LOG_FILE"
}

# Função para criar snapshots dos subvolumes
create_snapshot() {
    local subvolume_path="$1"
    local snapshot_name="$2"
    
    echo "Criando snapshot de $subvolume_path em $snapshot_name..."
    btrfs subvolume snapshot "$subvolume_path" "$snapshot_name"
    if [ $? -ne 0 ]; then
      echo "Erro ao criar snapshot: $snapshot_name"
      exit 1
    fi
    
    # Log de operação
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Snapshot criado: $snapshot_name" >> "$LOG_FILE"
}

# Pergunta ao usuário qual pasta usar
read -p "Digite o caminho da pasta de origem (ou pressione Enter para $HOME/Documentos): " source_dir
if [ -z "$source_dir" ]; then
  source_dir="$HOME/Documentos"
fi

# Verifica se a pasta existe
if [ ! -d "$source_dir" ]; then
  read -p "A pasta $source_dir não existe. Deseja criá-la? (s/n): " create_dir
  if [ "$create_dir" == "s" ]; then
    mkdir -p "$source_dir"
    echo "Pasta $source_dir criada."
  else
    echo "Pasta não criada. Saindo."
    exit 1
  fi
fi

# Criar subvolume para arquivos, caso não exista
create_subvolume_if_not_exists "$DATA_SUBVOLUME"

# Criar subvolume para snapshots, caso não exista
create_subvolume_if_not_exists "$SNAPSHOT_DIR"

# Mover todos os arquivos para o subvolume
move_files_to_subvolume "$source_dir" "$DATA_SUBVOLUME" "*"

# Criar snapshots dos subvolumes
create_snapshot "$DATA_SUBVOLUME" "$SNAPSHOT_DIR/data_files_snapshot_$(date +%Y%m%d_%H%M%S)"

echo "Script concluído com sucesso!"
