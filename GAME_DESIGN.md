# Documento de direção — Nightfall Chronicles

**Fantasia central:** uma exploradora de Nexo atravessa as ruínas entre três mundos, coletando fragmentos de uma estrela partida. A cada quatro câmaras, uma anomalia dimensional atua como chefe. As relíquias são transformações que alteram ritmo, arma e sobrevivência durante a expedição.

**Pilares:** combate rápido responsivo; legibilidade mobile; progressão baseada em escolhas; fantasia sombria sci-fi visualmente própria; profundidade de build e replay.

**Loop:** explorar câmara -> derrotar hordas -> coletar fragmentos -> selecionar mutação -> nova câmara -> chefe -> próxima região -> final.

**Paleta:** carmesim/âmbar nas Catacumbas, ciano nas Geleiras, violeta nas Fendas. O contraste entre inimigos magenta e tiros ciano é proposital para leitura visual.

**Armas no protótipo:** Pistola Nexo (equilibrada), Espingarda Solar (curto alcance e múltiplos projéteis), Raio Espectral (cadência alta). Chefe no estágio 4, 8 e 12.

**Direção de arte futura:** reconstruir os modelos IA como sprites 8 direções em camada separada com transparência real, normal maps leves, poses de ataque e passos; refazer tiles de 32x32 ou 48x48 respeitando costuras; produzir vídeos de ataque e VFX frames. As imagens atuais são materiais-base e prévias IA adaptadas para prototipagem.

**Online futuro (não entregue):** servidor autoritativo Godot headless; sessões de até 4 jogadores, lobby com código, criptografia e autenticação, detecção de pacotes, P2P não recomendado para combate; interpolação e reconciliação na rede. Requer provedores, pipeline CI, latência e testes reais em Android/iOS.

**Critérios de qualidade antes de publicar:** instalação em aparelhos físicos, tamanho <200MB, 60 FPS nos aparelhos-alvo, 5+ sessões de playtest com métricas, compatibilidade de controles e orientação, acessibilidade, QA de travamentos, licença dos recursos, privacidade e segurança de servidores.
