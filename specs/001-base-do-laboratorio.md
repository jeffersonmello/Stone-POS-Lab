# 001 — Base do laboratório

**Estado:** Base implementada com extensões propostas

**Data:** 2026-11-23

## Problema

Uma incompatibilidade observada em uma unidade Gertec motivou um laboratório para repetir a instalação, a abertura e os fluxos de integração em perfis de modelos diferentes. Para investigar inserção ou aproximação de cartão e leitura NFC/MIFARE, registre qual operação foi exercitada e em que equipamento físico.

## Implementado

| Área | Comportamento disponível |
| --- | --- |
| Aplicativo | Flutter desktop com macOS como plataforma inicial. |
| Catálogo | Pesquisa e fichas SmartPOS com modelo, informações técnicas, fontes e observações sobre variantes. |
| AVD | Localização do SDK, seleção de imagem oficial compatível com o host, solicitação de download, criação e ciclo de vida da instância. Resolução e DPI são aplicados quando a ficha fornece os valores. |
| Instâncias | Registro local do nome do AVD, perfil e imagem. O aplicativo localiza as instâncias gerenciadas no SDK e oferece ações de abrir, encerrar e remover. |
| Documentação | Guias embarcados e sincronização manual de quatro páginas oficiais Stone para leitura offline. |

Um perfil referencia o modelo físico. A execução usa a imagem selecionada e pode ter outra API ou ABI. O estado de execução apresentado pela interface acompanha a presença do AVD no ADB.

## Extensões propostas

- Instalar e abrir APKs autorizados a partir da interface. Mostrar diagnósticos de `minSdk`, ABI, assinatura e outros requisitos do perfil. Distinguir boot do Android, abertura do app e inicialização do SDK.
- Reproduzir resultados de teste com dados sintéticos e registrar a sequência de eventos. Começar com aprovação, recusa, cancelamento e timeout. Guardar o ambiente, as versões e um log sanitizado para comparar execuções.
- Registrar testes do SDK e sandbox oficial, além de acompanhar os testes de hardware em POS de desenvolvimento. Documentar por cenário a evidência de cartão inserido, cartão por aproximação, tag MIFARE e impressão. A homologação segue o processo oficial.
- Investigar os apps oficiais de teste Stone para carga por perfil depois de confirmar autorização de uso, distribuição, compatibilidade da imagem e dependências de provisionamento. Validar inicialização e transações com esses apps quando houver ambiente compatível.

O Android Emulator é a base de execução virtual. O catálogo pode registrar leitores, impressora e outros componentes do POS, cuja verificação depende da unidade de desenvolvimento e de evidência de bancada. [Perfis Android](https://developer.android.com/studio/run/managing-avds), [dispositivos suportados Stone](https://sdkandroid.stone.com.br/reference/dispositivos-suportados), [processo de integração Stone](https://sdkandroid.stone.com.br/reference/processo-de-integracao).

## Verificação da base

| Ação | Resultado esperado |
| --- | --- |
| Executar `flutter analyze` e `flutter test` na raiz | Análise estática concluída e teste do catálogo passando. O teste atual filtra o L400 e confirma que sua seleção aponta para a API 30. |
| Abrir o catálogo e selecionar um Gertec | A ficha mostra a variante, as fontes e a ressalva quando os dados do firmware ainda precisam de confirmação. |
| Criar um AVD com uma imagem instalada e compatível | A instância é exibida com o perfil e a imagem escolhidos. Ao reiniciar o gerenciador, a entrada aparece na lista. |
| Abrir, encerrar e remover uma instância descartável do laboratório | A interface acompanha o estado do AVD e retira a entrada depois da remoção. |
| Sincronizar as fontes Stone e voltar à documentação sem rede | As cópias baixadas permanecem disponíveis para leitura. |

## Evidências da migração

Em 23 de novembro de 2026, a versão neste repositório passou na formatação, na análise estática, no teste de catálogo e no build para macOS Apple Silicon com Flutter 3.44.0 e Xcode 27.2. Ao abrir a build, o catálogo apresentou 12 perfis e o guia de cenários foi exibido na aba Documentação.

Em um teste local do serviço Android, um AVD descartável com imagem AOSP ARM64 da API 30 iniciou em Android 11. O ADB confirmou 720 × 1600. A instância foi encerrada e removida. Testes de apps Stone, hardware e transações precisam de evidência no ambiente correspondente.
