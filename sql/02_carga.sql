-- =====================================================================
-- Trabalho Laboratório de Banco de Dados
--
-- BRUNO LUCAS CAIXETA BRAGA
-- CARLOS EDUARDO ESTRELA DE MACEDO
-- GUILHERME ALFEU BORGES CARVALHO BRAGA
-- RYAN GABRIEL ARAÚJO ALMEIDA
--
-- Sistema de Transportadora
--
-- Carga de dados do sistema de transportadora
-- A7 - Script de carga (DML)
-- Executar depois do arquivo 01_ddl.sql
-- Dados totalmente ficticios, usados apenas para fins academicos e testes
--
-- Revisoes aplicadas nesta versao:
-- 1) centros de distribuicao vinculados a enderecos coerentes;
-- 2) capacidades de veiculos ajustadas para valores plausiveis;
-- 3) validades de CNH coerentes com as operacoes registradas;
-- 4) rotas revisadas para finalizar no destino indicado;
-- 5) expedicoes e vinculos com encomendas corrigidos temporalmente;
-- 6) tentativas de entrega sincronizadas com o historico de status;
-- 7) ocorrencias posicionadas depois da postagem e em momentos logisticos coerentes.

USE db_transportadora;
SET FOREIGN_KEY_CHECKS = 1;


-- Cidades

INSERT INTO cidade (nome, uf) VALUES
('Brasília', 'DF'),
('Cristalina', 'GO'),
('Paracatu', 'MG'),
('Belo Horizonte', 'MG'),
('Goiânia', 'GO'),
('Anápolis', 'GO'),
('Uberlândia', 'MG'),
('Luziânia', 'GO'),
('Formosa', 'GO'),
('São Paulo', 'SP'),
('Campinas', 'SP'),
('Uberaba', 'MG'),
('Valparaíso de Goiás', 'GO'),
('Planaltina', 'DF'),
('Catalão', 'GO');



-- Enderecos
-- Os seis ultimos registros (IDs 61 a 66) sao enderecos especificos dos centros de distribuicao.

INSERT INTO endereco (logradouro, numero, complemento, bairro, cep, id_cidade) VALUES
('Rua Minas Gerais', '1127', NULL, 'Setor Bueno', '39256242', 11),
('Rua Minas Gerais', '2234', NULL, 'Asa Sul', '87397532', 12),
('SQN 210 Bloco', '953', NULL, 'Centro', '83563303', 1),
('Setor Industrial', '2414', 'Bloco D, sala 15', 'Vila Nova', '10851877', 12),
('Rua dos Andradas', '1394', NULL, 'Vila Nova', '30379320', 13),
('Av. Central', '1557', NULL, 'Asa Sul', '57052967', 13),
('Av. Contorno', '512', 'Bloco A, sala 30', 'Alto da Boa Vista', '20328665', 6),
('SQN 210 Bloco', '2886', 'Bloco C, sala 37', 'Asa Sul', '16006777', 5),
('Rua Tiradentes', '414', 'Bloco A, sala 15', 'Alto da Boa Vista', '46434564', 4),
('Av. Paulista', '859', 'Bloco B, sala 24', 'Vila Nova', '99593763', 11),
('Rua Minas Gerais', '1003', 'Bloco B, sala 35', 'Jardim América', '70589488', 2),
('Rua Tiradentes', '3148', 'Bloco B, sala 21', 'Centro', '40021941', 5),
('Av. Central', '865', 'Bloco D, sala 18', 'Industrial', '37869771', 1),
('Av. Brasil', '2634', NULL, 'Parque das Nações', '28726371', 8),
('Av. Contorno', '2208', NULL, 'Vila Nova', '86622538', 3),
('QNM 12 Conjunto', '2088', 'Bloco C, sala 15', 'Parque das Nações', '21915873', 15),
('Av. Anhanguera', '2788', 'Bloco B, sala 11', 'Alto da Boa Vista', '88172165', 1),
('Setor Industrial', '2168', NULL, 'Vila Nova', '82512981', 7),
('Av. Anhanguera', '1093', 'Bloco A, sala 35', 'Industrial', '24621400', 1),
('Rua das Flores', '2958', NULL, 'Vila Nova', '75612880', 7),
('Av. Central', '2562', NULL, 'Vila Nova', '93748619', 3),
('Av. Paulista', '3124', NULL, 'Jardim América', '80697897', 10),
('Rua das Flores', '2454', NULL, 'Industrial', '74042119', 15),
('Rua das Flores', '987', 'Bloco C, sala 16', 'Asa Sul', '21226849', 2),
('Alameda Santos', '1947', 'Bloco B, sala 9', 'Jardim América', '44741640', 8),
('Av. Anhanguera', '2990', 'Bloco B, sala 35', 'Setor Bueno', '50857508', 14),
('Setor Industrial', '496', 'Bloco D, sala 34', 'Setor Bueno', '39451165', 11),
('Av. Contorno', '943', NULL, 'Setor Bueno', '10942172', 6),
('Av. Brasil', '129', 'Bloco B, sala 5', 'Industrial', '19287626', 12),
('Setor Industrial', '878', NULL, 'Jardim América', '84847690', 4),
('Setor Industrial', '3308', NULL, 'Alto da Boa Vista', '34957196', 8),
('Rua dos Andradas', '1913', 'Bloco C, sala 28', 'Centro', '98259769', 2),
('Rua dos Andradas', '2983', NULL, 'Industrial', '24322354', 11),
('Setor Industrial', '575', NULL, 'Alto da Boa Vista', '34050385', 4),
('Av. Brasil', '309', NULL, 'Parque das Nações', '82132200', 8),
('Av. Brasil', '3087', 'Bloco A, sala 6', 'Setor Bueno', '31798516', 1),
('Rua Tiradentes', '1643', NULL, 'Centro', '31579488', 8),
('Rua Sete de Setembro', '1733', 'Bloco C, sala 30', 'Parque das Nações', '30289294', 1),
('Rua das Flores', '2373', NULL, 'Centro', '51104158', 5),
('Av. Contorno', '329', 'Bloco B, sala 4', 'Jardim América', '18981709', 1),
('Av. Central', '2334', 'Bloco B, sala 26', 'Setor Bueno', '85880708', 2),
('Rua Goiás', '2142', 'Bloco D, sala 38', 'Industrial', '44179309', 1),
('Rua dos Andradas', '537', 'Bloco B, sala 17', 'Vila Nova', '69929423', 11),
('Setor Industrial', '2545', 'Bloco A, sala 1', 'Asa Sul', '19602650', 15),
('QNM 12 Conjunto', '1430', NULL, 'Asa Sul', '42018478', 4),
('Rua Tiradentes', '2226', NULL, 'Vila Nova', '90173926', 5),
('Alameda Santos', '3347', NULL, 'Vila Nova', '96951206', 11),
('Av. Central', '439', NULL, 'Jardim América', '45697388', 15),
('Av. Paulista', '834', NULL, 'Vila Nova', '76244600', 10),
('Alameda Santos', '1735', 'Bloco A, sala 6', 'Vila Nova', '15778103', 5),
('Rua Minas Gerais', '1810', 'Bloco C, sala 11', 'Alto da Boa Vista', '83519109', 6),
('Av. Brasil', '2831', NULL, 'Jardim América', '81511136', 2),
('Av. Contorno', '607', NULL, 'Alto da Boa Vista', '26704142', 14),
('Av. Brasil', '3261', NULL, 'Centro', '56898315', 5),
('Av. Central', '1449', NULL, 'Alto da Boa Vista', '91351867', 11),
('Av. Anhanguera', '3321', 'Bloco B, sala 11', 'Jardim América', '64040125', 3),
('Av. Anhanguera', '2744', 'Bloco C, sala 27', 'Setor Bueno', '44970263', 3),
('Rua Tiradentes', '1928', 'Bloco D, sala 3', 'Setor Bueno', '36158936', 13),
('Rua Sete de Setembro', '3361', NULL, 'Setor Bueno', '39219124', 15),
('Av. Paulista', '1142', NULL, 'Asa Sul', '46585459', 11),
('Setor de Indústria e Abastecimento - SIA Trecho 3', '100', 'Galpão A', 'SIA', '71200000', 1),
('Avenida Perimetral Norte', '2500', 'Galpão B', 'Setor Empresarial', '74000000', 5),
('Avenida Cristiano Machado', '4800', 'Galpão C', 'Cidade Nova', '31170000', 4),
('Avenida das Nações Unidas', '15000', 'Galpão D', 'Vila Leopoldina', '05307000', 10),
('Avenida Brasil Norte', '1800', 'Galpão E', 'Distrito Agroindustrial', '75110000', 6),
('Avenida José Andraus Gassani', '3200', 'Galpão F', 'Distrito Industrial', '38402000', 7);



-- Centros de distribuicao
-- Cada centro foi vinculado a um endereco coerente com a cidade indicada em seu nome.

INSERT INTO centro_distribuicao (codigo, nome, id_endereco) VALUES
('CD001', 'CD Brasília Matriz', 61),
('CD002', 'CD Goiânia', 62),
('CD003', 'CD Belo Horizonte', 63),
('CD004', 'CD São Paulo', 64),
('CD005', 'CD Anápolis', 65),
('CD006', 'CD Uberlândia', 66);



-- Clientes

INSERT INTO cliente (tipo_cliente, telefone, email, data_cadastro) VALUES
('PF', '(61) 97548-9785', 'contato1@exemplo.com.br', '2025-11-08'),
('PF', NULL, 'contato2@exemplo.com.br', '2025-06-07'),
('PF', '(61) 95349-1626', NULL, '2024-09-18'),
('PF', '(61) 96139-8149', 'contato4@exemplo.com.br', '2024-07-01'),
('PF', NULL, 'contato5@exemplo.com.br', '2025-05-26'),
('PF', '(61) 98144-1027', 'contato6@exemplo.com.br', '2024-06-03'),
('PF', '(61) 94228-6967', 'contato7@exemplo.com.br', '2025-01-02'),
('PF', '(61) 93041-5920', 'contato8@exemplo.com.br', '2024-10-14'),
('PF', '(61) 95844-3085', 'contato9@exemplo.com.br', '2024-11-13'),
('PF', '(61) 93851-5930', 'contato10@exemplo.com.br', '2025-12-06'),
('PF', '(61) 94443-8043', 'contato11@exemplo.com.br', '2025-01-11'),
('PF', '(61) 98244-4501', 'contato12@exemplo.com.br', '2025-06-16'),
('PF', '(61) 95649-9445', 'contato13@exemplo.com.br', '2024-12-28'),
('PF', NULL, 'contato14@exemplo.com.br', '2025-04-10'),
('PF', '(61) 94680-4262', NULL, '2025-10-20'),
('PF', '(61) 98784-2193', 'contato16@exemplo.com.br', '2025-05-21'),
('PF', '(61) 97291-9099', 'contato17@exemplo.com.br', '2025-07-08'),
('PF', '(61) 91090-2746', 'contato18@exemplo.com.br', '2025-04-26'),
('PF', '(61) 99486-8611', NULL, '2025-03-26'),
('PF', '(61) 92988-8478', NULL, '2024-08-18'),
('PF', '(61) 96198-8251', 'contato21@exemplo.com.br', '2024-07-08'),
('PF', '(61) 99976-8305', 'contato22@exemplo.com.br', '2024-08-07'),
('PF', '(61) 95050-5543', 'contato23@exemplo.com.br', '2024-06-21'),
('PF', '(61) 94919-5499', 'contato24@exemplo.com.br', '2025-02-17'),
('PF', '(61) 96502-6238', 'contato25@exemplo.com.br', '2025-09-15'),
('PF', NULL, 'contato26@exemplo.com.br', '2025-07-03'),
('PF', '(61) 92052-7797', 'contato27@exemplo.com.br', '2024-05-30'),
('PF', '(61) 92020-4388', 'contato28@exemplo.com.br', '2024-11-03'),
('PF', '(61) 91320-7232', 'contato29@exemplo.com.br', '2024-12-11'),
('PF', '(61) 97389-7865', 'contato30@exemplo.com.br', '2024-05-26'),
('PJ', '(61) 94613-8999', 'contato31@exemplo.com.br', '2024-09-16'),
('PJ', '(61) 97371-6507', 'contato32@exemplo.com.br', '2024-10-18'),
('PJ', '(61) 98657-3091', 'contato33@exemplo.com.br', '2024-06-08'),
('PJ', NULL, 'contato34@exemplo.com.br', '2025-11-09'),
('PJ', NULL, 'contato35@exemplo.com.br', '2024-08-21'),
('PJ', '(61) 95262-7211', 'contato36@exemplo.com.br', '2024-08-28'),
('PJ', '(61) 97211-5558', 'contato37@exemplo.com.br', '2024-10-01'),
('PJ', '(61) 92341-8705', NULL, '2024-06-02'),
('PJ', NULL, 'contato39@exemplo.com.br', '2025-04-21'),
('PJ', '(61) 91659-1508', 'contato40@exemplo.com.br', '2025-05-16'),
('PJ', '(61) 93496-4908', NULL, '2025-08-11'),
('PJ', '(61) 94571-8619', 'contato42@exemplo.com.br', '2024-11-24'),
('PJ', '(61) 92876-3683', 'contato43@exemplo.com.br', '2025-08-18'),
('PJ', '(61) 96111-7149', 'contato44@exemplo.com.br', '2025-05-17');



-- Clientes pessoa fisica

INSERT INTO cliente_pf (id_cliente, nome, cpf) VALUES
(1, 'Ana Souza', '87635813702'),
(2, 'Bruno Lima', '42758756650'),
(3, 'Carla Mendes', '51972485812'),
(4, 'Diego Alves', '91534990643'),
(5, 'Elaine Rocha', '17656360518'),
(6, 'Fábio Torres', '84505672840'),
(7, 'Gabriela Nunes', '20181524415'),
(8, 'Hugo Ramos', '98072430966'),
(9, 'Isabela Costa', '11465576748'),
(10, 'João Pereira', '69483474381'),
(11, 'Karen Duarte', '77956393836'),
(12, 'Lucas Martins', '66287860835'),
(13, 'Mariana Silva', '61371191447'),
(14, 'Nelson Barros', '73688812930'),
(15, 'Olívia Fontes', '30217736696'),
(16, 'Paulo Cardoso', '33345239530'),
(17, 'Quésia Farias', '81871103554'),
(18, 'Rafael Teixeira', '92764373670'),
(19, 'Sabrina Gomes', '72206148127'),
(20, 'Tiago Moreira', '90449144995'),
(21, 'Ursula Prado', '54102423031'),
(22, 'Vinícius Castro', '43722851232'),
(23, 'Wesley Pinto', '44731952676'),
(24, 'Ximena Duarte', '73916119262'),
(25, 'Yara Batista', '89305318997'),
(26, 'Zeca Andrade', '54577419627'),
(27, 'Aline Ferreira', '74547774977'),
(28, 'Breno Viana', '56604487565'),
(29, 'Camila Rezende', '75205505671'),
(30, 'Douglas Freitas', '58155688071');



-- Clientes pessoa juridica

INSERT INTO cliente_pj (id_cliente, razao_social, nome_fantasia, cnpj) VALUES
(31, 'Comércio Silva Ltda', 'Comércio Silva', '46360324824542'),
(32, 'Distribuidora Central', 'Distribuidora Central', '93901672105574'),
(33, 'Indústria Alfa S/A', NULL, '88221130959249'),
(34, 'Mercado Bom Preço', NULL, '36890567170751'),
(35, 'Atacado Nordeste', 'Atacado Nordeste', '67199172177973'),
(36, 'Tech Solutions ME', 'Tech Solutions ME', '43821828781097'),
(37, 'Construtora Horizonte', 'Construtora Horizonte', '73073702803333'),
(38, 'Farmácia Vida Ltda', 'Farmácia Vida', '51408179361838'),
(39, 'Auto Peças União', 'Auto Peças União', '44242450486925'),
(40, 'Papelaria Criativa', 'Papelaria Criativa', '61937242305466'),
(41, 'Móveis Planalto', 'Móveis Planalto', '58380791914485'),
(42, 'Cerâmica Bela Vista', 'Cerâmica Bela Vista', '87462938951654'),
(43, 'Agropecuária Cerrado', 'Agropecuária Cerrado', '73860592495931'),
(44, 'Confecções Estrela', NULL, '42445262724553');



-- Primeiro cadastro os funcionarios sem supervisor

INSERT INTO funcionario (tipo_funcionario, nome, cpf, data_admissao, telefone, email, id_supervisor) VALUES
('MOTORISTA', 'Antonio Ferreira', '53776816193', '2025-03-07', '(61) 94033-4138', 'antonio.ferreira@transportadora.com.br', NULL),
('MOTORISTA', 'Beatriz Ramos', '46439355458', '2021-10-15', '(61) 99595-5636', 'beatriz.ramos@transportadora.com.br', NULL),
('MOTORISTA', 'Carlos Eduardo', '27096163003', '2021-03-07', '(61) 94727-6912', 'carlos.eduardo@transportadora.com.br', NULL),
('MOTORISTA', 'Débora Nunes', '49425401235', '2025-10-09', '(61) 93073-5494', 'débora.nunes@transportadora.com.br', NULL),
('MOTORISTA', 'Eduardo Santos', '83248631494', '2024-03-18', '(61) 93068-9042', 'eduardo.santos@transportadora.com.br', NULL),
('MOTORISTA', 'Fernanda Lopes', '87362090818', '2024-04-03', '(61) 98216-6582', 'fernanda.lopes@transportadora.com.br', NULL),
('MOTORISTA', 'Gustavo Dias', '44580399705', '2023-03-04', '(61) 92070-7565', 'gustavo.dias@transportadora.com.br', NULL),
('MOTORISTA', 'Helena Cunha', '20701970001', '2022-08-13', '(61) 91878-3485', 'helena.cunha@transportadora.com.br', NULL),
('MOTORISTA', 'Igor Salles', '19894898206', '2024-06-16', '(61) 97818-4697', 'igor.salles@transportadora.com.br', NULL),
('MOTORISTA', 'Juliana Rangel', '82051055121', '2023-09-19', '(61) 98253-5871', 'juliana.rangel@transportadora.com.br', NULL),
('MOTORISTA', 'Kleber Moura', '91003799033', '2023-06-12', '(61) 91986-2625', 'kleber.moura@transportadora.com.br', NULL),
('MOTORISTA', 'Larissa Vieira', '96791788173', '2024-08-31', '(61) 92330-3573', 'larissa.vieira@transportadora.com.br', NULL),
('MOTORISTA', 'Marcelo Tavares', '32505049577', '2022-10-03', NULL, 'marcelo.tavares@transportadora.com.br', NULL),
('MOTORISTA', 'Natália Borges', '65846067002', '2023-04-29', '(61) 98699-5771', 'natália.borges@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'Otávio Reis', '40204958203', '2024-03-26', '(61) 98438-2166', 'otávio.reis@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'Patrícia Amaral', '43017066829', '2024-05-14', '(61) 94241-7965', 'patrícia.amaral@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'Ricardo Neves', '83507404483', '2024-08-03', '(61) 95352-3330', 'ricardo.neves@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'Sandra Correia', '14601670222', '2024-12-02', '(61) 95728-8195', 'sandra.correia@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'Thiago Bastos', '70663637027', '2021-12-27', '(61) 97594-5460', 'thiago.bastos@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'Vanessa Aguiar', '85163955674', '2023-01-30', '(61) 91653-8078', 'vanessa.aguiar@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'William Cruz', '56104472157', '2022-06-19', '(61) 92496-4750', 'william.cruz@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'Yasmin Rocha', '89779872685', '2025-09-25', '(61) 95415-1659', 'yasmin.rocha@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'Zélia Prado', '75176947899', '2022-12-10', '(61) 95557-3973', 'zélia.prado@transportadora.com.br', NULL),
('OPERADOR_LOGISTICO', 'André Monteiro', '91591259548', '2023-05-29', '(61) 99056-2494', 'andré.monteiro@transportadora.com.br', NULL);

-- Depois atualizo quem e o supervisor de cada funcionario
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 1;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 2;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 3;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 4;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 5;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 6;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 7;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 8;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 9;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 10;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 11;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 12;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 13;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 14;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 17;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 18;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 19;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 20;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 21;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 22;
UPDATE funcionario SET id_supervisor = 15 WHERE id_funcionario = 23;
UPDATE funcionario SET id_supervisor = 16 WHERE id_funcionario = 24;



-- Motoristas
-- Datas de validade foram revisadas para manter as CNHs validas nas operacoes registradas.

INSERT INTO motorista (id_funcionario, numero_cnh, categoria_cnh, data_emissao_cnh, data_validade_cnh) VALUES
(1, '59263319540', 'E', '2021-03-07', '2027-11-23'),
(2, '25763103412', 'C', '2021-03-22', '2028-05-27'),
(3, '77403815179', 'D', '2020-06-05', '2029-03-06'),
(4, '70287155135', 'B', '2021-05-23', '2027-07-05'),
(5, '24273352225', 'E', '2019-02-24', '2028-02-06'),
(6, '72459963885', 'E', '2024-04-23', '2027-02-23'),
(7, '59471320507', 'E', '2017-11-27', '2028-07-28'),
(8, '17559101808', 'C', '2021-12-04', '2029-03-04'),
(9, '71366617919', 'E', '2023-07-23', '2028-04-04'),
(10, '49334934709', 'B', '2018-09-22', '2028-05-19'),
(11, '40465101567', 'B', '2019-09-29', '2026-10-02'),
(12, '75085810382', 'D', '2019-03-19', '2030-01-18'),
(13, '67008925827', 'E', '2019-08-16', '2027-06-18'),
(14, '84976326981', 'C', '2020-08-13', '2027-03-01');



-- Operadores logisticos

INSERT INTO operador_logistico (id_funcionario, setor, turno) VALUES
(15, 'Almoxarifado', 'NOITE'),
(16, 'Expedição', 'MANHA'),
(17, 'Atendimento', 'TARDE'),
(18, 'Atendimento', 'NOITE'),
(19, 'Atendimento', 'MANHA'),
(20, 'Atendimento', 'NOITE'),
(21, 'Atendimento', 'NOITE'),
(22, 'Almoxarifado', 'NOITE'),
(23, 'Faturamento', 'MANHA'),
(24, 'Faturamento', 'NOITE');



-- Veiculos
-- Capacidades de carga revisadas para faixas plausiveis ao porte de cada veiculo.

INSERT INTO veiculo (placa, modelo, capacidade_carga, categoria_cnh_exigida, situacao) VALUES
('IOO7K34', 'Renault Master', 1500.0, 'C', 'DISPONIVEL'),
('GUB7W58', 'Fiat Ducato', 1400.0, 'B', 'EM_USO'),
('MAN9K22', 'Iveco Daily', 3500.0, 'C', 'DISPONIVEL'),
('XAD2C70', 'Mercedes-Benz Atego', 8000.0, 'D', 'DISPONIVEL'),
('SQW8M50', 'Hyundai HR', 1800.0, 'B', 'MANUTENCAO'),
('WAB4H21', 'Renault Master', 1500.0, 'C', 'DISPONIVEL'),
('LSX0K17', 'Volkswagen Delivery', 5000.0, 'C', 'DISPONIVEL'),
('GKR2F32', 'Iveco Daily', 3500.0, 'C', 'MANUTENCAO'),
('RMP3O91', 'Hyundai HR', 1800.0, 'B', 'DISPONIVEL'),
('XMH8F19', 'Mercedes-Benz Sprinter', 1800.0, 'C', 'DISPONIVEL'),
('HZR7J35', 'Hyundai HR', 1800.0, 'B', 'MANUTENCAO'),
('GOO4A94', 'Volkswagen Delivery', 5000.0, 'C', 'DISPONIVEL'),
('XTV4Y39', 'Mercedes-Benz Sprinter', 1800.0, 'C', 'DISPONIVEL'),
('QRS2U22', 'Scania R450', 30000.0, 'E', 'EM_USO'),
('UAJ2C47', 'Volvo FH540', 30000.0, 'E', 'DISPONIVEL'),
('DOZ8Q44', 'Scania R450', 30000.0, 'E', 'DISPONIVEL');



-- Rotas

INSERT INTO rota (nome, descricao, situacao) VALUES
('Brasília-BH', 'Rota entre Brasília e Belo Horizonte via Cristalina/Paracatu', 'ATIVA'),
('Brasília-Goiânia', 'Rota entre Brasília e Goiânia via Anápolis', 'ATIVA'),
('Goiânia-Uberlândia', 'Rota entre Goiânia e Uberlândia', 'ATIVA'),
('Brasília-São Paulo', 'Rota de longa distância para São Paulo/Campinas', 'ATIVA'),
('Brasília-Formosa', 'Rota regional para o entorno do DF', 'ATIVA'),
('Luziânia-Valparaíso', 'Rota metropolitana sul do DF', 'ATIVA'),
('Uberaba-Catalão', 'Rota Triângulo Mineiro/Sul de Goiás', 'ATIVA');



-- Cidades que fazem parte das rotas
-- Sequencias revisadas para que o destino final seja coerente com o nome da rota.

INSERT INTO rota_cidade (id_rota, id_cidade, ordem_parada, distancia_desde_anterior_km, tempo_estimado_deslocamento_min) VALUES
(1, 1, 1, NULL, NULL),
(1, 2, 2, 110.67, 160),
(1, 3, 3, 369.65, 248),
(1, 4, 4, 408.22, 330),
(2, 1, 1, NULL, NULL),
(2, 6, 2, 191.68, 247),
(2, 5, 3, 65.01, 319),
(3, 5, 1, NULL, NULL),
(3, 7, 2, 104.49, 233),
(4, 1, 1, NULL, NULL),
(4, 2, 2, 130.0, 100),
(4, 7, 3, 520.0, 390),
(4, 11, 4, 560.0, 420),
(4, 10, 5, 100.0, 90),
(5, 1, 1, NULL, NULL),
(5, 14, 2, 45.0, 55),
(5, 9, 3, 35.0, 45),
(6, 8, 1, NULL, NULL),
(6, 13, 2, 32.0, 40),
(7, 12, 1, NULL, NULL),
(7, 15, 2, 387.38, 199);



-- Servicos adicionais

INSERT INTO servico_adicional (nome, descricao, valor_referencia, ativo) VALUES
('Seguro de transporte', 'Cobertura contra avarias e extravio', 25.0, 1),
('Entrega expressa', 'Prioridade na expedição e entrega em até 24h', 40.0, 1),
('Aviso de recebimento', 'Confirmação documental de entrega ao destinatário', 8.5, 1),
('Entrega agendada', 'Entrega em data e horário combinados com o cliente', 15.0, 1),
('Manuseio especial', 'Cuidados adicionais para itens frágeis', 20.0, 1),
('Embalagem reforçada', 'Embalagem adicional para proteção do volume', 12.0, 0);



-- Encomendas

INSERT INTO encomenda (codigo_rastreio, data_postagem, valor_declarado, id_cliente, id_endereco_origem, id_endereco_destino) VALUES
('BR100000TR', '2026-06-20', NULL, 21, 10, 26),
('BR100001TR', '2026-06-03', NULL, 35, 7, 24),
('BR100002TR', '2026-01-27', 325.95, 33, 14, 3),
('BR100003TR', '2026-01-20', 550.64, 6, 36, 28),
('BR100004TR', '2026-01-20', 1687.17, 15, 41, 38),
('BR100005TR', '2026-02-08', 635.82, 15, 3, 36),
('BR100006TR', '2026-05-28', 787.73, 8, 37, 20),
('BR100007TR', '2026-02-22', 2316.36, 38, 37, 41),
('BR100008TR', '2026-06-12', 2868.87, 5, 37, 4),
('BR100009TR', '2026-05-04', 1922.51, 28, 50, 21),
('BR100010TR', '2026-02-20', 1051.66, 20, 16, 51),
('BR100011TR', '2026-05-11', 3073.14, 37, 20, 34),
('BR100012TR', '2026-02-04', 722.07, 19, 39, 5),
('BR100013TR', '2026-05-10', 4041.81, 22, 10, 60),
('BR100014TR', '2026-05-31', 3443.44, 5, 49, 36),
('BR100015TR', '2026-06-06', 3354.06, 22, 45, 23),
('BR100016TR', '2026-03-15', 2801.19, 5, 54, 6),
('BR100017TR', '2026-03-25', 4171.24, 4, 47, 45),
('BR100018TR', '2026-04-13', 1480.28, 29, 19, 46),
('BR100019TR', '2026-06-10', NULL, 30, 23, 11),
('BR100020TR', '2026-03-19', NULL, 4, 14, 50),
('BR100021TR', '2026-05-12', NULL, 16, 26, 59),
('BR100022TR', '2026-03-17', 3447.3, 29, 26, 36),
('BR100023TR', '2026-04-21', 2878.54, 36, 18, 46),
('BR100024TR', '2026-01-26', NULL, 25, 15, 10),
('BR100025TR', '2026-01-08', 2488.7, 15, 43, 15),
('BR100026TR', '2026-02-11', 1572.94, 17, 19, 1),
('BR100027TR', '2026-06-30', 3992.68, 37, 21, 9),
('BR100028TR', '2026-01-18', 3662.63, 42, 44, 48),
('BR100029TR', '2026-04-15', 1676.51, 44, 52, 36),
('BR100030TR', '2026-01-20', NULL, 31, 41, 26),
('BR100031TR', '2026-02-02', 253.98, 14, 29, 11),
('BR100032TR', '2026-05-22', NULL, 1, 37, 10),
('BR100033TR', '2026-01-23', 2592.6, 24, 40, 2),
('BR100034TR', '2026-04-03', 2009.84, 10, 41, 17),
('BR100035TR', '2026-05-04', 1333.86, 8, 55, 32),
('BR100036TR', '2026-04-02', 2028.46, 10, 7, 48),
('BR100037TR', '2026-02-26', 2235.19, 11, 34, 2),
('BR100038TR', '2026-01-11', 1276.54, 10, 45, 35),
('BR100039TR', '2026-07-02', 2194.12, 42, 56, 6),
('BR100040TR', '2026-03-03', 3279.76, 11, 23, 50),
('BR100041TR', '2026-06-10', 4137.22, 22, 41, 15),
('BR100042TR', '2026-04-17', 979.37, 13, 52, 16),
('BR100043TR', '2026-07-11', NULL, 34, 32, 23),
('BR100044TR', '2026-05-05', 2919.35, 2, 51, 18),
('BR100045TR', '2026-07-09', 4012.58, 23, 29, 52),
('BR100046TR', '2026-01-31', 854.28, 24, 6, 15),
('BR100047TR', '2026-06-10', 2032.01, 14, 31, 40);



-- Volumes das encomendas

INSERT INTO volume_encomenda (id_encomenda, num_volume, peso, altura, largura, comprimento, descricao_conteudo) VALUES
(1, 1, 15.677, 59.67, 67.6, 16.39, 'Calçados'),
(1, 2, 35.269, 68.76, 40.85, 21.96, 'Utensílios domésticos'),
(1, 3, 4.178, 85.42, 59.14, 49.0, 'Eletrônicos'),
(2, 1, 7.401, 89.41, 7.07, 61.13, 'Brinquedos'),
(2, 2, 36.351, 17.42, 66.99, 98.13, 'Utensílios domésticos'),
(2, 3, 7.269, 51.6, 6.6, 80.94, 'Eletrônicos'),
(3, 1, 33.802, 16.84, 78.99, 23.51, 'Documentos'),
(3, 2, 1.551, 23.09, 42.59, 77.55, 'Utensílios domésticos'),
(4, 1, 24.633, 75.91, 9.57, 75.29, 'Brinquedos'),
(5, 1, 26.376, 81.87, 36.55, 92.18, NULL),
(5, 2, 6.145, 17.91, 43.29, 87.92, 'Peças automotivas'),
(5, 3, 27.502, 70.96, 16.24, 18.45, NULL),
(6, 1, 5.679, 10.25, 56.17, 55.42, 'Brinquedos'),
(6, 2, 35.357, 14.02, 47.02, 28.61, 'Livros'),
(6, 3, 2.186, 13.31, 38.91, 7.65, 'Eletrônicos'),
(7, 1, 14.855, 87.74, 50.46, 23.94, 'Livros'),
(7, 2, 20.52, 50.33, 40.85, 94.44, NULL),
(8, 1, 41.548, 80.88, 20.19, 47.52, 'Calçados'),
(9, 1, 17.839, 31.86, 55.34, 45.69, 'Documentos'),
(10, 1, 13.834, 15.4, 63.27, 94.25, 'Utensílios domésticos'),
(10, 2, 6.691, 80.04, 77.57, 25.86, 'Eletrônicos'),
(10, 3, 18.102, 46.42, 79.24, 84.08, 'Peças automotivas'),
(11, 1, 19.589, 48.83, 30.43, 23.6, 'Utensílios domésticos'),
(11, 2, 4.421, 36.11, 30.35, 48.57, 'Roupas'),
(11, 3, 17.48, 48.98, 27.16, 96.27, 'Eletrônicos'),
(12, 1, 43.735, 13.91, 24.92, 8.76, 'Peças automotivas'),
(13, 1, 34.083, 74.68, 68.72, 69.22, 'Livros'),
(14, 1, 6.977, 83.13, 47.79, 71.54, 'Eletrônicos'),
(14, 2, 12.774, 72.96, 18.75, 90.05, 'Livros'),
(15, 1, 28.659, 73.14, 11.28, 86.34, 'Eletrônicos'),
(16, 1, 38.866, 43.57, 30.44, 57.54, 'Livros'),
(17, 1, 6.076, 49.79, 22.88, 15.4, 'Peças automotivas'),
(17, 2, 12.007, 20.4, 74.92, 64.72, NULL),
(18, 1, 13.261, 47.51, 18.34, 37.97, 'Roupas'),
(19, 1, 1.952, 6.57, 42.92, 97.91, NULL),
(20, 1, 11.282, 43.0, 54.37, 66.76, 'Brinquedos'),
(20, 2, 24.702, 80.54, 77.77, 34.24, 'Documentos'),
(21, 1, 15.619, 75.74, 58.0, 65.42, 'Calçados'),
(22, 1, 44.19, 76.14, 6.07, 64.42, 'Livros'),
(23, 1, 7.597, 12.18, 68.1, 87.7, 'Livros'),
(23, 2, 27.065, 63.88, 8.39, 22.61, 'Livros'),
(24, 1, 0.462, 35.95, 29.67, 98.57, 'Utensílios domésticos'),
(24, 2, 11.227, 87.08, 28.22, 38.88, 'Roupas'),
(25, 1, 17.359, 45.34, 42.71, 24.09, NULL),
(26, 1, 4.361, 74.45, 15.79, 60.75, 'Calçados'),
(27, 1, 13.694, 58.52, 11.34, 95.98, 'Peças automotivas'),
(28, 1, 40.208, 71.64, 49.74, 77.61, 'Brinquedos'),
(28, 2, 6.981, 66.55, 53.24, 9.16, NULL),
(28, 3, 28.342, 67.38, 65.92, 18.23, NULL),
(29, 1, 25.711, 74.1, 6.21, 70.21, 'Documentos'),
(29, 2, 4.104, 8.56, 52.78, 96.15, 'Calçados'),
(30, 1, 25.266, 58.36, 51.97, 69.66, 'Brinquedos'),
(30, 2, 12.092, 43.84, 10.26, 93.59, NULL),
(31, 1, 29.771, 10.61, 60.26, 28.96, 'Eletrônicos'),
(32, 1, 10.795, 69.3, 22.31, 66.74, 'Brinquedos'),
(33, 1, 38.095, 11.52, 73.28, 32.3, 'Roupas'),
(33, 2, 27.879, 59.63, 10.81, 19.01, 'Livros'),
(34, 1, 33.522, 30.88, 47.58, 6.18, 'Roupas'),
(34, 2, 22.015, 87.66, 12.46, 25.68, 'Brinquedos'),
(34, 3, 13.301, 48.91, 39.85, 49.3, 'Eletrônicos'),
(35, 1, 9.206, 88.14, 75.22, 6.66, 'Brinquedos'),
(35, 2, 3.718, 48.06, 79.6, 99.43, 'Calçados'),
(36, 1, 41.27, 84.1, 10.6, 13.58, NULL),
(37, 1, 42.887, 16.27, 66.52, 53.33, 'Eletrônicos'),
(38, 1, 16.624, 47.32, 70.71, 42.44, 'Peças automotivas'),
(38, 2, 0.46, 46.79, 38.81, 33.69, 'Peças automotivas'),
(38, 3, 18.903, 36.97, 14.07, 36.48, 'Utensílios domésticos'),
(39, 1, 37.808, 15.2, 74.48, 72.74, 'Livros'),
(40, 1, 16.938, 38.4, 79.91, 60.97, 'Utensílios domésticos'),
(41, 1, 34.078, 77.61, 26.05, 9.9, 'Livros'),
(41, 2, 28.683, 17.66, 77.83, 46.44, 'Utensílios domésticos'),
(42, 1, 34.861, 71.74, 37.08, 7.76, 'Calçados'),
(43, 1, 24.85, 66.16, 8.71, 74.57, 'Brinquedos'),
(43, 2, 27.787, 16.78, 70.21, 51.13, NULL),
(44, 1, 7.933, 40.26, 26.13, 29.3, 'Livros'),
(45, 1, 29.623, 30.57, 46.8, 42.46, 'Peças automotivas'),
(45, 2, 29.051, 11.39, 42.55, 82.12, NULL),
(46, 1, 20.548, 33.29, 61.94, 45.61, NULL),
(47, 1, 11.211, 19.85, 46.69, 35.33, 'Utensílios domésticos'),
(48, 1, 36.478, 22.18, 6.51, 87.71, 'Calçados');



-- Historico dos status
-- Mantido como fonte cronologica principal para rastreamento das encomendas.

INSERT INTO historico_status_encomenda (status, data_hora, observacao, id_encomenda, id_centro) VALUES
('REGISTRADA', '2026-06-20 10:00:00', 'Evento registrado automaticamente pelo sistema.', 1, 2),
('COLETADA', '2026-06-21 12:00:00', NULL, 1, 1),
('EM_TRIAGEM', '2026-06-22 01:00:00', 'Atualizacao de status para EM_TRIAGEM.', 1, 2),
('SAIU_PARA_ENTREGA', '2026-06-23 04:00:00', NULL, 1, 2),
('TENTATIVA_FRUSTRADA', '2026-06-23 18:00:00', 'Atualizacao de status para TENTATIVA_FRUSTRADA.', 1, 4),
('SAIU_PARA_ENTREGA', '2026-06-24 05:00:00', NULL, 1, 1),
('ENTREGUE', '2026-06-25 07:00:00', 'Atualizacao de status para ENTREGUE.', 1, 4),
('REGISTRADA', '2026-06-03 10:00:00', NULL, 2, 4),
('COLETADA', '2026-06-03 19:00:00', NULL, 2, 1),
('EM_TRIAGEM', '2026-06-04 18:00:00', 'Atualizacao de status para EM_TRIAGEM.', 2, 1),
('SAIU_PARA_ENTREGA', '2026-06-05 16:00:00', NULL, 2, 4),
('TENTATIVA_FRUSTRADA', '2026-06-05 18:00:00', NULL, 2, 2),
('DEVOLVIDA', '2026-06-06 16:00:00', NULL, 2, 6),
('REGISTRADA', '2026-01-27 08:00:00', 'Evento registrado automaticamente pelo sistema.', 3, 5),
('COLETADA', '2026-01-27 13:00:00', NULL, 3, 1),
('EM_TRIAGEM', '2026-01-28 09:00:00', NULL, 3, 2),
('EM_TRANSITO', '2026-01-29 06:00:00', NULL, 3, 1),
('EM_TRIAGEM', '2026-01-29 22:00:00', 'Atualizacao de status para EM_TRIAGEM.', 3, 3),
('SAIU_PARA_ENTREGA', '2026-01-31 04:00:00', NULL, 3, 2),
('ENTREGUE', '2026-01-31 13:00:00', 'Atualizacao de status para ENTREGUE.', 3, 1),
('REGISTRADA', '2026-01-20 09:00:00', NULL, 4, 2),
('COLETADA', '2026-01-21 07:00:00', NULL, 4, 4),
('EM_TRIAGEM', '2026-01-21 22:00:00', NULL, 4, 3),
('EM_TRANSITO', '2026-01-22 10:00:00', NULL, 4, 6),
('EM_TRIAGEM', '2026-01-22 18:00:00', 'Atualizacao de status para EM_TRIAGEM.', 4, 1),
('SAIU_PARA_ENTREGA', '2026-01-23 12:00:00', NULL, 4, 1),
('EXTRAVIADA', '2026-01-23 23:00:00', NULL, 4, 2),
('REGISTRADA', '2026-01-20 08:00:00', NULL, 5, 3),
('COLETADA', '2026-01-21 01:00:00', NULL, 5, 5),
('EM_TRIAGEM', '2026-01-21 16:00:00', NULL, 5, 6),
('REGISTRADA', '2026-02-08 11:00:00', NULL, 6, 4),
('COLETADA', '2026-02-09 08:00:00', NULL, 6, 2),
('REGISTRADA', '2026-05-28 07:00:00', NULL, 7, 4),
('COLETADA', '2026-05-28 11:00:00', NULL, 7, 2),
('EM_TRIAGEM', '2026-05-29 05:00:00', NULL, 7, 6),
('EM_TRANSITO', '2026-05-30 06:00:00', 'Atualizacao de status para EM_TRANSITO.', 7, 4),
('EXTRAVIADA', '2026-05-30 22:00:00', NULL, 7, 2),
('REGISTRADA', '2026-02-22 07:00:00', NULL, 8, 3),
('COLETADA', '2026-02-22 12:00:00', 'Atualizacao de status para COLETADA.', 8, 5),
('EM_TRIAGEM', '2026-02-23 01:00:00', 'Atualizacao de status para EM_TRIAGEM.', 8, 3),
('SAIU_PARA_ENTREGA', '2026-02-23 04:00:00', NULL, 8, 6),
('ENTREGUE', '2026-02-23 20:00:00', NULL, 8, 2),
('REGISTRADA', '2026-06-12 10:00:00', NULL, 9, 4),
('COLETADA', '2026-06-13 12:00:00', NULL, 9, 4),
('EM_TRIAGEM', '2026-06-13 16:00:00', NULL, 9, 1),
('SAIU_PARA_ENTREGA', '2026-06-14 22:00:00', NULL, 9, 5),
('ENTREGUE', '2026-06-15 19:00:00', NULL, 9, 1),
('REGISTRADA', '2026-05-04 09:00:00', 'Evento registrado automaticamente pelo sistema.', 10, 3),
('COLETADA', '2026-05-05 06:00:00', 'Atualizacao de status para COLETADA.', 10, 6),
('REGISTRADA', '2026-02-20 07:00:00', NULL, 11, 2),
('COLETADA', '2026-02-20 23:00:00', 'Atualizacao de status para COLETADA.', 11, 4),
('EM_TRIAGEM', '2026-02-22 03:00:00', NULL, 11, 4),
('REGISTRADA', '2026-05-11 10:00:00', NULL, 12, 6),
('COLETADA', '2026-05-12 12:00:00', 'Atualizacao de status para COLETADA.', 12, 2),
('EM_TRIAGEM', '2026-05-13 00:00:00', NULL, 12, 4),
('SAIU_PARA_ENTREGA', '2026-05-13 04:00:00', NULL, 12, 5),
('TENTATIVA_FRUSTRADA', '2026-05-13 13:00:00', NULL, 12, 4),
('SAIU_PARA_ENTREGA', '2026-05-14 08:00:00', NULL, 12, 5),
('EXTRAVIADA', '2026-05-15 14:00:00', 'Atualizacao de status para EXTRAVIADA.', 12, 1),
('REGISTRADA', '2026-02-04 09:00:00', 'Evento registrado automaticamente pelo sistema.', 13, 2),
('COLETADA', '2026-02-05 09:00:00', NULL, 13, 4),
('EM_TRIAGEM', '2026-02-06 01:00:00', 'Atualizacao de status para EM_TRIAGEM.', 13, 5),
('REGISTRADA', '2026-05-10 08:00:00', 'Evento registrado automaticamente pelo sistema.', 14, 6),
('COLETADA', '2026-05-10 19:00:00', NULL, 14, 3),
('EM_TRIAGEM', '2026-05-11 05:00:00', NULL, 14, 6),
('REGISTRADA', '2026-05-31 10:00:00', NULL, 15, 2),
('COLETADA', '2026-06-01 16:00:00', NULL, 15, 5),
('EM_TRIAGEM', '2026-06-02 02:00:00', NULL, 15, 2),
('EM_TRANSITO', '2026-06-03 05:00:00', 'Atualizacao de status para EM_TRANSITO.', 15, 1),
('EXTRAVIADA', '2026-06-03 10:00:00', NULL, 15, 1),
('REGISTRADA', '2026-06-06 08:00:00', 'Evento registrado automaticamente pelo sistema.', 16, 3),
('COLETADA', '2026-06-06 17:00:00', NULL, 16, 1),
('REGISTRADA', '2026-03-15 11:00:00', 'Evento registrado automaticamente pelo sistema.', 17, 5),
('COLETADA', '2026-03-16 00:00:00', 'Atualizacao de status para COLETADA.', 17, 5),
('EM_TRIAGEM', '2026-03-16 10:00:00', 'Atualizacao de status para EM_TRIAGEM.', 17, 6),
('EM_TRANSITO', '2026-03-17 07:00:00', 'Atualizacao de status para EM_TRANSITO.', 17, 6),
('EM_TRIAGEM', '2026-03-17 20:00:00', NULL, 17, 3),
('EM_TRANSITO', '2026-03-18 06:00:00', NULL, 17, 1),
('EM_TRIAGEM', '2026-03-18 14:00:00', 'Atualizacao de status para EM_TRIAGEM.', 17, 1),
('SAIU_PARA_ENTREGA', '2026-03-19 03:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 17, 2),
('REGISTRADA', '2026-03-25 07:00:00', NULL, 18, 4),
('COLETADA', '2026-03-25 12:00:00', 'Atualizacao de status para COLETADA.', 18, 4),
('EM_TRIAGEM', '2026-03-26 07:00:00', 'Atualizacao de status para EM_TRIAGEM.', 18, 1),
('SAIU_PARA_ENTREGA', '2026-03-26 17:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 18, 4),
('TENTATIVA_FRUSTRADA', '2026-03-27 08:00:00', NULL, 18, 1),
('SAIU_PARA_ENTREGA', '2026-03-27 21:00:00', NULL, 18, 4),
('TENTATIVA_FRUSTRADA', '2026-03-29 00:00:00', 'Atualizacao de status para TENTATIVA_FRUSTRADA.', 18, 3),
('SAIU_PARA_ENTREGA', '2026-03-29 14:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 18, 2),
('ENTREGUE', '2026-03-29 21:00:00', NULL, 18, 4),
('REGISTRADA', '2026-04-13 07:00:00', NULL, 19, 3),
('COLETADA', '2026-04-13 13:00:00', NULL, 19, 1),
('EM_TRIAGEM', '2026-04-14 16:00:00', NULL, 19, 4),
('SAIU_PARA_ENTREGA', '2026-04-15 05:00:00', NULL, 19, 6),
('ENTREGUE', '2026-04-15 16:00:00', NULL, 19, 2),
('REGISTRADA', '2026-06-10 07:00:00', NULL, 20, 4),
('COLETADA', '2026-06-11 11:00:00', 'Atualizacao de status para COLETADA.', 20, 1),
('EM_TRIAGEM', '2026-06-11 14:00:00', 'Atualizacao de status para EM_TRIAGEM.', 20, 5),
('SAIU_PARA_ENTREGA', '2026-06-12 20:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 20, 6),
('TENTATIVA_FRUSTRADA', '2026-06-13 03:00:00', 'Atualizacao de status para TENTATIVA_FRUSTRADA.', 20, 6),
('SAIU_PARA_ENTREGA', '2026-06-13 17:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 20, 5),
('TENTATIVA_FRUSTRADA', '2026-06-14 00:00:00', NULL, 20, 5),
('SAIU_PARA_ENTREGA', '2026-06-14 18:00:00', NULL, 20, 2),
('REGISTRADA', '2026-03-19 07:00:00', NULL, 21, 6),
('COLETADA', '2026-03-20 02:00:00', NULL, 21, 6),
('EM_TRIAGEM', '2026-03-20 07:00:00', NULL, 21, 4),
('SAIU_PARA_ENTREGA', '2026-03-21 05:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 21, 3),
('ENTREGUE', '2026-03-21 14:00:00', NULL, 21, 4),
('REGISTRADA', '2026-05-12 09:00:00', NULL, 22, 4),
('COLETADA', '2026-05-13 06:00:00', NULL, 22, 4),
('EM_TRIAGEM', '2026-05-14 03:00:00', 'Atualizacao de status para EM_TRIAGEM.', 22, 4),
('SAIU_PARA_ENTREGA', '2026-05-14 17:00:00', NULL, 22, 1),
('ENTREGUE', '2026-05-15 06:00:00', 'Atualizacao de status para ENTREGUE.', 22, 1),
('REGISTRADA', '2026-03-17 11:00:00', 'Evento registrado automaticamente pelo sistema.', 23, 1),
('COLETADA', '2026-03-17 15:00:00', NULL, 23, 6),
('REGISTRADA', '2026-04-21 11:00:00', NULL, 24, 5),
('COLETADA', '2026-04-22 14:00:00', NULL, 24, 2),
('EM_TRIAGEM', '2026-04-23 11:00:00', 'Atualizacao de status para EM_TRIAGEM.', 24, 6),
('EM_TRANSITO', '2026-04-23 17:00:00', NULL, 24, 4),
('EM_TRIAGEM', '2026-04-24 20:00:00', 'Atualizacao de status para EM_TRIAGEM.', 24, 2),
('SAIU_PARA_ENTREGA', '2026-04-25 05:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 24, 1),
('ENTREGUE', '2026-04-25 15:00:00', NULL, 24, 2),
('REGISTRADA', '2026-01-26 11:00:00', NULL, 25, 4),
('COLETADA', '2026-01-27 04:00:00', NULL, 25, 2),
('EM_TRIAGEM', '2026-01-27 13:00:00', NULL, 25, 3),
('EM_TRANSITO', '2026-01-28 03:00:00', 'Atualizacao de status para EM_TRANSITO.', 25, 2),
('EM_TRIAGEM', '2026-01-28 15:00:00', NULL, 25, 4),
('SAIU_PARA_ENTREGA', '2026-01-28 20:00:00', NULL, 25, 5),
('TENTATIVA_FRUSTRADA', '2026-01-30 01:00:00', NULL, 25, 4),
('SAIU_PARA_ENTREGA', '2026-01-31 07:00:00', NULL, 25, 1),
('REGISTRADA', '2026-01-08 11:00:00', 'Evento registrado automaticamente pelo sistema.', 26, 4),
('COLETADA', '2026-01-09 00:00:00', NULL, 26, 5),
('EM_TRIAGEM', '2026-01-09 04:00:00', NULL, 26, 4),
('SAIU_PARA_ENTREGA', '2026-01-09 07:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 26, 3),
('ENTREGUE', '2026-01-10 05:00:00', 'Atualizacao de status para ENTREGUE.', 26, 5),
('REGISTRADA', '2026-02-11 09:00:00', 'Evento registrado automaticamente pelo sistema.', 27, 6),
('COLETADA', '2026-02-11 20:00:00', 'Atualizacao de status para COLETADA.', 27, 5),
('REGISTRADA', '2026-06-30 10:00:00', 'Evento registrado automaticamente pelo sistema.', 28, 1),
('COLETADA', '2026-07-01 07:00:00', NULL, 28, 6),
('EM_TRIAGEM', '2026-07-02 03:00:00', NULL, 28, 3),
('SAIU_PARA_ENTREGA', '2026-07-02 22:00:00', NULL, 28, 2),
('ENTREGUE', '2026-07-03 04:00:00', NULL, 28, 2),
('REGISTRADA', '2026-01-18 10:00:00', NULL, 29, 1),
('COLETADA', '2026-01-19 02:00:00', NULL, 29, 1),
('EM_TRIAGEM', '2026-01-20 01:00:00', NULL, 29, 3),
('EM_TRANSITO', '2026-01-20 03:00:00', 'Atualizacao de status para EM_TRANSITO.', 29, 1),
('EM_TRIAGEM', '2026-01-20 16:00:00', 'Atualizacao de status para EM_TRIAGEM.', 29, 5),
('SAIU_PARA_ENTREGA', '2026-01-21 10:00:00', NULL, 29, 6),
('ENTREGUE', '2026-01-21 12:00:00', NULL, 29, 1),
('REGISTRADA', '2026-04-15 07:00:00', NULL, 30, 2),
('COLETADA', '2026-04-16 09:00:00', NULL, 30, 1),
('EM_TRIAGEM', '2026-04-16 17:00:00', NULL, 30, 2),
('SAIU_PARA_ENTREGA', '2026-04-17 15:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 30, 5),
('ENTREGUE', '2026-04-18 12:00:00', NULL, 30, 2),
('REGISTRADA', '2026-01-20 07:00:00', NULL, 31, 1),
('COLETADA', '2026-01-20 09:00:00', 'Atualizacao de status para COLETADA.', 31, 4),
('EM_TRIAGEM', '2026-01-21 01:00:00', 'Atualizacao de status para EM_TRIAGEM.', 31, 1),
('SAIU_PARA_ENTREGA', '2026-01-21 10:00:00', NULL, 31, 1),
('ENTREGUE', '2026-01-21 15:00:00', 'Atualizacao de status para ENTREGUE.', 31, 3),
('REGISTRADA', '2026-02-02 09:00:00', 'Evento registrado automaticamente pelo sistema.', 32, 3),
('COLETADA', '2026-02-03 03:00:00', NULL, 32, 3),
('EXTRAVIADA', '2026-02-04 09:00:00', NULL, 32, 2),
('REGISTRADA', '2026-05-22 11:00:00', NULL, 33, 3),
('COLETADA', '2026-05-22 19:00:00', 'Atualizacao de status para COLETADA.', 33, 2),
('EM_TRIAGEM', '2026-05-24 01:00:00', NULL, 33, 4),
('EM_TRANSITO', '2026-05-25 06:00:00', 'Atualizacao de status para EM_TRANSITO.', 33, 6),
('EXTRAVIADA', '2026-05-26 10:00:00', NULL, 33, 5),
('REGISTRADA', '2026-01-23 11:00:00', 'Evento registrado automaticamente pelo sistema.', 34, 1),
('COLETADA', '2026-01-23 20:00:00', 'Atualizacao de status para COLETADA.', 34, 5),
('EM_TRIAGEM', '2026-01-24 10:00:00', NULL, 34, 5),
('SAIU_PARA_ENTREGA', '2026-01-24 17:00:00', NULL, 34, 2),
('ENTREGUE', '2026-01-25 14:00:00', NULL, 34, 2),
('REGISTRADA', '2026-04-03 08:00:00', 'Evento registrado automaticamente pelo sistema.', 35, 1),
('COLETADA', '2026-04-04 06:00:00', NULL, 35, 6),
('REGISTRADA', '2026-05-04 07:00:00', 'Evento registrado automaticamente pelo sistema.', 36, 1),
('COLETADA', '2026-05-05 11:00:00', 'Atualizacao de status para COLETADA.', 36, 5),
('EM_TRIAGEM', '2026-05-06 16:00:00', 'Atualizacao de status para EM_TRIAGEM.', 36, 6),
('EM_TRANSITO', '2026-05-07 00:00:00', NULL, 36, 2),
('EM_TRIAGEM', '2026-05-08 05:00:00', NULL, 36, 6),
('SAIU_PARA_ENTREGA', '2026-05-09 03:00:00', NULL, 36, 3),
('ENTREGUE', '2026-05-10 06:00:00', NULL, 36, 6),
('REGISTRADA', '2026-04-02 09:00:00', NULL, 37, 3),
('COLETADA', '2026-04-02 20:00:00', 'Atualizacao de status para COLETADA.', 37, 1),
('REGISTRADA', '2026-02-26 09:00:00', 'Evento registrado automaticamente pelo sistema.', 38, 5),
('COLETADA', '2026-02-27 06:00:00', NULL, 38, 6),
('EM_TRIAGEM', '2026-02-27 21:00:00', 'Atualizacao de status para EM_TRIAGEM.', 38, 5),
('EM_TRANSITO', '2026-02-28 21:00:00', NULL, 38, 1),
('EM_TRIAGEM', '2026-03-02 02:00:00', NULL, 38, 1),
('EM_TRANSITO', '2026-03-02 17:00:00', NULL, 38, 1),
('EM_TRIAGEM', '2026-03-03 19:00:00', NULL, 38, 1),
('SAIU_PARA_ENTREGA', '2026-03-04 12:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 38, 6),
('ENTREGUE', '2026-03-05 05:00:00', NULL, 38, 5),
('REGISTRADA', '2026-01-11 11:00:00', NULL, 39, 2),
('COLETADA', '2026-01-12 11:00:00', NULL, 39, 2),
('EM_TRIAGEM', '2026-01-13 09:00:00', NULL, 39, 1),
('EXTRAVIADA', '2026-01-14 04:00:00', 'Atualizacao de status para EXTRAVIADA.', 39, 1),
('REGISTRADA', '2026-07-02 09:00:00', NULL, 40, 4),
('COLETADA', '2026-07-03 07:00:00', NULL, 40, 1),
('EM_TRIAGEM', '2026-07-03 22:00:00', NULL, 40, 5),
('REGISTRADA', '2026-03-03 10:00:00', 'Evento registrado automaticamente pelo sistema.', 41, 6),
('COLETADA', '2026-03-03 16:00:00', NULL, 41, 5),
('EM_TRIAGEM', '2026-03-04 13:00:00', NULL, 41, 6),
('SAIU_PARA_ENTREGA', '2026-03-05 07:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 41, 2),
('ENTREGUE', '2026-03-06 02:00:00', NULL, 41, 6),
('REGISTRADA', '2026-06-10 10:00:00', NULL, 42, 3),
('COLETADA', '2026-06-11 02:00:00', 'Atualizacao de status para COLETADA.', 42, 6),
('EM_TRIAGEM', '2026-06-11 10:00:00', NULL, 42, 3),
('SAIU_PARA_ENTREGA', '2026-06-12 14:00:00', NULL, 42, 5),
('ENTREGUE', '2026-06-12 23:00:00', NULL, 42, 6),
('REGISTRADA', '2026-04-17 11:00:00', NULL, 43, 2),
('COLETADA', '2026-04-17 21:00:00', 'Atualizacao de status para COLETADA.', 43, 6),
('EM_TRIAGEM', '2026-04-18 20:00:00', NULL, 43, 1),
('EM_TRANSITO', '2026-04-19 02:00:00', 'Atualizacao de status para EM_TRANSITO.', 43, 3),
('EM_TRIAGEM', '2026-04-19 10:00:00', 'Atualizacao de status para EM_TRIAGEM.', 43, 1),
('EM_TRANSITO', '2026-04-19 18:00:00', NULL, 43, 4),
('EM_TRIAGEM', '2026-04-20 23:00:00', 'Atualizacao de status para EM_TRIAGEM.', 43, 4),
('SAIU_PARA_ENTREGA', '2026-04-21 21:00:00', NULL, 43, 3),
('REGISTRADA', '2026-07-11 08:00:00', NULL, 44, 6),
('COLETADA', '2026-07-11 17:00:00', 'Atualizacao de status para COLETADA.', 44, 4),
('EM_TRIAGEM', '2026-07-12 15:00:00', 'Atualizacao de status para EM_TRIAGEM.', 44, 4),
('SAIU_PARA_ENTREGA', '2026-07-13 13:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 44, 6),
('TENTATIVA_FRUSTRADA', '2026-07-14 12:00:00', 'Atualizacao de status para TENTATIVA_FRUSTRADA.', 44, 2),
('SAIU_PARA_ENTREGA', '2026-07-15 00:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 44, 3),
('ENTREGUE', '2026-07-15 15:00:00', 'Atualizacao de status para ENTREGUE.', 44, 2),
('REGISTRADA', '2026-05-05 08:00:00', NULL, 45, 4),
('COLETADA', '2026-05-06 05:00:00', NULL, 45, 4),
('EM_TRIAGEM', '2026-05-07 10:00:00', 'Atualizacao de status para EM_TRIAGEM.', 45, 2),
('EM_TRANSITO', '2026-05-07 12:00:00', 'Atualizacao de status para EM_TRANSITO.', 45, 4),
('EM_TRIAGEM', '2026-05-07 17:00:00', NULL, 45, 1),
('EM_TRANSITO', '2026-05-08 17:00:00', NULL, 45, 2),
('EM_TRIAGEM', '2026-05-09 13:00:00', NULL, 45, 4),
('SAIU_PARA_ENTREGA', '2026-05-10 07:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 45, 1),
('TENTATIVA_FRUSTRADA', '2026-05-11 01:00:00', NULL, 45, 3),
('REGISTRADA', '2026-07-09 10:00:00', NULL, 46, 6),
('COLETADA', '2026-07-10 12:00:00', 'Atualizacao de status para COLETADA.', 46, 1),
('EM_TRIAGEM', '2026-07-11 10:00:00', NULL, 46, 1),
('SAIU_PARA_ENTREGA', '2026-07-11 13:00:00', NULL, 46, 1),
('TENTATIVA_FRUSTRADA', '2026-07-12 11:00:00', 'Atualizacao de status para TENTATIVA_FRUSTRADA.', 46, 6),
('SAIU_PARA_ENTREGA', '2026-07-12 16:00:00', NULL, 46, 2),
('ENTREGUE', '2026-07-13 10:00:00', 'Atualizacao de status para ENTREGUE.', 46, 2),
('REGISTRADA', '2026-01-31 10:00:00', NULL, 47, 2),
('COLETADA', '2026-01-31 14:00:00', NULL, 47, 6),
('EM_TRIAGEM', '2026-02-01 15:00:00', 'Atualizacao de status para EM_TRIAGEM.', 47, 2),
('EM_TRANSITO', '2026-02-02 14:00:00', 'Atualizacao de status para EM_TRANSITO.', 47, 6),
('EM_TRIAGEM', '2026-02-03 05:00:00', 'Atualizacao de status para EM_TRIAGEM.', 47, 4),
('SAIU_PARA_ENTREGA', '2026-02-04 03:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 47, 2),
('ENTREGUE', '2026-02-05 06:00:00', NULL, 47, 2),
('REGISTRADA', '2026-06-10 10:00:00', 'Evento registrado automaticamente pelo sistema.', 48, 4),
('COLETADA', '2026-06-11 13:00:00', 'Atualizacao de status para COLETADA.', 48, 6),
('EM_TRIAGEM', '2026-06-12 11:00:00', NULL, 48, 3),
('SAIU_PARA_ENTREGA', '2026-06-13 08:00:00', NULL, 48, 6),
('TENTATIVA_FRUSTRADA', '2026-06-13 14:00:00', 'Atualizacao de status para TENTATIVA_FRUSTRADA.', 48, 3),
('SAIU_PARA_ENTREGA', '2026-06-14 18:00:00', 'Atualizacao de status para SAIU_PARA_ENTREGA.', 48, 5),
('TENTATIVA_FRUSTRADA', '2026-06-15 00:00:00', 'Atualizacao de status para TENTATIVA_FRUSTRADA.', 48, 5),
('DEVOLVIDA', '2026-06-15 02:00:00', NULL, 48, 6);



-- Ocorrencias
-- Datas revisadas para nunca anteceder a postagem e para refletir o momento logistico da encomenda.

INSERT INTO ocorrencia (tipo, data_hora, descricao, situacao, id_encomenda) VALUES
('RECUSA_DESTINATARIO', '2026-06-05 18:15:00', 'Destinatário recusou o recebimento da encomenda.', 'RESOLVIDA', 2),
('OUTRA', '2026-01-22 12:30:00', 'Ocorrência operacional registrada durante a transferência entre centros.', 'RESOLVIDA', 4),
('ATRASO', '2026-01-21 12:00:00', 'Processamento da encomenda sofreu atraso na unidade de triagem.', 'EM_TRATAMENTO', 5),
('EXTRAVIO', '2026-05-30 21:30:00', 'Encomenda não localizada durante conferência de transferência.', 'ABERTA', 7),
('VEICULO_INDISPONIVEL', '2026-05-13 08:30:00', 'Veículo apresentou pane mecânica durante a operação de entrega.', 'RESOLVIDA', 12),
('ATRASO', '2026-06-02 18:00:00', 'Transferência sofreu atraso em relação ao planejamento operacional.', 'RESOLVIDA', 15),
('ENDERECO_NAO_LOCALIZADO', '2026-03-19 04:00:00', 'Endereço informado não foi localizado durante a rota de entrega.', 'EM_TRATAMENTO', 17),
('VEICULO_INDISPONIVEL', '2026-04-14 18:00:00', 'Veículo precisou ser substituído antes da saída para entrega.', 'RESOLVIDA', 19),
('EXTRAVIO', '2026-02-04 08:30:00', 'Encomenda não localizada no centro de distribuição.', 'ABERTA', 32),
('EXTRAVIO', '2026-05-26 09:30:00', 'Encomenda não localizada após transferência entre centros.', 'EM_TRATAMENTO', 33),
('EXTRAVIO', '2026-01-14 03:30:00', 'Encomenda não localizada durante inventário da unidade.', 'RESOLVIDA', 39),
('ATRASO', '2026-06-11 18:00:00', 'Entrega atrasada em relação ao prazo operacional previsto.', 'RESOLVIDA', 42),
('ATRASO', '2026-05-08 12:00:00', 'Transferência entre centros apresentou atraso operacional.', 'EM_TRATAMENTO', 45),
('VEICULO_INDISPONIVEL', '2026-06-13 10:00:00', 'Veículo apresentou indisponibilidade antes da tentativa de entrega.', 'RESOLVIDA', 48);



-- Expedicoes
-- Datas, motoristas e veiculos revisados para manter coerencia temporal, CNH valida e categoria compativel.

INSERT INTO expedicao (data_hora_saida, data_hora_prevista_chegada, data_hora_chegada, status_expedicao, id_rota, id_veiculo, id_funcionario_motorista) VALUES
('2026-01-20 04:00:00', '2026-01-20 14:00:00', '2026-01-20 13:00:00', 'CONCLUIDA', 7, 4, 3),
('2026-01-22 11:00:00', '2026-01-22 18:00:00', '2026-01-22 17:00:00', 'CONCLUIDA', 2, 2, 4),
('2026-01-28 04:00:00', '2026-01-28 15:00:00', '2026-01-28 14:00:00', 'CONCLUIDA', 1, 1, 2),
('2026-01-29 07:00:00', '2026-01-29 21:00:00', '2026-01-29 20:00:00', 'CONCLUIDA', 4, 14, 1),
('2026-02-02 15:00:00', '2026-02-03 05:00:00', '2026-02-03 04:00:00', 'CONCLUIDA', 1, 3, 8),
('2026-02-28 22:00:00', '2026-03-01 11:00:00', '2026-03-01 10:00:00', 'CONCLUIDA', 1, 6, 14),
('2026-03-02 18:00:00', '2026-03-03 17:00:00', '2026-03-03 16:00:00', 'CONCLUIDA', 7, 4, 12),
('2026-03-17 08:00:00', '2026-03-17 19:00:00', '2026-03-17 18:00:00', 'CONCLUIDA', 2, 9, 10),
('2026-03-18 07:00:00', '2026-03-18 14:00:00', '2026-03-18 13:00:00', 'CONCLUIDA', 6, 2, 11),
('2026-04-19 03:00:00', '2026-04-19 10:00:00', '2026-04-19 09:00:00', 'CONCLUIDA', 7, 15, 13),
('2026-04-19 19:00:00', '2026-04-20 19:00:00', '2026-04-20 18:00:00', 'CONCLUIDA', 4, 16, 6),
('2026-04-23 18:00:00', '2026-04-24 17:00:00', '2026-04-24 16:00:00', 'CONCLUIDA', 3, 12, 2),
('2026-05-07 12:30:00', '2026-05-07 17:30:00', '2026-05-07 16:30:00', 'CONCLUIDA', 3, 13, 8),
('2026-05-08 18:00:00', '2026-05-09 12:00:00', '2026-05-09 11:00:00', 'CONCLUIDA', 3, 10, 14);



-- Encomendas ligadas as expedicoes
-- Vinculos revisados para que nenhuma encomenda seja carregada antes da postagem.

INSERT INTO expedicao_encomenda (id_expedicao, id_encomenda, ordem_carregamento, data_hora_carregamento, data_hora_descarregamento) VALUES
(1, 29, 1, '2026-01-20 03:35:00', '2026-01-20 12:45:00'),
(2, 4, 1, '2026-01-22 10:35:00', '2026-01-22 16:45:00'),
(3, 25, 1, '2026-01-28 03:35:00', '2026-01-28 13:45:00'),
(4, 3, 1, '2026-01-29 06:35:00', '2026-01-29 19:45:00'),
(5, 47, 1, '2026-02-02 14:35:00', '2026-02-03 03:45:00'),
(6, 38, 1, '2026-02-28 21:35:00', '2026-03-01 09:45:00'),
(7, 38, 1, '2026-03-02 17:35:00', '2026-03-03 15:45:00'),
(8, 17, 1, '2026-03-17 07:35:00', '2026-03-17 17:45:00'),
(9, 17, 1, '2026-03-18 06:35:00', '2026-03-18 12:45:00'),
(10, 43, 1, '2026-04-19 02:35:00', '2026-04-19 08:45:00'),
(11, 43, 1, '2026-04-19 18:35:00', '2026-04-20 17:45:00'),
(12, 24, 1, '2026-04-23 17:35:00', '2026-04-24 15:45:00'),
(13, 36, 1, '2026-05-07 12:05:00', '2026-05-07 16:15:00'),
(13, 45, 2, '2026-05-07 12:10:00', '2026-05-07 16:15:00'),
(14, 45, 1, '2026-05-08 17:35:00', '2026-05-09 10:45:00');



-- Tentativas de entrega
-- Registros sincronizados com os eventos ENTREGUE e TENTATIVA_FRUSTRADA do historico.

INSERT INTO tentativa_entrega (data_hora, resultado, motivo_insucesso, recebedor, id_encomenda, id_funcionario_motorista, id_veiculo) VALUES
('2026-06-23 17:30:00', 'INSUCESSO', 'Destinatário ausente no endereço.', NULL, 1, 4, 2),
('2026-06-25 06:30:00', 'SUCESSO', NULL, 'Porteiro Carlos', 1, 2, 1),
('2026-06-05 17:30:00', 'INSUCESSO', 'Destinatário recusou o recebimento.', NULL, 2, 3, 4),
('2026-01-31 12:30:00', 'SUCESSO', NULL, 'José Santos', 3, 1, 14),
('2026-02-23 19:30:00', 'SUCESSO', NULL, 'Ana Paula (vizinha autorizada)', 8, 8, 3),
('2026-06-15 18:30:00', 'SUCESSO', NULL, 'Maria Oliveira', 9, 10, 9),
('2026-05-13 12:30:00', 'INSUCESSO', 'Destinatário ausente no endereço.', NULL, 12, 6, 15),
('2026-03-27 07:30:00', 'INSUCESSO', 'Endereço não localizado.', NULL, 18, 14, 6),
('2026-03-28 23:30:00', 'INSUCESSO', 'Destinatário recusou o recebimento.', NULL, 18, 12, 4),
('2026-03-29 20:30:00', 'SUCESSO', NULL, 'Ana Paula (vizinha autorizada)', 18, 13, 16),
('2026-04-15 15:30:00', 'SUCESSO', NULL, 'Maria Oliveira', 19, 11, 2),
('2026-06-13 02:30:00', 'INSUCESSO', 'Destinatário recusou o recebimento.', NULL, 20, 2, 12),
('2026-06-13 23:30:00', 'INSUCESSO', 'Destinatário ausente no endereço.', NULL, 20, 4, 2),
('2026-03-21 13:30:00', 'SUCESSO', NULL, 'José Santos', 21, 2, 1),
('2026-05-15 05:30:00', 'SUCESSO', NULL, 'Ana Paula (vizinha autorizada)', 22, 3, 4),
('2026-04-25 14:30:00', 'SUCESSO', NULL, 'Maria Oliveira', 24, 1, 14),
('2026-01-30 00:30:00', 'INSUCESSO', 'Endereço não localizado.', NULL, 25, 8, 3),
('2026-01-10 04:30:00', 'SUCESSO', NULL, 'Recepção do condomínio', 26, 10, 9),
('2026-07-03 03:30:00', 'SUCESSO', NULL, 'José Santos', 28, 6, 15),
('2026-01-21 11:30:00', 'SUCESSO', NULL, 'Ana Paula (vizinha autorizada)', 29, 14, 6),
('2026-04-18 11:30:00', 'SUCESSO', NULL, 'Maria Oliveira', 30, 12, 4),
('2026-01-21 14:30:00', 'SUCESSO', NULL, 'Porteiro Carlos', 31, 13, 16),
('2026-01-25 13:30:00', 'SUCESSO', NULL, 'Recepção do condomínio', 34, 11, 2),
('2026-05-10 05:30:00', 'SUCESSO', NULL, 'José Santos', 36, 2, 12),
('2026-03-05 04:30:00', 'SUCESSO', NULL, 'Ana Paula (vizinha autorizada)', 38, 4, 2),
('2026-03-06 01:30:00', 'SUCESSO', NULL, 'Maria Oliveira', 41, 2, 1),
('2026-06-12 22:30:00', 'SUCESSO', NULL, 'Porteiro Carlos', 42, 3, 4),
('2026-07-14 11:30:00', 'INSUCESSO', 'Destinatário ausente no endereço.', NULL, 44, 1, 14),
('2026-07-15 14:30:00', 'SUCESSO', NULL, 'José Santos', 44, 8, 3),
('2026-05-11 00:30:00', 'INSUCESSO', 'Destinatário recusou o recebimento.', NULL, 45, 10, 9),
('2026-07-12 10:30:00', 'INSUCESSO', 'Destinatário ausente no endereço.', NULL, 46, 6, 15),
('2026-07-13 09:30:00', 'SUCESSO', NULL, 'Porteiro Carlos', 46, 14, 6),
('2026-02-05 05:30:00', 'SUCESSO', NULL, 'Recepção do condomínio', 47, 12, 4),
('2026-06-13 13:30:00', 'INSUCESSO', 'Destinatário ausente no endereço.', NULL, 48, 13, 16),
('2026-06-14 23:30:00', 'INSUCESSO', 'Endereço não localizado.', NULL, 48, 11, 2);



-- Servicos contratados em cada encomenda

INSERT INTO encomenda_servico (id_encomenda, id_servico, valor_contratado, data_contratacao) VALUES
(1, 2, 42.77, '2026-06-20'),
(2, 4, 15.27, '2026-06-03'),
(2, 1, 24.82, '2026-06-03'),
(13, 1, 28.34, '2026-02-04'),
(16, 1, 28.29, '2026-06-06'),
(18, 4, 17.15, '2026-03-25'),
(19, 4, 13.93, '2026-04-13'),
(21, 1, 26.96, '2026-03-19'),
(21, 2, 41.53, '2026-03-19'),
(22, 3, 8.54, '2026-05-12'),
(23, 3, 8.86, '2026-03-17'),
(24, 3, 8.69, '2026-04-21'),
(25, 1, 23.46, '2026-01-26'),
(32, 3, 8.57, '2026-02-02'),
(33, 2, 36.98, '2026-05-22'),
(34, 1, 27.7, '2026-01-23'),
(36, 1, 27.54, '2026-05-04'),
(36, 4, 14.78, '2026-05-04'),
(37, 5, 19.43, '2026-04-02'),
(39, 2, 38.77, '2026-01-11'),
(40, 5, 21.85, '2026-07-02'),
(42, 1, 28.06, '2026-06-10'),
(45, 5, 21.35, '2026-05-05'),
(47, 2, 36.1, '2026-01-31');
