# Cenários de compatibilidade

Uma incompatibilidade observada em um terminal Gertec motivou o Stone POS Lab. Use o mesmo APK em mais de um perfil para localizar a primeira diferença de comportamento. Registre a versão do Android, o modelo de referência, o tipo de imagem do emulador e a versão do aplicativo.

## Abrir o app pela primeira vez

Parta de uma instalação limpa. Instale o APK, inicie o app e registre até onde ele chega. Confira erros de instalação, encerramentos durante a inicialização e problemas de layout. Repita em outro perfil mantendo o APK e os passos iguais. Quando a aplicação depender do SDK Stone ou de apps do terminal, repita no POS de desenvolvimento.

## Testar a resposta da aplicação

Em uma build preparada para simulação, use respostas de aprovação, recusa e tempo esgotado para conferir o estado da interface e o tratamento de um retorno tardio. Registre se o caso rodou com simulação local ou no ambiente oficial de testes. Para validar a leitura física de cartão por inserção ou aproximação, NFC/MIFARE e impressão física, execute os casos em uma maquininha de desenvolvimento.

## Compartilhar um caso

Inclua modelo, versões, condição inicial, passos, resultado esperado e resultado observado. Se o erro só ocorre na maquininha, registre também firmware e versão do SDK. Use dados fictícios e revise logs e capturas antes de anexá-los a uma issue pública.

[Inicialização do SDK](https://sdkandroid.stone.com.br/reference/inicializando-o-sdk) · [Ambiente de testes Stone](https://sdkandroid.stone.com.br/reference/configurando-ambientes)
