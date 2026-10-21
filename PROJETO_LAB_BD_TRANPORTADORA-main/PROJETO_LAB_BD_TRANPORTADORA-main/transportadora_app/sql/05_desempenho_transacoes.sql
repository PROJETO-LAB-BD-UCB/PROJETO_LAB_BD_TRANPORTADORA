-- =====================================================================
-- ETAPA 2 - roteiro de medição, concorrência, injeção SQL e backup
-- Execute a parte de EXPLAIN ANTES dos índices; depois execute a seção
-- de criação de índices e repita os EXPLAIN, registrando as evidências.
-- =====================================================================
USE db_transportadora;

-- ---------------------------------------------------------------------
-- CONSULTA CRÍTICA 1: desempenho de motoristas por período.
-- 1) Execute o EXPLAIN antes dos índices e guarde o resultado.
EXPLAIN
SELECT f.id_funcionario, f.nome,
       COUNT(t.id_tentativa) AS tentativas,
       SUM(CASE WHEN t.resultado='SUCESSO' THEN 1 ELSE 0 END) AS sucessos,
       ROUND(100.0*SUM(CASE WHEN t.resultado='SUCESSO' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(t.id_tentativa),0),2) AS taxa_sucesso_pct
FROM funcionario f
JOIN motorista m ON m.id_funcionario=f.id_funcionario
LEFT JOIN tentativa_entrega t ON t.id_funcionario_motorista=m.id_funcionario
  AND t.data_hora >= '2026-01-01 00:00:00' AND t.data_hora < '2027-01-01 00:00:00'
GROUP BY f.id_funcionario,f.nome;

-- CONSULTA CRÍTICA 2: encomendas com filtro por período/status.
EXPLAIN
SELECT e.id_encomenda,e.codigo_rastreio,e.data_postagem,v.status_atual
FROM encomenda e
LEFT JOIN vw_encomenda_status_atual v ON v.id_encomenda=e.id_encomenda
WHERE e.data_postagem BETWEEN '2026-01-01' AND '2026-12-31'
  AND v.status_atual='EM_TRANSITO'
ORDER BY e.data_postagem DESC;

-- CONSULTA CRÍTICA 3: ocorrências por período/situação.
EXPLAIN
SELECT o.situacao,o.tipo,COUNT(*) AS total
FROM ocorrencia o
WHERE o.data_hora >= '2026-01-01 00:00:00' AND o.data_hora < '2027-01-01 00:00:00'
GROUP BY o.situacao,o.tipo;

-- ---------------------------------------------------------------------
-- Criar os índices candidatos uma única vez, de forma idempotente.
-- Execute o arquivo inteiro: primeiro serão exibidos os EXPLAINs de base;
-- este bloco adiciona somente os índices que ainda não existem; depois os
-- EXPLAINs são repetidos. Compare-os e use o tempo de execução observado no
-- Action Output do Workbench (EXPLAIN, isoladamente, não fornece duração).
SET @ddl_index = IF(
  (SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE() AND table_name = 'tentativa_entrega'
     AND index_name = 'idx_tentativa_motorista_data_resultado') = 0,
  'ALTER TABLE tentativa_entrega ADD INDEX idx_tentativa_motorista_data_resultado (id_funcionario_motorista,data_hora,resultado)',
  'SELECT ''idx_tentativa_motorista_data_resultado já existe'' AS informacao');
PREPARE stmt_index FROM @ddl_index; EXECUTE stmt_index; DEALLOCATE PREPARE stmt_index;

SET @ddl_index = IF(
  (SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE() AND table_name = 'encomenda'
     AND index_name = 'idx_encomenda_data_id') = 0,
  'ALTER TABLE encomenda ADD INDEX idx_encomenda_data_id (data_postagem,id_encomenda)',
  'SELECT ''idx_encomenda_data_id já existe'' AS informacao');
PREPARE stmt_index FROM @ddl_index; EXECUTE stmt_index; DEALLOCATE PREPARE stmt_index;

SET @ddl_index = IF(
  (SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE() AND table_name = 'ocorrencia'
     AND index_name = 'idx_ocorrencia_data_situacao_tipo') = 0,
  'ALTER TABLE ocorrencia ADD INDEX idx_ocorrencia_data_situacao_tipo (data_hora,situacao,tipo)',
  'SELECT ''idx_ocorrencia_data_situacao_tipo já existe'' AS informacao');
PREPARE stmt_index FROM @ddl_index; EXECUTE stmt_index; DEALLOCATE PREPARE stmt_index;

-- EXPLAIN DEPOIS DOS ÍNDICES: compare o plano com o obtido acima.
EXPLAIN
SELECT f.id_funcionario, f.nome,
       COUNT(t.id_tentativa) AS tentativas,
       SUM(CASE WHEN t.resultado='SUCESSO' THEN 1 ELSE 0 END) AS sucessos,
       ROUND(100.0*SUM(CASE WHEN t.resultado='SUCESSO' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(t.id_tentativa),0),2) AS taxa_sucesso_pct
FROM funcionario f
JOIN motorista m ON m.id_funcionario=f.id_funcionario
LEFT JOIN tentativa_entrega t ON t.id_funcionario_motorista=m.id_funcionario
  AND t.data_hora >= '2026-01-01 00:00:00' AND t.data_hora < '2027-01-01 00:00:00'
GROUP BY f.id_funcionario,f.nome;

EXPLAIN
SELECT e.id_encomenda,e.codigo_rastreio,e.data_postagem,v.status_atual
FROM encomenda e
LEFT JOIN vw_encomenda_status_atual v ON v.id_encomenda=e.id_encomenda
WHERE e.data_postagem BETWEEN '2026-01-01' AND '2026-12-31'
  AND v.status_atual='EM_TRANSITO'
ORDER BY e.data_postagem DESC;

EXPLAIN
SELECT o.situacao,o.tipo,COUNT(*) AS total
FROM ocorrencia o
WHERE o.data_hora >= '2026-01-01 00:00:00' AND o.data_hora < '2027-01-01 00:00:00'
GROUP BY o.situacao,o.tipo;

-- ---------------------------------------------------------------------
-- EXPERIMENTO DE CONCORRÊNCIA (duas janelas/sessões no MySQL Workbench)
-- Sessão A:
--   SELECT @@transaction_isolation;
--   START TRANSACTION;
--   SELECT id_encomenda FROM encomenda WHERE id_encomenda=1 FOR UPDATE;
--   -- Não faça COMMIT ainda.
-- Sessão B:
--   SELECT @@transaction_isolation;
--   START TRANSACTION;
--   UPDATE encomenda SET valor_declarado=COALESCE(valor_declarado,0)+0.01
--   WHERE id_encomenda=1;
--   -- Registre o tempo de espera/bloqueio. Depois faça ROLLBACK na sessão B.
-- Sessão A: COMMIT; observe a sessão B e depois encerre suas transações.
-- Use um registro de teste se não quiser mudar um registro real. Em sessão A
-- e B, registre o nível de isolamento e o comportamento observado.

-- ---------------------------------------------------------------------
-- TESTE DE INJEÇÃO SQL (executar no formulário de pesquisa da aplicação):
-- Digite como valor de pesquisa: ' OR 1=1 --
-- O resultado deve ser tratado como texto literal de pesquisa. Nenhuma tabela
-- pode ser apagada/modificada, pois os valores são enviados em parâmetros %s.

-- ---------------------------------------------------------------------
-- BACKUP (executar no Prompt de Comando, não dentro do editor SQL):
-- mysqldump -u SEU_USUARIO -p --routines --triggers db_transportadora > backup_db_transportadora.sql
-- RESTAURAÇÃO EM UM BANCO DE TESTE (primeiro crie db_transportadora_teste e adapte
-- o dump se ele contiver CREATE DATABASE/USE):
-- mysql -u SEU_USUARIO -p db_transportadora_teste < backup_db_transportadora.sql
-- Registre data, tamanho do arquivo e verifique contagens depois da restauração.
