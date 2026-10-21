# Nexo Logística — Etapa 2 (Python + MySQL)

Aplicação desktop para o **Sistema de Gestão de Transportadora, Rastreamento e Entregas**. Usa Python/Tkinter e `mysql-connector-python`; conecta ao servidor MySQL, e não ao aplicativo MySQL Workbench. O Workbench serve para executar os scripts e observar o banco.

> A aplicação e os scripts foram preparados para os requisitos B1–B7 do enunciado da Etapa 2. Eles precisam ser executados e testados no seu servidor MySQL para gerar as evidências reais do relatório. O pacote não afirma que testes de conexão, concorrência ou desempenho já foram realizados no computador da equipe.

## Requisitos

- Python 3.10 ou superior, com Tkinter disponível.
- MySQL Server 8.0 ou superior e MySQL Workbench para executar os scripts.
- Banco `db_transportadora` construído a partir do DDL da Etapa 1.
- Permissão para executar os scripts de segurança e criar papéis/triggers/views.

## Preparar o banco

Execute no MySQL Workbench, nessa ordem:

1. `sql/01_ddl.sql` — script original de criação do banco e tabelas. **Atenção:** contém `DROP DATABASE IF EXISTS db_transportadora`, então apaga e recria o banco com esse nome. Faça backup e só execute quando quiser recriar uma base de testes.
2. `sql/02_carga.sql` — insere a carga fictícia da Etapa 1.
3. `sql/04_etapa2_seguranca_auditoria.sql` — cria a tabela de usuários da aplicação, views para relatório/consulta, tabela de auditoria, quatro gatilhos de auditoria e três papéis de acesso do MySQL.
4. `sql/03_consultas.sql` — consultas acadêmicas da Etapa 1; opcional para abrir a interface.

O arquivo `sql/05_desempenho_transacoes.sql` contém consultas `EXPLAIN` antes/depois, criação condicional de índices (pode ser repetida), roteiro do experimento de concorrência, teste de SQL injection e comandos de backup. Registre o plano antes e depois e meça separadamente o tempo de execução no Workbench; os resultados dependem do volume de dados e do plano escolhido pelo seu servidor.

## Instalar e executar no Windows

Abra `cmd` na pasta que contém `app.py` e execute:

```bat
py -m venv .venv
.venv\Scripts\activate.bat
py -m pip install -r requirements.txt
py app.py
```

Alternativamente, depois de instalar as dependências, dê dois cliques em `run.bat`. Para executar os testes locais de hash e estrutura do projeto:

```bat
py -m unittest discover -s tests -v
```

Na primeira execução, configure a conexão MySQL pela tela da aplicação. Para uma instalação local típica, o host é `localhost`, porta `3306` e o banco é `db_transportadora`. Use as credenciais definidas na instalação/conta MySQL.

**Primeiro acesso à aplicação:** depois de executar `04_etapa2_seguranca_auditoria.sql`, conecte inicialmente com uma conta MySQL que tenha permissão para inserir em `usuario_aplicacao` (por exemplo, um usuário administrativo local) e a aplicação solicitará criar a primeira conta administradora. A senha precisa ter pelo menos 10 caracteres e é armazenada com PBKDF2-HMAC-SHA256, sal aleatório e iterações registradas. As próximas aberturas pedem usuário e senha. O perfil CONSULTA tem acesso às views limitadas de relatório e rastreamento, e não pode alterar registros pela interface.

## Funcionalidades incluídas

### B1 — Interface e CRUD

- Clientes PF/PJ: cadastrar, consultar/pesquisar, editar e excluir. Os dados comuns e a subclasse PF/PJ são atualizados na mesma transação; exclusão de cliente com encomendas é impedida pela chave estrangeira.
- Encomendas: cadastrar com volume 1 e histórico inicial `REGISTRADA` numa única transação; consultar/pesquisar, editar campos e excluir mediante confirmação explícita. A exclusão pode remover dados dependentes em cascata, como volumes, histórico e ocorrências.
- Ocorrências: criar, consultar, editar e excluir, com validação de domínio e campos obrigatórios.
- Serviços adicionais: criar, consultar, editar e excluir; o banco impede remover serviços já vinculados a encomendas.
- Rastreamento, painel, relatórios e consultas operacionais.
- Duas consultas parametrizadas com junções e agregações: desempenho de motoristas por período e encomendas por status/cidade/período.
- Relatório consolidado baseado na `vw_relatorio_operacional`.
- Mensagens de erro mais compreensíveis para erros de integridade comuns (documento/código duplicado, FK, CHECK e ausência de permissão).

### B2 — Camada de dados e credenciais

- Os valores digitados em filtros e formulários são enviados com parâmetros `%s` do conector; não são concatenados aos valores SQL.
- `config.ini` guarda localmente as credenciais de conexão do servidor; ele está listado em `.gitignore` e **não deve ser enviado ao Git**. O arquivo local não criptografa a senha do MySQL; use um usuário de banco específico e permissões mínimas.
- Para demonstrar resistência à injeção, pesquise pelo texto `' OR 1=1 --` no campo de pesquisa. Ele deve ser tratado como valor literal e não como SQL executável. Registre a entrada, resultado e a consulta parametrizada usada.

### B3 — Transação e concorrência

- O cadastro de cliente grava `cliente` + `cliente_pf`/`cliente_pj` na mesma transação.
- O cadastro de encomenda grava `encomenda` + `volume_encomenda` + `historico_status_encomenda` na mesma transação.
- Em **Segurança e testes → Transações e concorrência**, execute o teste de rollback. Ele insere uma encomenda e um volume válido, tenta inserir novamente o mesmo número de volume (violação da chave primária composta) e comprova que a encomenda e o volume não permanecem no banco. Essa falha intencional é mais portátil do que depender de CHECK constraints; execute somente em ambiente de teste.
- O nível de isolamento do servidor aparece ao clicar em **Consultar isolamento**.
- Para a concorrência, siga o roteiro de duas sessões no `sql/05_desempenho_transacoes.sql` e preencha o modelo de evidências `docs/ETAPA2_TESTES.md`. O teste concorrente precisa ser executado ao vivo em duas sessões; a interface não inventa resultados desse experimento.

### B4 — Otimização

`sql/05_desempenho_transacoes.sql` tem três consultas críticas com `EXPLAIN` e três índices candidatos. Registre plano e duração antes; aplique os índices uma vez; registre novamente plano e duração com o mesmo conjunto de dados e compare. Se um índice não melhorar a consulta, documente o resultado e explique-o.

### B5 — Segurança e perfis

O script cria os papéis MySQL:

- `nexo_consulta`: acesso a views limitadas, sem CPF/CNPJ, telefone e e-mail.
- `nexo_operador`: leitura das tabelas operacionais e escrita apenas nas tabelas usadas pelos CRUDs da aplicação.
- `nexo_admin`: administração completa do schema do projeto.

O script define `GRANT` e `REVOKE`. Ele cria papéis, mas não cria logins MySQL com senhas padrão. O bloco completo abaixo cria os três logins, atribui os papéis e mostra os privilégios; execute-o uma única vez, por uma conta administradora, depois de substituir as senhas de exemplo. Se algum login já existir, não execute novamente o `CREATE USER` correspondente.

A tabela `usuario_aplicacao` armazena as senhas de login da **interface** como hash e sal. Para alinhar também os privilégios reais do banco ao perfil autenticado, configure no `config.ini` conexões MySQL dedicadas. A seção `[mysql]` é a conta inicial/de configuração; após autenticar, a aplicação tenta trocar para a seção do perfil:

```ini
[mysql]
host = localhost
port = 3306
database = db_transportadora
user = conta_inicial_administrativa
password = senha_da_conta_inicial

[mysql_administrador]
user = nexo_admin_app
password = senha_forte_do_admin

[mysql_operador]
user = nexo_operador_app
password = senha_forte_do_operador

[mysql_consulta]
user = nexo_consulta_app
password = senha_forte_de_consulta
```

As seções de perfil herdam host, porta e banco de `[mysql]`. A conta `[mysql]` é usada na configuração inicial para criar o primeiro administrador; quando o perfil CONSULTA estiver configurado, ela também será usada para validar a autenticação da aplicação com privilégios mínimos. Após o login, a aplicação troca para a seção correspondente ao perfil autenticado. Crie os logins uma vez no Workbench usando senhas fortes, e atribua os papéis que o script 04 cria:

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

Troque as três senhas de exemplo antes de executar e não as salve no repositório. Se um login já existir, remova `CREATE USER` da execução e redefina a senha com o procedimento administrativo apropriado. A conta inicial precisa de permissão para criar o primeiro usuário da interface. Depois, quando um usuário se autentica, o programa troca para a seção MySQL que corresponde ao seu perfil. Se uma seção de perfil não estiver configurada, a interface mostra um aviso: as telas continuam restritas por perfil, mas a permissão no servidor permanece a da conta geral, o que não basta para demonstrar o menor privilégio.

O perfil CONSULTA deve acessar apenas views permitidas; o OPERADOR, as tabelas de negócio necessárias aos CRUDs; e o ADMINISTRADOR, as funções de administração do sistema. O script cria `vw_rastreamento_publico`, que limita as colunas expostas ao perfil de consulta, e `vw_relatorio_operacional`, usado pelo relatório operacional completo. A tela de relatório do perfil CONSULTA usa apenas `vw_rastreamento_publico`, que não expõe nome/documento/contato do remetente nem o valor declarado. A conta MySQL inicial precisa manter permissão para cadastrar o primeiro usuário da aplicação; guarde suas credenciais com cuidado e não as compartilhe. O fluxo normal de autenticação consulta a tabela de usuários via papel CONSULTA sempre que essa seção estiver configurada.

### B6 — Auditoria

O script cria `auditoria_alteracao` e quatro gatilhos (`trg_auditoria_cliente_upd`, `trg_auditoria_cliente_pf_upd`, `trg_auditoria_cliente_pj_upd`, `trg_auditoria_encomenda_upd`) para guardar autor, data/hora e JSON dos valores anterior/posterior em alterações de dados comuns de cliente, dados específicos PF/PJ e encomendas. As operações feitas pela aplicação definem a variável de sessão `@app_actor` dentro da transação. A tela **Segurança e testes → Auditoria** permite ao administrador consultar o histórico. Para gerar registros, edite um cliente ou uma encomenda.

### B7 — Projeto físico e backup

- Avalie e documente os tipos de dados na revisão do relatório final.
- Use o roteiro SQL para comparar três consultas com `EXPLAIN` antes/depois dos índices.
- Backup em Prompt de Comando (com cliente `mysqldump` instalado):

```bat
mysqldump -u SEU_USUARIO -p --routines --triggers db_transportadora > backup_db_transportadora.sql
```

Faça uma restauração em uma base de teste e valide contagens de registros e views. O script 05 inclui o roteiro em comentários; complete no relatório a frequência de backup, retenção e evidência de restauração.

## Arquivos principais

- `app.py` — telas e interface.
- `database.py` — conexão, consultas parametrizadas, autenticação e transações.
- `security.py` — hash de senha com PBKDF2-HMAC-SHA256 e sal aleatório.
- `sql/01_ddl.sql`, `02_carga.sql`, `03_consultas.sql` — arquivos originais da Etapa 1.
- `sql/04_etapa2_seguranca_auditoria.sql` — views, contas da aplicação, papéis e auditoria.
- `sql/05_desempenho_transacoes.sql` — desempenho, concorrência, injeção SQL e backup.
- `sql/06_verificacao_etapa2.sql` — consultas para conferir views, gatilhos, índices e volume real do banco.
- `docs/ETAPA2_TESTES.md` — roteiro para anotar evidências observadas no ambiente real.
- `docs/PLANO_FISICO_BACKUP.md` — premissas de crescimento, retenção, backup/restauração e decisões físicas propostas.
- `tests/` — testes locais de hash/sal e de estrutura; não substituem os testes conectados ao MySQL.

## Limites e validação pendente

A interface cobre os requisitos funcionais essenciais, mas a equipe ainda deve executar os scripts num MySQL real, validar cada fluxo, obter as evidências de concorrência/EXPLAIN/backup, revisar os privilégios no servidor e registrar os resultados no relatório. Não declare testes que não tenham sido executados. O enunciado também exige declarar no relatório como a IA foi usada, se aplicável.

## Correção aplicada para rastreamento e rollback

Se a pasta do projeto já estava instalada, copie a versão atualizada de `app.py` para a pasta existente e execute novamente `sql/04_etapa2_seguranca_auditoria.sql` no Workbench. Não execute novamente `01_ddl.sql` nem `02_carga.sql` para aplicar esta correção. O perfil CONSULTA agora usa views restritas no rastreamento, e a demonstração de rollback provoca uma chave primária duplicada depois de gravar duas tabelas na mesma transação.

Para testar o rastreamento, use um código presente na carga fictícia, por exemplo `BR100000TR`, `BR100001TR` ou `BR100002TR`. O código precisa existir exatamente na base conectada.
