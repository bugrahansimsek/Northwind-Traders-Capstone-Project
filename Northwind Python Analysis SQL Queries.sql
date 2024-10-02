-- 1- ÜRÜN SATIŞINA GÖRE EN POPÜLER KATEGORİ ANALİZİ (PostgreSQL - PYTHON)

--Satış ekibi, hangi kategorilerdeki ürünlerde daha fazla satış yapabileceğini analiz etmek istiyor.

--Onlara yardımcı olmak için sizden aşağıdaki bilgileri istediler.
-- Kategori Kimliği
-- Kategori İsmi
-- En fazla satılan ürün İsmi
-- Toplam satılan ürün sayısı

WITH category_product_sales AS (
    SELECT 
        cat.category_id,
        cat.category_name,
        p.product_name,
        SUM(od.quantity) AS total_quantity_sold,  -- Toplam satılan ürün miktarı
        ROW_NUMBER() OVER (PARTITION BY cat.category_id ORDER BY SUM(od.quantity) DESC) AS rn  -- Kategoriye göre sırala ve numaralandır
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    GROUP BY cat.category_id, cat.category_name, p.product_name
)
-- Ana Sorgu: Kategorideki en yüksek satan ürünü getirme ve miktara göre sıralama
SELECT 
    category_id,
    category_name,
    product_name,
    total_quantity_sold
FROM category_product_sales
WHERE rn = 1  -- Sadece her kategoride en çok satan ürünü al
ORDER BY total_quantity_sold DESC;

-- 2- MÜŞTERİ SADAKAT ANALİZİ  (PostgreSQL - PYTHON)
-- Satış Ekibi Müşterilerini Detaylı İncelemek İstiyor.
-- Onlara yardımcı olmak için sizden aşağıdaki bilgileri istediler.
-- En çok adette sipariş veren Müşteriler.
-- En çok para harcayan müşteriler.

SELECT 
    c.customer_id,
    c.company_name,
    COUNT(o.order_id) AS total_orders,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_spent DESC
LIMIT 10
