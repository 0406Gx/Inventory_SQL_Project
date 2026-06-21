-- =============================================
-- 进销存数据库 - 简化版建表语句
-- 按正确顺序创建表，避免外键依赖问题
-- =============================================

USE inventory_db;

-- 1. 供应商表（无外键依赖）
DROP TABLE IF EXISTS suppliers;
CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '供应商ID',
    supplier_name VARCHAR(100) NOT NULL COMMENT '供应商名称',
    phone VARCHAR(20) COMMENT '联系方式',
    address VARCHAR(200) COMMENT '供应商地址',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. 商品分类表（无外键依赖）
DROP TABLE IF EXISTS category;
CREATE TABLE category (
    cid INT AUTO_INCREMENT PRIMARY KEY COMMENT '分类ID',
    cname VARCHAR(50) NOT NULL COMMENT '分类名称',
    parent_id INT DEFAULT 0 COMMENT '父分类ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. 商品表（依赖 category）
DROP TABLE IF EXISTS product;
CREATE TABLE product (
    pid INT AUTO_INCREMENT PRIMARY KEY COMMENT '商品ID',
    pname VARCHAR(100) NOT NULL COMMENT '商品名称',
    cid INT COMMENT '分类ID',
    buy_price DECIMAL(10,2) COMMENT '进货价',
    sale_price DECIMAL(10,2) COMMENT '销售价',
    stock INT DEFAULT 0 COMMENT '库存数量',
    warn_num INT DEFAULT 10 COMMENT '库存预警线',
    unit VARCHAR(20) DEFAULT '件' COMMENT '单位',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. 入库单表（依赖 product 和 suppliers）
DROP TABLE IF EXISTS purchase;
CREATE TABLE purchase (
    pur_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '入库单ID',
    pid INT COMMENT '商品ID',
    supplier_id INT COMMENT '供应商ID',
    pur_date DATE COMMENT '入库日期',
    num INT NOT NULL COMMENT '入库数量',
    unit_price DECIMAL(10,2) COMMENT '进货单价',
    total_amount DECIMAL(12,2) COMMENT '总金额',
    operator VARCHAR(50) COMMENT '操作员',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. 销售单表（依赖 product）
DROP TABLE IF EXISTS sale;
CREATE TABLE sale (
    sale_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '销售单ID',
    pid INT COMMENT '商品ID',
    sale_date DATE COMMENT '销售日期',
    sale_num INT NOT NULL COMMENT '销售数量',
    unit_price DECIMAL(10,2) COMMENT '销售单价',
    total_amount DECIMAL(12,2) COMMENT '总金额',
    customer_name VARCHAR(100) COMMENT '客户名称',
    operator VARCHAR(50) COMMENT '操作员',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 添加外键约束（在所有表创建完成后添加）
ALTER TABLE product ADD CONSTRAINT fk_product_category FOREIGN KEY (cid) REFERENCES category(cid) ON DELETE SET NULL;
ALTER TABLE purchase ADD CONSTRAINT fk_purchase_product FOREIGN KEY (pid) REFERENCES product(pid) ON DELETE CASCADE;
ALTER TABLE purchase ADD CONSTRAINT fk_purchase_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL;
ALTER TABLE sale ADD CONSTRAINT fk_sale_product FOREIGN KEY (pid) REFERENCES product(pid) ON DELETE CASCADE;

-- =============================================
-- 插入测试数据
-- =============================================

-- 插入供应商数据
INSERT INTO suppliers (supplier_name, phone, address) VALUES
('华强电子有限公司', '0755-12345678', '深圳市福田区华强北路100号'),
('光明食品批发部', '021-87654321', '上海市静安区南京路200号'),
('金鑫五金建材', '020-11223344', '广州市天河区珠江新城'),
('华北物资供应中心', '022-99887766', '天津市和平区解放路'),
('成都川味调料厂', '028-87651234', '成都市锦江区春熙路'),
('浙江义乌小商品', '0579-23456789', '金华市义乌市稠州北路'),
('北京中关村电脑城', '010-88226655', '北京市海淀区中关村大街'),
('苏州丝绸制品厂', '0512-66778899', '苏州市姑苏区观前街'),
('广州服装批发市场', '020-33445566', '广州市越秀区流花路'),
('武汉光谷科技', '027-77889900', '武汉市洪山区光谷大道');

-- 插入商品分类数据
INSERT INTO category (cname, parent_id) VALUES
('电子产品', 0),
('食品饮料', 0),
('五金建材', 0),
('服装鞋帽', 0),
('办公用品', 0),
('电脑配件', 1),
('数码产品', 1),
('休闲食品', 2),
('粮油调味', 2),
('钢材', 3);

-- 插入商品数据（包含预警和积压状态）
INSERT INTO product (pname, cid, buy_price, sale_price, stock, warn_num, unit) VALUES
('联想ThinkPad笔记本', 6, 4500.00, 5200.00, 3, 5, '台'),        -- 预警
('Dell显示器24寸', 6, 800.00, 999.00, 8, 10, '台'),           -- 预警
('罗技无线鼠标', 6, 45.00, 89.00, 200, 30, '个'),             -- 积压
('金士顿8G内存条', 6, 180.00, 259.00, 18, 20, '条'),           -- 预警
('三星256G固态硬盘', 6, 380.00, 499.00, 12, 15, '个'),         -- 预警
('小米手机红米Note', 7, 750.00, 999.00, 18, 20, '台'),         -- 预警
('华为路由器', 7, 120.00, 199.00, 8, 10, '台'),                -- 预警
('洽洽瓜子500g', 8, 8.50, 15.00, 80, 100, '袋'),              -- 预警
('旺旺雪饼500g', 8, 7.00, 12.50, 95, 100, '袋'),              -- 预警
('农夫山泉550ml', 8, 1.00, 2.50, 280, 300, '瓶'),             -- 预警
('可口可乐330ml', 8, 1.80, 3.50, 180, 200, '罐'),             -- 预警
('金龙鱼调和油5L', 9, 55.00, 78.00, 35, 40, '桶'),            -- 预警
('海天酱油1.9L', 9, 12.00, 18.00, 280, 50, '瓶'),             -- 积压
('螺纹钢筋Φ12', 10, 3200.00, 3800.00, 8, 10, '吨'),           -- 预警
('槽钢10#', 10, 2800.00, 3400.00, 3, 5, '吨'),                -- 预警
('油漆白色5L', 3, 80.00, 128.00, 18, 20, '桶'),               -- 预警
('工具箱家用', 3, 65.00, 108.00, 12, 15, '个'),                -- 预警
('西装男款黑色', 4, 280.00, 458.00, 6, 8, '套'),               -- 预警
('运动鞋男', 4, 150.00, 268.00, 10, 12, '双'),                -- 预警
('A4复印纸500张', 5, 18.00, 28.00, 130, 150, '包'),           -- 预警
('得力订书机', 5, 12.00, 22.00, 35, 40, '个'),                -- 预警
('晨光中性笔黑色', 5, 1.00, 2.00, 480, 500, '支'),            -- 预警
('HP墨盒黑色', 5, 85.00, 148.00, 20, 25, '个'),               -- 预警
('美的电饭煲', 1, 220.00, 358.00, 6, 8, '台'),                -- 预警
('苏泊尔炒锅', 1, 150.00, 248.00, 8, 10, '口');

-- 插入入库单数据
INSERT INTO purchase (pid, supplier_id, pur_date, num, unit_price, total_amount, operator) VALUES
(1, 7, '2026-01-03', 10, 4500.00, 45000.00, '张三'),
(2, 7, '2026-01-05', 20, 800.00, 16000.00, '张三'),
(3, 7, '2026-01-07', 50, 45.00, 2250.00, '李四'),
(4, 7, '2026-01-10', 30, 180.00, 5400.00, '李四'),
(5, 7, '2026-01-12', 25, 380.00, 9500.00, '王五'),
(6, 1, '2026-01-15', 40, 750.00, 30000.00, '王五'),
(7, 1, '2026-01-18', 30, 120.00, 3600.00, '赵六'),
(8, 2, '2026-01-20', 100, 8.50, 850.00, '赵六'),
(9, 2, '2026-01-22', 120, 7.00, 840.00, '孙七'),
(10, 2, '2026-01-25', 200, 1.00, 200.00, '孙七'),
(11, 2, '2026-01-28', 150, 1.80, 270.00, '周八'),
(12, 2, '2026-02-01', 50, 55.00, 2750.00, '周八'),
(13, 2, '2026-02-05', 80, 12.00, 960.00, '吴九'),
(14, 3, '2026-02-08', 15, 3200.00, 48000.00, '吴九'),
(15, 3, '2026-02-10', 10, 2800.00, 28000.00, '郑十'),
(16, 4, '2026-02-15', 30, 80.00, 2400.00, '郑十'),
(17, 4, '2026-02-18', 25, 65.00, 1625.00, '张小'),
(18, 5, '2026-02-20', 15, 280.00, 4200.00, '张小'),
(19, 5, '2026-02-22', 20, 150.00, 3000.00, '李大'),
(20, 6, '2026-02-25', 100, 18.00, 1800.00, '李大'),
(21, 6, '2026-02-28', 50, 12.00, 600.00, '王二'),
(22, 6, '2026-03-02', 200, 1.00, 200.00, '王二'),
(23, 6, '2026-03-05', 40, 85.00, 3400.00, '王二'),
(24, 8, '2026-03-08', 20, 220.00, 4400.00, '刘三'),
(25, 8, '2026-03-10', 15, 150.00, 2250.00, '刘三');

-- 插入销售单数据
INSERT INTO sale (pid, sale_date, sale_num, unit_price, total_amount, customer_name, operator) VALUES
(1, '2026-01-05', 3, 5200.00, 15600.00, '深圳腾讯科技', '张三'),
(2, '2026-01-08', 8, 999.00, 7992.00, '广州小米之家', '张三'),
(3, '2026-01-10', 25, 89.00, 2225.00, '东莞电脑店', '李四'),
(4, '2026-01-12', 15, 259.00, 3885.00, '佛山数码广场', '李四'),
(5, '2026-01-15', 10, 499.00, 4990.00, '中山存储专家', '王五'),
(6, '2026-01-18', 20, 999.00, 19980.00, '珠海手机城', '王五'),
(7, '2026-01-20', 12, 199.00, 2388.00, '惠州网络设备店', '赵六'),
(8, '2026-01-22', 80, 15.00, 1200.00, '汕头零食批发', '赵六'),
(9, '2026-01-25', 60, 12.50, 750.00, '揭阳便利店', '孙七'),
(10, '2026-01-28', 150, 2.50, 375.00, '潮州超市', '孙七'),
(11, '2026-02-01', 100, 3.50, 350.00, '厦门饮料批发', '周八'),
(12, '2026-02-05', 25, 78.00, 1950.00, '福州永辉超市', '周八'),
(13, '2026-02-08', 40, 18.00, 720.00, '泉州调味品店', '吴九'),
(14, '2026-02-10', 8, 3800.00, 30400.00, '莆田建材市场', '吴九'),
(15, '2026-02-12', 5, 3400.00, 17000.00, '三明钢材经销商', '郑十'),
(16, '2026-02-15', 15, 128.00, 1920.00, '漳州油漆店', '郑十'),
(17, '2026-02-18', 12, 108.00, 1296.00, '龙岩五金工具店', '张小'),
(18, '2026-02-20', 8, 458.00, 3664.00, '宁德服装店', '张小'),
(19, '2026-02-22', 10, 268.00, 2680.00, '南平鞋业批发', '李大'),
(20, '2026-02-25', 50, 28.00, 1400.00, '杭州文具批发', '李大'),
(21, '2026-02-28', 30, 22.00, 660.00, '宁波办公用品', '王二'),
(22, '2026-03-02', 120, 2.00, 240.00, '温州文化用品', '王二'),
(23, '2026-03-05', 20, 148.00, 2960.00, '义乌打印耗材', '王二'),
(24, '2026-03-08', 10, 358.00, 3580.00, '金华家用电器', '刘三'),
(25, '2026-03-10', 8, 248.00, 1984.00, '台州厨具店', '刘三');

-- 验证数据
SELECT '供应商表' as 表名, COUNT(*) as 记录数 FROM suppliers
UNION ALL SELECT '商品分类表', COUNT(*) FROM category
UNION ALL SELECT '商品表', COUNT(*) FROM product
UNION ALL SELECT '入库单表', COUNT(*) FROM purchase
UNION ALL SELECT '销售单表', COUNT(*) FROM sale;
