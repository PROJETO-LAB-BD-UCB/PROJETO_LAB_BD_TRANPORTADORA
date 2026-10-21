# Nexo Logística — Projeto Final de Laboratório de Banco de Dados

Projeto desenvolvido para a disciplina **Laboratório de Banco de Dados**, da **Universidade Católica de Brasília (UCB)**, no semestre **2026/2**.

**Tema:** Sistema de Gestão de Transportadora, Rastreamento e Entregas  
**SGBD:** MySQL 8.0 ou superior  
**Aplicação:** Python 3 + Tkinter  
**Grupo:** 01

## Integrantes

- Bruno Lucas Caixeta Braga
- Carlos Eduardo Estrela de Macedo
- Guilherme Alfeu Borges Carvalho Braga
- Ryan Gabriel Araújo Almeida

## Objetivo do projeto

O Nexo Logística implementa um banco de dados para apoiar o fluxo operacional de uma transportadora, cobrindo cadastro de clientes, endereços, encomendas e volumes, rotas, expedições, veículos, motoristas, rastreamento por histórico de status, ocorrências, tentativas de entrega e serviços adicionais.

O projeto foi desenvolvido em duas etapas:

- **Etapa 1:** escopo e regras de negócio, MER conceitual, dicionário de dados, modelo lógico, normalização, DDL, carga inicial e 15 consultas SQL.
- **Etapa 2:** aplicação com interface, CRUDs, consultas parametrizadas, transações, concorrência, otimização com `EXPLAIN`, controle de acesso, hash de senhas, auditoria, projeto físico e plano de backup/restauração.

## Estrutura do repositório

```text
PROJETO_LAB_BD_TRANPORTADORA-main/
├── README.md
├── Apresentacao_Transportadora.pptx
├── MER - CONCEITUAL.pdf
├── docs/
│   ├── relatorio-etapa1.pdf
│   ├── dicionario-dados.pdf
│   ├── modelo-logico.pdf
│   ├── mer-conceitual.pdf
│   ├── mer-conceitual.dot
│   └── Relatorio_Final_Transportadora_Grupo01_Etapa2.pdf
├── docs_etapa2/
│   ├── Apresentacao_Final_Etapa2.pdf
│   └── mer-conceitual-etapa2-final.pdf
│   └── Relatorio_Final_Transportadora.pdf
├── sql/
│   ├── 01_ddl.sql
│   ├── 02_carga.sql
│   └── 03_consultas.sql
└── transportadora_app/
    ├── app.py
    ├── database.py
    ├── security.py
    ├── requirements.txt
    ├── config.ini.example
    ├── run.bat
    ├── README.md
    ├── COMECE_AQUI.txt
    ├── sql/
    │   ├── 01_ddl.sql
    │   ├── 02_carga.sql
    │   ├── 03_consultas.sql
    │   ├── 04_etapa2_seguranca_auditoria.sql
    │   ├── 05_desempenho_transacoes.sql
    │   └── 06_verificacao_etapa2.sql
    └── tests/
        ├── test_database_profiles.py
        ├── test_error_messages.py
        ├── test_project_structure.py
        └── test_security.py
```


## Requisitos

- MySQL Server 8.0 ou superior;
- MySQL Workbench ou outro cliente MySQL para executar os scripts;
- Python 3.10 ou superior;
- Tkinter disponível na instalação do Python;
- pacote `mysql-connector-python`, instalado por `requirements.txt`;
- Git/GitHub para versionamento.

## Como reconstruir o banco do zero

> **Atenção:** `01_ddl.sql` contém `DROP DATABASE IF EXISTS db_transportadora`. Faça backup de qualquer base que precise preservar.

No MySQL Workbench, execute os scripts nesta ordem:

1. `transportadora_app/sql/01_ddl.sql` — cria o banco, as 21 tabelas, restrições, triggers de integridade e a view de status atual;
2. `transportadora_app/sql/02_carga.sql` — insere a carga fictícia/sintética, incluindo os casos de contorno da Etapa 2;
3. `transportadora_app/sql/03_consultas.sql` — conjunto das 15 consultas acadêmicas da Etapa 1;
4. `transportadora_app/sql/04_etapa2_seguranca_auditoria.sql` — cria usuários da aplicação, views, auditoria e os três papéis MySQL;
5. `transportadora_app/sql/05_desempenho_transacoes.sql` — executa os estudos de `EXPLAIN`, cria os índices candidatos e contém o roteiro de concorrência e backup;
6. `transportadora_app/sql/06_verificacao_etapa2.sql` — confere objetos, índices, views, gatilhos e volume de dados.

Os arquivos `sql/01_ddl.sql`, `sql/02_carga.sql` e `sql/03_consultas.sql` da raiz podem ser usados no lugar das três primeiras cópias acima.

## Instalação e execução da aplicação

No Windows, abra o Prompt de Comando em `transportadora_app/` e execute:

```bat
py -m venv .venv
.venv\Scripts\activate.bat
py -m pip install -r requirements.txt
py app.py
```

Também é possível utilizar `run.bat` após instalar as dependências.

Na primeira execução, configure a conexão com o MySQL. Para uma instalação local típica:

```text
Host: localhost
Porta: 3306
Banco: db_transportadora
```


## Requisitos da Etapa 2 atendidos

### B1 — Aplicação com interface

A aplicação desktop foi desenvolvida em Python/Tkinter e possui CRUD completo para quatro entidades do modelo:

1. **Clientes PF/PJ**;
2. **Encomendas**;
3. **Ocorrências**;
4. **Serviços adicionais**.

Também foram implementadas:

- consulta parametrizada de desempenho de motoristas por período;
- consulta parametrizada de encomendas por status, cidade e período;
- relatório consolidado alimentado pela view `vw_relatorio_operacional`;
- mensagens tratadas para erros de integridade e ausência de permissão;
- operação de negócio envolvendo múltiplas tabelas dentro de uma única transação.

### B2 — Camada de acesso a dados

As entradas fornecidas pelo usuário são enviadas ao banco por parâmetros `%s` do `mysql-connector-python`, evitando concatenação direta de valores em comandos SQL.

A resistência a SQL Injection pode ser demonstrada com a entrada:

```text
' OR 1=1 --
```

O texto é tratado como valor literal da consulta parametrizada.


### B3 — Transações, COMMIT, ROLLBACK e concorrência

O projeto possui operações transacionais envolvendo mais de uma tabela, incluindo:

- cadastro de cliente: `cliente` + `cliente_pf` ou `cliente_pj`;
- cadastro de encomenda: `encomenda` + `volume_encomenda` + `historico_status_encomenda`.

Foram previstos os dois desfechos exigidos:

- **sucesso:** `COMMIT` confirma todas as alterações;
- **falha proposital:** `ROLLBACK` desfaz todas as alterações da operação.

O teste de rollback provoca propositalmente duplicidade na chave primária composta de `volume_encomenda` e, após a falha, consulta o banco para comprovar que os registros da transação não permaneceram.

O roteiro de concorrência com duas sessões está em `transportadora_app/sql/05_desempenho_transacoes.sql` e utiliza `SELECT ... FOR UPDATE` para observar bloqueio/espera e o nível de isolamento em vigor.

### B4 — Otimização de consultas

O arquivo `05_desempenho_transacoes.sql` contém três consultas críticas com:

- `EXPLAIN` antes dos índices;
- criação de três índices candidatos;
- `EXPLAIN` depois dos índices;
- roteiro para comparação do plano e do tempo observado com o mesmo volume de dados.

Os índices avaliados são:

- `idx_tentativa_motorista_data_resultado`;
- `idx_encomenda_data_id`;
- `idx_ocorrencia_data_situacao_tipo`.

O relatório final registra que um índice pode não ser escolhido pelo otimizador quando o custo estimado de outro plano for menor; esse resultado deve ser analisado, e não mascarado.

### B5 — Segurança e controle de acesso

Foram definidos três perfis de aplicação:

- **ADMINISTRADOR**;
- **OPERADOR**;
- **CONSULTA**.

E três papéis MySQL correspondentes:

- `nexo_admin`;
- `nexo_operador`;
- `nexo_consulta`.

O script 04 contém `GRANT` e `REVOKE` aplicando o princípio do menor privilégio. O perfil CONSULTA utiliza views restritas, sem exposição desnecessária de CPF/CNPJ, telefone, e-mail ou valor declarado.

Para demonstrar os perfis também com **logins MySQL reais**, crie as três contas por uma sessão administrativa, substituindo as senhas de exemplo antes da execução:

```sql
CREATE USER 'nexo_admin_app'@'localhost' IDENTIFIED BY 'SUBSTITUA_POR_SENHA_FORTE_1';
GRANT 'nexo_admin'@'%' TO 'nexo_admin_app'@'localhost';
SET DEFAULT ROLE 'nexo_admin'@'%' TO 'nexo_admin_app'@'localhost';

CREATE USER 'nexo_operador_app'@'localhost' IDENTIFIED BY 'SUBSTITUA_POR_SENHA_FORTE_2';
GRANT 'nexo_operador'@'%' TO 'nexo_operador_app'@'localhost';
SET DEFAULT ROLE 'nexo_operador'@'%' TO 'nexo_operador_app'@'localhost';

CREATE USER 'nexo_consulta_app'@'localhost' IDENTIFIED BY 'SUBSTITUA_POR_SENHA_FORTE_3';
GRANT 'nexo_consulta'@'%' TO 'nexo_consulta_app'@'localhost';
SET DEFAULT ROLE 'nexo_consulta'@'%' TO 'nexo_consulta_app'@'localhost';

SHOW GRANTS FOR 'nexo_admin_app'@'localhost';
SHOW GRANTS FOR 'nexo_operador_app'@'localhost';
SHOW GRANTS FOR 'nexo_consulta_app'@'localhost';
```

Depois, copie `config.ini.example` para `config.ini` e preencha as seções `[mysql_administrador]`, `[mysql_operador]` e `[mysql_consulta]`. O arquivo `config.ini` permanece apenas no computador da equipe e não deve ser enviado ao Git.

As senhas dos usuários da interface são armazenadas com:

- PBKDF2-HMAC-SHA256;
- sal aleatório de 16 bytes;
- 310.000 iterações;
- comparação segura com `hmac.compare_digest`.

Senhas de usuários da aplicação não são armazenadas em texto claro.

### B6 — Gatilhos e auditoria

A tabela `auditoria_alteracao` registra alterações relevantes e o script 04 cria quatro gatilhos de auditoria:

- `trg_auditoria_cliente_upd`;
- `trg_auditoria_cliente_pf_upd`;
- `trg_auditoria_cliente_pj_upd`;
- `trg_auditoria_encomenda_upd`.

Os registros incluem autor, data/hora, operação, identificador do registro e valores anterior/posterior em JSON.

### B7 — Projeto físico e backup

O relatório final documenta:

- revisão dos tipos de dados;
- estimativa de crescimento das tabelas de maior movimento em dois anos;
- análise de índices e desempenho;
- estratégia de backup, retenção e restauração;
- discussão sobre particionamento/arquivamento histórico quando aplicável.

Exemplo de backup:

```bat
mysqldump -u SEU_USUARIO -p --routines --triggers db_transportadora > backup_db_transportadora.sql
```

A restauração deve ser validada em uma base de teste, conferindo contagens, views, triggers e consultas principais.

### B8 — Relatório final e apresentação

O relatório consolidado das Etapas 1 e 2 está em:

```text
docs/Relatorio_Final_Transportadora_Grupo01.pdf
```

O modelo conceitual revisado da Etapa 2 está em:

```text
docs_etapa2/mer-conceitual-etapa2-final.pdf
```

A apresentação da Etapa 2 está em:

```text
docs_etapa2/Apresentacao_Final_Etapa2.pdf
```

Os arquivos `relatorio-etapa1.pdf`, `mer-conceitual.pdf` e demais documentos antigos permanecem apenas como histórico da Etapa 1. Para a entrega final, use o relatório consolidado e o MER revisado indicados acima.

A demonstração deve priorizar o banco em operação: CRUD, consulta parametrizada, relatório por view, transação com sucesso e falha, restrição tratada, `EXPLAIN` e perfis distintos.

## Testes

Execute os testes automatizados locais dentro de `transportadora_app/`:

```bat
py -m unittest discover -s tests -v
```

Na revisão deste pacote, os **14 testes automatizados** foram executados com sucesso. Esses testes verificam hash/sal, perfis de conexão, tratamento de mensagens e estrutura mínima do projeto.

Além dos testes automatizados, a equipe informou a conclusão com sucesso dos testes integrados previstos para a Etapa 2. As evidências utilizadas na entrega devem corresponder ao ambiente real de demonstração.

## Dados pessoais e dados de teste

A carga do projeto utiliza dados **fictícios ou sintéticos**. Dados pessoais reais de terceiros não devem ser inseridos no repositório, em arquivos de configuração, dumps ou evidências.

No domínio, CPF/CNPJ, telefone, e-mail, endereço e dados de funcionários seriam considerados informações pessoais e devem ser protegidos por menor privilégio e views restritas.

## Integridade acadêmica e uso de IA

O uso de inteligência artificial foi declarado no relatório final. As ferramentas informadas pela equipe foram:

- **ChatGPT 5.6 — versão Plus**;
- **Gemini 4 — versão Pro**;
- **Claude Opus 5.5 — versão Pro**;
- **Claude Sonnet 5.5 — versão gratuita**;
- **BLACKBOX**.

As ferramentas foram utilizadas como apoio ao estudo, revisão de documentação e código. Os resultados utilizados no projeto foram revisados e testados pela equipe, que permanece responsável pelas decisões de modelagem, implementação e demonstração.

Não foram utilizados modelos, scripts ou aplicações de outras equipes como autoria própria.


## Observação sobre o MySQL Workbench

O MySQL Workbench é apenas um cliente para executar e inspecionar comandos SQL. A aplicação conecta diretamente ao **MySQL Server** e não depende de o Workbench estar aberto durante seu uso.
