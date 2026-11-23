---
name: runtime-android
description: Altera ou diagnostica o runtime Android do Stone POS Lab. Use para descoberta do SDK, imagens e ABIs, criação e ciclo de vida de AVDs, instalação e abertura de APKs ou execução de testes em AVD e POS de desenvolvimento.
---

# Runtime Android

Comece por `lib/android_runtime.dart`, `lib/create_dialog.dart` e pela [especificação inicial](../../../specs/001-base-do-laboratorio.md). O app usa as ferramentas do Android SDK instaladas no host.

- Ao selecionar uma imagem, valide API, arquitetura do host e disponibilidade da imagem oficial. Para APKs autorizados, confira `minSdk`, bibliotecas nativas e assinatura quando pertinentes. São verificações diferentes da compatibilidade com serviços, permissões privilegiadas ou periféricos de um POS. [Aceleração e arquiteturas](https://developer.android.com/studio/run/emulator-acceleration), [APK Analyzer](https://developer.android.com/tools/apkanalyzer).
- Quando só houver imagem de outra API, mantenha visíveis a API de referência do perfil e a API escolhida. Use os campos conhecidos do perfil e os padrões da imagem para campos ausentes.
- Preserve as instâncias existentes e direcione comandos mutáveis apenas à instância escolhida. Use o nome validado do AVD e selecione o serial explicitamente nos comandos ADB. Em etapas com efeitos parciais, confira o estado efetivo do SDK antes de salvar ou mostrar sucesso. [Comandos do emulador](https://developer.android.com/studio/run/emulator-commandline), [ADB](https://developer.android.com/tools/adb).
- Ao adicionar diagnósticos, diferencie processo iniciado, AVD visível no ADB, boot concluído, APK instalado, app aberto e SDK iniciado. Capture somente os logs necessários de cada etapa. Para reproduzir um erro, registre a API, imagem, ABI e versão do APK. Inclua a versão do firmware quando o teste ocorrer em POS.
- Execute simulações com dados sintéticos. Use apps oficiais apenas quando houver pacote autorizado, ambiente de teste adequado e compatibilidade comprovada. Valide cartão, NFC/MIFARE, impressão e outros periféricos no POS apropriado. [Testes com o projeto demo Stone](https://sdkandroid.stone.com.br/reference/testes-com-projeto-demo), [processo de integração Stone](https://sdkandroid.stone.com.br/reference/processo-de-integracao).

Em mudanças de runtime, teste a operação em uma instância descartável quando houver SDK compatível. Registre a limitação quando o host, a imagem ou o terminal necessário estiver indisponível.
