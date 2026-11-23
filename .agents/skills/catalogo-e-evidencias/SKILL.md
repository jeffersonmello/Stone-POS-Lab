---
name: catalogo-e-evidencias
description: Atualiza fichas SmartPOS, guias sincronizados e evidências de bancada do Stone POS Lab. Use ao investigar modelos, variantes, firmware, capacidades de leitores ou divergências entre documentação e terminais observados.
---

# Catálogo e evidências

Use `data/catalog.json` para os dados consumidos pelo aplicativo e `data/guides/` para procedimentos de uso e integração. Registre mudanças no contrato de dados ou na forma de comprovar cobertura na [especificação](../../../specs/README.md).

- Confirme a variante pelo identificador exato. Para o SDK, use a matriz da Stone. Para dimensões, tela e hardware, use o fabricante da variante. Registre o firmware observado apenas com evidência da unidade testada. Um modelo ausente da matriz atual pode continuar útil como referência histórica, com essa condição explícita na ficha. [Dispositivos suportados](https://sdkandroid.stone.com.br/reference/dispositivos-suportados), [pré-requisitos Stone](https://sdkandroid.stone.com.br/reference/pre-requisitos).
- Mantenha o `id` estável porque ele referencia instâncias existentes. Em campos opcionais, use `null` quando o valor ainda estiver em aberto. Preserve a fonte e explique em `notes` quando duas variantes ou fontes divergirem. A resolução e o DPI usados no AVD são parâmetros do teste, ainda que venham da ficha.
- Nos registros de bancada, anote data, ambiente, modelo e variante, Android, firmware, versão do app ou SDK, passos, resultado e evidência sanitizada. Registre separadamente pagamento por chip inserido, pagamento por aproximação e leitura de tag MIFARE. Cada caso exige evidência própria de hardware e software.
- Na sincronização de guias, mantenha a URL oficial e preserve a última cópia válida se uma fonte falhar. Ao descobrir uma mudança documental que afete uma ficha ou um teste, guarde a fonte e atualize o critério depois de verificar a condição aplicável.

Verifique se o catálogo continua carregando, se os identificadores são únicos e se o detalhe do modelo e o formulário de criação exibem a variante selecionada.
