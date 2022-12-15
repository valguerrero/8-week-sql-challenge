# Case Study #1 - Danny's Diner

View sql script solutiion here: 

## Case Study Questions

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT 
    s.customer_id,
	SUM(m.price) AS total_spent
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m 
    ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;
```

| customer_id | total_spent |
|-------------|-------------|
| A           | 76          |
| B           | 74          |
| C           | 36          |

***

### 2. How many days has each customer visited the restaurant?

```sql
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 1;
```

| customer_id | days_visited |
|-------------|--------------|
| A           | 4            |
| B           | 6            |
| C           | 2            |

***

### 3. What was the first item from the menu purchased by each customer?

```sql
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
```
| customer_id | product_name |
|-------------|--------------|
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |

***

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT 
    m.product_name,
    COUNT(s.product_id) AS total_purchased
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC
LIMIT 1;
```

| product_name | total_purchased |
|--------------|-----------------|
| ramen        | 8               |

***

### 5. Which item was the most popular for each customer?

```sql
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
```

| customer_id | product_name | total_purchased |
|-------------|--------------|-----------------|
| A           | ramen        | 3               |
| B           | sushi        | 2               |
| B           | curry        | 2               |
| B           | ramen        | 2               |
| C           | ramen        | 3               |

***

### 6. Which item was purchased first by the customer after they became a member?

```sql
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
```

| customer_id | order_date | product_name |
|-------------|------------|--------------|
| A           | 2021-01-07 | curry        |
| B           | 2021-01-11 | sushi        |

***

### 7. Which item was purchased just before the customer became a member?

```sql
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
```

| customer_id | order_date | product_name |
|-------------|------------|--------------|
| A           | 2021-01-01 | curry        |
| A           | 2021-01-01 | sushi        |
| B           | 2021-01-04 | sushi        |

***

### 8. What is the total items and amount spent for each member before they became a member?

```sql
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
```

| customer_id | unique_menu_items | total_spent |
|-------------|-------------------|-------------|
| A           | 2                 | 25          |
| B           | 2                 | 40          |

***

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
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
```

| customer_id | total_points |
|-------------|--------------|
| B           | 940          |
| A           | 860          |
| C           | 360          |

***

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
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
```

| customer_id | total_points |
|-------------|--------------|
| A           | 1370         |
| B           | 820          |