CREATE TRIGGER Trigger_Clientes AFTER INSERT
ON datawarehouse.tb010_clientes
FOR EACH ROW
BEGIN
INSERT INTO DW.Clientes VALUES (new.tb010_cpf, new.tb010_nome, null);
END;
--------------------------------------------------------------------------------------------
CREATE TRIGGER Trigger_ClientesVenda AFTER INSERT
ON datawarehouse.tb010_012_vendas
FOR EACH ROW
BEGIN
UPDATE DW.Clientes SET ultima_venda = new.tb010_012_data WHERE cpf_cliente =
new.tb010_cpf;
END
--------------------------------------------------------------------------------------------
CREATE PROCEDURE Vendas_Mensais()
BEGIN
INSERT INTO DW.Fato_Vendas (quantidade, id_produto, id_categoria, dia, dia_semana,
mes, ano)
SELECT sum(v.tb010_012_quantidade), v.tb012_cod_produto, p.tb013_cod_categoria,
day(v.tb010_012_data), weekday(v.tb010_012_data), month(v.tb010_012_data),
year(v.tb010_012_data)
FROM datawarehouse.tb010_012_vendas V, datawarehouse.tb012_produtos P,
datawarehouse.tb005_funcionarios F, datawarehouse.tb004_lojas L
WHERE p.tb012_cod_produto = v.tb012_cod_produto AND v.tb005_matricula =
f.tb005_matricula AND f.tb004_cod_loja = l.tb004_cod_loja AND v.tb010_012_data BETWEEN
DATE_SUB(NOW(), INTERVAL 1 MONTH) AND NOW()
GROUP BY v.tb012_cod_produto, v.tb010_012_data, l.tb004_cod_loja;
INSERT INTO DW.Fato_Vendas (quantidade, id_produto, id_categoria, dia, dia_semana,
mes, ano)
SELECT sum(v.tb010_012_quantidade), v.tb012_cod_produto, p.tb013_cod_categoria, null,
weekday(v.tb010_012_data), month(v.tb010_012_data), year(v.tb010_012_data)
FROM datawarehouse.tb010_012_vendas V, datawarehouse.tb012_produtos P,
datawarehouse.tb005_funcionarios F, datawarehouse.tb004_lojas L
WHERE p.tb012_cod_produto = v.tb012_cod_produto AND v.tb005_matricula =
f.tb005_matricula AND f.tb004_cod_loja = l.tb004_cod_loja AND v.tb010_012_data BETWEEN
DATE_SUB(NOW(), INTERVAL 1 MONTH) AND NOW()
GROUP BY v.tb012_cod_produto, weekday(v.tb010_012_data), month(v.tb010_012_data),
year(v.tb010_012_data), l.tb004_cod_loja;
INSERT INTO DW.Fato_Vendas (quantidade, id_produto, id_categoria, dia, dia_semana,
mes, ano)
SELECT sum(v.tb010_012_quantidade), v.tb012_cod_produto, p.tb013_cod_categoria, null, null,
month(v.tb010_012_data), select year(v.tb010_012_data)
FROM datawarehouse.tb010_012_vendas V, datawarehouse.tb012_produtos P,
datawarehouse.tb005_funcionarios F, datawarehouse.tb004_lojas L
WHERE p.tb012_cod_produto = v.tb012_cod_produto AND v.tb005_matricula =
f.tb005_matricula AND f.tb004_cod_loja = l.tb004_cod_loja AND v.tb010_012_data BETWEEN
DATE_SUB(NOW(), INTERVAL 1 MONTH) AND NOW()
GROUP BY v.tb012_cod_produto, month(v.tb010_012_data), year(v.tb010_012_data),
l.tb004_cod_loja;
END
--------------------------------------------------------------------------------------------
CREATE PROCEDURE Compras_Mensais()
BEGIN
INSERT INTO DW.Fato_Compras (quantidade, valor, id_produto, mes, ano)
SELECT sum(c.tb012_017_quantidade), sum(c.tb012_017_valor_unitario), c.tb012_cod_produto,
month(c.tb012_017_data), year(c.tb012_017_data)
FROM datawarehouse.tb012_017_compras C
WHERE c.tb012_017_data BETWEEN DATE_SUB(NOW(), INTERVAL 1 MONTH) AND NOW()
GROUP BY c.tb012_cod_produto;
END ;
--------------------------------------------------------------------------------------------
CREATE PROCEDURE Venda_Compra_Anual()
BEGIN
INSERT INTO DW.Fato_Vendas (quantidade, id_produto, id_categoria, dia, dia_semana,
mes, ano)
SELECT sum(v.tb010_012_quantidade), v.tb012_cod_produto, p.tb013_cod_categoria, null, null,
null, year(v.tb010_012_data)
FROM datawarehouse.tb010_012_vendas V, datawarehouse.tb012_produtos P,
datawarehouse.tb005_funcionarios F, datawarehouse.tb004_lojas L
WHERE p.tb012_cod_produto = v.tb012_cod_produto AND v.tb005_matricula =
f.tb005_matricula AND f.tb004_cod_loja = l.tb004_cod_loja AND v.tb010_012_data BETWEEN
DATE_SUB(NOW(), INTERVAL 1 YEAR) AND NOW()
GROUP BY v.tb012_cod_produto, YEAR(v.tb010_012_data), l.tb004_cod_loja;
INSERT INTO DW.Fato_Compras (quantidade, valor, id_produto, mes, ano)
SELECT sum(c.tb012_017_quantidade), sum(c.tb012_017_valor_unitario), c.tb012_cod_produto,
null, year(c.tb012_017_data)
FROM datawarehouse.tb012_017_compras C
WHERE c.tb012_017_data BETWEEN DATE_SUB(NOW(), INTERVAL 1 YEAR) AND NOW()
GROUP BY c.tb012_cod_produto, YEAR(c.tb012_017_data);
END
--------------------------------------------------------------------------------------------
CREATE EVENT DW_mes
ON SCHEDULE EVERY '1' MONTH
STARTS '2023-03-10 00:00:00'
DO
BEGIN
IF MONTH(NOW()) = 1 THEN
CALL Venda_Compra_Anual();
END IF;
CALL Vendas_Mensais();
CALL Compras_Mensais();
END