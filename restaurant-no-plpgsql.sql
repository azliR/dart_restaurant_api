DROP SCHEMA public CASCADE;

CREATE SCHEMA public;

CREATE TYPE discount_type_enum AS ENUM ('fixed', 'percentage');

CREATE TYPE order_status_enum AS ENUM (
    'pending',
    'preparing',
    'ready',
    'complete',
    'cancelled'
);

CREATE TYPE order_type_enum AS ENUM ('scheduled', 'now');

CREATE TYPE pickup_type_enum AS ENUM ('pickup', 'dine-in');

CREATE TYPE store_role_enum AS ENUM ('admin', 'staff');

CREATE TABLE coupons (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    inserted_by UUID NOT NULL,
    coupon_code VARCHAR(16) NOT NULL,
    name VARCHAR(64) NOT NULL,
    description VARCHAR(255),
    expiry_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    discount_type discount_type_enum NOT NULL,
    discount DECIMAL(11, 2) NOT NULL,
    min_total DECIMAL(11, 2) NOT NULL,
    max_discount DECIMAL(11, 2) NOT NULL,
    max_number_use_total INTEGER,
    max_number_use_customer INTEGER NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    all_store BOOLEAN NOT NULL,
    all_customer BOOLEAN NOT NULL,
    is_valid BOOLEAN NOT NULL,
    CONSTRAINT pk_coupons PRIMARY KEY (id)
);

CREATE TABLE coupon_customers(
    coupon_id UUID NOT NULL,
    customer_id UUID NOT NULL,
    CONSTRAINT pk_coupon_customers PRIMARY KEY (coupon_id, customer_id)
);

CREATE TABLE coupon_stores(
    coupon_id UUID NOT NULL,
    store_id UUID NOT NULL,
    CONSTRAINT pk_coupon_stores PRIMARY KEY (coupon_id, store_id)
);

CREATE TABLE customers (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    full_name VARCHAR(64) NOT NULL,
    phone VARCHAR(16) NOT NULL,
    language_code VARCHAR(2) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (id)
);

CREATE TABLE items (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL,
    category_id UUID NOT NULL,
    sub_category_id UUID,
    name VARCHAR(64) NOT NULL,
    picture TEXT,
    price DECIMAL(11, 2) NOT NULL,
    special_offer DECIMAL(11, 2) NULL,
    description VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_items PRIMARY KEY (id)
);

CREATE TABLE item_addons (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    addon_category_id UUID NOT NULL,
    name VARCHAR(64) NOT NULL,
    price DECIMAL(11, 2) NOT NULL,
    CONSTRAINT pk_item_addons PRIMARY KEY (id)
);

CREATE TABLE item_addon_categories (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL,
    name VARCHAR(64) NOT NULL,
    description VARCHAR(255),
    is_multiple_choice BOOLEAN NOT NULL,
    CONSTRAINT pk_item_addon_categories PRIMARY KEY (id)
);

CREATE TABLE item_categories (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    name VARCHAR(64) NOT NULL,
    CONSTRAINT pk_item_categories PRIMARY KEY (id)
);

CREATE TABLE item_category_l10ns (
    category_id UUID NOT NULL,
    language_code VARCHAR(2) NOT NULL,
    name VARCHAR(64) NOT NULL,
    CONSTRAINT pk_item_category_l10ns PRIMARY KEY (category_id, language_code)
);

CREATE TABLE item_sub_categories (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL,
    name VARCHAR(64) NOT NULL,
    CONSTRAINT pk_item_sub_categories PRIMARY KEY (id)
);

CREATE TABLE item_sub_category_l10ns (
    sub_category_id UUID NOT NULL,
    language_code VARCHAR(2) NOT NULL,
    name VARCHAR(64) NOT NULL,
    CONSTRAINT pk_item_sub_category_l10ns PRIMARY KEY (sub_category_id, language_code)
);

CREATE TABLE orders (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    store_id UUID NOT NULL,
    store_account_id UUID,
    table_id UUID,
    coupon_id UUID,
    buyer VARCHAR(64) NOT NULL,
    store_image TEXT,
    store_banner TEXT,
    table_price DECIMAL(11, 2),
    brutto DECIMAL(11, 2) NOT NULL,
    netto DECIMAL(11, 2) NOT NULL,
    coupon_code VARCHAR(16),
    coupon_name VARCHAR(64),
    discount DECIMAL(11, 2),
    discount_nominal DECIMAL(11, 2),
    status order_status_enum NOT NULL,
    order_type order_type_enum NOT NULL,
    scheduled_at TIMESTAMP WITHOUT TIME ZONE,
    pickup_type pickup_type_enum NOT NULL,
    rating DECIMAL(2, 1),
    comment VARCHAR(255),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (id)
);

CREATE TABLE order_details (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    item_id UUID NOT NULL,
    item_name VARCHAR(64) NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(11, 2) NOT NULL,
    total DECIMAL(11, 2) NOT NULL,
    picture TEXT,
    item_detail VARCHAR(255),
    CONSTRAINT pk_order_details PRIMARY KEY (id)
);

CREATE TABLE order_detail_addons (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    order_detail_id UUID NOT NULL,
    addon_id UUID NOT NULL,
    addon_name VARCHAR(64) NOT NULL,
    price DECIMAL(11, 2) NOT NULL,
    CONSTRAINT pk_order_detail_addons PRIMARY KEY (id)
);

CREATE TABLE postcodes (
    postcode VARCHAR(5) NOT NULL,
    city VARCHAR(128) NOT NULL,
    state VARCHAR(128) NOT NULL,
    country VARCHAR(56) NOT NULL,
    CONSTRAINT pk_postcodes PRIMARY KEY (postcode)
);

CREATE TABLE reservation_tables (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL,
    name VARCHAR(64) NOT NULL,
    max_person INTEGER NOT NULL,
    book_price DECIMAL(11, 2) NOT NULL,
    CONSTRAINT pk_reservation_tables PRIMARY KEY (id)
);

CREATE TABLE stores (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    store_admin_id UUID NOT NULL,
    name VARCHAR(64) NOT NULL,
    description VARCHAR(255),
    image TEXT,
    banner TEXT,
    phone VARCHAR(16) NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    postcode VARCHAR(5) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    rating DECIMAL(2, 1),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_stores PRIMARY KEY (id)
);

CREATE TABLE store_pickup_types (
    store_id UUID NOT NULL,
    pickup_type pickup_type_enum NOT NULL,
    CONSTRAINT pk_store_pickup_types PRIMARY KEY (store_id, pickup_type)
);

CREATE TABLE store_accounts (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    full_name VARCHAR(64) NOT NULL,
    role store_role_enum NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_store_accounts PRIMARY KEY (id)
);

CREATE TABLE store_admins (
    store_account_id UUID NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    token_reset_password VARCHAR(255),
    token_expired_at TIMESTAMP WITHOUT TIME ZONE,
    last_updated_password TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT pk_store_admins PRIMARY KEY (store_account_id)
);

CREATE TABLE store_staffs (
    store_account_id UUID NOT NULL,
    store_id UUID NOT NULL,
    username VARCHAR(36) NOT NULL,
    password VARCHAR(255) NOT NULL,
    is_locked BOOLEAN DEFAULT FALSE NOT NULL,
    CONSTRAINT pk_store_staffs PRIMARY KEY (store_account_id)
);

CREATE UNIQUE INDEX uk_coupons_on_coupon_code_is_valid ON coupons(coupon_code, is_valid);

CREATE UNIQUE INDEX uk_customers_on_phone ON customers(phone);

CREATE UNIQUE INDEX uk_stores_on_store_admin_id ON stores(store_admin_id);

CREATE UNIQUE INDEX uk_stores_on_phone ON stores(phone);

CREATE UNIQUE INDEX uk_store_admins_on_email ON store_admins(email);

CREATE UNIQUE INDEX uk_store_staffs_on_store_id_username ON store_staffs(store_id, username);

ALTER TABLE coupons
ADD CONSTRAINT fk_coupons_on_inserted_by FOREIGN KEY (inserted_by) REFERENCES store_admins (store_account_id);

ALTER TABLE coupon_customers
ADD CONSTRAINT fk_coupon_customers_on_coupon FOREIGN KEY (coupon_id) REFERENCES coupons (id);

ALTER TABLE coupon_customers
ADD CONSTRAINT fk_coupon_customers_on_customer FOREIGN KEY (customer_id) REFERENCES customers (id);

ALTER TABLE coupon_stores
ADD CONSTRAINT fk_coupon_stores_on_coupon FOREIGN KEY (coupon_id) REFERENCES coupons (id);

ALTER TABLE coupon_stores
ADD CONSTRAINT fk_coupon_stores_on_store FOREIGN KEY (store_id) REFERENCES stores (id);

ALTER TABLE items
ADD CONSTRAINT fk_items_on_store FOREIGN KEY (store_id) REFERENCES stores (id);

ALTER TABLE items
ADD CONSTRAINT fk_items_on_category FOREIGN KEY (category_id) REFERENCES item_categories (id);

ALTER TABLE items
ADD CONSTRAINT fk_items_on_sub_category FOREIGN KEY (sub_category_id) REFERENCES item_sub_categories (id);

ALTER TABLE item_addons
ADD CONSTRAINT fk_item_addons_on_addon_category FOREIGN KEY (addon_category_id) REFERENCES item_addon_categories (id);

ALTER TABLE item_addon_categories
ADD CONSTRAINT fk_item_addon_categories_on_item FOREIGN KEY (item_id) REFERENCES items (id);

ALTER TABLE item_category_l10ns
ADD CONSTRAINT fk_item_category_l10ns_on_category FOREIGN KEY (category_id) REFERENCES item_categories (id);

ALTER TABLE item_sub_categories
ADD CONSTRAINT fk_item_sub_categories_on_category FOREIGN KEY (store_id) REFERENCES stores (id);

ALTER TABLE item_sub_category_l10ns
ADD CONSTRAINT fk_item_sub_category_l10ns_on_sub_category FOREIGN KEY (sub_category_id) REFERENCES item_sub_categories (id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_on_customer FOREIGN KEY (customer_id) REFERENCES customers (id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_on_store FOREIGN KEY (store_id) REFERENCES stores (id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_on_store_account FOREIGN KEY (store_account_id) REFERENCES store_accounts (id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_on_table FOREIGN KEY (table_id) REFERENCES reservation_tables (id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_on_coupon FOREIGN KEY (coupon_id) REFERENCES coupons (id);

ALTER TABLE order_details
ADD CONSTRAINT fk_order_details_on_order FOREIGN KEY (order_id) REFERENCES orders (id);

ALTER TABLE order_details
ADD CONSTRAINT fk_order_details_on_item FOREIGN KEY (item_id) REFERENCES items (id);

ALTER TABLE order_detail_addons
ADD CONSTRAINT fk_order_detail_addons_on_order_detail FOREIGN KEY (order_detail_id) REFERENCES order_details (id);

ALTER TABLE order_detail_addons
ADD CONSTRAINT fk_order_detail_addons_on_addon FOREIGN KEY (addon_id) REFERENCES item_addons (id);

ALTER TABLE reservation_tables
ADD CONSTRAINT fk_reservation_tables_on_store FOREIGN KEY (store_id) REFERENCES stores (id);

ALTER TABLE stores
ADD CONSTRAINT fk_stores_on_postcode FOREIGN KEY (postcode) REFERENCES postcodes (postcode);

ALTER TABLE stores
ADD CONSTRAINT fk_stores_on_store_admins FOREIGN KEY (store_admin_id) REFERENCES store_admins (store_account_id);

ALTER TABLE store_pickup_types
ADD CONSTRAINT fk_store_pickup_types_on_store FOREIGN KEY (store_id) REFERENCES stores (id);

ALTER TABLE store_admins
ADD CONSTRAINT fk_store_admins_on_store_account FOREIGN KEY (store_account_id) REFERENCES store_accounts (id);

ALTER TABLE store_staffs
ADD CONSTRAINT fk_store_staffs_on_store_account FOREIGN KEY (store_account_id) REFERENCES store_accounts (id);

ALTER TABLE store_staffs
ADD CONSTRAINT fk_store_staffs_on_store FOREIGN KEY (store_id) REFERENCES stores (id);

-- insert store_accounts
INSERT INTO store_accounts (id, full_name, role)
VALUES (
        'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f',
        'Rizal Hadiyansah',
        'admin'
    );

-- insert store_admins
INSERT INTO store_admins (
        store_account_id,
        email,
        password,
        token_reset_password
    )
VALUES (
        'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f',
        'rizalhadiyansah@gmail.com',
        '$2a$12$q3mLZR3i86cSR90DSf1X6u1lXfGAy4KILvbxR3fQjDSJVTkSpVEyC',
        NULL
    );

-- insert postcodes
INSERT INTO postcodes(postcode, city, state, country)
VALUES (
        '45595',
        'Kuningan',
        'West Java',
        'Indonesia'
    );

-- insert stores
INSERT INTO stores(
        id,
        store_admin_id,
        name,
        description,
        image,
        banner,
        phone,
        street_address,
        postcode,
        latitude,
        longitude,
        rating
    )
VALUES (
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f',
        'Alpha Store',
        'Alpha Store',
        'https://www.koalahero.com/wp-content/uploads/2019/10/Makanan-McDonald.jpg',
        'https://seeklogo.com/images/M/mcdonald-s-logo-255A7B5646-seeklogo.com.png',
        '08123456789',
        'Jalan Raya Kuningan',
        '45595',
        -6.945171261146366,
        107.70812694679151,
        4.5
    );

-- insert store_pickup_types
INSERT INTO store_pickup_types(store_id, pickup_type)
VALUES (
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'pickup'
    );

-- insert store_pickup_types
INSERT INTO store_pickup_types(store_id, pickup_type)
VALUES (
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'dine-in'
    );

-- insert store_staffs
INSERT INTO store_staffs (
        store_account_id,
        store_id,
        username,
        password,
        is_locked
    )
VALUES (
        'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'a_lpha',
        '$2a$12$q3mLZR3i86cSR90DSf1X6u1lXfGAy4KILvbxR3fQjDSJVTkSpVEyC',
        FALSE
    );

-- insert reservation_tables
INSERT INTO reservation_tables (id, store_id, name, max_person, book_price)
VALUES (
        '947898b3-be6c-4a70-86b8-2286154af42b',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Table 1',
        2,
        10000
    );

-- insert item_categories
INSERT INTO item_categories (id, name)
VALUES (
        '00b1347c-0d82-4c1b-adcb-28247d299170',
        'Burgers'
    );

-- insert item_category_l10ns
INSERT INTO item_category_l10ns (category_id, language_code, name)
VALUES (
        '00b1347c-0d82-4c1b-adcb-28247d299170',
        'id',
        'Burger'
    );

-- insert item_sub_categories
INSERT INTO item_sub_categories (id, store_id, name)
VALUES (
        'db126848-5a16-4723-bcb1-524695a0d286',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Breakfasts'
    );

-- insert item_sub_category_l10ns
INSERT INTO item_sub_category_l10ns (sub_category_id, language_code, name)
VALUES (
        'db126848-5a16-4723-bcb1-524695a0d286',
        'id',
        'Sarapan'
    );

-- insert items
INSERT INTO items (
        id,
        store_id,
        category_id,
        sub_category_id,
        name,
        picture,
        price,
        special_offer,
        description
    )
VALUES (
        '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '00b1347c-0d82-4c1b-adcb-28247d299170',
        'db126848-5a16-4723-bcb1-524695a0d286',
        'McDonalds Burger',
        'https://www.koalahero.com/wp-content/uploads/2019/10/Makanan-McDonald.jpg',
        10000,
        9000,
        'McDonalds Burger'
    );

-- insert item_addon_categories
INSERT INTO item_addon_categories (
        id,
        item_id,
        name,
        description,
        is_multiple_choice
    )
VALUES (
        '17b3be90-d177-4e59-8582-cf6c97f94aa9',
        '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae',
        'Add on',
        'Makin enak tambah add on',
        TRUE
    );

-- insert item_addons
INSERT INTO item_addons (id, addon_category_id, name, price)
VALUES (
        'cb6c9073-8680-4a6a-85a4-bf9bb7c91ee3',
        '17b3be90-d177-4e59-8582-cf6c97f94aa9',
        'Extra sauce Kari Spesial',
        5000
    );

-- insert customers
INSERT INTO customers (id, full_name, phone, language_code)
VALUES (
        '1c7b3156-986b-487b-8d6c-2db03806ca30',
        'Rizal Hadiyansah',
        '08123456789',
        'en'
    );

-- insert coupons
INSERT INTO coupons (
        id,
        inserted_by,
        coupon_code,
        name,
        description,
        expiry_date,
        discount_type,
        discount,
        min_total,
        max_discount,
        max_number_use_total,
        max_number_use_customer,
        all_store,
        all_customer,
        is_valid
    )
VALUES (
        '19fb0734-01a4-40a1-a95e-ff6d18fc2af6',
        'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f',
        'BREAK',
        'Coupon New Customer',
        'This coupon is for new customer from store Alpha Store',
        '2023-01-01',
        'percentage',
        10,
        0,
        20000,
        NULL,
        1,
        FALSE,
        FALSE,
        TRUE
    );

-- insert coupon_customers
INSERT INTO coupon_customers (coupon_id, customer_id)
VALUES (
        '19fb0734-01a4-40a1-a95e-ff6d18fc2af6',
        '1c7b3156-986b-487b-8d6c-2db03806ca30'
    );

-- insert coupon_stores
INSERT INTO coupon_stores (coupon_id, store_id)
VALUES (
        '19fb0734-01a4-40a1-a95e-ff6d18fc2af6',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d'
    );

-- insert orders
INSERT INTO orders (
        id,
        customer_id,
        store_id,
        store_account_id,
        table_id,
        coupon_id,
        buyer,
        store_image,
        store_banner,
        table_price,
        brutto,
        netto,
        coupon_code,
        coupon_name,
        discount,
        discount_nominal,
        status,
        order_type,
        scheduled_at,
        pickup_type,
        rating,
        comment
    )
VALUES (
        'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c',
        '1c7b3156-986b-487b-8d6c-2db03806ca30',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f',
        '947898b3-be6c-4a70-86b8-2286154af42b',
        '19fb0734-01a4-40a1-a95e-ff6d18fc2af6',
        'Rizal Hadiyansah',
        'https://www.koalahero.com/wp-content/uploads/2019/10/Makanan-McDonald.jpg',
        'https://seeklogo.com/images/M/mcdonald-s-logo-255A7B5646-seeklogo.com.png',
        10000,
        38000,
        34200,
        'BREAK',
        'Coupon New Customer',
        10,
        3800,
        'pending',
        'scheduled',
        '2022-05-04',
        'dine-in',
        4.0,
        'Not bad'
    );

-- insert order_details
INSERT INTO order_details (
        id,
        order_id,
        item_id,
        item_name,
        quantity,
        price,
        total,
        picture,
        item_detail
    )
VALUES (
        '2cb56b76-c756-4b57-ac66-1f346e4bc065',
        'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c',
        '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae',
        'McDonalds Burger',
        2,
        9000,
        28000,
        'https://www.koalahero.com/wp-content/uploads/2019/10/Makanan-McDonald.jpg',
        ''
    );

-- insert order_detail_addons
INSERT INTO order_detail_addons (id, order_detail_id, addon_id, addon_name, price)
VALUES (
        '92120f69-a875-4389-a835-33e46c36a3e0',
        '2cb56b76-c756-4b57-ac66-1f346e4bc065',
        'cb6c9073-8680-4a6a-85a4-bf9bb7c91ee3',
        'Extra sauce Kari Spesial',
        5000
    );

--
--
-- UPDATE
--
UPDATE coupons
SET "name" = 'Coupon For New Customer',
    expiry_date = '2022-12-13'
WHERE id = '19fb0734-01a4-40a1-a95e-ff6d18fc2af6';

UPDATE customers
SET language_code = 'id'
WHERE id = '1c7b3156-986b-487b-8d6c-2db03806ca30';

UPDATE item_addon_categories
SET description = 'Makin enak tambah add on!'
WHERE id = '17b3be90-d177-4e59-8582-cf6c97f94aa9';

UPDATE item_addons
SET "name" = 'Extra sauce kari spesial',
    price = 4000
WHERE id = 'cb6c9073-8680-4a6a-85a4-bf9bb7c91ee3';

UPDATE item_categories
SET "name" = 'Pizza'
WHERE id = '00b1347c-0d82-4c1b-adcb-28247d299170';

UPDATE item_category_l10ns
SET "name" = 'Pizza'
WHERE category_id = '00b1347c-0d82-4c1b-adcb-28247d299170'
    AND language_code = 'id';

UPDATE item_sub_categories
SET "name" = 'Breakfast menus'
WHERE id = 'db126848-5a16-4723-bcb1-524695a0d286';

UPDATE item_sub_category_l10ns
SET "name" = 'Menu sarapan'
WHERE sub_category_id = 'db126848-5a16-4723-bcb1-524695a0d286'
    AND language_code = 'id';

UPDATE items
SET price = 12000,
    special_offer = 10000
WHERE id = '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae';

UPDATE order_detail_addons
SET price = 4000
WHERE id = '92120f69-a875-4389-a835-33e46c36a3e0';

UPDATE order_details
SET price = 10000,
    total = 29000
WHERE id = '2cb56b76-c756-4b57-ac66-1f346e4bc065';

UPDATE orders
SET "comment" = 'Makanannya enak!'
WHERE id = 'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c';

UPDATE postcodes
SET country = 'Indonesia'
WHERE postcode = '45595';

UPDATE reservation_tables
SET "name" = 'Meja depan'
WHERE id = '947898b3-be6c-4a70-86b8-2286154af42b';

UPDATE store_accounts
SET full_name = 'Alpha'
WHERE id = 'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f';

UPDATE store_admins
SET token_reset_password = '8c23cca8-9089-40a8-a85f-e5f02446e14a',
    token_expired_at = '2022-06-22',
    last_updated_password = now()
WHERE store_account_id = 'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f';

UPDATE store_staffs
SET username = 'rizal'
WHERE store_account_id = 'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f';

UPDATE stores
SET "name" = 'Rizal Store'
WHERE id = '93ab578c-46fa-42f6-b61f-ef13fe13045d';

--
--
-- Delete
DELETE FROM order_detail_addons
WHERE id = '92120f69-a875-4389-a835-33e46c36a3e0';

DELETE FROM order_details
WHERE id = '2cb56b76-c756-4b57-ac66-1f346e4bc065';

DELETE FROM orders
WHERE id = 'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c';

DELETE FROM coupon_stores
WHERE coupon_id = '19fb0734-01a4-40a1-a95e-ff6d18fc2af6'
    AND store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d';

DELETE FROM coupon_customers
WHERE coupon_id = '19fb0734-01a4-40a1-a95e-ff6d18fc2af6'
    AND customer_id = '1c7b3156-986b-487b-8d6c-2db03806ca30';

DELETE FROM coupons
WHERE id = '19fb0734-01a4-40a1-a95e-ff6d18fc2af6';

DELETE FROM customers
WHERE id = '1c7b3156-986b-487b-8d6c-2db03806ca30';

DELETE FROM item_addons
WHERE id = 'cb6c9073-8680-4a6a-85a4-bf9bb7c91ee3';

DELETE FROM item_addon_categories
WHERE id = '17b3be90-d177-4e59-8582-cf6c97f94aa9';

DELETE FROM items
WHERE id = '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae';

DELETE FROM item_sub_category_l10ns
WHERE sub_category_id = 'db126848-5a16-4723-bcb1-524695a0d286'
    AND language_code = 'id';

DELETE FROM item_sub_categories
WHERE id = 'db126848-5a16-4723-bcb1-524695a0d286';

DELETE FROM item_category_l10ns
WHERE category_id = '00b1347c-0d82-4c1b-adcb-28247d299170'
    AND language_code = 'id';

DELETE FROM item_categories
WHERE id = '00b1347c-0d82-4c1b-adcb-28247d299170';

DELETE FROM reservation_tables
WHERE id = '947898b3-be6c-4a70-86b8-2286154af42b';

DELETE FROM store_staffs
WHERE store_account_id = 'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f';

DELETE FROM store_pickup_types
WHERE store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
    AND pickup_type = 'dine-in';

DELETE FROM store_pickup_types
WHERE store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
    AND pickup_type = 'pickup';

DELETE FROM stores
WHERE id = '93ab578c-46fa-42f6-b61f-ef13fe13045d';

DELETE FROM postcodes
WHERE postcode = '45595';

DELETE FROM store_admins
WHERE store_account_id = 'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f';

DELETE FROM store_accounts
WHERE id = 'a9a54fca-ec42-40e5-ad1e-f1aaa3b0322f';

--
--
-- SELECT
--
-- Stores
--
-- Get Store by Id
SELECT stores.*,
    postcodes.city,
    postcodes.state,
    postcodes.country
FROM stores
    JOIN postcodes ON stores.postcode = postcodes.postcode
WHERE stores.id = '93ab578c-46fa-42f6-b61f-ef13fe13045d';

-- Get Nearest Store (Example, lat: -6.938068, lng: 107.7006738)
SELECT nearby_stores.*,
    postcodes.city,
    postcodes.state,
    postcodes.country
FROM (
        SELECT *,
            (
                6371 * acos(
                    cos(radians(-6.938068)) * cos(radians(latitude)) * cos(
                        radians(longitude) - radians(107.7006738)
                    ) + sin(radians(-6.938068)) * sin(radians(latitude))
                )
            ) AS distance
        FROM stores
    ) nearby_stores
    LEFT JOIN postcodes ON nearby_stores.postcode = postcodes.postcode
WHERE distance <= 5
ORDER BY distance
LIMIT 10 OFFSET 0;

-- Items
--
-- Get Item by Id
SELECT *
FROM items
WHERE id = '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae';

-- Get Items by Store Id and Sub Category Id
SELECT *
FROM items
WHERE store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
    AND (
        CASE
            WHEN 'db126848-5a16-4723-bcb1-524695a0d286' IS NOT NULL THEN sub_category_id = 'db126848-5a16-4723-bcb1-524695a0d286'
            ELSE TRUE
        END
    )
ORDER BY (
        CASE
            WHEN special_offer IS NOT NULL THEN special_offer
            ELSE price
        END
    )
LIMIT 10 OFFSET 0;

-- Get Nearby Items with Special Offers (-6.938068, 107.7006738)
SELECT items.*
FROM (
        SELECT *,
            (
                6371 * acos(
                    cos(radians(-6.938068)) * cos(radians(latitude)) * cos(
                        radians(longitude) - radians(107.7006738)
                    ) + sin(radians(-6.938068)) * sin(radians(latitude))
                )
            ) AS distance
        FROM stores
    ) nearby_stores,
    items
WHERE nearby_stores.distance <= 5
    AND items.store_id = nearby_stores.id
    AND items.special_offer IS NOT NULL
ORDER BY distance
LIMIT 10 OFFSET 0;

-- Add ons
--
-- Get Addon Categories by Item ID
SELECT *
FROM item_addon_categories
WHERE item_id = '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae'
ORDER BY is_multiple_choice,
    name;

-- Get Addons by Addon Category ID
SELECT *
FROM item_addons
WHERE addon_category_id IN (
        '17b3be90-d177-4e59-8582-cf6c97f94aa9',
        '17b3be90-d177-4e59-8582-cf6c97f94aa8'
    )
ORDER BY price;

-- Categories
--
-- Get Categories Have Items with language code (Example, language_code: id)
SELECT item_categories.id,
    item_category_l10ns.language_code,
    item_categories.name,
    item_category_l10ns.name AS translated_name
FROM item_categories
    LEFT JOIN item_category_l10ns ON item_categories.id = item_category_l10ns.category_id
    AND item_category_l10ns.language_code = 'id'
WHERE (
        SELECT COUNT(*)
        FROM items
        WHERE items.category_id = item_categories.id
    ) > 0
ORDER BY (
        CASE
            WHEN item_category_l10ns.name IS NOT NULL THEN item_category_l10ns.name
            ELSE item_categories.name
        END
    )
LIMIT 10 OFFSET 0;

-- Get Sub Categories
-- Get Sub Categories Have Items with language code (Example, language_code: id)
SELECT item_sub_categories.id,
    item_sub_category_l10ns.language_code,
    item_sub_categories.name,
    item_sub_category_l10ns.name AS translated_name
FROM item_sub_categories
    LEFT JOIN item_sub_category_l10ns ON item_sub_categories.id = item_sub_category_l10ns.sub_category_id
    AND item_sub_category_l10ns.language_code = 'id'
WHERE item_sub_categories.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
    AND (
        SELECT COUNT(*)
        FROM items
        WHERE items.sub_category_id = item_sub_categories.id
    ) > 0
ORDER BY (
        CASE
            WHEN item_sub_category_l10ns.name IS NOT NULL THEN item_sub_category_l10ns.name
            ELSE item_sub_categories.name
        END
    )
LIMIT 10 OFFSET 0;

-- Orders
--
-- Get Order by Id
SELECT *
FROM orders
WHERE id = 'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c';

-- Get Order Detail
SELECT *
FROM order_details
WHERE order_id = 'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c';

-- Get Orders by Customers ID
SELECT *
FROM orders
WHERE customer_id = '1c7b3156-986b-487b-8d6c-2db03806ca30'
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;

-- Coupons
--
-- Get Coupon by Coupon Code and Store ID
SELECT *
FROM coupons,
    coupon_stores
WHERE coupons.coupon_code = 'BREAK'
    AND coupons.is_valid = TRUE
    AND coupon_stores.coupon_id = coupons.id
    AND coupon_stores.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d';

-- Get Coupon by Store Id
SELECT coupons.*
FROM coupons,
    coupon_stores
WHERE coupon_stores.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
LIMIT 10 OFFSET 0;

-- Get Coupon by Store Id Ordered by Highest Discount (Example, total)
SELECT coupons.*
FROM coupons,
    coupon_stores
WHERE coupon_stores.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
ORDER BY discount DESC
LIMIT 10 OFFSET 0;

-- Get Coupon by Customer ID Ordered by Expiry Date
SELECT coupons.*
FROM coupons,
    coupon_customers
WHERE coupon_customers.customer_id = '1c7b3156-986b-487b-8d6c-2db03806ca30'
    AND coupons.id = coupon_customers.coupon_id
ORDER BY coupons.expiry_date
LIMIT 10 OFFSET 0;

-- Reservation Table
--
-- Get reservation table by Store ID
SELECT reservation_tables.*,
    (
        SELECT COUNT(orders) AS total_person
        FROM orders,
            reservation_tables
        WHERE orders.table_id = reservation_tables.id
            AND (
                orders.status != 'complete'
                OR orders.status != 'cancelled'
            )
    ) AS total_person
FROM reservation_tables
WHERE reservation_tables.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
ORDER BY name;