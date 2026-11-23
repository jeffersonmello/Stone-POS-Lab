# Primeiros passos

Use o catálogo para escolher um terminal de referência e criar uma instância Android local. Cada ficha mostra os dados públicos do modelo e indica quais detalhes pedem confirmação no equipamento. A imagem Android usada pelo emulador tem versão e arquitetura próprias.

## Prepare o Android local

1. Instale o Android Studio e abra o SDK Manager. Instale **Android Emulator**, **Android SDK Platform-Tools** e **Android SDK Command-line Tools**.
2. No Device Manager, baixe uma imagem Android compatível com a arquitetura do computador. Use a API do terminal quando houver uma imagem compatível e anote qualquer diferença de versão ao registrar o teste.
3. No laboratório, confira o caminho do SDK. Abra o catálogo, selecione o modelo e crie uma instância com a imagem instalada. Inicie a instância e use um APK de teste da sua aplicação.

[Gerenciar dispositivos virtuais](https://developer.android.com/studio/run/managing-avds) · [Aceleração e arquiteturas](https://developer.android.com/studio/run/emulator-acceleration)

## Escolha o ambiente de teste

- **Emulador local** — instalação, abertura do aplicativo, layout, navegação, perda de rede e fluxo de pagamentos quando a build oferece uma integração simulada. Uma imagem AOSP permite verificar as dependências do app em um ambiente sem Google Play Services.
- **POS de desenvolvimento** — inicialização do SDK oficial, firmware, apps internos, impressão, leitura física de cartão e NFC. Use o sandbox do fornecedor para exercitar os retornos transacionais.

[Limitações do Android Emulator](https://developer.android.com/studio/run/advanced-emulator-usage) · [Sandbox Stone](https://sdkandroid.stone.com.br/reference/configurando-ambientes)

## Registre o cenário

Anote o modelo físico de referência, a versão do Android e do firmware, a imagem virtual, a versão do APK e do SDK, o estado inicial, a sequência de passos e o resultado esperado. Use dados de teste e omita credenciais e dados de portadores ao compartilhar logs.
