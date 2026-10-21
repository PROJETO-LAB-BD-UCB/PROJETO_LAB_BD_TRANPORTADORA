# Etapa 2 — Registro de evidências de teste

Preencha este documento com resultados reais obtidos pela equipe. Não deixe exemplos hipotéticos como se fossem resultados medidos.

## 1. CRUD — B1

| Entidade | Criar | Consultar | Alterar | Excluir | Evidência / observação |
|---|---|---|---|---|---|
| Cliente | ☐ | ☐ | ☐ | ☐ | |
| Encomenda | ☐ | ☐ | ☐ | ☐ | |
| Ocorrência | ☐ | ☐ | ☐ | ☐ | |
| Serviço adicional | ☐ | ☐ | ☐ | ☐ | |

## 2. Consultas parametrizadas e view

| Teste | Parâmetros usados | Resultado observado | Evidência |
|---|---|---|---|
| Desempenho de motoristas por período | | | |
| Encomendas agrupadas por status/cidade | | | |
| Relatório baseado em `vw_relatorio_operacional` | | | |
| Entrada de pesquisa `' OR 1=1 --` | | | |

## 3. Transação e rollback

- Data/hora:
- Usuário da aplicação:
- Código `ROLLBACK-TEST` gerado:
- Falha observada ao inserir volume inválido:
- Contagem do código após a operação:
- Confirmado que nenhuma encomenda de teste permaneceu? Sim / Não
- Evidência (mensagem da interface / consulta SQL):

## 4. Concorrência com duas sessões

- Data/hora:
- Servidor MySQL / versão:
- `@@transaction_isolation` na sessão A:
- `@@transaction_isolation` na sessão B:
- Comando bloqueador na sessão A:
- Comando concorrente na sessão B:
- Tempo de espera/bloqueio observado:
- Resultado após `COMMIT` ou `ROLLBACK` da sessão A:
- Interpretação:

## 5. Desempenho e índices

Repita cada consulta antes e depois da criação dos índices, com o mesmo conjunto de dados.

| Consulta | Plano antes (`EXPLAIN`) | Duração antes | Índice criado | Plano depois | Duração depois | Conclusão |
|---|---|---|---|---|---|---|
| Tentativas por motorista/período | | | | | | |
| Encomendas por data/status | | | | | | |
| Ocorrências por período/situação | | | | | | |

## 6. Perfis e auditoria

| Perfil MySQL | Conta criada (não registrar senha) | `SHOW GRANTS` conferido | Testes de permissão |
|---|---|---|---|
| `nexo_consulta` | ☐ | ☐ | |
| `nexo_operador` | ☐ | ☐ | |
| `nexo_admin` | ☐ | ☐ | |

- Atualização de cliente gerou auditoria com autor, data e JSON anterior/posterior? Sim / Não
- Atualização de encomenda gerou auditoria com autor, data e JSON anterior/posterior? Sim / Não
- Evidência de hash e sal: tabela `usuario_aplicacao` contém `senha_salt`/`senha_hash` sem senha clara? Sim / Não

## 7. Backup e restauração

- Data do backup:
- Comando utilizado (sem senha):
- Tamanho do arquivo:
- Banco de teste restaurado:
- Contagens de tabelas comparadas:
- Views e triggers validadas:
- Resultado da restauração:

## 8. Declaração de uso de IA

Descreva quais partes foram apoiadas por ferramenta de IA, como o resultado foi revisado/testado pela equipe e que decisões foram alteradas ou confirmadas. Todos os integrantes devem conseguir explicar o código e as decisões técnicas.

**Modelo de declaração para adaptar e validar pela equipe:** “Utilizamos uma ferramenta de IA como apoio à estruturação da interface Python, à organização de consultas parametrizadas, à elaboração dos scripts complementares de segurança/auditoria e à documentação de testes. A equipe revisou o código e executou testes automatizados locais. Os testes integrados que dependem do servidor MySQL — permissões, transações, concorrência, planos de execução e restauração — serão executados pela equipe no ambiente próprio; só serão relatados como concluídos após observação e registro das evidências.” Ajuste o texto à atividade realmente realizada e não declare testes que não tenham sido executados.


## 9. Projeto físico, crescimento e manutenção

- Premissa adotada de encomendas por dia para projeção (informar e justificar):
- Período projetado e data-base:
- Contagens atuais obtidas com `sql/06_verificacao_etapa2.sql`:
- Tamanho atual das tabelas/índices em MB:
- Projeção revisada para `encomenda`, `historico_status_encomenda`, `volume_encomenda`, `tentativa_entrega`, `ocorrencia` e `expedicao_encomenda`:
- Decisão sobre índices redundantes, com plano `EXPLAIN` como evidência:
- Decisão sobre particionamento/arquivamento e justificativa:
- Frequência de backup e retenção aprovada:
- Resultado de restauração em base de teste:


## 10. Checklist dos documentos de entrega

- [ ] Relatório final consolidado com A1–A5 revisados e resultados reais da Etapa 2.
- [ ] Adendo ao modelo lógico/dicionário atualizado conforme o DDL executado.
- [ ] README reproduz passos realmente testados em uma máquina limpa.
- [ ] Apresentação final coerente com a versão entregue e sem métricas não medidas.
- [ ] Declaração de uso de IA revisada pela equipe.
- [ ] `config.ini`, senhas e dumps com dados não foram incluídos no Git/ZIP compartilhado.
