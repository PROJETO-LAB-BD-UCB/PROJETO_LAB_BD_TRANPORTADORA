-- =====================================================================
-- ETAPA 2 - extensões de segurança, relatório consolidado e auditoria
-- Execute DEPOIS de 01_ddl.sql. Compatible com MySQL 8.0+.
-- Este arquivo não apaga o banco nem os dados existentes.
-- =====================================================================
USE db_transportadora;

-- 1) Usuários da aplicação. Senha nunca é armazenada em texto claro;
-- security.py usa PBKDF2-HMAC-SHA256, sal aleatório e 310.000 iterações.
CREATE TABLE IF NOT EXISTS usuario_aplicacao (
    id_usuario       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome_usuario     VARCHAR(60)  NOT NULL,
    nome_exibicao    VARCHAR(120) NOT NULL,
    senha_salt       CHAR(32)     NOT NULL,
    senha_hash       CHAR(64)     NOT NULL,
    iteracoes_hash   INT UNSIGNED NOT NULL DEFAULT 310000,
    perfil           VARCHAR(20)  NOT NULL,
    ativo            TINYINT(1)   NOT NULL DEFAULT 1,
    data_criacao     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultimo_login     DATETIME     NULL,
    CONSTRAINT pk_usuario_aplicacao PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_aplicacao_nome UNIQUE (nome_usuario),
    CONSTRAINT ck_usuario_aplicacao_perfil CHECK (perfil IN ('ADMINISTRADOR','OPERADOR','CONSULTA')),
    CONSTRAINT ck_usuario_aplicacao_ativo CHECK (ativo IN (0,1))
) ENGINE=InnoDB;

-- 2) View de consulta com colunas operacionais; omite CPF/CNPJ, telefone,
-- e-mail e outros dados pessoais. É a fonte do relatório consolidado.
CREATE OR REPLACE VIEW vw_relatorio_operacional AS
SELECT
    e.id_encomenda,
    e.codigo_rastreio,
    e.data_postagem,
    COALESCE(pf.nome, pj.razao_social, CONCAT('Cliente #', c.id_cliente)) AS remetente,
    cid.nome AS cidade_destino,
    cid.uf AS uf_destino,
    COALESCE(v.status_atual, 'SEM_HISTORICO') AS status_atual,
    e.valor_declarado,
    COUNT(DISTINCT vol.num_volume) AS total_volumes,
    COUNT(DISTINCT oc.id_ocorrencia) AS total_ocorrencias
FROM encomenda e
JOIN cliente c ON c.id_cliente = e.id_cliente
LEFT JOIN cliente_pf pf ON pf.id_cliente = c.id_cliente
LEFT JOIN cliente_pj pj ON pj.id_cliente = c.id_cliente
LEFT JOIN vw_encomenda_status_atual v ON v.id_encomenda = e.id_encomenda
JOIN endereco ed ON ed.id_endereco = e.id_endereco_destino
JOIN cidade cid ON cid.id_cidade = ed.id_cidade
LEFT JOIN volume_encomenda vol ON vol.id_encomenda = e.id_encomenda
LEFT JOIN ocorrencia oc ON oc.id_encomenda = e.id_encomenda
GROUP BY e.id_encomenda, e.codigo_rastreio, e.data_postagem,
         COALESCE(pf.nome, pj.razao_social, CONCAT('Cliente #', c.id_cliente)),
         cid.nome, cid.uf, COALESCE(v.status_atual, 'SEM_HISTORICO'), e.valor_declarado;

-- Uma vista ainda mais limitada para o perfil de consulta.
CREATE OR REPLACE VIEW vw_rastreamento_publico AS
SELECT codigo_rastreio, data_postagem, status_atual, cidade_destino, uf_destino
FROM vw_relatorio_operacional;

-- Histórico de rastreamento sem expor documentos, contatos ou observações internas.
-- Permite que o perfil CONSULTA veja a linha do tempo usando somente uma view.
CREATE OR REPLACE VIEW vw_historico_rastreamento_publico AS
SELECT e.codigo_rastreio, h.data_hora, h.status, cd.nome AS centro
FROM historico_status_encomenda h
JOIN encomenda e ON e.id_encomenda = h.id_encomenda
LEFT JOIN centro_distribuicao cd ON cd.id_centro = h.id_centro;

CREATE OR REPLACE VIEW vw_desempenho_motoristas AS
SELECT f.id_funcionario AS id_motorista,
       f.nome AS motorista,
       COUNT(t.id_tentativa) AS total_tentativas,
       SUM(CASE WHEN t.resultado = 'SUCESSO' THEN 1 ELSE 0 END) AS sucessos,
       SUM(CASE WHEN t.resultado = 'INSUCESSO' THEN 1 ELSE 0 END) AS insucessos,
       ROUND(100.0 * SUM(CASE WHEN t.resultado = 'SUCESSO' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(t.id_tentativa), 0), 2) AS taxa_sucesso_pct
FROM funcionario f
JOIN motorista m ON m.id_funcionario = f.id_funcionario
LEFT JOIN tentativa_entrega t ON t.id_funcionario_motorista = m.id_funcionario
GROUP BY f.id_funcionario, f.nome;

-- 3) Auditoria de alteração em CLIENTE e ENCOMENDA: armazena autor,
-- horário e JSON anterior/posterior. O app define @app_actor por transação.
CREATE TABLE IF NOT EXISTS auditoria_alteracao (
    id_auditoria       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tabela_afetada     VARCHAR(64) NOT NULL,
    operacao           VARCHAR(10) NOT NULL,
    registro_id        VARCHAR(80) NOT NULL,
    autor              VARCHAR(288) NOT NULL,
    data_hora          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valores_anteriores JSON NOT NULL,
    valores_posteriores JSON NOT NULL,
    CONSTRAINT pk_auditoria_alteracao PRIMARY KEY (id_auditoria),
    INDEX idx_auditoria_tabela_data (tabela_afetada, data_hora),
    INDEX idx_auditoria_autor (autor)
) ENGINE=InnoDB;

DROP TRIGGER IF EXISTS trg_auditoria_cliente_upd;
DROP TRIGGER IF EXISTS trg_auditoria_cliente_pf_upd;
DROP TRIGGER IF EXISTS trg_auditoria_cliente_pj_upd;
DROP TRIGGER IF EXISTS trg_auditoria_encomenda_upd;
DELIMITER $$
CREATE TRIGGER trg_auditoria_cliente_upd
AFTER UPDATE ON cliente
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_alteracao
       (tabela_afetada, operacao, registro_id, autor, valores_anteriores, valores_posteriores)
    VALUES
       ('cliente', 'UPDATE', CAST(OLD.id_cliente AS CHAR),
        COALESCE(NULLIF(@app_actor, ''), USER()),
        JSON_OBJECT('tipo_cliente', OLD.tipo_cliente, 'telefone', OLD.telefone,
                    'email', OLD.email, 'data_cadastro', OLD.data_cadastro),
        JSON_OBJECT('tipo_cliente', NEW.tipo_cliente, 'telefone', NEW.telefone,
                    'email', NEW.email, 'data_cadastro', NEW.data_cadastro));
END$$

CREATE TRIGGER trg_auditoria_cliente_pf_upd
AFTER UPDATE ON cliente_pf
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_alteracao
       (tabela_afetada, operacao, registro_id, autor, valores_anteriores, valores_posteriores)
    VALUES
       ('cliente_pf', 'UPDATE', CAST(OLD.id_cliente AS CHAR),
        COALESCE(NULLIF(@app_actor, ''), USER()),
        JSON_OBJECT('nome', OLD.nome, 'cpf', OLD.cpf),
        JSON_OBJECT('nome', NEW.nome, 'cpf', NEW.cpf));
END$$

CREATE TRIGGER trg_auditoria_cliente_pj_upd
AFTER UPDATE ON cliente_pj
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_alteracao
       (tabela_afetada, operacao, registro_id, autor, valores_anteriores, valores_posteriores)
    VALUES
       ('cliente_pj', 'UPDATE', CAST(OLD.id_cliente AS CHAR),
        COALESCE(NULLIF(@app_actor, ''), USER()),
        JSON_OBJECT('razao_social', OLD.razao_social, 'nome_fantasia', OLD.nome_fantasia, 'cnpj', OLD.cnpj),
        JSON_OBJECT('razao_social', NEW.razao_social, 'nome_fantasia', NEW.nome_fantasia, 'cnpj', NEW.cnpj));
END$$

CREATE TRIGGER trg_auditoria_encomenda_upd
AFTER UPDATE ON encomenda
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_alteracao
       (tabela_afetada, operacao, registro_id, autor, valores_anteriores, valores_posteriores)
    VALUES
       ('encomenda', 'UPDATE', CAST(OLD.id_encomenda AS CHAR),
        COALESCE(NULLIF(@app_actor, ''), USER()),
        JSON_OBJECT('codigo_rastreio', OLD.codigo_rastreio, 'data_postagem', OLD.data_postagem,
                    'valor_declarado', OLD.valor_declarado, 'id_cliente', OLD.id_cliente,
                    'id_endereco_origem', OLD.id_endereco_origem,
                    'id_endereco_destino', OLD.id_endereco_destino),
        JSON_OBJECT('codigo_rastreio', NEW.codigo_rastreio, 'data_postagem', NEW.data_postagem,
                    'valor_declarado', NEW.valor_declarado, 'id_cliente', NEW.id_cliente,
                    'id_endereco_origem', NEW.id_endereco_origem,
                    'id_endereco_destino', NEW.id_endereco_destino));
END$$
DELIMITER ;

-- 4) Papéis de acesso do MySQL 8. O usuário administrador que executa este
-- script precisa ter permissão para criar papéis e conceder privilégios.
CREATE ROLE IF NOT EXISTS 'nexo_consulta'@'%';
CREATE ROLE IF NOT EXISTS 'nexo_operador'@'%';
CREATE ROLE IF NOT EXISTS 'nexo_admin'@'%';

-- Demonstração executável de GRANT e REVOKE aplicando menor privilégio.
-- O GRANT inicial faz o REVOKE funcionar em uma instalação limpa; a permissão
-- de SELECT na tabela bruta de encomendas é então removida do perfil CONSULTA.
-- Ao final do script, CONSULTA recebe SELECT apenas nas views aprovadas.
GRANT SELECT ON db_transportadora.encomenda TO 'nexo_consulta'@'%';
REVOKE SELECT ON db_transportadora.encomenda FROM 'nexo_consulta'@'%';
GRANT SELECT ON db_transportadora.vw_rastreamento_publico TO 'nexo_consulta'@'%';
GRANT SELECT ON db_transportadora.vw_historico_rastreamento_publico TO 'nexo_consulta'@'%';
GRANT SELECT ON db_transportadora.vw_desempenho_motoristas TO 'nexo_consulta'@'%';

-- Operador pode consultar a estrutura e escrever apenas nas entidades usadas
-- pelos formulários CRUD; não recebe administração de schema/usuários.
GRANT SELECT ON db_transportadora.cliente TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.cliente_pf TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.cliente_pj TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.cidade TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.endereco TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.centro_distribuicao TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.funcionario TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.motorista TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.operador_logistico TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.veiculo TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.rota TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.rota_cidade TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.encomenda TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.expedicao TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.volume_encomenda TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.historico_status_encomenda TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.ocorrencia TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.expedicao_encomenda TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.tentativa_entrega TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.servico_adicional TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.encomenda_servico TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.vw_encomenda_status_atual TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.vw_relatorio_operacional TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.vw_rastreamento_publico TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.vw_historico_rastreamento_publico TO 'nexo_operador'@'%';
GRANT SELECT ON db_transportadora.vw_desempenho_motoristas TO 'nexo_operador'@'%';
GRANT INSERT, UPDATE, DELETE ON db_transportadora.cliente TO 'nexo_operador'@'%';
GRANT INSERT, UPDATE, DELETE ON db_transportadora.cliente_pf TO 'nexo_operador'@'%';
GRANT INSERT, UPDATE, DELETE ON db_transportadora.cliente_pj TO 'nexo_operador'@'%';
GRANT INSERT, UPDATE, DELETE ON db_transportadora.encomenda TO 'nexo_operador'@'%';
GRANT INSERT, UPDATE, DELETE ON db_transportadora.volume_encomenda TO 'nexo_operador'@'%';
GRANT INSERT, UPDATE, DELETE ON db_transportadora.historico_status_encomenda TO 'nexo_operador'@'%';
GRANT INSERT, UPDATE, DELETE ON db_transportadora.ocorrencia TO 'nexo_operador'@'%';
GRANT INSERT, UPDATE, DELETE ON db_transportadora.servico_adicional TO 'nexo_operador'@'%';

GRANT ALL PRIVILEGES ON db_transportadora.* TO 'nexo_admin'@'%';

-- A autenticação da interface precisa consultar hashes/sais e atualizar apenas
-- ultimo_login. O perfil de consulta não recebe INSERT/DELETE ou UPDATE geral
-- na tabela de contas da aplicação.
GRANT SELECT (id_usuario, nome_usuario, nome_exibicao, senha_salt, senha_hash, iteracoes_hash, perfil, ativo)
    ON db_transportadora.usuario_aplicacao TO 'nexo_consulta'@'%';
GRANT UPDATE (ultimo_login) ON db_transportadora.usuario_aplicacao TO 'nexo_consulta'@'%';
GRANT SELECT (id_usuario, nome_usuario, nome_exibicao, senha_salt, senha_hash, iteracoes_hash, perfil, ativo)
    ON db_transportadora.usuario_aplicacao TO 'nexo_operador'@'%';
GRANT UPDATE (ultimo_login) ON db_transportadora.usuario_aplicacao TO 'nexo_operador'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_transportadora.usuario_aplicacao TO 'nexo_admin'@'%';

-- EXEMPLOS PARA ATRIBUIR UM PAPEL A UM LOGIN MYSQL APÓS CRIÁ-LO COM SENHA
-- FORTE (não use senhas padrão em repositórios):
-- CREATE USER 'nexo_leitor_app'@'localhost' IDENTIFIED BY '<senha_forte_unica>';
-- GRANT 'nexo_consulta'@'%' TO 'nexo_leitor_app'@'localhost';
-- SET DEFAULT ROLE 'nexo_consulta'@'%' TO 'nexo_leitor_app'@'localhost';
-- SHOW GRANTS FOR 'nexo_leitor_app'@'localhost';
-- Para mudar/remover privilégios de uma conta: REVOKE 'nexo_consulta'@'%' FROM 'nexo_leitor_app'@'localhost';

-- 5) Índices candidatos para as três consultas de desempenho. A instrução
-- sql/05_desempenho_transacoes.sql contém o roteiro EXPLAIN antes/depois.
