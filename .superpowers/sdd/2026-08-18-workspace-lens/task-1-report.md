# Relatório — Tarefa 1: modelo puro de agrupamento

## Implementação

Implementei `WorkspaceModel.js` como um modelo puro compatível com o uso em QML/JavaScript ES5. A implementação normaliza IDs de aplicativos, deriva nomes seguros, agrupa janelas preservando a ordem e os títulos, calcula contagens/estado de foco e produz os grupos resumidos com overflow.

## Arquivos

- `WorkspaceModel.js`
- `tests/load-workspace-model.mjs`
- `tests/workspace-model.test.mjs`

## Testes e resultados

- Teste focado: `node --test tests/workspace-model.test.mjs` — 6 passaram, 0 falharam.
- Suíte completa: `node --test` — 6 passaram, 0 falharam.
- Verificação de whitespace: `git diff --check` — sem problemas.

## Evidência TDD

- RED: antes de criar `WorkspaceModel.js`, `node --test tests/workspace-model.test.mjs` falhou com `ENOENT` ao tentar carregar o arquivo ausente.
- GREEN: após a implementação mínima, o mesmo comando passou nos seis testes.

## Autorrevisão

Revisei a implementação contra cada requisito do brief: normalização `.desktop`, workspace vazio persistente, agrupamento por app, títulos, limite de resumo, overflow, separação de IDs web e fallbacks de metadados. O diff não apresentou whitespace inválido.

## Preocupações

Nenhuma preocupação funcional identificada dentro do escopo da Tarefa 1. A suíte disponível contém apenas os seis testes do modelo; os consumidores QML das tarefas posteriores ainda não foram exercitados.

## Commit

`feat: agrupar apps por workspace`
