-- =====================================================================
-- Trabalho Laboratório de Banco de Dados
--
-- BRUNO LUCAS CAIXETA BRAGA
-- CARLOS EDUARDO ESTRELA DE MACEDO
-- GUILHERME ALFEU BORGES CARVALHO BRAGA
-- RYAN GABRIEL ARAÚJO ALMEIDA
--
-- Sistema de Transportadora, Rastreamento e Entregas
-- A8 - Consultas de verificacao
-- Arquivo: 03_consultas.sql

-- =====================================================================
-- Distribuicao exigida pelo enunciado (15 consultas comentadas):
--   Basicas (5): projecao, WHERE, ordenacao, LIKE, BETWEEN, IN, tratamento de NULL
--   Juncoes e agregacao (5): >=1 com 3 tabelas, >=1 com LEFT JOIN, >=1 com GROUP BY + HAVING
--   Avancadas (5): >=1 subconsulta correlacionada, >=1 EXISTS, >=1 pergunta de negocio nao trivial
-- Cada bloco comeca com a pergunta de negocio que a consulta responde.
-- Consultas revisadas para a estrutura de 01_ddl.sql e para a carga de 02_carga.sql.
-- A carga atual possui 48 encomendas, 24 funcionarios, 14 motoristas, 16 veiculos,
-- 7 rotas, 6 centros de distribuicao, 254 eventos de historico e 35 tentativas de entrega.
-- =====================================================================


USE db_transportadora;


-- #####################################################################
-- BLOCO 1 - CONSULTAS BASICAS

-- -----------------------------------------------------------------
-- Consulta 1 (Basica - projecao, WHERE, tratamento de NULL, ORDER BY)
-- Pergunta de negocio: Quais clientes nao informaram telefone de
-- contato no cadastro, do cadastro mais recente para o mais antigo?
-- Util para a equipe de atendimento priorizar a complementacao de
-- dados de contato.


SELECT
    id_cliente,
    tipo_cliente,
    email,
    data_cadastro
FROM cliente
WHERE telefone IS NULL
ORDER BY data_cadastro DESC;


-- -----------------------------------------------------------------
-- Consulta 2 (Basica - LIKE)
-- Pergunta de negocio: Quais ocorrencias registradas no sistema
-- mencionam "atraso" na descricao, independentemente do tipo
-- formalmente classificado?


SELECT
    id_ocorrencia,
    tipo,
    data_hora,
    descricao,
    situacao
FROM ocorrencia
WHERE descricao LIKE '%atraso%'
ORDER BY data_hora;


-- -----------------------------------------------------------------
-- Consulta 3 (Basica - BETWEEN, ORDER BY)
-- Pergunta de negocio: Quais encomendas foram postadas no primeiro
-- trimestre de 2026 (janeiro a marco)? Apoia o fechamento de
-- relatorio trimestral de volume postado.


SELECT
    id_encomenda,
    codigo_rastreio,
    data_postagem,
    valor_declarado
FROM encomenda
WHERE data_postagem BETWEEN '2026-01-01' AND '2026-03-31'
ORDER BY data_postagem;


-- -----------------------------------------------------------------
-- Consulta 4 (Basica - IN)
-- Pergunta de negocio: Quais veiculos da frota estao indisponiveis
-- para uso agora (em manutencao ou inativos), para planejamento de
-- expedicoes futuras?


SELECT
    id_veiculo,
    placa,
    modelo,
    situacao
FROM veiculo
WHERE situacao IN ('MANUTENCAO', 'INATIVO')
ORDER BY situacao, placa;


-- -----------------------------------------------------------------
-- Consulta 5 (Basica - WHERE com tratamento de NULL, ORDER BY, LIMIT)
-- Pergunta de negocio: Quais sao as 10 encomendas de maior valor
-- declarado entre as que tiveram valor informado pelo remetente?
-- (RN11: valor declarado e opcional e, quando informado, nao pode
-- ser negativo.)


SELECT
    codigo_rastreio,
    valor_declarado,
    data_postagem
FROM encomenda
WHERE valor_declarado IS NOT NULL
ORDER BY valor_declarado DESC
LIMIT 10;


-- #####################################################################
-- JUNCOES E AGREGACAO

-- -----------------------------------------------------------------
-- Consulta 6 (Juncao com 6 tabelas + LEFT JOIN para especializacao)
-- Pergunta de negocio: Para as 15 encomendas mais recentes, quem e o
-- cliente remetente (Pessoa Fisica ou Juridica) e para qual cidade
-- de destino a encomenda foi enviada?
-- Observacao de modelagem: CLIENTE_PF e CLIENTE_PJ sao subclasses
-- totais e exclusivas de CLIENTE (RN02); como uma linha de CLIENTE so
-- tem correspondencia em uma das duas tabelas, usamos LEFT JOIN nas
-- duas e COALESCE para obter o nome do remetente independentemente
-- do tipo de pessoa, sem precisar de UNION.


SELECT
    e.codigo_rastreio,
    COALESCE(pf.nome, pj.razao_social) AS remetente,
    cid.nome AS cidade_destino,
    cid.uf   AS uf_destino
FROM encomenda e
JOIN cliente c            ON c.id_cliente = e.id_cliente
LEFT JOIN cliente_pf pf   ON pf.id_cliente = c.id_cliente
LEFT JOIN cliente_pj pj   ON pj.id_cliente = c.id_cliente
JOIN endereco end_dest    ON end_dest.id_endereco = e.id_endereco_destino
JOIN cidade cid           ON cid.id_cidade = end_dest.id_cidade
ORDER BY e.data_postagem DESC
LIMIT 15;


-- -----------------------------------------------------------------
-- Consulta 7 (LEFT JOIN explicito + GROUP BY)
-- Pergunta de negocio: Quantas expedicoes cada motorista ja
-- conduziu, incluindo motoristas que nunca saram em nenhuma
-- expedicao registrada (devem aparecer com total 0, nao serem
-- omitidos do relatorio)?


SELECT
    f.nome AS motorista,
    COUNT(ex.id_expedicao) AS total_expedicoes
FROM funcionario f
JOIN motorista m       ON m.id_funcionario = f.id_funcionario
LEFT JOIN expedicao ex ON ex.id_funcionario_motorista = m.id_funcionario
GROUP BY f.id_funcionario, f.nome
ORDER BY total_expedicoes DESC, motorista;


-- -----------------------------------------------------------------
-- Consulta 8 (GROUP BY + HAVING)
-- Pergunta de negocio: Quais clientes ja enviaram mais de uma
-- encomenda pela transportadora? (identificacao de clientes
-- recorrentes para acoes comerciais de fidelizacao)


SELECT
    e.id_cliente,
    COALESCE(pf.nome, pj.razao_social) AS cliente,
    COUNT(*) AS total_encomendas
FROM encomenda e
JOIN cliente c          ON c.id_cliente = e.id_cliente
LEFT JOIN cliente_pf pf ON pf.id_cliente = c.id_cliente
LEFT JOIN cliente_pj pj ON pj.id_cliente = c.id_cliente
GROUP BY e.id_cliente, pf.nome, pj.razao_social
HAVING COUNT(*) > 1
ORDER BY total_encomendas DESC;


-- -----------------------------------------------------------------
-- Consulta 9 (Juncao com 3 tabelas + agregacao condicional)
-- Pergunta de negocio: Qual o desempenho de cada motorista nas
-- tentativas de entrega registradas: quantas tentativas ao todo,
-- quantas com sucesso e qual a taxa de sucesso (%)? Apoia avaliacao
-- operacional de motoristas mencionada no A1 (desempenho de rotas,
-- utilizacao de veiculos e motoristas).


SELECT
    f.nome AS motorista,
    COUNT(*) AS total_tentativas,
    SUM(CASE WHEN t.resultado = 'SUCESSO' THEN 1 ELSE 0 END) AS tentativas_sucesso,
    ROUND(100.0 * SUM(CASE WHEN t.resultado = 'SUCESSO' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_sucesso
FROM tentativa_entrega t
JOIN motorista m    ON m.id_funcionario = t.id_funcionario_motorista
JOIN funcionario f  ON f.id_funcionario = m.id_funcionario
GROUP BY f.id_funcionario, f.nome
ORDER BY pct_sucesso DESC, total_tentativas DESC;


-- -----------------------------------------------------------------
-- Consulta 10 (LEFT JOIN + agregacao)
-- Pergunta de negocio: Quantas encomendas distintas e quantos
-- eventos de historico cada centro de distribuicao ja processou,
-- incluindo centros que ainda nao tenham movimentacao registrada?
-- Indica os centros com maior volume de movimentacao (RN13).


SELECT
    cd.nome AS centro,
    COUNT(DISTINCT h.id_encomenda) AS encomendas_processadas,
    COUNT(h.id_historico) AS total_eventos_historico
FROM centro_distribuicao cd
LEFT JOIN historico_status_encomenda h ON h.id_centro = cd.id_centro
GROUP BY cd.id_centro, cd.nome
ORDER BY encomendas_processadas DESC, centro;


-- #####################################################################
-- BLOCO 3 - CONSULTAS AVANCADAS

-- -----------------------------------------------------------------
-- Consulta 11 (Subconsulta CORRELACIONADA)
-- Pergunta de negocio: Qual o status mais recente (e a data/hora
-- correspondente) de cada encomenda, considerando todo o historico
-- registrado?
-- A subconsulta e correlacionada porque usa e.id_encomenda da linha
-- externa. O criterio de desempate e o mesmo da view
-- vw_encomenda_status_atual: data_hora DESC e id_historico DESC.


SELECT
    e.id_encomenda,
    e.codigo_rastreio,
    h.status AS status_atual,
    h.data_hora AS data_hora_status
FROM encomenda e
JOIN historico_status_encomenda h
    ON h.id_historico = (
        SELECT h2.id_historico
        FROM historico_status_encomenda h2
        WHERE h2.id_encomenda = e.id_encomenda
        ORDER BY h2.data_hora DESC, h2.id_historico DESC
        LIMIT 1
    )
ORDER BY e.id_encomenda;


-- -----------------------------------------------------------------
-- Consulta 12 (EXISTS)
-- Pergunta de negocio: Quais clientes ja tiveram, em algum momento,
-- pelo menos uma encomenda com status EXTRAVIADA registrado no
-- historico? Apoia acoes preventivas de relacionamento com clientes
-- afetados por extravio.


SELECT
    c.id_cliente,
    COALESCE(pf.nome, pj.razao_social) AS cliente
FROM cliente c
LEFT JOIN cliente_pf pf ON pf.id_cliente = c.id_cliente
LEFT JOIN cliente_pj pj ON pj.id_cliente = c.id_cliente
WHERE EXISTS (
    SELECT 1
    FROM encomenda e
    JOIN historico_status_encomenda h ON h.id_encomenda = e.id_encomenda
    WHERE e.id_cliente = c.id_cliente
      AND h.status = 'EXTRAVIADA'
)
ORDER BY cliente;


-- -----------------------------------------------------------------
-- Consulta 13 (Pergunta de negocio NAO TRIVIAL - pontualidade)
-- Pergunta de negocio: Entre as expedicoes concluidas, qual e o
-- desempenho de prazo de cada rota? O relatorio mostra quantidade de
-- expedicoes, atraso/adiantamento medio em minutos e percentual de
-- chegadas no prazo ou adiantadas. Valores positivos em
-- media_diferenca_min indicam atraso medio; negativos, adiantamento.


SELECT
    r.id_rota,
    r.nome AS rota,
    COUNT(*) AS total_expedicoes_concluidas,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                ex.data_hora_prevista_chegada,
                ex.data_hora_chegada
            )
        ),
        1
    ) AS media_diferenca_min,
    SUM(
        CASE
            WHEN ex.data_hora_chegada <= ex.data_hora_prevista_chegada THEN 1
            ELSE 0
        END
    ) AS total_no_prazo_ou_adiantadas,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN ex.data_hora_chegada <= ex.data_hora_prevista_chegada THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        1
    ) AS pct_no_prazo_ou_adiantadas
FROM expedicao ex
JOIN rota r ON r.id_rota = ex.id_rota
WHERE ex.status_expedicao = 'CONCLUIDA'
  AND ex.data_hora_chegada IS NOT NULL
GROUP BY r.id_rota, r.nome
ORDER BY media_diferenca_min DESC, rota;


-- -----------------------------------------------------------------
-- Consulta 14 (Pergunta de negocio NAO TRIVIAL - validade da CNH)
-- Pergunta de negocio: Considerando apenas tentativas de entrega em
-- que a CNH do motorista estava dentro do periodo de validade na data
-- da tentativa, qual foi a taxa de sucesso por categoria de CNH
-- exigida pelo veiculo?
-- Observacao: esta consulta verifica apenas a validade temporal da
-- CNH; a compatibilidade entre categoria do motorista e do veiculo
-- corresponde a uma regra de integridade distinta do projeto.


SELECT
    v.categoria_cnh_exigida,
    COUNT(*) AS total_tentativas_com_cnh_valida,
    SUM(CASE WHEN t.resultado = 'SUCESSO' THEN 1 ELSE 0 END) AS tentativas_sucesso,
    ROUND(
        100.0 *
        SUM(CASE WHEN t.resultado = 'SUCESSO' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS pct_sucesso
FROM tentativa_entrega t
JOIN veiculo v
    ON v.id_veiculo = t.id_veiculo
JOIN motorista m
    ON m.id_funcionario = t.id_funcionario_motorista
WHERE DATE(t.data_hora)
      BETWEEN m.data_emissao_cnh AND m.data_validade_cnh
GROUP BY v.categoria_cnh_exigida
ORDER BY pct_sucesso DESC, v.categoria_cnh_exigida;


-- -----------------------------------------------------------------
-- Consulta 15 (Pergunta de negocio NAO TRIVIAL - ranking de receita)
-- Pergunta de negocio: Quais os 3 clientes que mais geraram receita
-- em servicos adicionais contratados (RN23-RN25), e quantas
-- encomendas distintas de cada um contrataram algum servico?
-- Apoia identificacao de clientes estrategicos para upsell de
-- servicos (seguro, entrega expressa, agendada, etc.).


SELECT
    COALESCE(pf.nome, pj.razao_social) AS cliente,
    SUM(es.valor_contratado) AS receita_servicos,
    COUNT(DISTINCT e.id_encomenda) AS qtd_encomendas_com_servico
FROM encomenda e
JOIN encomenda_servico es ON es.id_encomenda = e.id_encomenda
JOIN cliente c             ON c.id_cliente = e.id_cliente
LEFT JOIN cliente_pf pf    ON pf.id_cliente = c.id_cliente
LEFT JOIN cliente_pj pj    ON pj.id_cliente = c.id_cliente
GROUP BY e.id_cliente, pf.nome, pj.razao_social
ORDER BY receita_servicos DESC
LIMIT 3;

