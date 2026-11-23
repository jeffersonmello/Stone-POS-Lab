# Como contribuir

Correções de bugs, melhorias na documentação e medições de terminais são bem-vindas. Consulte as [issues existentes](https://github.com/jeffersonmello/Stone-POS-Lab/issues) e escolha o formulário que combina com sua contribuição.

## Desenvolvimento local

Use Flutter **3.44.0**, a mesma versão da integração contínua. Consulte o [README](README.md) para configurar o Android SDK e executar o app no macOS. As orientações de trabalho e os pontos de entrada do código estão em [AGENTS.md](AGENTS.md).

Na raiz do repositório, rode as verificações usadas na CI.

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
```

Para corrigir a formatação, rode `dart format lib test`. Os testes automatizados usam o Flutter, e mudanças no gerenciamento de instâncias também se beneficiam de um teste com Android Emulator no macOS.

## Perfis de terminais

Confira o [guia das especificações](specs/README.md) e mantenha a fonte de cada dado. Registre fabricante, modelo e variante. Para medições de bancada, inclua a data, o firmware e as versões do Android e da API quando disponíveis. Declare lacunas e diferenças entre variantes. Trate separadamente as capacidades físicas e o que foi validado no emulador.

## Envio de mudanças

Abra um pull request com o motivo da mudança, suas evidências e como você a testou. Compartilhe somente materiais públicos ou autorizados. Use dados de teste e remova credenciais, números de série, identificadores de lojista e dados de cartão de logs e capturas.

Consulte o [Código de Conduta](CODE_OF_CONDUCT.md) e a [política de segurança](SECURITY.md).
