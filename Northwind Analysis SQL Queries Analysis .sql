--Genel Bakış (PostgreSQL  - PowerBI - DAX)

-- Şirket Genel Kurul Toplantısında şirket durumuna genel bir analiz yapmak istiyor.

----Onlara yardımcı olmak için sizden aşağıdaki bilgileri istediler:

-- Brüt Satış (total_gross_sales): Ürün fiyatı çarpı satılan miktarla hesaplanır.
-- Net Satış (total_net_sales): Brüt satıştan indirimler düşülerek hesaplanır.
-- Çalışan Sayısı (total_employees): Farklı çalışanların sayısını verir.
-- Toplam Satış Miktarı (total_sales_quantity): Satılan tüm ürünlerin miktarlarını toplar.
-- Toplam Sipariş Sayısı (total_orders): Toplam farklı siparişlerin sayısını verir.
-- Müşteri Sayısı (total_customers): Farklı müşterilerin sayısını toplar.
-- Toplam İndirim Tutarı (total_discount_amount): Uygulanan indirimleri toplar.
-- Toplam Nakliye Ücreti (total_freight): Nakliye ücretlerini toplar.
-- Tedarikçi Sayısı (total_suppliers): Farklı tedarikçi sayısını verir.

SELECT 
    -- Brüt Satış
    SUM(od.unit_price * od.quantity) AS total_gross_sales,

    -- Net Satış (Brüt satıştan indirimlerin çıkarılması)
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_net_sales,

    -- Çalışan Sayısı (Farklı çalışanların sayısı)
    COUNT(DISTINCT e.employee_id) AS total_employees,

    -- Toplam Satış Miktarı (Toplam satılan ürün adedi)
    SUM(od.quantity) AS total_sales_quantity,

    -- Toplam Sipariş Sayısı
    COUNT(DISTINCT o.order_id) AS total_orders,

    -- Müşteri Sayısı (Farklı müşterilerin sayısı)
    COUNT(DISTINCT c.customer_id) AS total_customers,

    -- Toplam İndirim Tutarı
    SUM(od.unit_price * od.quantity * od.discount) AS total_discount_amount,

    -- Toplam Nakliye Ücreti
    SUM(o.freight) AS total_freight,

    -- Tedarikçi Sayısı (Farklı tedarikçilerin sayısı)
    COUNT(DISTINCT p.supplier_id) AS total_suppliers

FROM 
    orders o
JOIN 
    order_details od ON o.order_id = od.order_id
JOIN 
    products p ON od.product_id = p.product_id
JOIN 
    customers c ON o.customer_id = c.customer_id
JOIN 
    employees e ON o.employee_id = e.employee_id;

-- Satış Analizi (PostgreSQL  - PowerBI - DAX)

-- Satış Ekibimiz Şirket satışlarımızı analiz etmek istiyor.

----Onlara yardımcı olmak için sizden aşağıdaki bilgileri istediler:

-- Brüt Satışı Ay bazında incelemek.
-- Brüt Satışı Yıl bazında incelemek.
-- Toptancıların hangi ürünleri sağladığı toplam kaç ürün aldığımız Net kazancımız.
-- Çalışan Sayımız toplam yaptıkları satış.

WITH monthly_sales AS (
    SELECT 
        TO_CHAR(o.order_date, 'Month') AS month,
        SUM(od.unit_price * od.quantity) AS total_gross_sales
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY TO_CHAR(o.order_date, 'Month')
),
yearly_sales_distribution AS (
    SELECT 
        EXTRACT(YEAR FROM o.order_date) AS year,
        COUNT(o.order_id) * 100.0 / (SELECT COUNT(*) FROM orders) AS percentage_of_orders
    FROM orders o
    GROUP BY EXTRACT(YEAR FROM o.order_date)
),
supplier_sales AS (
    SELECT 
        s.company_name AS supplier_name,
        SUM(od.quantity) AS total_quantity_sold,
        SUM(od.unit_price * od.quantity) AS total_revenue
    FROM suppliers s
    JOIN products p ON s.supplier_id = p.supplier_id
    JOIN order_details od ON p.product_id = od.product_id
    GROUP BY s.company_name
),
employee_sales AS (
    SELECT 
        e.first_name || ' ' || e.last_name AS employee_name,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales
    FROM employees e
    JOIN orders o ON e.employee_id = o.employee_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY e.first_name, e.last_name
)

-- Ana Sorgu
SELECT 
    ms.month,
    ms.total_gross_sales,
    ys.year,
    ys.percentage_of_orders,
    ss.supplier_name,
    ss.total_quantity_sold,
    ss.total_revenue,
    es.employee_name,
    es.total_sales
FROM 
    monthly_sales ms
JOIN 
    yearly_sales_distribution ys ON 1=1 -- Ay ve yıl karşılaştırması için uygun bir ilişki olmadığı için bağlamadık
JOIN 
    supplier_sales ss ON 1=1 -- Sorguları birleştirmek için
JOIN 
    employee_sales es ON 1=1 -- Çalışan verilerini de ekliyoruz
ORDER BY 
    ms.month, ys.year, ss.total_revenue DESC, es.total_sales DESC;

--Ürün Analizi (PostgreSQL  - PowerBI - DAX)
-- Şirket Ürünler hakkında detay analiz istiyor.

----Onlara yardımcı olmak için sizden aşağıdaki bilgileri istediler:
-- Kategoriye göre Toplam Sipariş Sayısı ve Brüt Satış
-- Kategoriye göre Brüt Satış hangi kategori ne kadar kar kazandırmış
-- Kategorilerin içinde hangi ürünler var yıllara göre toplam ne kadar satılmış ve topla ne kar edilmiş

WITH category_sales AS (
    SELECT 
        c.category_name,
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        SUM(od.quantity) AS total_quantity_sold,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN orders o ON od.order_id = o.order_id
    GROUP BY c.category_name, EXTRACT(YEAR FROM o.order_date)
),
category_summary AS (
    SELECT 
        c.category_name,
        SUM(od.quantity) AS total_quantity_sold,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY c.category_name
),
category_distribution AS (
    SELECT
        c.category_name,
        SUM(od.quantity) * 100.0 / (SELECT SUM(quantity) FROM order_details) AS category_percentage
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY c.category_name
)
-- Ana Sorgu
SELECT 
    cs.category_name,
    cs.order_year,
    cs.total_quantity_sold,
    cs.total_revenue,
    cs_total.total_quantity_sold AS toplam_satis_miktari,
    cs_total.total_revenue AS brut_satis,
    cd.category_percentage
FROM 
    category_sales cs
JOIN 
    category_summary cs_total ON cs.category_name = cs_total.category_name
JOIN 
    category_distribution cd ON cs.category_name = cd.category_name
ORDER BY cs.order_year, cs.category_name;

--Müşteri Analizi (PostgreSQL  - PowerBI - DAX)
-- Şirket toplantıda deyatlı müşteri analizi istiyor.

----Onlara yardımcı olmak için sizden aşağıdaki bilgileri istediler:
--Müşterilerin toplam siparişlerini ne kadar para harcadıklarını ne kadar indirim aldıklarını, Buna Görede Segmentledik
-- Hangi Kategoride alışveriş yapmış müşteri ne kadar almış
-- Hangi aylarda almış ne kadar almış

WITH customer_analysis AS (
    -- Müşteri Harcaması, Sipariş Sayısı ve Ortalama Harcama
    SELECT 
        c.customer_id,
        c.company_name,
        COUNT(o.order_id) AS total_orders,  -- Toplam sipariş sayısı
        SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC AS total_spent,  -- Toplam harcama
        ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC / COUNT(o.order_id), 2) AS avg_order_value,  -- Ortalama sipariş değeri

        -- İndirimden Faydalanma Analizi
        SUM((od.discount * od.unit_price * od.quantity))::NUMERIC AS total_discount_given,  -- Toplam indirim tutarı

        -- Müşteri Sipariş Zaman Aralıkları (Gün Cinsinden)
        ROUND(AVG(o.shipped_date - o.order_date), 2) AS avg_delivery_days,  -- Ortalama teslimat süresi

        -- Kar Marjı Analizi (Toplam Satıştan Ürün Maliyetinin Çıkarılması)
        SUM((od.unit_price * od.quantity * (1 - od.discount)) - (p.unit_price * od.quantity))::NUMERIC AS total_profit  -- Toplam kâr/zarar
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
    WHERE o.shipped_date IS NOT NULL  -- Teslim edilen siparişler
    GROUP BY c.customer_id, c.company_name
),
category_data AS (
    -- Kategori bazında satış verileri
    SELECT 
        cat.category_name,
        SUM(od.quantity) AS total_sales_quantity,  -- Toplam satış miktarı
        SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC AS gross_sales,  -- Brüt satış
        SUM(od.discount * od.unit_price * od.quantity) AS total_discount  -- Toplam indirim tutarı
    FROM categories cat
    JOIN products p ON cat.category_id = p.category_id
    JOIN order_details od ON p.product_id = od.product_id
    GROUP BY cat.category_name
)
-- Ana sorgu: Müşteri verileri ve kategori verilerini getiriyoruz
SELECT 
    customer_id,
    company_name,
    total_orders,
    total_spent,
    avg_order_value,
    total_discount_given,
    avg_delivery_days,
    total_profit,

    -- Müşteri Segmentasyonu
    CASE 
        WHEN total_spent >= 10000 THEN 'High Value Customers'
        WHEN total_spent BETWEEN 5000 AND 9999 THEN 'Medium Value Customers'
        ELSE 'Low Value Customers'
    END AS customer_segment,

    -- Müşteri İndirim Alışkanlığına Göre Segment
    CASE 
        WHEN total_discount_given > 1000 THEN 'Discount Hunter'
        WHEN total_discount_given BETWEEN 500 AND 1000 THEN 'Occasional Discount User'
        ELSE 'Non-Discount User'
    END AS discount_behavior

FROM customer_analysis

UNION ALL

-- Kategori bazındaki verileri ekleyelim
SELECT 
    NULL AS customer_id,
    cat_data.category_name AS company_name,  -- Kategoriyi company_name olarak isimlendirdik
    cat_data.total_sales_quantity AS total_orders,
    cat_data.gross_sales AS total_spent,
    NULL AS avg_order_value,
    cat_data.total_discount AS total_discount_given,
    NULL AS avg_delivery_days,
    NULL AS total_profit,
    NULL AS customer_segment,
    NULL AS discount_behavior
FROM category_data cat_data
ORDER BY total_spent DESC;

--Lojistik Analizi (PostgreSQL  - PowerBI - DAX)
--Şirket toplantısında detaylı lojistik analizi istiyorlar.

----Onlara yardımcı olmak için sizden aşağıdaki bilgileri istediler:
-- Ülkelere göre satış miktarı
-- Kargo firmaları taşıma yüzdeleri
-- Şirketlerin toplam siparişleri
-- Ortalama nakliye ücreti ve süreleri

WITH shipping_analysis AS (
    -- Toplam Nakliye Ücreti, Nakliye Miktarı ve Ortalama Nakliye Süresi
    SELECT 
        SUM(o.freight) AS total_shipping_cost,  -- Toplam Nakliye Ücreti
        COUNT(o.order_id) AS total_shipping_quantity,  -- Nakliye edilen toplam sipariş sayısı
        ROUND(AVG(o.shipped_date - o.order_date), 2) AS avg_shipping_time  -- Ortalama Nakliye Süresi (Gün)
    FROM orders o
    WHERE o.shipped_date IS NOT NULL  -- Sadece teslim edilen siparişler
),
customer_analysis AS (
    -- Toplam Müşteri Sayısı
    SELECT 
        COUNT(DISTINCT c.customer_id) AS total_customers  -- Eşsiz müşteri sayısı
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
),
shipping_method_analysis AS (
    -- Nakliye Yöntemlerine Göre Sipariş Dağılımı
    SELECT 
        s.company_name AS shipping_company,  -- Nakliye firması ismi
        COUNT(o.order_id) AS total_orders,  -- Nakliye edilen toplam sipariş sayısı
        ROUND((COUNT(o.order_id)::NUMERIC / SUM(COUNT(o.order_id)) OVER()) * 100, 2) AS order_percentage  -- Toplam içindeki yüzdesi
    FROM orders o
    JOIN shippers s ON o.ship_via = s.shipper_id
    GROUP BY s.company_name
),
customer_order_analysis AS (
    -- Müşteri Şirketlerine Göre Sipariş Sayıları
    SELECT 
        c.company_name AS customer_company,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.company_name
    ORDER BY total_orders DESC  -- En çok sipariş veren müşteriler
)
-- Ana sorgu
SELECT 
    sa.total_shipping_cost,
    sa.total_shipping_quantity,
    sa.avg_shipping_time,
    ca.total_customers,
    sm.shipping_company,
    sm.total_orders AS shipping_company_orders,
    sm.order_percentage,
    co.customer_company,
    co.total_orders AS customer_total_orders
FROM shipping_analysis sa
JOIN customer_analysis ca ON 1 = 1  -- Her iki tabloyu birleştiriyoruz çünkü sadece toplamları alıyoruz
JOIN shipping_method_analysis sm ON 1 = 1
JOIN customer_order_analysis co ON 1 = 1
ORDER BY co.total_orders DESC;

--RFM Analizi (PostgreSQL  - PowerBI - DAX)
-- Şirket detaylı müşteri Analizi istiyor.

----Onlara yardımcı olmak için sizden aşağıdaki bilgileri istediler:
-- RFM Analizi
-- Churn Analizi
-- Kategori/Ürün detaylı Yıllara göre roplam satış Brüt satış 

--RFM Analiz

WITH recency_data AS (
    SELECT 
        c.customer_id,
        c.company_name,
        CURRENT_DATE - MAX(o.order_date) AS recency  -- Son alışveriş tarihinden bugüne kadar geçen gün sayısı
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.company_name
),
frequency_data AS (
    SELECT 
        c.customer_id,
        COUNT(o.order_id) AS frequency  -- Müşterinin toplam sipariş sayısı
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
),
monetary_data AS (
    SELECT 
        c.customer_id,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS monetary  -- Müşterinin toplam harcama miktarı
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id
)
SELECT 
    r.customer_id,
    r.company_name,
    r.recency,
    f.frequency,
    m.monetary,
    
    -- Recency, Frequency, and Monetary skoru
    NTILE(5) OVER (ORDER BY r.recency ASC) AS R_Score,
    NTILE(5) OVER (ORDER BY f.frequency DESC) AS F_Score,
    NTILE(5) OVER (ORDER BY m.monetary DESC) AS M_Score,

    -- RFM Skorlarının birleştirilmesi
    (CAST(NTILE(5) OVER (ORDER BY r.recency) AS TEXT) ||
     CAST(NTILE(5) OVER (ORDER BY f.frequency DESC) AS TEXT) ||
     CAST(NTILE(5) OVER (ORDER BY m.monetary DESC) AS TEXT)) AS RFM_Score,

    -- Müşteri Segmentasyonu
    CASE 
        WHEN NTILE(5) OVER (ORDER BY r.recency) IN (1, 2) AND NTILE(5) OVER (ORDER BY f.frequency DESC) IN (1, 2) THEN 'Uyuyanlar'
        WHEN NTILE(5) OVER (ORDER BY r.recency) IN (1, 2) AND NTILE(5) OVER (ORDER BY f.frequency DESC) IN (3, 4) THEN 'Risk Altında'
        WHEN NTILE(5) OVER (ORDER BY r.recency) IN (1, 2) AND NTILE(5) OVER (ORDER BY f.frequency DESC) = 5 THEN 'Kaybedemeyiz'
        WHEN NTILE(5) OVER (ORDER BY r.recency) = 3 AND NTILE(5) OVER (ORDER BY f.frequency DESC) IN (1, 2) THEN 'Uykuya Dalma Noktasında'
        WHEN NTILE(5) OVER (ORDER BY r.recency) = 3 AND NTILE(5) OVER (ORDER BY f.frequency DESC) = 3 THEN 'Dikkat Gerektirenler'
        WHEN NTILE(5) OVER (ORDER BY r.recency) IN (3, 4) AND NTILE(5) OVER (ORDER BY f.frequency DESC) IN (4, 5) THEN 'Sadık Müşteriler'
        WHEN NTILE(5) OVER (ORDER BY r.recency) = 4 AND NTILE(5) OVER (ORDER BY f.frequency DESC) = 1 THEN 'Umut Verenler'
        WHEN NTILE(5) OVER (ORDER BY r.recency) = 5 AND NTILE(5) OVER (ORDER BY f.frequency DESC) = 1 THEN 'Yeni Müşteriler'
        WHEN NTILE(5) OVER (ORDER BY r.recency) IN (4, 5) AND NTILE(5) OVER (ORDER BY f.frequency DESC) IN (2, 3) THEN 'Potansiyel Sadıklar'
        WHEN NTILE(5) OVER (ORDER BY r.recency) = 5 AND NTILE(5) OVER (ORDER BY f.frequency DESC) IN (4, 5) THEN 'Şampiyonlar'
        ELSE 'Diğer'
    END AS customer_segment
FROM recency_data r
JOIN frequency_data f ON r.customer_id = f.customer_id
JOIN monetary_data m ON r.customer_id = m.customer_id
ORDER BY RFM_Score DESC;

-- Churn Analizi

WITH customer_last_order AS (
    -- Müşterilerin son sipariş tarihini buluyoruz
    SELECT 
        c.customer_id,
        c.company_name,
        MAX(o.order_date) AS last_order_date  -- Müşterinin en son sipariş verdiği tarih
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.company_name
)
SELECT 
    c.customer_id,
    c.company_name,
    c.last_order_date,
    
    -- Churn olup olmadığını belirlemek için son sipariş tarihinden itibaren geçen süreyi hesaplıyoruz
    CASE 
        WHEN c.last_order_date < (SELECT MAX(order_date) FROM orders) - INTERVAL '6 months' THEN 'Churn'  -- Son sipariş 6 ay öncesindeyse müşteri churn olarak kabul edilir
        ELSE 'Active'
    END AS customer_status
FROM customer_last_order c
ORDER BY c.last_order_date DESC;

-- 1-ÜRÜN SATIŞINA GÖRE EN POPÜLER KATEGORİ ANALİZİ (PostgreSQL - PYTHON)

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
