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
SELECT 
    product_name AS producto,
    COALESCE(units_in_stock, 0) AS stock,
    COALESCE(reorder_level, 0) AS nivel_reposicion,
    COALESCE(units_on_order, 0) AS pedido_a_proveedor,
    CASE
        WHEN COALESCE(units_in_stock, 0) = 0 THEN 'CRÍTICO'
        ELSE 'AVISO'
    END AS situacion
FROM products
WHERE discontinued = 0 
  AND COALESCE(units_in_stock, 0) <= COALESCE(reorder_level, 0);

--Ejercicio04
SELECT 
	p.product_name AS producto,
	c.category_name AS categoria,
	s.company_name AS proveedor,
	s.country AS pais,
	s.city AS ciudad
FROM products p
	INNER JOIN categories c ON p.category_id = c.category_id
	INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE s.country IN ('Italy','France','Spain')
ORDER BY pais DESC, producto ASC;

--Ejercicio05
SELECT
	c.contact_name AS cliente,
	o.order_date AS fecha_pedido,
	p.product_name AS producto,
	od.unit_price AS precio_unitario,
	od.quantity AS cantidad,
	od.discount AS descuento,
	ROUND(
        (od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0)))::NUMERIC, 
        2
    ) AS importe_linea
FROM customers c
	INNER JOIN orders o USING(customer_id)
	INNER JOIN order_details od USING(order_id)
	INNER JOIN products p USING(product_id);

--Ejercicio06
SELECT
    c.category_name AS categoria,
    COUNT(od.order_id) AS num_lineas,
    COUNT(DISTINCT p.product_id) AS num_productos,
    ROUND(
        SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0)))::NUMERIC, 
        2
    ) AS facturacion
FROM categories c
    INNER JOIN products p USING(category_id)
    INNER JOIN order_details od USING(product_id)
GROUP BY c.category_name
HAVING SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0)))::NUMERIC > 100000
ORDER BY facturacion DESC;
	

-- Ejercicio07
SELECT 
    c.company_name AS cliente,
    c.country AS pais,
    COUNT(o.order_id) AS num_pedidos,
    COALESCE(TO_CHAR(MAX(o.order_date), 'YYYY-MM-DD'), 'SIN PEDIDOS') AS ultimo_pedido
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name, c.country
ORDER BY num_pedidos ASC, cliente ASC;


-- Ejercicio08
SELECT 
    e.first_name || ' ' || e.last_name AS empleado,
    e.title AS cargo,
    COALESCE(j.first_name || ' ' || j.last_name, 'DIRECCIÓN GENERAL') AS responsable,
    COALESCE(j.title, 'DIRECCIÓN GENERAL') AS cargo_responsable
FROM employees e
LEFT JOIN employees j ON e.reports_to = j.employee_id
ORDER BY responsable, empleado;


-- Ejercicio09
WITH anios AS (
    SELECT DISTINCT EXTRACT(YEAR FROM order_date)::INT AS anio 
    FROM orders 
    WHERE order_date IS NOT NULL
),
rejilla AS (
    SELECT c.category_id, c.category_name, a.anio
    FROM categories c
    CROSS JOIN anios a
),
ventas_reales AS (
    SELECT 
        p.category_id,
        EXTRACT(YEAR FROM o.order_date)::INT AS anio,
        SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0))) AS total
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
    GROUP BY p.category_id, EXTRACT(YEAR FROM o.order_date)::INT
)
SELECT 
    r.category_name AS categoria,
    r.anio,
    ROUND(COALESCE(v.total, 0)::NUMERIC, 2) AS facturacion
FROM rejilla r
LEFT JOIN ventas_reales v ON r.category_id = v.category_id AND r.anio = v.anio
ORDER BY categoria ASC, anio ASC;


-- Ejercicio10
WITH c_pais AS (
    SELECT country AS pais, COUNT(*) AS num_clientes
    FROM customers
    GROUP BY country
),
s_pais AS (
    SELECT country AS pais, COUNT(*) AS num_proveedores
    FROM suppliers
    GROUP BY country
)
SELECT 
    COALESCE(c.pais, s.pais) AS pais,
    COALESCE(c.num_clientes, 0) AS num_clientes,
    COALESCE(s.num_proveedores, 0) AS num_proveedores,
    CASE 
        WHEN c.pais IS NOT NULL AND s.pais IS NOT NULL THEN 'AMBOS'
        WHEN c.pais IS NOT NULL THEN 'SOLO CLIENTES'
        ELSE 'SOLO PROVEEDORES'
    END AS tipo_presencia
FROM c_pais c
FULL JOIN s_pais s ON c.pais = s.pais
ORDER BY pais ASC;


-- Ejercicio11
SELECT 
    'CLIENTE' AS origen,
    UPPER(contact_name) AS contacto,
    company_name AS organizacion,
    city AS ciudad,
    country AS pais
FROM customers

UNION ALL

SELECT 
    'PROVEEDOR' AS origen,
    UPPER(contact_name) AS contacto,
    company_name AS organizacion,
    city AS ciudad,
    country AS pais
FROM suppliers

UNION ALL

SELECT 
    'EMPLEADO' AS origen,
    UPPER(first_name || ' ' || last_name) AS contacto,
    'NORTHWIND TRADERS' AS organizacion,
    city AS ciudad,
    country AS pais
FROM employees
ORDER BY origen ASC, pais ASC;


-- Ejercicio12_a
SELECT country AS pais FROM customers
EXCEPT
SELECT country AS pais FROM suppliers
ORDER BY pais ASC;


-- Ejercicio12_b
SELECT country AS pais FROM customers
INTERSECT
SELECT country AS pais FROM suppliers
ORDER BY pais ASC;


-- Ejercicio13
SELECT 
    c.company_name AS cliente,
    c.country AS pais,
    COUNT(o.order_id) AS pedidos_realizados
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o2
    JOIN order_details od ON o2.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    WHERE o2.customer_id = c.customer_id
      AND cat.category_name = 'Seafood'
)
GROUP BY c.customer_id, c.company_name, c.country
ORDER BY pedidos_realizados DESC;


-- Ejercicio14
SELECT 
    product_name AS producto,
    ROUND(unit_price::NUMERIC, 2) AS precio,
    ROUND((SELECT AVG(unit_price) FROM products)::NUMERIC, 2) AS precio_medio_catalogo,
    ROUND((unit_price - (SELECT AVG(unit_price) FROM products))::NUMERIC, 2) AS diferencia
FROM products
WHERE discontinued = 0 
  AND unit_price > (SELECT AVG(unit_price) FROM products)
ORDER BY diferencia DESC;


-- Ejercicio15
WITH pedidos_totales AS (
    SELECT 
        o.order_id,
        o.customer_id,
        SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0))) AS total_pedido
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.order_id, o.customer_id
)
SELECT 
    c.company_name AS cliente,
    c.country AS pais,
    COUNT(pt.order_id) AS num_pedidos,
    ROUND(SUM(pt.total_pedido)::NUMERIC, 2) AS importe_total,
    ROUND(AVG(pt.total_pedido)::NUMERIC, 2) AS ticket_medio
FROM customers c
JOIN pedidos_totales pt ON c.customer_id = pt.customer_id
GROUP BY c.customer_id, c.company_name, c.country
ORDER BY ticket_medio DESC
LIMIT 15;


-- Ejercicio16
SELECT 
    c.category_name AS categoria,
    p.product_name AS producto,
    ROUND(p.unit_price::NUMERIC, 2) AS precio,
    ROUND((
        SELECT AVG(p2.unit_price) 
        FROM products p2 
        WHERE p2.category_id = p.category_id
    )::NUMERIC, 2) AS precio_medio_categoria
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.unit_price = (
    SELECT MAX(p3.unit_price)
    FROM products p3
    WHERE p3.category_id = p.category_id
)
ORDER BY categoria;


-- Ejercicio17
WITH facturacion_cliente AS (
    SELECT 
        c.customer_id,
        SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0))) AS facturacion
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id
),
cuartiles AS (
    SELECT 
        customer_id,
        facturacion,
        NTILE(4) OVER (ORDER BY facturacion DESC) AS cuartil
    FROM facturacion_cliente
),
segmentados AS (
    SELECT 
        customer_id,
        facturacion,
        CASE cuartil
            WHEN 1 THEN 'A - Estratégico'
            WHEN 2 THEN 'B - Consolidado'
            WHEN 3 THEN 'C - Ocasional'
            WHEN 4 THEN 'D - Marginal'
        END AS segmento
    FROM cuartiles
)
SELECT 
    segmento,
    COUNT(*) AS num_clientes,
    ROUND(SUM(facturacion)::NUMERIC, 2) AS facturacion_segmento,
    ROUND((SUM(facturacion) * 100.0 / SUM(SUM(facturacion)) OVER ())::NUMERIC, 2) AS porcentaje_sobre_total
FROM segmentados
GROUP BY segmento
ORDER BY segmento ASC;


-- Ejercicio18
WITH metricas_producto AS (
    SELECT 
        c.category_name AS categoria,
        p.product_name AS producto,
        SUM(od.quantity) AS unidades,
        ROUND(SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0)))::NUMERIC, 2) AS facturacion
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_details od ON p.product_id = od.product_id
    GROUP BY c.category_name, p.product_id, p.product_name
),
rankings AS (
    SELECT 
        categoria,
        DENSE_RANK() OVER (PARTITION BY categoria ORDER BY facturacion DESC) AS posicion_en_categoria,
        producto,
        unidades,
        facturacion,
        DENSE_RANK() OVER (ORDER BY facturacion DESC) AS posicion_global
    FROM metricas_producto
)
SELECT 
    categoria,
    posicion_en_categoria,
    producto,
    unidades,
    facturacion,
    posicion_global
FROM rankings
WHERE posicion_en_categoria <= 3
ORDER BY categoria ASC, posicion_en_categoria ASC;


-- Ejercicio19
WITH ventas_mes AS (
    SELECT 
        DATE_TRUNC('month', o.order_date)::DATE AS mes,
        ROUND(SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0)))::NUMERIC, 2) AS facturacion
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 1997
    GROUP BY DATE_TRUNC('month', o.order_date)::DATE
)
SELECT 
    mes,
    facturacion,
    SUM(facturacion) OVER (ORDER BY mes) AS acumulado,
    ROUND(AVG(facturacion) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)::NUMERIC, 2) AS media_movil_3m,
    LAG(facturacion, 1) OVER (ORDER BY mes) AS mes_anterior,
    ROUND(((facturacion - LAG(facturacion, 1) OVER (ORDER BY mes)) * 100.0 / NULLIF(LAG(facturacion, 1) OVER (ORDER BY mes), 0))::NUMERIC, 2) AS variacion_pct
FROM ventas_mes
ORDER BY mes ASC;


-- Ejercicio20
-- NOTA: La comparación de tendencia entre 1997 y 1998 no es homogénea sin normalizar, 
-- ya que 1997 incluye 12 meses y 1998 sólo dispone de registros hasta mayo.
WITH ventas_base AS (
    SELECT 
        c.category_name AS categoria,
        EXTRACT(YEAR FROM o.order_date)::INT AS anio,
        od.unit_price * od.quantity * (1 - COALESCE(od.discount, 0)) AS importe
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_details od ON p.product_id = od.product_id
    JOIN orders o ON od.order_id = o.order_id
    GROUP BY c.category_name, EXTRACT(YEAR FROM o.order_date)::INT, od.order_id, od.product_id
),
resumen AS (
    SELECT 
        COALESCE(categoria, 'TOTAL GENERAL') AS categoria,
        ROUND(SUM(importe) FILTER (WHERE anio = 1996)::NUMERIC, 2) AS f_1996,
        ROUND(SUM(importe) FILTER (WHERE anio = 1997)::NUMERIC, 2) AS f_1997,
        ROUND(SUM(importe) FILTER (WHERE anio = 1998)::NUMERIC, 2) AS f_1998,
        ROUND(SUM(importe)::NUMERIC, 2) AS total,
        ROUND(SUM(importe) FILTER (WHERE anio = 1998)::NUMERIC - SUM(importe) FILTER (WHERE anio = 1997)::NUMERIC, 2) AS dif_98_97
    FROM ventas_base
    GROUP BY ROLLUP(categoria)
)
SELECT 
    categoria,
    COALESCE(f_1996, 0) AS f_1996,
    COALESCE(f_1997, 0) AS f_1997,
    COALESCE(f_1998, 0) AS f_1998,
    total,
    ROUND((total * 100.0 / MAX(CASE WHEN categoria = 'TOTAL GENERAL' THEN total END) OVER())::NUMERIC, 2) AS peso_pct,
    CASE 
        WHEN categoria = 'TOTAL GENERAL' THEN '-'
        WHEN dif_98_97 > 0 THEN 'CRECE'
        ELSE 'DECRECE'
    END AS tendencia
FROM resumen
ORDER BY CASE WHEN categoria = 'TOTAL GENERAL' THEN 1 ELSE 0 END, total DESC;









