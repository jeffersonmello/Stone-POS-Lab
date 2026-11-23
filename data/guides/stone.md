# Integração Stone

## Inicialização e ativação

Em uma integração por Providers, inicialize `StoneStart.init` e configure o nome do app. Em uma instalação sem ativação, a primeira chamada pode retornar `null`. Uma ativação existente pode retornar uma lista de `UserModel` com os dados do lojista, incluindo seu `StoneCode`. Valide esses dois estados separadamente. Quando o app usa apenas Deeplink, a ativação fica com os apps internos do POS.

[Inicialização do SDK](https://sdkandroid.stone.com.br/reference/inicializando-o-sdk) · [Provider de ativação](https://sdkandroid.stone.com.br/reference/provedor-ativacao)

## Sandbox e testes

Obtenha as credenciais de integração pelo programa de parcerias e use o POS de desenvolvimento para os testes oficiais. O sandbox usa os centavos do valor para controlar a resposta. A documentação ilustra `R$ 1,00` com `0000` e `R$ 1,01` com `1007`. Confira a tabela antes de montar os casos. Para Pix/QR via SDK, peça as credenciais específicas do ambiente de teste.

[Processo de integração](https://sdkandroid.stone.com.br/reference/processo-de-integracao) · [Configuração de ambientes](https://sdkandroid.stone.com.br/reference/configurando-ambientes) · [Códigos de resposta](https://sdkandroid.stone.com.br/page/retorno-do-sandbox)

## Deeplink e apps do POS

O Deeplink chama apps Stone instalados no terminal por Intents. Configure o esquema de retorno no AndroidManifest e confira o contrato de cada operação. A Stone mantém um exemplo oficial e fornece os apps de desenvolvimento pelo canal de parcerias. Para validar esses componentes em uma instância virtual, confirme com a Stone quais pacotes podem ser usados, em que imagem Android e com quais dependências.

[Configuração do Deeplink](https://sdkandroid.stone.com.br/reference/configuracao-deeplink) · [Demo de Deeplink](https://github.com/stone-payments/pos-android-deeplink-demo)

## Build e homologação

Confirme a biblioteca, a variante por fabricante e os requisitos de assinatura do modelo alvo. A referência Stone prevê variantes para Positivo, Gertec e Tectoy. Use o roteiro da Stone no equipamento de desenvolvimento e guarde as versões de firmware, SDK e APK utilizadas.

[Processo de build e assinaturas](https://sdkandroid.stone.com.br/reference/processo-de-build-de-aplica%C3%A7%C3%A3o) · [Dispositivos suportados](https://sdkandroid.stone.com.br/reference/dispositivos-suportados) · [Índice da documentação](https://sdkandroid.stone.com.br/llms.txt)
