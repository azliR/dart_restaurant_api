--
--
-- SELECT
--
-- Home
--
SELECT SUM(orders.total_person)
FROM reservation_tables
  FULL JOIN (
    SELECT orders.table_id,
      COALESCE(SUM(orders.table_person), 0) as total_person
    FROM orders
    WHERE orders.pickup_type = 'dine-in'
      AND orders.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
      AND (
        orders.order_type = 'now'
        OR (
          orders.order_type = 'scheduled'
          AND orders.scheduled_at <= NOW()
        )
      )
    GROUP BY orders.table_id
  ) AS orders ON orders.table_id = reservation_tables.id
WHERE reservation_tables.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
  AND reservation_tables.is_active = TRUE;

-- Get Nearby Store (Example, lat: -6.938068, lng: 107.7006738)
WITH total_table AS (
  SELECT COALESCE(
      SUM(
        CASE
          WHEN reservation_tables.is_for_one_order = TRUE THEN 1
          ELSE 0
        END
      ),
      0
    ) AS total_table,
    COALESCE(
      SUM(
        CASE
          WHEN reservation_tables.is_for_one_order = TRUE THEN 0
          ELSE reservation_tables.max_person
        END
      ),
      0
    ) AS total_shared_table
  FROM reservation_tables
  WHERE reservation_tables.store_id = nearby_stores.id
    AND reservation_tables.is_active = TRUE
)
SELECT total_table,
  (
    SELECT (
        COALESCE(SUM(orders.table_person), 0)
      ) AS total_person
    FROM orders,
      reservation_tables
    WHERE reservation_tables.store_id = nearby_stores.id
      AND reservation_tables.is_active = TRUE
      AND orders.table_id = reservation_tables.id
      AND orders.pickup_type = 'dine-in'
      AND (
        orders.order_type = 'now'
        OR (
          orders.order_type = 'scheduled'
          AND orders.scheduled_at <= NOW()
        )
      )
  ) AS total_,
  nearby_stores.*,
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
LIMIT 10;

-- Get Nearby Items with Special Offers (-6.938068, 107.7006738)
SELECT items.*,
  nearby_stores.distance
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
LIMIT 10;

--
-- Store
--
-- Get Store by Id
SELECT stores.*,
  postcodes.city,
  postcodes.state,
  postcodes.country
FROM stores
  JOIN postcodes ON stores.postcode = postcodes.postcode
WHERE stores.id = '93ab578c-46fa-42f6-b61f-ef13fe13045d';

--
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

--
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

-- Get Order Detail Addon
SELECT *
FROM order_detail_addons
WHERE order_detail_id = 'd0dc6416-d1cb-4e4c-b5d0-3af7b176fb4c';

-- Get Orders by Customers ID
SELECT orders.*,
  COUNT(order_details) AS total_item
FROM orders
  LEFT JOIN order_details ON orders.id = order_details.order_id
WHERE customer_id = '1c7b3156-986b-487b-8d6c-2db03806ca30'
GROUP BY orders.id
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;

-- Customer
--
-- Get Customer by Id
SELECT *
FROM items
WHERE id = ALL('{7b1c8c31-4a0f-4457-8c71-8f06631aa9ae}');

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
    SELECT COALESCE(SUM(orders.table_person), 0) AS total_person
    FROM orders
    WHERE orders.table_id = reservation_tables.id
      AND orders.pickup_type = 'dine-in'
      AND (
        orders.order_type = 'now'
        OR (
          orders.order_type = 'scheduled'
          AND orders.scheduled_at <= NOW()
        )
      )
  ) AS total_person
FROM reservation_tables
WHERE reservation_tables.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
ORDER BY name;

-- Trend pemesanan
SELECT DATE_TRUNC('month', orders.created_at) AS date,
  items.name,
  SUM(order_details.quantity) AS total_sales
FROM items,
  order_details,
  orders
WHERE items.id = order_details.item_id
  AND order_details.order_id = orders.id
  AND orders.status = 'complete'
  AND orders.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
  AND orders.created_at >= DATE_TRUNC('year', NOW()) - INTERVAL '1 year'
GROUP BY date,
  items.name
ORDER BY date DESC;