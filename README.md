# Nightfall Chronicles — edição expandida (Godot 4.4.1)

**Tipo:** projeto de jogo nativo 2D / protótipo alfa, sem HTML e sem WebView.

## Conteúdo presente nos arquivos

- Campanha em 24 câmaras e 6 regiões com artes derivadas de imagens de IA.
- 48 variações de arenas em JPG, integradas à renderização do jogo.
- 6 variações gráficas de chefes, com padrões de ataque básicos compartilhados.
- 5 armas com cadências, danos, velocidades e leques diferentes.
- 12 melhorias selecionáveis após vencer cada sala.
- Controles móveis por dois joysticks, teclado e mouse.
- 12 trilhas originais sintetizadas (PCM WAV 44,1 kHz / estéreo, 132 s cada).
- Sons de tiros, esquiva, cura e dano.
- Salvamento local de cristais, recorde e mute.

**Ainda não implementado:** multiplayer online, persistência em nuvem, progressão de conta ou matchmaking.
**Ainda não verificado:** abertura em Godot 4.4.1, instalação em aparelho físico Android e versão assinada iOS.

## Como produzir APK Android

O caminho é abrir esta pasta como projeto Godot 4.4.1, importar os recursos,
instalar os templates de exportação e configurar Java 17 + Android SDK.
A forma recomendada é enviar *o conteúdo da pasta raiz* para um repositório GitHub
com GitHub Actions autorizado e disparar o workflow `Compilar APK Android nativo`.
O workflow importa os recursos, executa o teste de partida, exporta com
assinatura de debug e rejeita artefatos menores que 200 MiB.

**Importante:** os arquivos de música estão em formato WAV não comprimido.
Isso atende ao pedido de um pacote extenso, mas não significa um jogo mais
profissional; pode gastar muito armazenamento, tempo de importação e memória.

## iOS

O workflow `Preparar projeto iOS para Xcode` pode preparar arquivos para Xcode;
para instalar no iPhone é necessária assinatura Apple com um team/developer account.
Não se fornece IPA assinado neste pacote.

## Verificações locais

`python3 ci/check_assets.py` examina todos os recursos essenciais, os áudios,
as salas, as imagens e o tamanho. Não é um teste de gameplay nem substitui a
execução na engine.
