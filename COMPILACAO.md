# Compilação e instalação

Este ZIP não é APK ou IPA.

## GitHub Actions

1. Crie um repositório vazio na sua conta do GitHub e autorize o aplicativo GitHub a acessá-lo.
2. Envie **todo o conteúdo** desta pasta para a raiz do repositório. Cada WAV tem 22,2 MiB, abaixo do limite de 100 MiB por arquivo imposto pelo GitHub ao fazer push.
3. Abra **Actions > Compilar APK Android nativo > Run workflow**.
4. Caso a ação termine com sucesso, abra **Artifacts** e baixe `nightfall-chronicles-android-debug`.
5. Extraia o ZIP do artefato e instale o APK, autorizando a origem no Android.

A ação instala Godot 4.4.1, templates de exportação, Java 17 e Android SDK,
executa um teste de fumaça e valida assinatura e tamanho >= 200 MiB.
**A ação ainda não foi executada.** Não existe APK verificado até ela passar.

Para trabalhar pelo editor, abra `project.godot` no Godot 4.4.1 e use **Projeto > Exportar > Android** depois de configurar os templates, Java e SDK.

## iOS

Use macOS/Xcode e credenciais da Apple para compilar e assinar uma versão instalável.
A ação iOS incluída é apenas uma tentativa de exportação do projeto Xcode, não um IPA assinado.

## Observações

Os recursos sonoros WAV são extensos. Embora a compressão ZIP do APK possa reduzir
o tamanho, o workflow exige >=200 MiB e interrompe a entrega caso o limite não
seja alcançado.
