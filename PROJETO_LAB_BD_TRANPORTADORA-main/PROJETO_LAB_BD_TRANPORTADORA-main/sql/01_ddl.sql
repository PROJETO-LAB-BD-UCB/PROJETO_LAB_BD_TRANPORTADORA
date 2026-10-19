-- =====================================================================
-- Trabalho Laboratório de Banco de Dados
--
-- BRUNO LUCAS CAIXETA BRAGA
-- CARLOS EDUARDO ESTRELA DE MACEDO
-- GUILHERME ALFEU BORGES CARVALHO BRAGA
-- RYAN GABRIEL ARAÚJO ALMEIDA
--
-- Sistema de Transportadora
-- Script de criacao do banco e das tabelas
-- Feito para MySQL 8.0 ou superior
--
-- Revisao Etapa 2 - feedback do professor:
-- 1) comentarios de restricoes revisados e vinculados as RNs corretas;
-- 2) coerencia dos discriminadores tipo_cliente/tipo_funcionario reforcada por triggers;
-- 3) RN28/RN29 implementadas para validade e compatibilidade de CNH;
-- 4) criterio fisico de compatibilidade de CNH neste projeto: categoria do motorista
--    deve ser igual a categoria_cnh_exigida do veiculo.
-- =====================================================================


DROP DATABASE IF EXISTS db_transportadora;
CREATE DATABASE db_transportadora
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci; -- padrao adotado nos scripts da disciplina
USE db_transportadora;

-- Tabela principal dos clientes
CREATE TABLE cliente (
    id_cliente      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    tipo_cliente    VARCHAR(2)   NOT NULL COMMENT 'PF ou PJ',
    telefone        VARCHAR(20)  NULL,
    email           VARCHAR(120) NULL,
    data_cadastro   DATE         NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT ck_cliente_tipo CHECK (tipo_cliente IN ('PF','PJ')) -- RN02: especializacao total/exclusiva PF ou PJ
) ENGINE=InnoDB;

-- Dados dos clientes pessoa fisica
CREATE TABLE cliente_pf (
    id_cliente  INT UNSIGNED  NOT NULL,
    nome        VARCHAR(150)  NOT NULL,
    cpf         CHAR(11)      NOT NULL,
    CONSTRAINT pk_cliente_pf PRIMARY KEY (id_cliente),
    CONSTRAINT fk_cliente_pf_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_cliente_pf_cpf UNIQUE (cpf), -- RN01: CPF identifica unicamente a pessoa fisica
    CONSTRAINT ck_cliente_pf_cpf CHECK (cpf REGEXP '^[0-9]{11}$') -- RN03: CPF deve conter 11 digitos numericos
) ENGINE=InnoDB;

-- Dados dos clientes pessoa juridica
CREATE TABLE cliente_pj (
    id_cliente      INT UNSIGNED  NOT NULL,
    razao_social    VARCHAR(150)  NOT NULL,
    nome_fantasia   VARCHAR(150)  NULL,
    cnpj            CHAR(14)      NOT NULL,
    CONSTRAINT pk_cliente_pj PRIMARY KEY (id_cliente),
    CONSTRAINT fk_cliente_pj_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_cliente_pj_cnpj UNIQUE (cnpj), -- RN01: CNPJ identifica unicamente a pessoa juridica
    CONSTRAINT ck_cliente_pj_cnpj CHECK (cnpj REGEXP '^[0-9]{14}$') -- RN03: CNPJ deve conter 14 digitos numericos
) ENGINE=InnoDB;

-- RN02: coerencia entre o discriminador CLIENTE.tipo_cliente e as subclasses.
-- A totalidade e garantida pelo cadastro transacional da aplicacao: a superclasse e
-- a subclasse correspondente sao inseridas na mesma transacao. Os triggers abaixo
-- impedem subtipo incompatível, participacao simultanea em PF/PJ e troca de tipo
-- enquanto existir uma subclasse incompatível.
DELIMITER $$
CREATE TRIGGER trg_cliente_tipo_upd
BEFORE UPDATE ON cliente
FOR EACH ROW
BEGIN
    IF NEW.tipo_cliente <> OLD.tipo_cliente THEN
        IF NEW.tipo_cliente = 'PF' AND EXISTS (
            SELECT 1 FROM cliente_pj WHERE id_cliente = OLD.id_cliente
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN02: cliente com subclasse PJ nao pode ser alterado para PF.';
        END IF;
        IF NEW.tipo_cliente = 'PJ' AND EXISTS (
            SELECT 1 FROM cliente_pf WHERE id_cliente = OLD.id_cliente
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN02: cliente com subclasse PF nao pode ser alterado para PJ.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_cliente_pf_tipo_ins
BEFORE INSERT ON cliente_pf
FOR EACH ROW
BEGIN
    IF (SELECT tipo_cliente FROM cliente WHERE id_cliente = NEW.id_cliente) <> 'PF' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: CLIENTE_PF exige CLIENTE.tipo_cliente = PF.';
    END IF;
    IF EXISTS (SELECT 1 FROM cliente_pj WHERE id_cliente = NEW.id_cliente) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: cliente nao pode pertencer simultaneamente a PF e PJ.';
    END IF;
END$$

CREATE TRIGGER trg_cliente_pf_tipo_upd
BEFORE UPDATE ON cliente_pf
FOR EACH ROW
BEGIN
    IF (SELECT tipo_cliente FROM cliente WHERE id_cliente = NEW.id_cliente) <> 'PF' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: CLIENTE_PF exige CLIENTE.tipo_cliente = PF.';
    END IF;
    IF EXISTS (SELECT 1 FROM cliente_pj WHERE id_cliente = NEW.id_cliente) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: cliente nao pode pertencer simultaneamente a PF e PJ.';
    END IF;
END$$

CREATE TRIGGER trg_cliente_pj_tipo_ins
BEFORE INSERT ON cliente_pj
FOR EACH ROW
BEGIN
    IF (SELECT tipo_cliente FROM cliente WHERE id_cliente = NEW.id_cliente) <> 'PJ' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: CLIENTE_PJ exige CLIENTE.tipo_cliente = PJ.';
    END IF;
    IF EXISTS (SELECT 1 FROM cliente_pf WHERE id_cliente = NEW.id_cliente) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: cliente nao pode pertencer simultaneamente a PF e PJ.';
    END IF;
END$$

CREATE TRIGGER trg_cliente_pj_tipo_upd
BEFORE UPDATE ON cliente_pj
FOR EACH ROW
BEGIN
    IF (SELECT tipo_cliente FROM cliente WHERE id_cliente = NEW.id_cliente) <> 'PJ' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: CLIENTE_PJ exige CLIENTE.tipo_cliente = PJ.';
    END IF;
    IF EXISTS (SELECT 1 FROM cliente_pf WHERE id_cliente = NEW.id_cliente) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: cliente nao pode pertencer simultaneamente a PF e PJ.';
    END IF;
END$$
DELIMITER ;

-- Cidade, endereco e centro de distribuicao
CREATE TABLE cidade (
    id_cidade   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100)  NOT NULL,
    uf          CHAR(2)       NOT NULL,
    CONSTRAINT pk_cidade PRIMARY KEY (id_cidade),
    CONSTRAINT uq_cidade_nome_uf UNIQUE (nome, uf)
) ENGINE=InnoDB;

CREATE TABLE endereco (
    id_endereco     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    logradouro      VARCHAR(150)  NOT NULL,
    numero          VARCHAR(10)   NOT NULL,
    complemento     VARCHAR(100)  NULL,
    bairro          VARCHAR(100)  NOT NULL,
    cep             CHAR(8)       NOT NULL,
    id_cidade       INT UNSIGNED  NOT NULL,
    CONSTRAINT pk_endereco PRIMARY KEY (id_endereco),
    CONSTRAINT fk_endereco_cidade FOREIGN KEY (id_cidade)
        REFERENCES cidade (id_cidade) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_endereco_cidade (id_cidade)
) ENGINE=InnoDB;

-- Cada centro de distribuicao fica ligado a um endereco
CREATE TABLE centro_distribuicao (
    id_centro   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    codigo      VARCHAR(20)   NOT NULL,
    nome        VARCHAR(150)  NOT NULL,
    id_endereco INT UNSIGNED  NOT NULL,
    CONSTRAINT pk_centro_distribuicao PRIMARY KEY (id_centro),
    CONSTRAINT fk_centro_endereco FOREIGN KEY (id_endereco)
        REFERENCES endereco (id_endereco) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_centro_codigo UNIQUE (codigo),
    CONSTRAINT uq_centro_endereco UNIQUE (id_endereco) -- um endereco nao pode ser usado por dois centros
) ENGINE=InnoDB;

-- Funcionarios, motoristas e operadores logisticos
CREATE TABLE funcionario (
    id_funcionario      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    tipo_funcionario     VARCHAR(20)   NOT NULL COMMENT 'tipo do funcionario',
    nome                 VARCHAR(150)  NOT NULL,
    cpf                  CHAR(11)      NOT NULL,
    data_admissao        DATE          NOT NULL,
    telefone             VARCHAR(20)   NULL,
    email                VARCHAR(120)  NULL,
    id_supervisor        INT UNSIGNED  NULL,
    CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
    CONSTRAINT fk_funcionario_supervisor FOREIGN KEY (id_supervisor)
        REFERENCES funcionario (id_funcionario) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT uq_funcionario_cpf UNIQUE (cpf), -- identificador documental unico do funcionario
    CONSTRAINT ck_funcionario_cpf CHECK (cpf REGEXP '^[0-9]{11}$'), -- CPF do funcionario com 11 digitos numericos
    CONSTRAINT ck_funcionario_tipo CHECK (tipo_funcionario IN ('MOTORISTA','OPERADOR_LOGISTICO')), -- RN26: especializacao total/exclusiva
    INDEX idx_funcionario_supervisor (id_supervisor)
) ENGINE=InnoDB;

-- RN31: impede autossupervisao.
DELIMITER $$
CREATE TRIGGER trg_funcionario_autosupervisao_ins
BEFORE INSERT ON funcionario
FOR EACH ROW
BEGIN
    IF NEW.id_supervisor IS NOT NULL AND NEW.id_supervisor = NEW.id_funcionario THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN31: um funcionario nao pode ser supervisor de si mesmo.';
    END IF;
END$$

CREATE TRIGGER trg_funcionario_autosupervisao_upd
BEFORE UPDATE ON funcionario
FOR EACH ROW
BEGIN
    IF NEW.id_supervisor IS NOT NULL AND NEW.id_supervisor = NEW.id_funcionario THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN31: um funcionario nao pode ser supervisor de si mesmo.';
    END IF;
END$$
DELIMITER ;

CREATE TABLE motorista (
    id_funcionario      INT UNSIGNED  NOT NULL,
    numero_cnh           VARCHAR(20)   NOT NULL,
    categoria_cnh        CHAR(1)       NOT NULL,
    data_emissao_cnh      DATE          NOT NULL,
    data_validade_cnh     DATE          NOT NULL,
    CONSTRAINT pk_motorista PRIMARY KEY (id_funcionario),
    CONSTRAINT fk_motorista_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_motorista_cnh UNIQUE (numero_cnh), -- RN27: numero de CNH unico
    CONSTRAINT ck_motorista_categoria CHECK (categoria_cnh IN ('A','B','C','D','E')), -- RN27: categoria de CNH no dominio A-E
    CONSTRAINT ck_motorista_validade CHECK (data_validade_cnh > data_emissao_cnh) -- RN27: validade posterior a emissao
) ENGINE=InnoDB;

CREATE TABLE operador_logistico (
    id_funcionario  INT UNSIGNED  NOT NULL,
    setor           VARCHAR(80)   NOT NULL,
    turno           VARCHAR(6)    NOT NULL,
    CONSTRAINT pk_operador_logistico PRIMARY KEY (id_funcionario),
    CONSTRAINT fk_operador_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_operador_turno CHECK (turno IN ('MANHA','TARDE','NOITE'))
) ENGINE=InnoDB;

-- RN26: coerencia entre FUNCIONARIO.tipo_funcionario e as subclasses operacionais.
-- A totalidade e mantida pelas operacoes transacionais da aplicacao/carga. Estes
-- triggers impedem subtipo incompatível e participacao simultanea nas duas subclasses.
DELIMITER $$
CREATE TRIGGER trg_funcionario_tipo_upd
BEFORE UPDATE ON funcionario
FOR EACH ROW
BEGIN
    IF NEW.tipo_funcionario <> OLD.tipo_funcionario THEN
        IF NEW.tipo_funcionario = 'MOTORISTA' AND EXISTS (
            SELECT 1 FROM operador_logistico WHERE id_funcionario = OLD.id_funcionario
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN26: operador logistico nao pode ser alterado para MOTORISTA sem ajustar a subclasse.';
        END IF;
        IF NEW.tipo_funcionario = 'OPERADOR_LOGISTICO' AND EXISTS (
            SELECT 1 FROM motorista WHERE id_funcionario = OLD.id_funcionario
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN26: motorista nao pode ser alterado para OPERADOR_LOGISTICO sem ajustar a subclasse.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_motorista_tipo_ins
BEFORE INSERT ON motorista
FOR EACH ROW
BEGIN
    IF (SELECT tipo_funcionario FROM funcionario WHERE id_funcionario = NEW.id_funcionario) <> 'MOTORISTA' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN26: MOTORISTA exige FUNCIONARIO.tipo_funcionario = MOTORISTA.';
    END IF;
    IF EXISTS (SELECT 1 FROM operador_logistico WHERE id_funcionario = NEW.id_funcionario) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN26: funcionario nao pode ser MOTORISTA e OPERADOR_LOGISTICO simultaneamente.';
    END IF;
END$$

CREATE TRIGGER trg_motorista_tipo_upd
BEFORE UPDATE ON motorista
FOR EACH ROW
BEGIN
    IF (SELECT tipo_funcionario FROM funcionario WHERE id_funcionario = NEW.id_funcionario) <> 'MOTORISTA' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN26: MOTORISTA exige FUNCIONARIO.tipo_funcionario = MOTORISTA.';
    END IF;
    IF EXISTS (SELECT 1 FROM operador_logistico WHERE id_funcionario = NEW.id_funcionario) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN26: funcionario nao pode ser MOTORISTA e OPERADOR_LOGISTICO simultaneamente.';
    END IF;
END$$

CREATE TRIGGER trg_operador_tipo_ins
BEFORE INSERT ON operador_logistico
FOR EACH ROW
BEGIN
    IF (SELECT tipo_funcionario FROM funcionario WHERE id_funcionario = NEW.id_funcionario) <> 'OPERADOR_LOGISTICO' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN26: OPERADOR_LOGISTICO exige FUNCIONARIO.tipo_funcionario = OPERADOR_LOGISTICO.';
    END IF;
    IF EXISTS (SELECT 1 FROM motorista WHERE id_funcionario = NEW.id_funcionario) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN26: funcionario nao pode ser OPERADOR_LOGISTICO e MOTORISTA simultaneamente.';
    END IF;
END$$

CREATE TRIGGER trg_operador_tipo_upd
BEFORE UPDATE ON operador_logistico
FOR EACH ROW
BEGIN
    IF (SELECT tipo_funcionario FROM funcionario WHERE id_funcionario = NEW.id_funcionario) <> 'OPERADOR_LOGISTICO' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN26: OPERADOR_LOGISTICO exige FUNCIONARIO.tipo_funcionario = OPERADOR_LOGISTICO.';
    END IF;
    IF EXISTS (SELECT 1 FROM motorista WHERE id_funcionario = NEW.id_funcionario) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN26: funcionario nao pode ser OPERADOR_LOGISTICO e MOTORISTA simultaneamente.';
    END IF;
END$$
DELIMITER ;

-- Veiculos e rotas
CREATE TABLE veiculo (
    id_veiculo              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    placa                    VARCHAR(8)      NOT NULL,
    modelo                   VARCHAR(80)     NOT NULL,
    capacidade_carga         DECIMAL(8,2)    NOT NULL,
    categoria_cnh_exigida    CHAR(1)         NOT NULL,
    situacao                 VARCHAR(12)     NOT NULL,
    CONSTRAINT pk_veiculo PRIMARY KEY (id_veiculo),
    CONSTRAINT uq_veiculo_placa UNIQUE (placa), -- RN30: placa nao pode repetir
    CONSTRAINT ck_veiculo_capacidade CHECK (capacidade_carga > 0), -- RN30: capacidade deve ser maior que zero
    CONSTRAINT ck_veiculo_categoria CHECK (categoria_cnh_exigida IN ('A','B','C','D','E')), -- RN29: categoria exigida pertence ao dominio A-E
    CONSTRAINT ck_veiculo_situacao CHECK (situacao IN ('DISPONIVEL','EM_USO','MANUTENCAO','INATIVO'))
) ENGINE=InnoDB;

CREATE TABLE rota (
    id_rota     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100)  NOT NULL,
    descricao   VARCHAR(255)  NULL,
    situacao    VARCHAR(8)    NOT NULL,
    CONSTRAINT pk_rota PRIMARY KEY (id_rota),
    CONSTRAINT ck_rota_situacao CHECK (situacao IN ('ATIVA','INATIVA'))
) ENGINE=InnoDB;

-- Tabela que liga as rotas com as cidades
CREATE TABLE rota_cidade (
    id_rota                             INT UNSIGNED     NOT NULL,
    id_cidade                           INT UNSIGNED     NOT NULL,
    ordem_parada                        SMALLINT UNSIGNED NOT NULL,
    distancia_desde_anterior_km         DECIMAL(7,2)     NULL,
    tempo_estimado_deslocamento_min     SMALLINT UNSIGNED NULL,
    CONSTRAINT pk_rota_cidade PRIMARY KEY (id_rota, id_cidade), -- RN20/RN22: N:N e cidade no maximo uma vez por rota
    CONSTRAINT fk_rota_cidade_rota FOREIGN KEY (id_rota)
        REFERENCES rota (id_rota) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rota_cidade_cidade FOREIGN KEY (id_cidade)
        REFERENCES cidade (id_cidade) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_rota_cidade_ordem UNIQUE (id_rota, ordem_parada), -- RN21: ordem da parada e unica dentro da rota
    CONSTRAINT ck_rota_cidade_ordem CHECK (ordem_parada > 0),
    CONSTRAINT ck_rota_cidade_deslocamento CHECK (
        (ordem_parada = 1
         AND distancia_desde_anterior_km IS NULL
         AND tempo_estimado_deslocamento_min IS NULL)
        OR
        (ordem_parada > 1
         AND distancia_desde_anterior_km > 0
         AND tempo_estimado_deslocamento_min > 0)
    ), -- RN19/RN21: primeira parada sem deslocamento anterior; demais com distancia/tempo positivos
    INDEX idx_rota_cidade_cidade (id_cidade)
) ENGINE=InnoDB;

-- Encomendas
CREATE TABLE encomenda (
    id_encomenda            INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    codigo_rastreio         VARCHAR(30)    NOT NULL,
    data_postagem            DATE           NOT NULL,
    valor_declarado          DECIMAL(12,2)  NULL,
    id_cliente               INT UNSIGNED   NOT NULL,
    id_endereco_origem       INT UNSIGNED   NOT NULL,
    id_endereco_destino      INT UNSIGNED   NOT NULL,
    CONSTRAINT pk_encomenda PRIMARY KEY (id_encomenda),
    CONSTRAINT fk_encomenda_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN04: toda encomenda pertence a um cliente existente
    CONSTRAINT fk_encomenda_endereco_origem FOREIGN KEY (id_endereco_origem)
        REFERENCES endereco (id_endereco) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN05: toda encomenda possui endereco de origem existente
    CONSTRAINT fk_encomenda_endereco_destino FOREIGN KEY (id_endereco_destino)
        REFERENCES endereco (id_endereco) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN05: toda encomenda possui endereco de destino existente
    CONSTRAINT uq_encomenda_codigo_rastreio UNIQUE (codigo_rastreio),
    CONSTRAINT ck_encomenda_valor CHECK (valor_declarado >= 0), -- RN11: valor nao pode ser negativo
    INDEX idx_encomenda_cliente (id_cliente),
    INDEX idx_encomenda_origem (id_endereco_origem),
    INDEX idx_encomenda_destino (id_endereco_destino)
) ENGINE=InnoDB;

-- RN06: endereco de origem deve ser diferente do endereco de destino.
DELIMITER $$
CREATE TRIGGER trg_encomenda_origem_destino_ins
BEFORE INSERT ON encomenda
FOR EACH ROW
BEGIN
    IF NEW.id_endereco_origem = NEW.id_endereco_destino THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN06: endereco de origem deve ser diferente do endereco de destino.';
    END IF;
END$$

CREATE TRIGGER trg_encomenda_origem_destino_upd
BEFORE UPDATE ON encomenda
FOR EACH ROW
BEGIN
    IF NEW.id_endereco_origem = NEW.id_endereco_destino THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN06: endereco de origem deve ser diferente do endereco de destino.';
    END IF;
END$$
DELIMITER ;

-- Expedicoes
CREATE TABLE expedicao (
    id_expedicao                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    data_hora_saida                 DATETIME      NULL,
    data_hora_prevista_chegada       DATETIME      NOT NULL,
    data_hora_chegada                DATETIME      NULL,
    status_expedicao                 VARCHAR(16)   NOT NULL,
    id_rota                          INT UNSIGNED  NOT NULL,
    id_veiculo                       INT UNSIGNED  NOT NULL,
    id_funcionario_motorista         INT UNSIGNED  NOT NULL,
    CONSTRAINT pk_expedicao PRIMARY KEY (id_expedicao),
    CONSTRAINT fk_expedicao_rota FOREIGN KEY (id_rota)
        REFERENCES rota (id_rota) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN32: toda expedicao usa exatamente uma rota existente
    CONSTRAINT fk_expedicao_veiculo FOREIGN KEY (id_veiculo)
        REFERENCES veiculo (id_veiculo) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN32: toda expedicao usa exatamente um veiculo existente
    CONSTRAINT fk_expedicao_motorista FOREIGN KEY (id_funcionario_motorista)
        REFERENCES motorista (id_funcionario) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN32: toda expedicao possui exatamente um motorista
    CONSTRAINT ck_expedicao_status CHECK (status_expedicao IN
        ('PLANEJADA','EM_CARREGAMENTO','EM_TRANSITO','CONCLUIDA','CANCELADA')),
    INDEX idx_expedicao_rota (id_rota),
    INDEX idx_expedicao_veiculo (id_veiculo),
    INDEX idx_expedicao_motorista (id_funcionario_motorista)
) ENGINE=InnoDB;

-- RN28/RN29 - integridade operacional da expedicao.
-- RN28: quando houver data_hora_saida, a CNH deve estar vigente nessa data.
-- RN29: neste projeto, a compatibilidade fisica e implementada por igualdade entre
-- categoria_cnh do motorista e categoria_cnh_exigida do veiculo.
DELIMITER $$
CREATE TRIGGER trg_expedicao_cnh_ins
BEFORE INSERT ON expedicao
FOR EACH ROW
BEGIN
    DECLARE v_categoria_motorista CHAR(1);
    DECLARE v_categoria_veiculo CHAR(1);
    DECLARE v_emissao DATE;
    DECLARE v_validade DATE;

    SET v_categoria_motorista = (SELECT categoria_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_emissao = (SELECT data_emissao_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_validade = (SELECT data_validade_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_categoria_veiculo = (SELECT categoria_cnh_exigida FROM veiculo WHERE id_veiculo = NEW.id_veiculo);

    IF v_categoria_motorista IS NOT NULL AND v_categoria_veiculo IS NOT NULL
       AND v_categoria_motorista <> v_categoria_veiculo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN29: categoria da CNH do motorista incompativel com o veiculo da expedicao.';
    END IF;

    IF NEW.data_hora_saida IS NOT NULL AND v_emissao IS NOT NULL AND v_validade IS NOT NULL
       AND DATE(NEW.data_hora_saida) NOT BETWEEN v_emissao AND v_validade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN28: CNH do motorista nao esta valida na data de saida da expedicao.';
    END IF;
END$$

CREATE TRIGGER trg_expedicao_cnh_upd
BEFORE UPDATE ON expedicao
FOR EACH ROW
BEGIN
    DECLARE v_categoria_motorista CHAR(1);
    DECLARE v_categoria_veiculo CHAR(1);
    DECLARE v_emissao DATE;
    DECLARE v_validade DATE;

    SET v_categoria_motorista = (SELECT categoria_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_emissao = (SELECT data_emissao_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_validade = (SELECT data_validade_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_categoria_veiculo = (SELECT categoria_cnh_exigida FROM veiculo WHERE id_veiculo = NEW.id_veiculo);

    IF v_categoria_motorista IS NOT NULL AND v_categoria_veiculo IS NOT NULL
       AND v_categoria_motorista <> v_categoria_veiculo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN29: categoria da CNH do motorista incompativel com o veiculo da expedicao.';
    END IF;

    IF NEW.data_hora_saida IS NOT NULL AND v_emissao IS NOT NULL AND v_validade IS NOT NULL
       AND DATE(NEW.data_hora_saida) NOT BETWEEN v_emissao AND v_validade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN28: CNH do motorista nao esta valida na data de saida da expedicao.';
    END IF;
END$$
DELIMITER ;

-- RN33 (minimo de uma encomenda antes de iniciar) exige verificacao transacional,
-- pois depende da existencia de linhas em EXPEDICAO_ENCOMENDA. A aplicacao/rotina
-- de inicio da expedicao deve validar essa pre-condicao antes da mudanca de status.

-- Volumes das encomendas
CREATE TABLE volume_encomenda (
    id_encomenda         INT UNSIGNED       NOT NULL,
    num_volume           SMALLINT UNSIGNED  NOT NULL,
    peso                 DECIMAL(8,3)       NOT NULL,
    altura               DECIMAL(7,2)       NOT NULL,
    largura              DECIMAL(7,2)       NOT NULL,
    comprimento          DECIMAL(7,2)       NOT NULL,
    descricao_conteudo   VARCHAR(200)       NULL,
    CONSTRAINT pk_volume_encomenda PRIMARY KEY (id_encomenda, num_volume), -- RN08/RN10: numero unico no contexto da encomenda e identificacao da entidade fraca
    CONSTRAINT fk_volume_encomenda FOREIGN KEY (id_encomenda)
        REFERENCES encomenda (id_encomenda) ON DELETE CASCADE ON UPDATE CASCADE, -- RN10: volume nao existe sem encomenda
    CONSTRAINT ck_volume_numero CHECK (num_volume > 0), -- RN08: numeracao do volume inicia em 1
    CONSTRAINT ck_volume_peso CHECK (peso > 0), -- RN09: peso deve ser positivo
    CONSTRAINT ck_volume_altura CHECK (altura > 0), -- RN09: altura deve ser positiva
    CONSTRAINT ck_volume_largura CHECK (largura > 0), -- RN09: largura deve ser positiva
    CONSTRAINT ck_volume_comprimento CHECK (comprimento > 0) -- RN09: comprimento deve ser positivo
) ENGINE=InnoDB;

-- RN07 (encomenda com pelo menos um volume antes da liberacao) e uma pre-condicao
-- transacional e nao pode ser garantida por CHECK na linha de ENCOMENDA.

-- Historico de status das encomendas
CREATE TABLE historico_status_encomenda (
    id_historico    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    status          VARCHAR(20)   NOT NULL,
    data_hora       DATETIME      NOT NULL,
    observacao      VARCHAR(255)  NULL,
    id_encomenda    INT UNSIGNED  NOT NULL,
    id_centro       INT UNSIGNED  NOT NULL,
    CONSTRAINT pk_historico_status_encomenda PRIMARY KEY (id_historico),
    CONSTRAINT fk_historico_encomenda FOREIGN KEY (id_encomenda)
        REFERENCES encomenda (id_encomenda) ON DELETE CASCADE ON UPDATE CASCADE, -- RN13/RN14: evento pertence a uma encomenda existente
    CONSTRAINT fk_historico_centro FOREIGN KEY (id_centro)
        REFERENCES centro_distribuicao (id_centro) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN13: todo evento registra o centro responsavel
    CONSTRAINT ck_historico_status CHECK (status IN
        ('REGISTRADA','COLETADA','EM_TRIAGEM','EM_TRANSITO','SAIU_PARA_ENTREGA',
         'ENTREGUE','TENTATIVA_FRUSTRADA','DEVOLVIDA','EXTRAVIADA')), -- RN12: dominio fechado de status; RN35 define as transicoes permitidas
    INDEX idx_historico_encomenda (id_encomenda),
    INDEX idx_historico_centro (id_centro)
) ENGINE=InnoDB;

-- RN35 depende do status anterior da mesma encomenda e deve ser validada por
-- trigger/rotina transacional ao registrar a mudanca de status.
-- RN15 (ENTREGUE somente apos tentativa bem-sucedida) tambem depende de consulta
-- entre tabelas e e tratada na operacao transacional de entrega da Etapa 2.

-- Ocorrencias
CREATE TABLE ocorrencia (
    id_ocorrencia   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    tipo            VARCHAR(25)   NOT NULL,
    data_hora       DATETIME      NOT NULL,
    descricao       VARCHAR(255)  NOT NULL,
    situacao        VARCHAR(15)   NOT NULL,
    id_encomenda    INT UNSIGNED  NOT NULL,
    CONSTRAINT pk_ocorrencia PRIMARY KEY (id_ocorrencia),
    CONSTRAINT fk_ocorrencia_encomenda FOREIGN KEY (id_encomenda)
        REFERENCES encomenda (id_encomenda) ON DELETE CASCADE ON UPDATE CASCADE, -- RN18: ocorrencia pertence a uma encomenda existente
    CONSTRAINT ck_ocorrencia_tipo CHECK (tipo IN
        ('AVARIA','ATRASO','EXTRAVIO','ENDERECO_NAO_LOCALIZADO',
         'RECUSA_DESTINATARIO','VEICULO_INDISPONIVEL','OUTRA')), -- tipo permitido pelo sistema
    CONSTRAINT ck_ocorrencia_situacao CHECK (situacao IN
        ('ABERTA','EM_TRATAMENTO','RESOLVIDA','CANCELADA')),
    INDEX idx_ocorrencia_encomenda (id_encomenda)
) ENGINE=InnoDB;

-- Relacao entre expedicao e encomenda
CREATE TABLE expedicao_encomenda (
    id_expedicao                 INT UNSIGNED       NOT NULL,
    id_encomenda                 INT UNSIGNED       NOT NULL,
    ordem_carregamento           SMALLINT UNSIGNED  NOT NULL,
    data_hora_carregamento        DATETIME           NOT NULL,
    data_hora_descarregamento     DATETIME           NULL,
    CONSTRAINT pk_expedicao_encomenda PRIMARY KEY (id_expedicao, id_encomenda), -- RN34: associacao N:N entre expedicao e encomenda
    CONSTRAINT fk_expedicao_encomenda_expedicao FOREIGN KEY (id_expedicao)
        REFERENCES expedicao (id_expedicao) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_expedicao_encomenda_encomenda FOREIGN KEY (id_encomenda)
        REFERENCES encomenda (id_encomenda) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_expedicao_encomenda_ordem UNIQUE (id_expedicao, ordem_carregamento), -- ordem de carregamento unica por expedicao
    CONSTRAINT ck_expedicao_encomenda_ordem CHECK (ordem_carregamento > 0),
    INDEX idx_expedicao_encomenda_encomenda (id_encomenda)
) ENGINE=InnoDB;

-- Tentativas de entrega
CREATE TABLE tentativa_entrega (
    id_tentativa                 INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    data_hora                    DATETIME      NOT NULL,
    resultado                    VARCHAR(10)   NOT NULL,
    motivo_insucesso             VARCHAR(255)  NULL,
    recebedor                    VARCHAR(150)  NULL,
    id_encomenda                 INT UNSIGNED  NOT NULL,
    id_funcionario_motorista     INT UNSIGNED  NOT NULL,
    id_veiculo                   INT UNSIGNED  NOT NULL,
    CONSTRAINT pk_tentativa_entrega PRIMARY KEY (id_tentativa),
    CONSTRAINT fk_tentativa_encomenda FOREIGN KEY (id_encomenda)
        REFERENCES encomenda (id_encomenda) ON DELETE CASCADE ON UPDATE CASCADE, -- RN16: tentativa pertence a uma encomenda existente
    CONSTRAINT fk_tentativa_motorista FOREIGN KEY (id_funcionario_motorista)
        REFERENCES motorista (id_funcionario) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN16: tentativa possui exatamente um motorista
    CONSTRAINT fk_tentativa_veiculo FOREIGN KEY (id_veiculo)
        REFERENCES veiculo (id_veiculo) ON DELETE RESTRICT ON UPDATE CASCADE, -- RN16: tentativa utiliza exatamente um veiculo
    CONSTRAINT ck_tentativa_resultado CHECK (resultado IN ('SUCESSO','INSUCESSO')), -- RN17: dominio do resultado
    CONSTRAINT ck_tentativa_motivo CHECK ( -- RN17: insucesso exige motivo; sucesso exige NULL
        (resultado = 'INSUCESSO' AND motivo_insucesso IS NOT NULL) OR
        (resultado = 'SUCESSO' AND motivo_insucesso IS NULL)
    ),
    INDEX idx_tentativa_encomenda (id_encomenda),
    INDEX idx_tentativa_motorista (id_funcionario_motorista),
    INDEX idx_tentativa_veiculo (id_veiculo)
) ENGINE=InnoDB;

-- RN29: compatibilidade entre motorista e veiculo tambem se aplica a tentativa
-- de entrega. Como complemento de integridade operacional, a CNH tambem deve estar
-- vigente na data_hora da tentativa. O criterio de categoria e igualdade entre
-- categoria_cnh e categoria_cnh_exigida, conforme definido para este projeto.
DELIMITER $$
CREATE TRIGGER trg_tentativa_cnh_ins
BEFORE INSERT ON tentativa_entrega
FOR EACH ROW
BEGIN
    DECLARE v_categoria_motorista CHAR(1);
    DECLARE v_categoria_veiculo CHAR(1);
    DECLARE v_emissao DATE;
    DECLARE v_validade DATE;

    SET v_categoria_motorista = (SELECT categoria_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_emissao = (SELECT data_emissao_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_validade = (SELECT data_validade_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_categoria_veiculo = (SELECT categoria_cnh_exigida FROM veiculo WHERE id_veiculo = NEW.id_veiculo);

    IF v_categoria_motorista IS NOT NULL AND v_categoria_veiculo IS NOT NULL
       AND v_categoria_motorista <> v_categoria_veiculo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN29: categoria da CNH do motorista incompativel com o veiculo da tentativa.';
    END IF;

    IF v_emissao IS NOT NULL AND v_validade IS NOT NULL
       AND DATE(NEW.data_hora) NOT BETWEEN v_emissao AND v_validade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CNH do motorista nao esta vigente na data da tentativa de entrega.';
    END IF;
END$$

CREATE TRIGGER trg_tentativa_cnh_upd
BEFORE UPDATE ON tentativa_entrega
FOR EACH ROW
BEGIN
    DECLARE v_categoria_motorista CHAR(1);
    DECLARE v_categoria_veiculo CHAR(1);
    DECLARE v_emissao DATE;
    DECLARE v_validade DATE;

    SET v_categoria_motorista = (SELECT categoria_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_emissao = (SELECT data_emissao_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_validade = (SELECT data_validade_cnh FROM motorista WHERE id_funcionario = NEW.id_funcionario_motorista);
    SET v_categoria_veiculo = (SELECT categoria_cnh_exigida FROM veiculo WHERE id_veiculo = NEW.id_veiculo);

    IF v_categoria_motorista IS NOT NULL AND v_categoria_veiculo IS NOT NULL
       AND v_categoria_motorista <> v_categoria_veiculo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN29: categoria da CNH do motorista incompativel com o veiculo da tentativa.';
    END IF;

    IF v_emissao IS NOT NULL AND v_validade IS NOT NULL
       AND DATE(NEW.data_hora) NOT BETWEEN v_emissao AND v_validade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CNH do motorista nao esta vigente na data da tentativa de entrega.';
    END IF;
END$$
DELIMITER ;

-- Servicos adicionais e servicos das encomendas
CREATE TABLE servico_adicional (
    id_servico          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    nome                 VARCHAR(100)   NOT NULL,
    descricao            VARCHAR(255)   NULL,
    valor_referencia      DECIMAL(10,2)  NOT NULL,
    ativo                 TINYINT(1)     NOT NULL DEFAULT 1,
    CONSTRAINT pk_servico_adicional PRIMARY KEY (id_servico),
    CONSTRAINT ck_servico_valor CHECK (valor_referencia >= 0),
    CONSTRAINT ck_servico_ativo CHECK (ativo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE encomenda_servico (
    id_encomenda        INT UNSIGNED   NOT NULL,
    id_servico           INT UNSIGNED   NOT NULL,
    valor_contratado      DECIMAL(10,2)  NOT NULL,
    data_contratacao      DATE           NOT NULL,
    CONSTRAINT pk_encomenda_servico PRIMARY KEY (id_encomenda, id_servico), -- RN23/RN24: N:N e mesmo servico no maximo uma vez por encomenda
    CONSTRAINT fk_encomenda_servico_encomenda FOREIGN KEY (id_encomenda)
        REFERENCES encomenda (id_encomenda) ON DELETE CASCADE ON UPDATE CASCADE, -- a encomenda deve existir
    CONSTRAINT fk_encomenda_servico_servico FOREIGN KEY (id_servico)
        REFERENCES servico_adicional (id_servico) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_encomenda_servico_valor CHECK (valor_contratado >= 0), -- RN25: valor efetivamente contratado e preservado e nao negativo
    INDEX idx_encomenda_servico_servico (id_servico)
) ENGINE=InnoDB;

-- Atributo derivado: status atual nao e persistido em ENCOMENDA (RN12-RN14).
-- View para mostrar o status mais recente de cada encomenda
-- Em caso de empate, o maior id_historico fica como o mais recente
CREATE OR REPLACE VIEW vw_encomenda_status_atual AS
SELECT id_encomenda, status AS status_atual, data_hora AS data_hora_status
FROM (
    SELECT id_encomenda, status, data_hora,
           ROW_NUMBER() OVER (PARTITION BY id_encomenda
                               ORDER BY data_hora DESC, id_historico DESC) AS rn
    FROM historico_status_encomenda
) t
WHERE rn = 1;
