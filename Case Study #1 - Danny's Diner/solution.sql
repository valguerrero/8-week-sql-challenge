-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
    s.customer_id,
	SUM(m.price) AS total_spent
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m 
    ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;

-- 2. How many days has each customer visited the restaurant?

SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 1;

-- 3. What was the first item from the menu purchased by each customer?

WITH ordered_sales AS (
    SELECT
        s.customer_id,
        m.product_name,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS order_rank
    FROM dannys_diner.sales AS s
    INNER JOIN dannys_diner.menu AS m
        ON s.product_id = m.product_id
)

SELECT DISTINCT 
    customer_id, 
    product_name
FROM ordered_sales
WHERE order_rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    m.product_name,
    COUNT(s.product_id) AS total_purchased
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH purchases_count AS (
    SELECT
        s.customer_id,
        m.product_name,
        COUNT(m.product_id) AS total_purchased,
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(m.product_id) DESC) AS order_rank
    FROM dannys_diner.sales AS s
    INNER JOIN dannys_diner.menu AS m
        ON s.product_id = m.product_id
    GROUP BY 1, 2
)

SELECT
    customer_id,
    product_name,
    total_purchased
FROM purchases_count
WHERE order_rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH ordered_sales AS (
    SELECT
        sales.customer_id,
        menu.product_name,
        sales.order_date,
        members.join_date,
        DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS order_rank
    FROM dannys_diner.sales
    INNER JOIN dannys_diner.members
        ON sales.customer_id = members.customer_id
    INNER JOIN dannys_diner.menu
        ON sales.product_id = menu.product_id
    WHERE order_date >= join_date
)

SELECT DISTINCT 
    customer_id, 
    order_date,
    product_name
FROM ordered_sales
WHERE order_rank = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH ordered_sales AS (
    SELECT
        sales.customer_id,
        menu.product_name,
        sales.order_date,
        members.join_date,
        DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS order_rank
    FROM dannys_diner.sales
    INNER JOIN dannys_diner.members
        ON sales.customer_id = members.customer_id
    INNER JOIN dannys_diner.menu
        ON sales.product_id = menu.product_id
    WHERE order_date < join_date
)

SELECT DISTINCT 
    customer_id, 
    order_date,
    product_name
FROM ordered_sales
WHERE order_rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
    sales.customer_id,
    COUNT(DISTINCT menu.product_name) AS unique_menu_items,
    SUM(menu.price) AS total_spent
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
    ON sales.customer_id = members.customer_id
INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
WHERE order_date < join_date
GROUP BY 1;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
    s.customer_id,
    SUM(CASE
            WHEN m.product_name = 'sushi' THEN (m.price * 20)
            ELSE m.price * 10
        END) AS total_points
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
    sales.customer_id,
    SUM(CASE
            WHEN sales.order_date BETWEEN members.join_date AND members.join_date + 6 THEN menu.price * 20
            WHEN menu.product_name = 'sushi' THEN (menu.price * 20)
            ELSE menu.price * 10
        END) AS total_points
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
    ON sales.customer_id = members.customer_id
INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
WHERE sales.order_date <= '2021-01-31'
GROUP BY 1
ORDER BY 2 DESC;
