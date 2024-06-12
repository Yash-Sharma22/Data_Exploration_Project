USE project_1;
CREATE TABLE goldusers_signup(
userid integer,
gold_signup_date date);
INSERT INTO goldusers_signup(userid,gold_signup_date) 
VALUES 
(1,'09-22-2017'),
(3,'04-21-2017');
SELECT * FROM goldusers_signup;

USE project_1;
SELECT * FROM goldusers_signup;
SELECT * FROM product;
SELECT * FROM sales;
SELECT * FROM users;

-- Q1 Total amount each customer spend on zomato?
SELECT a.userid, SUM(b.price) as total_amt
FROM sales as a
INNER JOIN product as b
ON a.product_id = b.product_id
GROUP BY a.userid;

-- Q-2 How many days each customer visited zomato?
SELECT userid,COUNT(created_date) as days_visit
FROM sales 
GROUP BY userid;

-- Q-3 What was the first product purchased by each customer?
-- New
SELECT * FROM
(SELECT*, rank() 
over(partition by userid order by created_date) rnk 
FROM sales) a WHERE rnk = 1;

-- Q-4 What is the most purchased item on the menu and how many times was it purchases by all customers?
SELECT product_id, COUNT(product_id) as num
FROM sales 
GROUP BY product_id
ORDER BY num DESC;
--
SELECT userid, COUNT(product_id)
FROM sales
WHERE product_id =
(SELECT TOP 1 product_id---, COUNT(product_id) as num --- TOP1 Is just like limit1 :)
FROM sales 
GROUP BY product_id
ORDER BY COUNT(product_id) DESC)
GROUP BY userid;

-- Q-5 Which item was the most popular among the customers?
-- GOOD
SELECT * 
FROM
(SELECT *, RANK()
OVER(PARTITION BY userid ORDER BY cnt) as rnk
FROM
(SELECT userid,product_id,COUNT(product_id)as cnt
FROM sales
GROUP BY userid,product_id)as a)as b
WHERE rnk = 1;

-- Q-6 Which item was purchased first by the customer after they become a member?
SELECT * FROM
(SELECT c.*,RANK()
OVER(PARTITION BY userid ORDER BY created_date)as rnk FROM
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date
FROM sales as a
INNER JOIN goldusers_signup as b
ON a.userid = b.userid AND created_date>=gold_signup_date)as c)as d
WHERE rnk = 1;

-- Q-7 Which item was purchased just before the customer became a member?
SELECT * FROM
(SELECT c.*,RANK()
OVER(PARTITION BY userid ORDER BY created_date DESC)as rnk FROM
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date
FROM sales as a
INNER JOIN goldusers_signup as b
ON a.userid = b.userid AND created_date<gold_signup_date)as c)as d
WHERE rnk = 1;

-- Q-8 What is the total orders and amount spent for each member before they became a member?
SELECT userid, COUNT(created_date),SUM(price) FROM
(SELECT c.*, d.price 
FROM
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date
FROM sales as a
INNER JOIN goldusers_signup as b
ON a.userid = b.userid AND created_date<gold_signup_date)as c
INNER JOIN product as d
ON c.product_id = d.product_id) as e
GROUP BY userid;

-- Q-9(**) If buying each product generates points for eg 5rs=2 zomato pooints and each product 
-- has different purchasing points for eg for p1 5rs=1 zomato point, for p2 10rs=5zomato point 
-- and p3 5rs=1 zomato point. Calculate points collected by each customer and for which product
-- most points have been given till now?
SELECT userid,SUM(points_earned) as total_pts FROM
(SELECT e.*,amt/Points as points_earned FROM
(SELECT d.*, CASE WHEN product_id=1 THEN 5
WHEN product_id=2 THEN 2
WHEN product_id=3 THEN 5
ELSE 0 END AS Points FROM
(SELECT userid,product_id,SUM(price) as amt FROM --forgot to mention colmn name and error:)
(SELECT a.*,b.price
FROM sales as a
INNER JOIN product as b
ON a.product_id = b.product_id)as c
GROUP BY userid,product_id)as d)as e)as f
GROUP BY userid;
--
SELECT * FROM
(SELECT *,RANK()
OVER(ORDER BY total_pts DESC) rnk FROM
(SELECT product_id,SUM(points_earned) as total_pts FROM
(SELECT e.*,amt/Points as points_earned FROM
(SELECT d.*, CASE WHEN product_id=1 THEN 5
WHEN product_id=2 THEN 2
WHEN product_id=3 THEN 5
ELSE 0 END AS Points FROM
(SELECT userid,product_id,SUM(price) as amt FROM --forgot to mention colmn name and error:)
(SELECT a.*,b.price
FROM sales as a
INNER JOIN product as b
ON a.product_id = b.product_id)as c
GROUP BY userid,product_id)as d)as e)as f
GROUP BY product_id)as g)as f
WHERE rnk=1;

-- Q-10 In the first one year after a customer joins the gold program(including the joining date)
-- irrespective of what the customer has purchased they earn 5 zomato points for every 10rs spent 
-- who earned more 1 or 3 and what was their points earnings in their first yr?
-- (*)created_date<=gold_signup_date+365
SELECT c.*,d.price*0.5 as total_pt FROM
(SELECT a.userid,a.product_id,a.created_date,b.gold_signup_date
FROM sales as a 
INNER JOIN goldusers_signup as b
ON a.userid = b.userid
WHERE created_date>=gold_signup_date AND created_date<=DATEADD(YEAR,1,gold_signup_date))as c   
INNER JOIN product as d
ON c.product_id = d.product_id;

-- Q-11 Rnk all the transactions of the customer
SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) as rnk FROM sales;

-- Q-12 Rank all the transactions for each member whenever they are a zomato gold memebr for every 
-- non gold member mark as na(***)
SELECT g.*,CASE WHEN rnk=0 THEN 'NA' ELSE rnk END AS rnkk FROM
(SELECT c.*,CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE RANK() OVER(PARTITION BY userid ORDER BY created_date DESC)END)AS VARCHAR) AS rnk FROM
(SELECT a.userid,a.product_id,a.created_date,b.gold_signup_date
FROM sales as a
LEFT JOIN goldusers_signup as b
ON a.userid = b.userid AND created_date>=gold_signup_date)as c)as g;
-- CAST FUNCTION IS USED TO CHANGE DATATYPE
