-- =====================================================================
-- ETAPA 2 - consultas de conferência pós-instalação
-- Execute depois de 01_ddl.sql, 02_carga.sql e 04_etapa2_seguranca_auditoria.sql.
-- Consultas de leitura: não alteram os registros do domínio.
-- =====================================================================
USE db_transportadora;

-- 1) Versão do MySQL e nível de isolamento corrente.
SELECT VERSION() AS versao_mysql, @@transaction_isolation AS nivel_isolamento;

-- 2) Volumes reais (COUNT exato) das tabelas de maior movimento.
SELECT 'encomenda' AS tabela, COUNT(*) AS total FROM encomenda
UNION ALL SELECT 'volume_encomenda', COUNT(*) FROM volume_encomenda
UNION ALL SELECT 'historico_status_encomenda', COUNT(*) FROM historico_status_encomenda
UNION ALL SELECT 'tentativa_entrega', COUNT(*) FROM tentativa_entrega
UNION ALL SELECT 'ocorrencia', COUNT(*) FROM ocorrencia
UNION ALL SELECT 'expedicao_encomenda', COUNT(*) FROM expedicao_encomenda
UNION ALL SELECT 'encomenda_servico', COUNT(*) FROM encomenda_servico;

-- 3) Views necessárias à aplicação/relatório.
SELECT table_name AS view_disponivel
FROM information_schema.views
WHERE table_schema = DATABASE()
  AND table_name IN ('vw_encomenda_status_atual', 'vw_relatorio_operacional',
                     'vw_rastreamento_publico', 'vw_historico_rastreamento_publico', 'vw_desempenho_motoristas')
ORDER BY table_name;

-- 4) Gatilhos de auditoria instalados.
SELECT trigger_name, event_object_table, event_manipulation, action_timing
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
  AND trigger_name LIKE 'trg_auditoria_%'
ORDER BY event_object_table, trigger_name;

-- 5) Índices da Etapa 2 instalados.
SELECT table_name, index_name, seq_in_index, column_name
FROM information_schema.statistics
WHERE table_schema = DATABASE()
  AND index_name IN ('idx_tentativa_motorista_data_resultado',
                     'idx_encomenda_data_id',
                     'idx_ocorrencia_data_situacao_tipo')
ORDER BY table_name, index_name, seq_in_index;

-- 6) Revise os privilégios de cada conta no editor SQL (substitua os nomes
-- pelos logins que a equipe criou). Estes comandos retornam evidência direta:
-- SHOW GRANTS FOR 'nexo_consulta_app'@'localhost';
-- SHOW GRANTS FOR 'nexo_operador_app'@'localhost';
-- SHOW GRANTS FOR 'nexo_admin_app'@'localhost';

-- 7) Para testar auditoria, edite uma linha de cliente/encomenda pela aplicação,
-- depois execute a consulta abaixo. Ela não deve ser usada como única evidência;
-- confira se autor, data, JSON anterior e JSON posterior fazem sentido.
SELECT id_auditoria, tabela_afetada, operacao, registro_id, autor, data_hora,
       valores_anteriores, valores_posteriores
FROM auditoria_alteracao
ORDER BY id_auditoria DESC
LIMIT 50;
