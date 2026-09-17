SELECT
    (SELECT count(*) FROM customers)     AS clientes,
    (SELECT count(*) FROM orders)        AS pedidos,
    (SELECT count(*) FROM order_details) AS lineas,
    (SELECT count(*) FROM products)      AS productos,
    (SELECT count(*) FROM employees)     AS empleados,
    (SELECT count(*) FROM suppliers)     AS proveedores;


SELECT contype AS tipo, count(*) AS total
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'public'
GROUP BY contype
ORDER BY 1;

SELECT customer_id, company_name, city
FROM customers
WHERE customer_id IN ('ANATR', 'BERGS', 'BLONP');

-- IMPORTANTE -> Me ayuda para sacar datos entre tablas
SELECT conrelid::regclass AS tabla_origen,
       confrelid::regclass AS tabla_destino,
       conname AS nombre_restriccion
FROM pg_constraint
WHERE contype = 'f'
ORDER BY 1, 2;

-- Ejercicio 01
SELECT product_name AS producto, ROUND(unit_price::NUMERIC,2) AS precio
FROM products
WHERE unit_price BETWEEN 10 AND 50
	AND discontinued = 0
ORDER BY unit_price;

--Ejercicio 02
SELECT country AS pais, 
	COUNT(customer_id) AS num_clientes, 
	COUNT(DISTINCT(city)) AS num_ciudades
FROM customers
GROUP BY country
HAVING COUNT(customer_id) >= 5
ORDER BY num_clientes DESC;

--Ejercicio 03
SELECT product_name AS producto,
	units_in_stock AS stock,
	reorder_level AS nivel_reposicion,
	units_on_order AS pedido_a_proveedor,
	CASE
    	WHEN units_in_stock = 0 THEN 'CRÍTICO'
    ELSE 'AVISO'
  		END AS situacion
FROM products
WHERE discontinued = 0 
	AND units_in_stock <= reorder_level;











