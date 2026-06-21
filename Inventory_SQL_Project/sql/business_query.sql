-- =============================================
-- 进销存数据库 - 业务统计查询SQL
-- 共18条核心查询
-- =============================================

USE inventory_db;

-- =============================================
-- 第一部分：缺货预警查询
-- =============================================

-- 1. 查询库存低于预警值的缺货商品
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 商品分类,
    p.stock AS 当前库存,
    p.warn_num AS 预警线,
    (p.warn_num - p.stock) AS 缺口数量,
    CASE 
        WHEN p.stock = 0 THEN '已售罄'
        WHEN p.stock < p.warn_num * 0.5 THEN '严重缺货'
        ELSE '需要补货'
    END AS 缺货等级
FROM product p
LEFT JOIN category c ON p.cid = c.cid
WHERE p.stock < p.warn_num
ORDER BY (p.warn_num - p.stock) DESC;

-- 2. 查询库存为0的商品（售罄商品）
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 商品分类,
    p.buy_price AS 进货价,
    p.sale_price AS 销售价,
    p.stock AS 当前库存
FROM product p
LEFT JOIN category c ON p.cid = c.cid
WHERE p.stock = 0
ORDER BY p.pname;

-- 3. 查询接近预警线的商品（库存低于预警线120%）
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    p.stock AS 当前库存,
    p.warn_num AS 预警线,
    ROUND(p.stock / p.warn_num * 100, 1) AS 库存预警比,
    p.unit AS 单位
FROM product p
WHERE p.stock <= p.warn_num * 1.2 AND p.stock > 0
ORDER BY ROUND(p.stock / p.warn_num * 100, 1) ASC;

-- =============================================
-- 第二部分：月度进销存汇总
-- =============================================

-- 4. 本月各类商品进销存汇总
SELECT 
    c.cname AS 商品分类,
    COUNT(DISTINCT p.pid) AS 商品种类数,
    COALESCE(SUM(pc.pur_num), 0) AS 本月入库数量,
    COALESCE(SUM(sc.sale_num), 0) AS 本月销售数量,
    COALESCE(SUM(pc.pur_num), 0) - COALESCE(SUM(sc.sale_num), 0) AS 本月库存变化,
    COALESCE(SUM(sc.sale_amount), 0) AS 本月销售额,
    COALESCE(SUM(sc.sale_num * p.buy_price), 0) AS 本月成本额,
    COALESCE(SUM(sc.sale_amount), 0) - COALESCE(SUM(sc.sale_num * p.buy_price), 0) AS 本月毛利
FROM category c
LEFT JOIN product p ON c.cid = p.cid
LEFT JOIN (
    SELECT pid, SUM(num) AS pur_num 
    FROM purchase 
    WHERE DATE_FORMAT(pur_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
    GROUP BY pid
) pc ON p.pid = pc.pid
LEFT JOIN (
    SELECT pid, SUM(sale_num) AS sale_num, SUM(total_amount) AS sale_amount 
    FROM sale 
    WHERE DATE_FORMAT(sale_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
    GROUP BY pid
) sc ON p.pid = sc.pid
GROUP BY c.cid, c.cname
ORDER BY 本月销售额 DESC;

-- 5. 本月各商品进销存明细
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 分类,
    p.stock AS 当前库存,
    COALESCE(pc.pur_num, 0) AS 本月入库,
    COALESCE(sc.sale_num, 0) AS 本月销售,
    p.stock + COALESCE(pc.pur_num, 0) - COALESCE(sc.sale_num, 0) AS 期末库存
FROM product p
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN (
    SELECT pid, SUM(num) AS pur_num 
    FROM purchase 
    WHERE DATE_FORMAT(pur_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
    GROUP BY pid
) pc ON p.pid = pc.pid
LEFT JOIN (
    SELECT pid, SUM(sale_num) AS sale_num 
    FROM sale 
    WHERE DATE_FORMAT(sale_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
    GROUP BY pid
) sc ON p.pid = sc.pid
ORDER BY c.cname, p.pname;

-- 6. 指定月份进销存汇总（参数化查询示例）
SELECT 
    DATE_FORMAT(pur_date, '%Y-%m') AS 月份,
    COUNT(DISTINCT pid) AS 入库商品种类,
    SUM(num) AS 总入库数量,
    SUM(total_amount) AS 总入库金额
FROM purchase
WHERE pur_date BETWEEN '2026-01-01' AND '2026-01-31'
GROUP BY DATE_FORMAT(pur_date, '%Y-%m');

SELECT 
    DATE_FORMAT(sale_date, '%Y-%m') AS 月份,
    COUNT(DISTINCT pid) AS 销售商品种类,
    SUM(sale_num) AS 总销售数量,
    SUM(total_amount) AS 总销售额
FROM sale
WHERE sale_date BETWEEN '2026-01-01' AND '2026-01-31'
GROUP BY DATE_FORMAT(sale_date, '%Y-%m');

-- 7. 季度进销存统计
SELECT 
    QUARTER(pur_date) AS 季度,
    YEAR(pur_date) AS 年份,
    SUM(total_amount) AS 季度入库金额
FROM purchase
WHERE YEAR(pur_date) = 2026
GROUP BY QUARTER(pur_date), YEAR(pur_date)
ORDER BY 季度;

-- =============================================
-- 第三部分：供应商供货排行
-- =============================================

-- 8. 供应商供货金额排行
SELECT 
    s.supplier_id AS 供应商ID,
    s.supplier_name AS 供应商名称,
    s.phone AS 联系电话,
    COUNT(DISTINCT p.pid) AS 供应商品种数,
    SUM(pc.pur_num) AS 总供货数量,
    SUM(pc.pur_amount) AS 总供货金额,
    RANK() OVER (ORDER BY SUM(pc.pur_amount) DESC) AS 供货金额排名
FROM suppliers s
LEFT JOIN (
    SELECT supplier_id, pid, SUM(num) AS pur_num, SUM(total_amount) AS pur_amount
    FROM purchase
    GROUP BY supplier_id, pid
) pc ON s.supplier_id = pc.supplier_id
LEFT JOIN product p ON pc.pid = p.pid
GROUP BY s.supplier_id, s.supplier_name, s.phone
ORDER BY 总供货金额 DESC;

-- 9. 各供应商供货商品明细
SELECT 
    s.supplier_name AS 供应商名称,
    p.pname AS 商品名称,
    c.cname AS 商品分类,
    SUM(pur.num) AS 累计供货数量,
    SUM(pur.total_amount) AS 累计供货金额,
    MAX(pur.pur_date) AS 最近供货日期
FROM suppliers s
INNER JOIN purchase pur ON s.supplier_id = pur.supplier_id
INNER JOIN product p ON pur.pid = p.pid
LEFT JOIN category c ON p.cid = c.cid
GROUP BY s.supplier_id, s.supplier_name, p.pid, p.pname, c.cname
ORDER BY s.supplier_name, 累计供货金额 DESC;

-- 10. 供应商供货稳定性分析（按月统计）
SELECT 
    s.supplier_name AS 供应商名称,
    DATE_FORMAT(pur.pur_date, '%Y-%m') AS 供货月份,
    COUNT(*) AS 供货次数,
    SUM(pur.num) AS 供货数量,
    SUM(pur.total_amount) AS 供货金额
FROM suppliers s
INNER JOIN purchase pur ON s.supplier_id = pur.supplier_id
WHERE YEAR(pur.pur_date) = 2026
GROUP BY s.supplier_name, DATE_FORMAT(pur.pur_date, '%Y-%m')
ORDER BY s.supplier_name, 供货月份;

-- =============================================
-- 第四部分：滞销商品筛选
-- =============================================

-- 11. 滞销商品（连续30天无销售）
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 商品分类,
    p.stock AS 当前库存,
    p.sale_price AS 销售价,
    COALESCE(MAX(s.sale_date), '从未销售') AS 最后销售日期,
    DATEDIFF(CURDATE(), COALESCE(MAX(s.sale_date), CURDATE())) AS 无销售天数
FROM product p
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN sale s ON p.pid = s.pid
GROUP BY p.pid, p.pname, c.cname, p.stock, p.sale_price
HAVING DATEDIFF(CURDATE(), COALESCE(MAX(s.sale_date), CURDATE())) > 30
ORDER BY 无销售天数 DESC;

-- 12. 滞销商品库存占比分析
SELECT 
    c.cname AS 商品分类,
    COUNT(DISTINCT p.pid) AS 商品总数,
    COUNT(DISTINCT CASE WHEN DATEDIFF(CURDATE(), COALESCE(MAX(s.sale_date), CURDATE())) > 30 THEN p.pid END) AS 滞销商品数,
    ROUND(COUNT(DISTINCT CASE WHEN DATEDIFF(CURDATE(), COALESCE(MAX(s.sale_date), CURDATE())) > 30 THEN p.pid END) / COUNT(DISTINCT p.pid) * 100, 2) AS 滞销占比
FROM product p
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN sale s ON p.pid = s.pid
GROUP BY c.cid, c.cname
ORDER BY 滞销占比 DESC;

-- 13. 长期零销售商品（入库超过30天从未销售）
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 分类,
    p.stock AS 库存数量,
    MIN(pur.pur_date) AS 首次入库日期,
    DATEDIFF(CURDATE(), MIN(pur.pur_date)) AS 在库天数
FROM product p
INNER JOIN purchase pur ON p.pid = pur.pid
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN sale s ON p.pid = s.pid
GROUP BY p.pid, p.pname, c.cname, p.stock
HAVING MAX(s.sale_date) IS NULL AND DATEDIFF(CURDATE(), MIN(pur.pur_date)) > 30
ORDER BY 在库天数 DESC;

-- =============================================
-- 第五部分：销售排行榜
-- =============================================

-- 14. 商品销售排行榜（按销售数量）
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 商品分类,
    SUM(s.sale_num) AS 总销售数量,
    SUM(s.total_amount) AS 总销售额,
    RANK() OVER (ORDER BY SUM(s.sale_num) DESC) AS 销量排名,
    ROUND(SUM(s.total_amount) / SUM(s.sale_num), 2) AS 平均单价
FROM product p
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN sale s ON p.pid = s.pid
GROUP BY p.pid, p.pname, c.cname
HAVING SUM(s.sale_num) > 0
ORDER BY 总销售数量 DESC
LIMIT 20;

-- 15. 商品销售排行榜（按销售额）
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 商品分类,
    SUM(s.sale_num) AS 总销售数量,
    SUM(s.total_amount) AS 总销售额,
    RANK() OVER (ORDER BY SUM(s.total_amount) DESC) AS 销售额排名,
    p.stock AS 当前库存
FROM product p
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN sale s ON p.pid = s.pid
GROUP BY p.pid, p.pname, c.cname, p.stock
HAVING SUM(s.total_amount) > 0
ORDER BY 总销售额 DESC
LIMIT 20;

-- =============================================
-- 第六部分：利润分析
-- =============================================

-- 16. 商品利润分析
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 分类,
    p.buy_price AS 进货价,
    p.sale_price AS 销售价,
    ROUND((p.sale_price - p.buy_price) / p.buy_price * 100, 2) AS 毛利率,
    SUM(s.sale_num) AS 销售数量,
    SUM(s.total_amount) AS 销售额,
    SUM(s.sale_num * p.buy_price) AS 成本总额,
    SUM(s.total_amount) - SUM(s.sale_num * p.buy_price) AS 毛利总额
FROM product p
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN sale s ON p.pid = s.pid
GROUP BY p.pid, p.pname, c.cname, p.buy_price, p.sale_price
HAVING SUM(s.sale_num) > 0
ORDER BY 毛利率 DESC;

-- 17. 分类利润汇总
SELECT 
    c.cname AS 分类名称,
    COUNT(DISTINCT p.pid) AS 商品种数,
    SUM(s.sale_num) AS 销售总量,
    SUM(s.total_amount) AS 销售总额,
    SUM(s.sale_num * p.buy_price) AS 成本总额,
    SUM(s.total_amount) - SUM(s.sale_num * p.buy_price) AS 分类毛利,
    ROUND((SUM(s.total_amount) - SUM(s.sale_num * p.buy_price)) / SUM(s.total_amount) * 100, 2) AS 分类毛利率
FROM product p
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN sale s ON p.pid = s.pid
GROUP BY c.cid, c.cname
HAVING SUM(s.total_amount) > 0
ORDER BY 分类毛利 DESC;

-- =============================================
-- 第七部分：综合查询
-- =============================================

-- 18. 库存与销售综合分析表
SELECT 
    p.pid AS 商品ID,
    p.pname AS 商品名称,
    c.cname AS 分类,
    p.stock AS 当前库存,
    p.warn_num AS 预警线,
    COALESCE(SUM(pur.num), 0) AS 历史入库总量,
    COALESCE(SUM(s.sale_num), 0) AS 历史销售总量,
    p.stock + COALESCE(SUM(s.sale_num), 0) - COALESCE(SUM(pur.num), 0) AS 账目差异,
    CASE 
        WHEN p.stock = 0 THEN '缺货'
        WHEN p.stock < p.warn_num THEN '预警'
        WHEN p.stock > p.warn_num * 3 THEN '积压'
        ELSE '正常'
    END AS 库存状态
FROM product p
LEFT JOIN category c ON p.cid = c.cid
LEFT JOIN purchase pur ON p.pid = pur.pid
LEFT JOIN sale s ON p.pid = s.pid
GROUP BY p.pid, p.pname, c.cname, p.stock, p.warn_num
ORDER BY c.cname, p.pname;
