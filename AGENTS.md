# Stone POS Lab

Aplicativo Flutter desktop para catalogar SmartPOS, gerenciar dispositivos virtuais Android (AVDs) e documentar testes de integração. Uma incompatibilidade em uma unidade Gertec motivou o projeto. O objetivo é comparar o comportamento da aplicação em modelos diferentes. Inserção e aproximação de cartão, leitura NFC/MIFARE e demais interações físicas exigem testes em bancada. A plataforma inicial é macOS. A [especificação inicial](specs/001-base-do-laboratorio.md) registra o estado do produto.

## Como trabalhar no projeto

- Leia [specs/README.md](specs/README.md) antes de alterar um comportamento, uma integração ou um requisito. Use uma especificação existente ou escreva uma curta com o resultado esperado e como verificá-lo. Para correções pequenas, atualize apenas a documentação afetada.
- O aplicativo Flutter fica na raiz. Consulte [a arquitetura](docs/ARCHITECTURE.md) para localizar os componentes. Use `data/catalog.json` para perfis, `data/guides/` para guias do produto e `specs/` para decisões, critérios de aceitação e evidências de implementação.
- Use a skill [catálogo e evidências](.agents/skills/catalogo-e-evidencias/SKILL.md) para manter fichas, fontes e observações de bancada. Use a skill [runtime Android](.agents/skills/runtime-android/SKILL.md) ao alterar imagens, AVDs, comandos do SDK ou compatibilidade de instalação.
- Preserve a memória técnica em arquivos versionados. Ao trazer uma descoberta de um protótipo, uma conversa ou um projeto interno, registre o comportamento observado, o ambiente e uma evidência publicável. Use o [guia de cenários](data/guides/cenarios.md) para procedimentos que possam ser repetidos. Mantenha os caminhos, credenciais, anexos e logs privados fora deste repositório.
- Identifique em cada resultado o modelo de referência e o ambiente efetivamente executado. Use o AVD para os comportamentos disponíveis na imagem Android local e teste componentes Stone, leitores e impressão em ambiente autorizado com o hardware necessário.

## Verificação

Execute `flutter analyze` e `flutter test` para mudanças no aplicativo. Use `flutter run -d macos` para mudanças que dependam da janela do app ou do SDK instalado. Registre o que foi efetivamente executado na especificação quando a alteração incluir validação dependente de AVD, sandbox ou POS físico.

Para uma revisão focada em alegações de compatibilidade e evidências de teste, use o agente `pos_compatibility_review` quando disponível. [Configuração do revisor](.codex/agents/pos-compatibility-review.toml).
