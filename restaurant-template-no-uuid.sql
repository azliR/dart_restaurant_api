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
    inserted_by VARCHAR(128) NOT NULL,
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
    customer_id VARCHAR(128) NOT NULL,
    CONSTRAINT pk_coupon_customers PRIMARY KEY (coupon_id, customer_id)
);

CREATE TABLE coupon_stores(
    coupon_id UUID NOT NULL,
    store_id UUID NOT NULL,
    CONSTRAINT pk_coupon_stores PRIMARY KEY (coupon_id, store_id)
);

CREATE TABLE customers (
    id VARCHAR(128) NOT NULL,
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
    name VARCHAR(128) NOT NULL,
    picture TEXT,
    price DECIMAL(11, 2) NOT NULL,
    special_offer DECIMAL(11, 2) NULL,
    description TEXT,
    rating DECIMAL(2, 1),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_items PRIMARY KEY (id)
);

CREATE TABLE item_addons (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    addon_category_id UUID NOT NULL,
    name VARCHAR(64) NOT NULL,
    price DECIMAL(11, 2),
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
    customer_id VARCHAR(128) NOT NULL,
    store_id UUID NOT NULL,
    store_account_id VARCHAR(128),
    table_id UUID,
    coupon_id UUID,
    buyer VARCHAR(64) NOT NULL,
    store_name VARCHAR(64) NOT NULL,
    store_image TEXT,
    table_name VARCHAR(64),
    table_price DECIMAL(11, 2),
    table_person SMALLINT,
    coupon_name VARCHAR(64),
    coupon_code VARCHAR(16),
    discount DECIMAL(11, 2),
    discount_type discount_type_enum,
    discount_nominal DECIMAL(11, 2),
    brutto DECIMAL(11, 2) NOT NULL,
    netto DECIMAL(11, 2) NOT NULL,
    status order_status_enum NOT NULL,
    order_type order_type_enum NOT NULL,
    scheduled_at TIMESTAMP WITHOUT TIME ZONE,
    pickup_type pickup_type_enum NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (id)
);

CREATE TABLE order_details (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    item_id UUID NOT NULL,
    item_name VARCHAR(64) NOT NULL,
    quantity SMALLINT NOT NULL,
    price DECIMAL(11, 2) NOT NULL,
    total DECIMAL(11, 2) NOT NULL,
    picture TEXT,
    item_detail TEXT,
    rating DECIMAL(2, 1),
    comment VARCHAR(255),
    CONSTRAINT pk_order_details PRIMARY KEY (id)
);

CREATE TABLE order_detail_addons (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    order_detail_id UUID NOT NULL,
    addon_id UUID NOT NULL,
    addon_name VARCHAR(64) NOT NULL,
    addon_price DECIMAL(11, 2) NOT NULL,
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
    max_person SMALLINT NOT NULL,
    book_price DECIMAL(11, 2) NOT NULL,
    is_for_one_order BOOLEAN NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_reservation_tables PRIMARY KEY (id)
);

CREATE TABLE stores (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    store_admin_id VARCHAR(128) NOT NULL,
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
    id VARCHAR(128) NOT NULL,
    full_name VARCHAR(64) NOT NULL,
    role store_role_enum NOT NULL,
    language_code VARCHAR(2) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_store_accounts PRIMARY KEY (id)
);

CREATE TABLE store_admins (
    store_account_id VARCHAR(128) NOT NULL,
    email VARCHAR(255) NOT NULL,
    CONSTRAINT pk_store_admins PRIMARY KEY (store_account_id)
);

CREATE TABLE store_staffs (
    store_account_id VARCHAR(128) NOT NULL,
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
INSERT INTO public.store_accounts (id, full_name, "role", language_code, created_at)
VALUES(
        'firebase:ZYaSOubGEkZ1eUw5i4lmoz27R4u2',
        'Rizal Hadiyansah',
        'admin'::public."store_role_enum",
        'en',
        '2022-06-04 15:53:43.972'
    );

INSERT INTO public.store_accounts (id, full_name, "role", language_code, created_at)
VALUES(
        '5edb2b6f-105d-44d7-8c25-89aa899485d6',
        'Ririn Siti Arofah',
        'admin'::public."store_role_enum",
        'en',
        '2022-06-04 15:53:43.976'
    );

INSERT INTO public.store_accounts (id, full_name, "role", language_code, created_at)
VALUES(
        'b7bd94f8-8bc3-46e2-9f89-0101825b051d',
        'Aisha Azlir',
        'admin'::public."store_role_enum",
        'en',
        '2022-06-05 14:21:42.038'
    );

-- insert store_admins
INSERT INTO public.store_admins (store_account_id, email)
VALUES(
        'firebase:ZYaSOubGEkZ1eUw5i4lmoz27R4u2',
        'rizalhadiyansah@gmail.com'
    );

INSERT INTO public.store_admins (store_account_id, email)
VALUES(
        '5edb2b6f-105d-44d7-8c25-89aa899485d6',
        'ririnsitiarofah03@gmail.com'
    );

INSERT INTO public.store_admins (store_account_id, email)
VALUES(
        'b7bd94f8-8bc3-46e2-9f89-0101825b051d',
        'aishaazlir@gmail.com'
    );

-- insert postcodes
INSERT INTO public.postcodes (postcode, city, state, country)
VALUES('45595', 'Kuningan', 'West Java', 'Indonesia');

-- insert stores
INSERT INTO public.stores (
        id,
        store_admin_id,
        "name",
        description,
        image,
        banner,
        phone,
        street_address,
        postcode,
        latitude,
        longitude,
        rating,
        is_active
    )
VALUES(
        '4007f665-8f90-4b94-9d7e-d98ffadcd5c6',
        '5edb2b6f-105d-44d7-8c25-89aa899485d6',
        'KFC',
        NULL,
        'https://upload.wikimedia.org/wikipedia/id/thumb/b/bf/KFC_logo.svg/1200px-KFC_logo.svg.png',
        'https://d1sag4ddilekf6.azureedge.net/compressed/merchants/2-CYU3LAJUVJM1AN/hero/590a06cec3944335a339eb1d1ea365ac_1593013745890046822.jpeg',
        '089660952861',
        'Jl. Soekarno Hatta',
        '45595',
        -6.9449868,
        107.7069983,
        NULL,
        true
    );

INSERT INTO public.stores (
        id,
        store_admin_id,
        "name",
        description,
        image,
        banner,
        phone,
        street_address,
        postcode,
        latitude,
        longitude,
        rating,
        is_active
    )
VALUES(
        '420eb312-f6e1-40dc-9a1a-04190123432f',
        'b7bd94f8-8bc3-46e2-9f89-0101825b051d',
        'Kopi Kenangan',
        NULL,
        'https://awards.brandingforum.org/wp-content/uploads/2020/12/KOPI-KENANGAN_LOGO-2020.png',
        'https://www.malangculinary.com/upload/img_15948174713.jpg',
        '088232611211',
        'Jl. Teratai Biru',
        '45595',
        -6.94521211,
        107.7061991,
        NULL,
        true
    );

INSERT INTO public.stores (
        id,
        store_admin_id,
        "name",
        description,
        image,
        banner,
        phone,
        street_address,
        postcode,
        latitude,
        longitude,
        rating,
        is_active
    )
VALUES(
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'firebase:ZYaSOubGEkZ1eUw5i4lmoz27R4u2',
        'Alpha Store',
        'Alpha Store',
        'https://seeklogo.com/images/M/mcdonald-s-logo-255A7B5646-seeklogo.com.png',
        'https://www.koalahero.com/wp-content/uploads/2019/10/Makanan-McDonald.jpg',
        '081234567891',
        'Jalan Raya Kuningan',
        '45595',
        -6.945171261146366,
        107.70812694679151,
        4.5,
        true
    );

-- insert store_staffs
INSERT INTO public.store_staffs (
        store_account_id,
        store_id,
        username,
        "password",
        is_locked
    )
VALUES(
        'firebase:ZYaSOubGEkZ1eUw5i4lmoz27R4u2',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'a_lpha',
        '$2a$12$q3mLZR3i86cSR90DSf1X6u1lXfGAy4KILvbxR3fQjDSJVTkSpVEyC',
        false
    );

-- insert store_pickup_types
INSERT INTO public.store_pickup_types (store_id, pickup_type)
VALUES(
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'pickup'::public."pickup_type_enum"
    );

INSERT INTO public.store_pickup_types (store_id, pickup_type)
VALUES(
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'dine-in'::public."pickup_type_enum"
    );

-- insert reservation_tables
INSERT INTO public.reservation_tables (
        id,
        store_id,
        "name",
        max_person,
        book_price,
        is_for_one_order
    )
VALUES(
        '947898b3-be6c-4a70-86b8-2286154af42b',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Table 1',
        2,
        10000.00,
        true
    );

INSERT INTO public.reservation_tables (
        id,
        store_id,
        "name",
        max_person,
        book_price,
        is_for_one_order
    )
VALUES(
        '083f426a-5539-44e2-9e7f-79199c6b2d3e',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Table 2',
        2,
        10000.00,
        true
    );

INSERT INTO public.reservation_tables (
        id,
        store_id,
        "name",
        max_person,
        book_price,
        is_for_one_order
    )
VALUES(
        '739e0eef-7ad2-4cc4-9b93-b4983c270beb',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Table 3',
        2,
        10000.00,
        true
    );

INSERT INTO public.reservation_tables (
        id,
        store_id,
        "name",
        max_person,
        book_price,
        is_for_one_order
    )
VALUES(
        'fe6fef7e-9ca6-4366-bd44-4394e099e209',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Table 4',
        4,
        10000.00,
        true
    );

-- insert item_categories
INSERT INTO public.item_categories (id, "name")
VALUES(
        '00b1347c-0d82-4c1b-adcb-28247d299170',
        'Beverages'
    );

INSERT INTO public.item_categories (id, "name")
VALUES(
        '32eebcf9-c49f-4bb3-bf1f-a1cc95256451',
        'Fast food'
    );

INSERT INTO public.item_categories (id, "name")
VALUES(
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        'Snacks'
    );

INSERT INTO public.item_categories (id, "name")
VALUES(
        'dc8c798e-288f-4176-8e58-587bdd5a591f',
        'Chicken & duck'
    );

INSERT INTO public.item_categories (id, "name")
VALUES(
        'a205065c-7f2d-4eac-af8f-1e51f0ff0a18',
        'Breads'
    );

INSERT INTO public.item_categories (id, "name")
VALUES(
        '52bece28-3a8d-4ec8-8d25-07cce771ac19',
        'Rice'
    );

-- insert item_category_l10ns
INSERT INTO public.item_category_l10ns (category_id, language_code, "name")
VALUES(
        '00b1347c-0d82-4c1b-adcb-28247d299170',
        'id',
        'Minuman'
    );

INSERT INTO public.item_category_l10ns (category_id, language_code, "name")
VALUES(
        '32eebcf9-c49f-4bb3-bf1f-a1cc95256451',
        'id',
        'Cepat Saji'
    );

INSERT INTO public.item_category_l10ns (category_id, language_code, "name")
VALUES(
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        'id',
        'Jajanan'
    );

INSERT INTO public.item_category_l10ns (category_id, language_code, "name")
VALUES(
        'dc8c798e-288f-4176-8e58-587bdd5a591f',
        'id',
        'Ayam & bebek'
    );

INSERT INTO public.item_category_l10ns (category_id, language_code, "name")
VALUES(
        'a205065c-7f2d-4eac-af8f-1e51f0ff0a18',
        'id',
        'Roti'
    );

INSERT INTO public.item_category_l10ns (category_id, language_code, "name")
VALUES(
        '52bece28-3a8d-4ec8-8d25-07cce771ac19',
        'id',
        'Paket Nasi'
    );

-- insert item_sub_categories
INSERT INTO public.item_sub_categories (id, store_id, "name")
VALUES(
        'db126848-5a16-4723-bcb1-524695a0d286',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Breakfasts'
    );

INSERT INTO public.item_sub_categories (id, store_id, "name")
VALUES(
        '0d36862d-0165-4bc6-a497-198e8021d892',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Vegetarian'
    );

INSERT INTO public.item_sub_categories (id, store_id, "name")
VALUES(
        '296b4d9d-e1ac-4a5e-8981-209eb1a1dbad',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Desserts'
    );

INSERT INTO public.item_sub_categories (id, store_id, "name")
VALUES(
        '28811fd2-7dfa-430e-82b3-909754d962ec',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Super Crispy'
    );

INSERT INTO public.item_sub_categories (id, store_id, "name")
VALUES(
        '79509666-e5a0-41c3-a9e6-828797936cd3',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'Snacks'
    );

-- insert item_sub_category_l10ns
INSERT INTO public.item_sub_category_l10ns (sub_category_id, language_code, "name")
VALUES(
        'db126848-5a16-4723-bcb1-524695a0d286',
        'id',
        'Sarapan'
    );

INSERT INTO public.item_sub_category_l10ns (sub_category_id, language_code, "name")
VALUES(
        '0d36862d-0165-4bc6-a497-198e8021d892',
        'id',
        'Vegetarian'
    );

INSERT INTO public.item_sub_category_l10ns (sub_category_id, language_code, "name")
VALUES(
        '296b4d9d-e1ac-4a5e-8981-209eb1a1dbad',
        'id',
        'Makanan Penutup'
    );

INSERT INTO public.item_sub_category_l10ns (sub_category_id, language_code, "name")
VALUES(
        '28811fd2-7dfa-430e-82b3-909754d962ec',
        'id',
        'Super Crispy'
    );

INSERT INTO public.item_sub_category_l10ns (sub_category_id, language_code, "name")
VALUES(
        '79509666-e5a0-41c3-a9e6-828797936cd3',
        'id',
        'Camilan'
    );

-- insert items
INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '00b1347c-0d82-4c1b-adcb-28247d299170',
        'db126848-5a16-4723-bcb1-524695a0d286',
        'McDonalds Burger',
        'https://www.koalahero.com/wp-content/uploads/2019/10/Makanan-McDonald.jpg',
        10000.00,
        9000.00,
        'McDonalds Burger',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        'c171b7c0-9457-49af-8872-b0ff5081bbc1',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '52bece28-3a8d-4ec8-8d25-07cce771ac19',
        'db126848-5a16-4723-bcb1-524695a0d286',
        'Sup Oyong Soun Pedas',
        'https://kbu-cdn.com/dk/wp-content/uploads/sup-oyong-soun-pedas.jpg',
        10000.00,
        NULL,
        'Sup Oyong Soun Pedas salah satu kreasi sup untuk hidangan sehari-hari sehat bergizi karna sayur oyong yang mengandung beragam nutrisi. Untuk menyajikan sup sayur oyong yang lezat, Bunda bisa dimasaknya dengan praktis menggunakan Kobe Bumbu Nasi Goreng Poll Pedas. Tak perlu tambahan bumbu atau cabe lagi, karena kandungannya sudah lengkap sehingga memasak makanan pedas jadi mudah. Hidangan sup oyong pakai bihun ini juga bisa menyegarkan tubuh jika disantap saat tak enak badan loh, karena oyong dan sounnya lembut jadi mudah ditelan.',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        'e42dd265-873e-44d9-abaa-5f937c9d4d6e',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        'db126848-5a16-4723-bcb1-524695a0d286',
        'Roti Bakar Keju Milky',
        'https://kbu-cdn.com/dk/wp-content/uploads/roti-bakar-keju-milky.jpg',
        14000.00,
        12000.00,
        'Bunda sekeluarga penggemar roti? Yuk coba kreasi roti yang enak sekali, resep Roti Bakar Keju Milky! Bayangkan kelezatan roti yang renyah diolesi dengan adonan campuran keju, susu dan Kobe Tepung Pisang Goreng Crispy. Tentunya yang mencoba akan ketagihan dengan sensasi rasa manis dan gurih yang lumer di mulut. Nggak kalah enaknya dengan menu roti bakar yang terkenal itu deh. Yuk Bunda dicoba resepnya untuk menu sarapan besok pagi, disandingkan dengan susu coklat hangat makin menyempurnakan sajian roti manis ini.',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        '0098d69a-1d47-4f1b-a423-58e157388744',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '52bece28-3a8d-4ec8-8d25-07cce771ac19',
        'db126848-5a16-4723-bcb1-524695a0d286',
        'Tomat Goreng Telur Pedas',
        'https://kbu-cdn.com/dk/wp-content/uploads/tomat-goreng-telur-pedas.jpg',
        12000.00,
        11000.00,
        'Tomat Goreng Telur Pedas merupakan kreasi telur dengan paduan tomat segar di atasnya. Telur merupakan salah satu bahan masakan yang wajib distok. Selain mudah dikreasikan menjadi menu masakan, rasanya yang enak pun disukai siapa aja. Menu telur tomat goreng ini bisa menjadi alternatif hidangan sehari-hari Bunda nih. Rasanya lezat berbumbu karena menggunakan Kobe Tepung Bumbu Putih dan Lada Kobe. Ditambah dengan taburan BonCabe level 10, rasa Bawang Goreng menambah sensasi pedas nikmat yang bikin mau nambah terus. Mau masak enak dengan cara yang tak ribet dan waktunya sebentar? Yuk coba kreasi telur tomat ini.',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        '2cf7dd2d-59c0-4b5d-a61c-7177b1120247',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        '0d36862d-0165-4bc6-a497-198e8021d892',
        'Kelereng Keju Kentang',
        'https://kbu-cdn.com/dk/wp-content/uploads/kelereng-keju-kentang.jpg',
        9000.00,
        8000.00,
        'Kelereng Keju Kentang inspirasi camilan berbahan kentang dengan paduan keju. Rasanya gurih lezat dan cara membuatnya juga praktis cocok banget disajikan sebagai camilan untuk keluarga dan si kecil. Pakai Kobe Tepung Bakwan Kress, bikin camilan keju kelereng jadi mudah dan adonan pun mudah dibentuknya. Tambahan Lada Kobe juga menghadirkan aroma yang lezat dan rasa pedas khas lada yang sedap. Anak tak doyan ngemil? Coba yuk sajikan kelereng keju ini, selain enak pastinya juga bisa mengenyangkan karena kandungan kentangnya.',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        '427643c1-9b79-4016-a806-cdef76a79ab7',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        '0d36862d-0165-4bc6-a497-198e8021d892',
        'Corn Flakes Cookies',
        'https://kbu-cdn.com/dk/wp-content/uploads/corn-flakes-cookies.jpg',
        8000.00,
        NULL,
        'Bikin kreasi kukis dari sereal jagung yuk, resep Corn Flakes Cookies. Biasanya cornflakes dinikmati bersama dengan susu cair, sekarang cornflakes banyak juga diminati untuk dijadikan cookies. Sudah tentu rasanya lebih enak, manis dan garing. Cara membuat Corn Flakes Cookies praktis dengan menggunakan Kobe Tepung Pisang Goreng Crispy. Adonan kukis jadi renyah, harum dan lezat. Menu cookies ini cocok sekali Bunda sajikan untuk merayakan hari raya besar atau suguhan menjamu tamu. Dinikmati dengan secangkir teh atau kopi hangat pastinya makin menambah kenikmatan makan kukis sereal jagung ini.',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        'c9113655-b1dc-4415-8ad1-34540db0df92',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '00b1347c-0d82-4c1b-adcb-28247d299170',
        '296b4d9d-e1ac-4a5e-8981-209eb1a1dbad',
        'Bukok Pandan',
        'https://kbu-cdn.com/dk/wp-content/uploads/bukok-pandan.jpg',
        5000.00,
        4000.00,
        'Bukok Pandan yang creamy lezat dan menggoda. Bukok Pandan adalah salah satu dessert asal Filipina yang kini telah populer di Indonesia. Minuman yang enak dikonsumsi saat dingin ini terdiri dari berbagai campuran bahan. Seperti daging kelapa muda, susu kental manis, agar-agar, nata de coco dan tentunya daun pandan. Cara membuat Bukok Pandan isiannya pun mudah Bunda, pakai Kobe Tepung Pisang Goreng Crispy hasil adonan isian menjadi manis dan lembut. Dessert ini cocok menjadi pilihan menu untuk acara kumpul bersama keluarga besar. Yuk coba resepnya!',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        '3ceeecb7-5061-480a-8dcc-036b54a860cb',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        '296b4d9d-e1ac-4a5e-8981-209eb1a1dbad',
        'Martabak Jantung Pisang',
        'https://kbu-cdn.com/dk/wp-content/uploads/martabak-jantung-pisang.jpg',
        7000.00,
        6000.00,
        'Martabak Jantung Pisang ini olahan spesial yang bisa spesial dari martabak telur yang yang bisa jadi pilihan suguhan untuk menemani minum teh. Cara membuat sederhana cukup pakai teflon. Isian martabak unik dari jantung pisang ini rasanya tak terlupakan deh! Apalagi jantung pisang sama sehatnya dengan buahnya. Ada kandungan vitamin, mineral dan serat. Kunci rasa gurih isian martabak tentunya Saus Tiram Selera. Pakai Kobe Tepung Serbaguna Special bikin rasanya makin sip. Tentunya resep unik ini menambah daftar makanan kesukaan keluarga di rumah. Bisa jadi bekal juga untuk Ayah.',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        'c61f2371-f967-4eda-bf39-c7e2875ef3aa',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        '79509666-e5a0-41c3-a9e6-828797936cd3',
        'Sosis Krispy',
        'https://kbu-cdn.com/dk/wp-content/uploads/sosis-krispy.jpg',
        6000.00,
        5000.00,
        'Sosis Krispy menu sosis super gampang yang pastinya disukai si kecil. Bingung ketika si kecil susah makan dan mulai pilih-pilih makanan Bunda? Sajikan aja menu sosis goreng ini, dijamin si kecil akan lahap. Cara membuat sosis krispi praktis dengan menggunakan Kobe Tepung Bakwan Kress. Teksturnya menjadi renyah di luar, kress dan gurih berbumbu. Tak hanya menjadi menu sederhana makan nasi, kreasi sosis ini juga bisa menjadi camilan saat santai lho Bunda. Yuk recook menu sosis krispy praktis yang enak jika bingung mau masak apa untuk si kecil.',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        '1e6bc1ae-8772-43ae-823e-7c0c9c199658',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        '79509666-e5a0-41c3-a9e6-828797936cd3',
        'Kentang Tornado Renyah',
        'https://kbu-cdn.com/dk/wp-content/uploads/kentang-tornado-renyah.jpg',
        7000.00,
        6000.00,
        'Siapa yang suka ngemil kentang? Resep Kentang Tornado Renyah wajib banget dicoba buat inspirasi camilan kentang yang gurih dan krispi. Cara membuatnya juga cukup mudah Bunda. Tak perlu pakai alat, Bunda bisa membuat kentang mirip tornado ini dengan menggunakan sumpit kemudian dipotong-potong tipis. Dibalur dengan adonan Kobe Tepung Bumbu Putih, dapat menghasilkan tekstur kentang menjadi garing dan rasanya gurih berbumbu tanpa tambahan garam atau penyedap rasa. Daripada jajan kentang di luar, lebih baik bikin sendiri dengan resep yang gampang. Yuk recook resepnya Bunda!',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        '1dc4e414-1c77-4dfe-834c-ab6794169a5d',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '5abecb46-5672-45aa-9605-0f41cb6b6208',
        '28811fd2-7dfa-430e-82b3-909754d962ec',
        'Tahu Super Crispy',
        'https://kbu-cdn.com/dk/wp-content/uploads/tahu-super-crispy.jpg',
        11000.00,
        10000.00,
        'Yuk intip jajanan favorit semua orang, resep Tahu Super Crispy. Menu tahu yang renyah dan garing ini memang banyak disukai karena cocok dijadikan camilan atau lauk tambahan. Tak perlu membeli di tukang gorengan, Bunda bisa buat sendiri kreasi tahu goreng yang super renyah. Cara membuat Tahu Super Crispy yang lezat cukup menggunakan Kobe Tepung Kentucky Super Crispy. Gurih dan berbumbu yang pas, serta krispinya tahan lama. Rasanya enak banget apalagi dimakan bersama dengan cabe rawit, sambal kecap, saus atau sambal tabur. Olahan tahu yang super gampang, super crispy dan super nikmat!',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        '82c8dbdb-9e10-4724-ac7f-55574ceceb74',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'dc8c798e-288f-4176-8e58-587bdd5a591f',
        '28811fd2-7dfa-430e-82b3-909754d962ec',
        'Ayam Saus Lemon',
        'https://kbu-cdn.com/dk/wp-content/uploads/ayam-saus-lemon.jpg',
        15000.00,
        14000.00,
        'Kreasi ayam dengan cita rasa asam manis yang lezat, resep Ayam Saus Lemon. Jika Bunda bosan dengan hidangan ayam goreng yang polos, bisa mencoba menu ayam ini. Renyahnya ayam yang dikombinasikan dengan saus lemon tentunya bisa membuat siapa saja ingin mencobanya. Masak ayam goreng crispy kian mudah dengan menggunakan Kobe Tepung Kentucky Super Crispy. Membuat ayam menjadi gurih berbumbu pas sehingga sangat cocok dipadu dengan sausnya. Hidangan restoran ini bisa Bunda buat di dapur rumah sendiri loh. Yuk cicipi nikmatnya Ayam Saus Lemon bikinan sendiri dengan mengikuti resep berikut ini!',
        NULL,
        true
    );

INSERT INTO public.items (
        id,
        store_id,
        category_id,
        sub_category_id,
        "name",
        picture,
        price,
        special_offer,
        description,
        rating,
        is_active
    )
VALUES(
        'c7f2bc71-3bfa-4315-83ef-ddc1f75a3225',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        '32eebcf9-c49f-4bb3-bf1f-a1cc95256451',
        '28811fd2-7dfa-430e-82b3-909754d962ec',
        'Keripik Usus',
        'https://kbu-cdn.com/dk/wp-content/uploads/keripik-usus.jpg',
        12000.00,
        10000.00,
        'Keripik Usus ini resep goreng tepung yang bisa dijadikan lauk maupun camilan. Resep ini istimewa karena cara buat simpel namun renyahnya tahan lama. Bahkan Bunda bisa jadikan menu ini untuk berjualan kiloan. Kunci resep ini tentu saja Kobe Tepung Kentucky Super Crispy. Praktis dan anti gagal, usus ayam pun jadi enak tanpa perlu susah. Bunda bahkan hanya perlu 3 bahan saja untuk mengolahnya. Bunda bisa simpan dalam toples juga agar tahan lama. Sebagai lauk pun tak kalah sedap tinggal dipadukan dengan sambal atau tauburan BonCabe. Bikin yuk Bunda.',
        NULL,
        true
    );

-- insert item_addon_categories
INSERT INTO public.item_addon_categories (
        id,
        item_id,
        "name",
        description,
        is_multiple_choice
    )
VALUES(
        '02fa8872-1c60-481f-b169-65792d5da007',
        'c61f2371-f967-4eda-bf39-c7e2875ef3aa',
        'Flavour',
        'Choose the flavor you like!',
        false
    );

INSERT INTO public.item_addon_categories (
        id,
        item_id,
        "name",
        description,
        is_multiple_choice
    )
VALUES(
        '17b3be90-d177-4e59-8582-cf6c97f94aa9',
        'c61f2371-f967-4eda-bf39-c7e2875ef3aa',
        'Add on',
        'More delicious with add ons!',
        true
    );

-- insert item_addons
INSERT INTO public.item_addons (id, addon_category_id, "name", price)
VALUES(
        '4e21ce09-4995-4645-8270-9fbaf09de3d6',
        '02fa8872-1c60-481f-b169-65792d5da007',
        'Original',
        NULL
    );

INSERT INTO public.item_addons (id, addon_category_id, "name", price)
VALUES(
        'e092f6ab-742b-4424-835c-508016db7100',
        '02fa8872-1c60-481f-b169-65792d5da007',
        'Balado',
        NULL
    );

INSERT INTO public.item_addons (id, addon_category_id, "name", price)
VALUES(
        '31c64ea7-184c-4afa-b618-ef10f58d721d',
        '02fa8872-1c60-481f-b169-65792d5da007',
        'Salty',
        NULL
    );

INSERT INTO public.item_addons (id, addon_category_id, "name", price)
VALUES(
        'b1bf5ef6-1aa4-473f-961a-256cb006505a',
        '17b3be90-d177-4e59-8582-cf6c97f94aa9',
        'Extra ketchup',
        1000.00
    );

INSERT INTO public.item_addons (id, addon_category_id, "name", price)
VALUES(
        'cb6c9073-8680-4a6a-85a4-bf9bb7c91ee3',
        '17b3be90-d177-4e59-8582-cf6c97f94aa9',
        'Extra fried onions',
        2000.00
    );

-- insert customers
INSERT INTO public.customers (id, full_name, phone, language_code, created_at)
VALUES(
        '1c7b3156-986b-487b-8d6c-2db03806ca30',
        'Rizal Hadiyansah',
        '08123456789',
        'en',
        '2022-06-04 15:53:44.132'
    );

-- insert coupons
INSERT INTO public.coupons (
        id,
        inserted_by,
        coupon_code,
        "name",
        description,
        expiry_date,
        discount_type,
        discount,
        min_total,
        max_discount,
        max_number_use_total,
        max_number_use_customer,
        created_at,
        all_store,
        all_customer,
        is_valid
    )
VALUES(
        '19fb0734-01a4-40a1-a95e-ff6d18fc2af6',
        'firebase:ZYaSOubGEkZ1eUw5i4lmoz27R4u2',
        'BREAK',
        'Coupon New Customer',
        'This coupon is for new customer from store Alpha Store',
        '2023-01-01 00:00:00.000',
        'percentage'::public."discount_type_enum",
        10.00,
        0.00,
        20000.00,
        NULL,
        1,
        '2022-06-04 15:53:44.135',
        false,
        false,
        true
    );

-- insert coupon_customers
INSERT INTO public.coupon_customers (coupon_id, customer_id)
VALUES(
        '19fb0734-01a4-40a1-a95e-ff6d18fc2af6',
        '1c7b3156-986b-487b-8d6c-2db03806ca30'
    );

-- insert coupon_stores
INSERT INTO public.coupon_stores (coupon_id, store_id)
VALUES(
        '19fb0734-01a4-40a1-a95e-ff6d18fc2af6',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d'
    );

-- insert orders
INSERT INTO public.orders (
        id,
        customer_id,
        store_id,
        store_account_id,
        table_id,
        coupon_id,
        buyer,
        store_name,
        store_image,
        table_name,
        table_price,
        table_person,
        coupon_code,
        coupon_name,
        discount,
        discount_type,
        discount_nominal,
        brutto,
        netto,
        status,
        order_type,
        scheduled_at,
        pickup_type,
        created_at
    )
VALUES(
        'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c',
        '1c7b3156-986b-487b-8d6c-2db03806ca30',
        '93ab578c-46fa-42f6-b61f-ef13fe13045d',
        'firebase:ZYaSOubGEkZ1eUw5i4lmoz27R4u2',
        '947898b3-be6c-4a70-86b8-2286154af42b',
        '19fb0734-01a4-40a1-a95e-ff6d18fc2af6',
        'Rizal Hadiyansah',
        'Alpha Store',
        'https://www.koalahero.com/wp-content/uploads/2019/10/Makanan-McDonald.jpg',
        'Table 1',
        10000.00,
        2,
        'BREAK',
        'Coupon New Customer',
        10.00,
        'percentage'::public."discount_type_enum",
        3800.00,
        38000.00,
        34200.00,
        'pending'::public."order_status_enum",
        'scheduled'::public."order_type_enum",
        '2022-05-04 00:00:00.000',
        'dine-in'::public."pickup_type_enum",
        '2022-06-04 15:53:44.148'
    );

-- insert order_details
INSERT INTO public.order_details (
        id,
        order_id,
        item_id,
        item_name,
        quantity,
        price,
        total,
        picture,
        item_detail,
        rating,
        comment
    )
VALUES(
        '2cb56b76-c756-4b57-ac66-1f346e4bc065',
        'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c',
        '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae',
        'McDonalds Burger',
        2,
        9000.00,
        28000.00,
        'https://www.koalahero.com/wp-content/uploads/2019/10/Makanan-McDonald.jpg',
        '',
        4.5,
        'Good'
    );

-- insert order_detail_addons
INSERT INTO public.order_detail_addons (
        id,
        order_detail_id,
        addon_id,
        addon_name,
        addon_price
    )
VALUES(
        '92120f69-a875-4389-a835-33e46c36a3e0',
        '2cb56b76-c756-4b57-ac66-1f346e4bc065',
        'cb6c9073-8680-4a6a-85a4-bf9bb7c91ee3',
        'Extra sauce Kari Spesial',
        5000.00
    );