#!/bin/bash

# Exibe o menu
echo "Selecione uma opção:"
echo "1. Baixar Vídeo"
echo "2. Baixar Aúdio"
echo "3. Baixar Playlist"
read -p "Opção: " opcao

# Função para baixar vídeo
baixar_video() {
    read -p "Digite a URL do vídeo: " url
    yt-dlp "$url"
}

# Função para baixar música
baixar_musica() {
    read -p "Digite a URL da música: " url
    yt-dlp --extract-audio --audio-format mp3 "$url"
}

# Função para baixar playlist
baixar_playlist() {
    read -p "Digite a URL da playlist: " url
    yt-dlp --yes-playlist "$url"
}

# Executa a função correspondente à opção selecionada
case $opcao in
    1)
        baixar_video
        ;;
    2)
        baixar_musica
        ;;
    3)
        baixar_playlist
        ;;
    *)
        echo "Opção inválida!"
        ;;
esac