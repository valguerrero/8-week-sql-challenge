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