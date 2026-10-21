# Etapa 2 — proposta de projeto físico, crescimento e backup

> **Natureza deste documento:** proposta acadêmica com premissas explícitas. Os números abaixo são projeções de cenário, não medições do MySQL real. A equipe deve compará-los com o volume efetivo da carga e ajustar as premissas, caso necessário.

## 1. Premissas de crescimento para dois anos

Para estimar crescimento, adota-se um cenário hipotético de **200 encomendas por dia**, durante **730 dias**. A carga da Etapa 1 é de teste e tem apenas dezenas de encomendas; portanto, ela não representa diretamente uma operação comercial nesse ritmo.

| Tabela de movimento | Premissa de negócio | Projeção para 2 anos |
|---|---:|---:|
| `encomenda` | 200 encomendas/dia | 146.000 linhas |
| `historico_status_encomenda` | 4 eventos por encomenda | 584.000 linhas |
| `volume_encomenda` | média de 1,4 volumes por encomenda | cerca de 204.400 linhas |
| `tentativa_entrega` | média de 1,25 tentativas por encomenda | cerca de 182.500 linhas |
| `ocorrencia` | média de 0,10 ocorrências por encomenda | cerca de 14.600 linhas |
| `expedicao_encomenda` | média de 1,6 trechos/expedições por encomenda | cerca de 233.600 linhas de associação |
| `encomenda_servico` | média de 0,4 serviços adicionais por encomenda | cerca de 58.400 linhas |

Fórmula aplicada às tabelas proporcionais: `encomendas em 2 anos × média de registros por encomenda`. As médias são hipóteses e devem ser substituídas por observações de produção, quando houver.

Para obter o tamanho real da base após executar a carga e os testes, use:

```sql
SELECT table_name,
       table_rows AS linhas_estimadas,
       ROUND(data_length / 1024 / 1024, 2) AS dados_mb,
       ROUND(index_length / 1024 / 1024, 2) AS indices_mb,
       ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_mb
FROM information_schema.tables
WHERE table_schema = 'db_transportadora'
ORDER BY data_length + index_length DESC;
```

`TABLE_ROWS` em tabelas InnoDB é estimado pelo servidor; não deve ser apresentado como contagem exata. Para contagem exata, execute `SELECT COUNT(*)` na tabela específica. Não alegue um tamanho medido antes de executar a consulta no servidor da equipe.

## 2. Decisões de projeto físico

- **Índices:** o DDL já indexa as chaves estrangeiras mais usadas. O script `sql/05_desempenho_transacoes.sql` acrescenta índices candidatos para busca por motorista/período (`idx_tentativa_motorista_data_resultado`), encomendas por data e ocorrências por período/situação. Como o DDL original já possui `idx_tentativa_motorista`, confira os planos e a cobertura do índice composto antes de decidir se o índice simples pode ser removido em uma revisão separada. A pertinência de cada índice deve ser julgada pela comparação do plano `EXPLAIN` e do tempo observado antes/depois, não apenas pela existência do índice.
- **Histórico temporal:** `historico_status_encomenda` é uma tabela de alto movimento e sustenta a view de status atual. O histórico não deve ser apagado só porque a encomenda foi entregue; é evidência de rastreamento e pode ser necessária para atendimento e auditoria.
- **Tipos de dados:** datas usam `DATE`/`DATETIME`; valores monetários usam `DECIMAL`, não `FLOAT`; identificadores são inteiros sem sinal; CPF/CNPJ e CEP são texto, para preservar zeros à esquerda. Códigos e documentos devem ser validados sem converter para números.
- **Particionamento:** não se recomenda implementar particionamento nesta versão acadêmica sem medição que o justifique. Tabelas particionadas podem restringir o uso de chaves estrangeiras dependendo da versão e do desenho, o que conflita com a integridade referencial do modelo. Reavaliar apenas se o histórico atingir volume muito maior e houver plano explícito para preservar as referências.
- **Arquivamento:** se a política da transportadora permitir e a obrigação de retenção tiver sido aprovada, estudar arquivamento de encomendas encerradas antigas com seus volumes, eventos, tentativas e associações. O arquivamento deve tratar todo o conjunto relacionado e ser reversível/testado; não apagar históricos isoladamente.

## 3. Plano de backup e retenção

Para a escala acadêmica, propõe-se um backup lógico diário do banco, incluindo rotinas e gatilhos, com a seguinte retenção inicial:

- 7 cópias diárias;
- 4 cópias semanais;
- 12 cópias mensais.

Manter pelo menos uma cópia em local separado do computador que executa o MySQL. Como os dumps podem incluir dados pessoais e histórico operacional, restringir permissões do diretório e não versionar os arquivos de backup no Git. As cópias devem ter data no nome e ser verificadas após a geração.

No Prompt de Comando do Windows, com o cliente de linha de comando do MySQL instalado:

```bat
mysqldump --single-transaction --routines --triggers --events --hex-blob -u SEU_USUARIO -p db_transportadora > backup_db_transportadora.sql
```

O terminal solicitará a senha. Não coloque a senha diretamente na linha de comando, no script ou no repositório.

## 4. Procedimento de restauração de teste

1. Faça o backup e anote data, tamanho do arquivo e versão do MySQL.
2. Crie uma base de teste isolada: `CREATE DATABASE db_transportadora_teste CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;`.
3. Restaure o dump para a base de teste (o dump sem `--databases` pode ser direcionado a uma base escolhida):

   ```bat
   mysql -u SEU_USUARIO -p db_transportadora_teste < backup_db_transportadora.sql
   ```

4. Compare as contagens das tabelas de maior movimento no original e na cópia; verifique também a presença das views e triggers em `information_schema.views` e `information_schema.triggers`.
5. Execute uma consulta de rastreamento em uma encomenda de teste na cópia e confirme que o histórico e o status atual são consultáveis.
6. Registre o resultado real, tempo decorrido, eventuais correções e responsável no `docs/ETAPA2_TESTES.md`.
7. Apague a base de teste somente após terminar de coletar as evidências e confirmar que ela não é necessária.

## 5. Limitações a declarar no relatório

As projeções de volume são estimativas baseadas nas premissas acima. Os planos `EXPLAIN`, tempos de execução, bloqueios, restauração e contagens pós-restauração devem vir do ambiente da equipe. Não preencha evidências com valores hipotéticos apresentados como medidos.
