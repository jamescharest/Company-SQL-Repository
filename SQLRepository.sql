#############################
-- Examining our data tables
#############################

SELECT * FROM customers;
SELECT * FROM departments; 
SELECT * FROM employees;
SELECT * FROM regions;
SELECT * FROM sales; 

#############################
-- Examining employee data
#############################

# Number of current employees
SELECT
	COUNT(*) AS Number_Employees
FROM employees;

# Number of departments
SELECT
	COUNT(DISTINCT(department)) AS Number_Departments
FROM employees;

# Number of employees by department
SELECT
	department,
    COUNT(*)
FROM employees
GROUP BY department
ORDER BY COUNT(*) DESC;

# Breakdown of employees by gender
SELECT
	COUNT(DISTINCT employee_ID) AS Total_Employees,
    COUNT(DISTINCT IF(gender = "F", employee_id, NULL)) AS Female,
    COUNT(DISTINCT IF(gender = "M", employee_id, NULL)) AS Male
FROM employees;

# Breakdown of employees by gender and department
SELECT
	department,
    COUNT(DISTINCT employee_ID) AS Total_Employees,
    COUNT(DISTINCT IF(gender = "F", employee_id, NULL)) AS Female,
    COUNT(DISTINCT IF(gender = "M", employee_id, NULL)) AS Male
FROM employees
GROUP BY department
ORDER BY COUNT(DISTINCT employee_ID) DESC;

# Hire date of employees in order
SELECT
	ROW_NUMBER() OVER(ORDER BY hire_date) AS hire_order, 
    last_name,
    first_name, 
    hire_date
FROM employees;

# Hire date of employees in order, grouped by department
# All listed
SELECT
	ROW_NUMBER() OVER(PARTITION BY department ORDER BY hire_date) AS hire_order, 
    last_name,
    first_name, 
    department,
    hire_date
FROM employees;

#Filter by specific department
SELECT
	ROW_NUMBER() OVER(ORDER BY hire_date) AS hire_order, 
    last_name,
    first_name, 
    department,
    hire_date
FROM employees
WHERE department = "Beauty";

#Determine how long each employee has been working (years and months)
SELECT
	last_name,
    first_name,
    department,
    CONCAT(
		FLOOR((TIMESTAMPDIFF(MONTH, hire_date, CURDATE()) / 12)), " years ",
        MOD(TIMESTAMPDIFF(MONTH, hire_date, CURDATE()), 12), " months"
        ) AS time_employed
FROM employees
ORDER BY last_name;

#In order to correctly order later, months/years have to be numeric
#Needs this for later querying to organize
SELECT
	last_name,
    first_name,
    department,
    CONCAT(
		FLOOR((TIMESTAMPDIFF(MONTH, hire_date, CURDATE()) / 12)), " years ",
        MOD(TIMESTAMPDIFF(MONTH, hire_date, CURDATE()), 12), " months"
        ) AS time_employed,
	FLOOR((TIMESTAMPDIFF(MONTH, hire_date, CURDATE()) / 12)) AS years,
    MOD(TIMESTAMPDIFF(MONTH, hire_date, CURDATE()), 12) AS months
FROM employees
ORDER BY last_name;

#Determine how order of who has been working longest in each department
SELECT
	ROW_NUMBER() OVER(PARTITION BY department ORDER BY years DESC, months DESC) AS Row_N,
    last_name,
    first_name,
    department,
    time_employed
FROM(
SELECT
	last_name,
    first_name,
    department,
    CONCAT(
		FLOOR((TIMESTAMPDIFF(MONTH, hire_date, CURDATE()) / 12)), " years ",
        MOD(TIMESTAMPDIFF(MONTH, hire_date, CURDATE()), 12), " months"
        ) AS time_employed,
	FLOOR((TIMESTAMPDIFF(MONTH, hire_date, CURDATE()) / 12)) AS years,
    MOD(TIMESTAMPDIFF(MONTH, hire_date, CURDATE()), 12) AS months
FROM employees) a
;

#Number of employees by region
SELECT
	e.region_id,
    r.region,
    r.country,
    COUNT(*) AS Num_Employees
FROM employees e
	INNER JOIN regions r ON e.region_id = r.region_id
GROUP BY e.region_id, r.region, r.country
ORDER BY region_id;

# Number of employees in each region by department
SELECT
	department,
    COUNT(DISTINCT employee_ID) AS Total_Employees,
    COUNT(DISTINCT IF(region_id = "1", employee_id, NULL)) AS SouthwestUS,
    COUNT(DISTINCT IF(region_id = "2", employee_id, NULL)) AS NortheastUS,
	COUNT(DISTINCT IF(region_id = "3", employee_id, NULL)) AS NorthwestUS,
    COUNT(DISTINCT IF(region_id = "4", employee_id, NULL)) AS CentralAsia,
    COUNT(DISTINCT IF(region_id = "5", employee_id, NULL)) AS EastAsia,
    COUNT(DISTINCT IF(region_id = "6", employee_id, NULL)) AS QuebecCanada,
    COUNT(DISTINCT IF(region_id = "7", employee_id, NULL)) AS NSCanada
FROM employees
GROUP BY department
ORDER BY COUNT(DISTINCT employee_ID) DESC;

#Salaries by department, in order
SELECT
	ROW_NUMBER() OVER(PARTITION BY department ORDER BY salary DESC) as Row_Num,
    first_name,
    last_name,
    department,
    salary
FROM employees;

#Salaries by department, with differences between them
SELECT
	ROW_NUMBER() OVER(PARTITION BY department ORDER BY salary DESC) as Row_Num,
    first_name,
    last_name,
    department,
    salary,
    LEAD(salary) OVER(PARTITION BY department) AS next_highest_salary,
    salary - LEAD(salary) OVER(PARTITION BY department) AS salary_diff
FROM employees;

WITH salaryrankings AS (
	SELECT
	ROW_NUMBER() OVER(PARTITION BY department ORDER BY salary DESC) as Row_Num,
    first_name,
    last_name,
    department,
    salary,
    LEAD(salary) OVER(PARTITION BY department) AS next_highest_salary
	FROM employees)
SELECT 
	first_name,
    last_name,
    salary,
    salary - next_highest_salary AS salary_diff
FROM salaryrankings
WHERE department = "Automotive";

#Salaries by region
SELECT
	ROW_NUMBER() OVER(PARTITION BY region_id ORDER BY salary DESC) AS Row_Num,
    e.first_name,
    e.last_name,
    e.region_id,
    r.region,
    r.country,
    e.salary
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id;

#Total salary by department
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(salary) DESC) AS Row_Num,
    department,
    SUM(salary) AS total_salary
FROM employees
GROUP BY department;

#Total salary by region
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(e.salary) DESC) AS Row_Num,
    e.region_id,
    r.region,
    r.country,
    SUM(e.salary) AS total_salary
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id
GROUP BY region_id;

#Salary measurables total
SELECT
	ROUND(MIN(salary),2) AS min_salary,
    ROUND(MAX(salary), 2) AS max_salary,
    ROUND(AVG(salary), 2) AS avg_salary
FROM employees;

#Group employees by salary tiers
SELECT
	employee_id,
    department,
    salary,
    (CASE
		WHEN salary <= "25000" THEN "Under $25,000"
        WHEN salary <= "50000" THEN "$25,000-$50,000"
        WHEN salary <= "75000" THEN "$50,000-$75,000"
        WHEN salary <= "100000" THEN "$75,000-$100,000"
        WHEN salary <= "125000" THEN "$100,000-$125,000"
        WHEN salary <= "150000" THEN "$125,000-$150,000"
        WHEN salary > "150000" THEN "Over $150,000"
        ELSE 1
	END) AS salary_tier
FROM employees;
    
# Count number of employees by tier
SELECT
	salary_tier,
    COUNT(*)
FROM(
SELECT
	employee_id,
    department,
    salary,
    (CASE
		WHEN salary <= "25000" THEN "Under $25,000"
        WHEN salary <= "50000" THEN "$25,000-$50,000"
        WHEN salary <= "75000" THEN "$50,000-$75,000"
        WHEN salary <= "100000" THEN "$75,000-$100,000"
        WHEN salary <= "125000" THEN "$100,000-$125,000"
        WHEN salary <= "150000" THEN "$125,000-$150,000"
        WHEN salary > "150000" THEN "Over $150,000"
        ELSE 1
	END) AS salary_tier
FROM employees)a
GROUP BY salary_tier;

#Salary Measurables by department
SELECT
	department,
    ROUND(MIN(salary),2) AS min_salary,
    ROUND(MAX(salary), 2) AS max_salary,
    ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY department;

#Salary Measurables by region
SELECT
    e.region_id,
    r.region,
    r.country,
    ROUND(MIN(e.salary), 2) AS min_salary,
    ROUND(MAX(e.salary), 2) AS max_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id
GROUP BY e.region_id, r.region, r.country;


#Get a list of employee emails
SELECT
	CONCAT(first_name, " ", last_name) AS employee,
    email
FROM employees
WHERE email IS NOT NULL;

#Get a list of employees who need to share their emails
SELECT
	ROW_NUMBER() OVER() AS Row_Num,
    CONCAT(first_name, " ", last_name) AS employee
FROM employees
WHERE email IS NULL;

#Get a count of employees who haven't shared email
SELECT
	COUNT(*) AS employees_no_email
FROM employees
WHERE email IS NULL;

#Create table to determine correlation between time worked and salary
#Can put this into other software later (like Tableau, R, or Python) to visualize

SELECT
	ROW_NUMBER() OVER(PARTITION BY department) AS Row_Num,
    first_name,
    last_name,
    department,
    salary,
    TIMESTAMPDIFF(DAY, hire_date, CURDATE()) AS days_employed
FROM employees;


#############################
-- Examining customer data
#############################

#Count unique customers from sales
SELECT
	COUNT(DISTINCT Customer_ID) AS unique_customers
FROM sales;

#See if that matches customer list
SELECT
	COUNT(*) AS unique_customers
FROM customers;

#Number of unique customers per region
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS Row_Num,
    region,
    COUNT(*) AS num_customers
FROM customers
GROUP BY region;

#Number of unique customers per state
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS Row_Num,
    state,
    COUNT(*) AS num_customers
FROM customers
GROUP BY state;

#Number of unique customers by segment
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS Row_Num,
    segment,
    COUNT(*) AS num_customers
FROM customers
GROUP BY segment;

#Group customers by age brackets
#Get range of customer ages
SELECT
	MIN(age),
    MAX(age)
FROM customers;

#Use brackets: 18-24, 25-34, 35-44, 45-54, 55-64, and 65 and older
SELECT
	COUNT(DISTINCT Customer_ID) AS TotalCustomers,
    COUNT(DISTINCT IF(age BETWEEN 18 AND 24, Customer_ID, NULL)) AS "18-24",
    COUNT(DISTINCT IF(age BETWEEN 25 AND 34, Customer_ID, NULL)) AS "25-34",
    COUNT(DISTINCT IF(age BETWEEN 35 AND 44, Customer_ID, NULL)) AS "35-44",
    COUNT(DISTINCT IF(age BETWEEN 45 AND 54, Customer_ID, NULL)) AS "45-54",
    COUNT(DISTINCT IF(age BETWEEN 55 AND 64, Customer_ID, NULL)) AS "55-64",
    COUNT(DISTINCT IF(age >= 65, Customer_ID, NULL)) AS "65+"
FROM customers;

#Count number of orders per customer
SELECT
    ROW_NUMBER() OVER(ORDER BY COUNT(s.Order_ID) DESC) AS Row_Num,
    c.Customer_Name,
    COUNT(s.Order_ID) AS orders
FROM customers c
INNER JOIN sales s ON c.Customer_ID = s.Customer_ID
GROUP BY c.Customer_Name;


#############################
-- Examining sales data
#############################

#Reminder of customer and sales data
SELECT * FROM customers;
SELECT * FROM sales;

# Total distinct orders
SELECT
	COUNT(DISTINCT Order_ID) as OrderCount
FROM sales; 

# Average profit per order
SELECT
	COUNT(DISTINCT Order_ID) as order_count,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(SUM(profit)) / COUNT(DISTINCT Order_ID) AS avg_order_profit
FROM sales;

# Distinct order by year
SELECT
	YEAR(Order_Date) AS year,
    COUNT(DISTINCT Order_ID) as OrderCount
FROM sales
GROUP BY YEAR(Order_Date);

# Ranked Order count by year
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT(DISTINCT Order_ID) DESC) AS Row_Num,
    YEAR(Order_Date) AS year,
    COUNT(DISTINCT Order_ID) as OrderCount
FROM sales
GROUP BY YEAR(Order_Date);

# Distinct orders by month/year
SELECT
	DATE_FORMAT(Order_Date, '%Y-%m') AS year_and_month,
    COUNT(DISTINCT Order_ID) as OrderCount
FROM sales
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m');

# Ranked orders by month/year
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT(DISTINCT Order_ID) DESC) AS Row_Num,
    DATE_FORMAT(Order_Date, '%Y-%m') AS year_and_month,
    COUNT(DISTINCT Order_ID) as OrderCount
FROM sales
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m');

# Sales per year
SELECT
	YEAR(Order_Date) AS year,
    ROUND(SUM(sales)) AS total_sales
FROM sales
GROUP BY YEAR(Order_Date);

# Profits per year
SELECT
	YEAR(Order_Date) AS year,
    ROUND(SUM(profit)) AS total_profit
FROM sales
GROUP BY YEAR(Order_Date);

# Average profit per order by year
SELECT
	YEAR(Order_Date) AS year,
    COUNT(DISTINCT Order_ID) as order_count,
    ROUND(SUM(profit)) AS total_profit,
    ROUND(SUM(profit)) / COUNT(DISTINCT Order_ID) AS avg_order_profit
FROM sales
GROUP BY YEAR(Order_Date);

# Ranked orders per segment
SELECT
	RANK() OVER(ORDER BY COUNT(DISTINCT(s.Order_ID)) DESC) AS Row_Num,
    c.Segment,
    COUNT(DISTINCT(s.Order_ID)) AS Orders    
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Segment;

# Total sales
SELECT
	ROUND(SUM(sales)) AS total_sales
FROM sales;

# Sales per segment
SELECT
	c.Segment,
	ROUND(SUM(s.Sales),2) AS Sales
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Segment
ORDER BY ROUND(SUM(s.Sales),2) DESC;

# Profit by segment
SELECT
	c.Segment,
    ROUND(SUM(s.Profit)) AS Total_Profit
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Segment;

# Sales and Profit by segment
SELECT
	c.Segment,
    ROUND(SUM(s.Sales),2) AS Total_Sales,
    ROUND(SUM(s.Profit),2)AS Total_Profit
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Segment;

# Sales by region
SELECT
	c.Region,
    ROUND(SUM(s.Sales),2) AS Total_sales
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Region;

# Ranked Sales by region
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(s.Sales) DESC) AS Row_Num,
    c.Region,
    ROUND(SUM(s.Sales),2) AS Total_sales
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Region;

# Profits by region
SELECT
	c.Region,
    ROUND(SUM(s.Profit),2) AS Total_profit
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Region;

# Ranked profits by region
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(s.Profit) DESC) AS Row_Num,
    c.Region,
    ROUND(SUM(s.Profit),2) AS Total_profits
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Region;

# Most purchased items
SELECT
	Product_ID,
    Category,
    Sub_Category,
    COUNT(DISTINCT Order_ID) as distinct_orders,
    SUM(Quantity) AS total_quantity_sold
FROM sales
GROUP BY Product_ID, Category, Sub_Category
ORDER BY SUM(Quantity) DESC;

# Distinct orders & total items sold of Categories
SELECT
	Category,
    COUNT(DISTINCT Order_ID) as distinct_orders,
    SUM(Quantity) AS total_quantity_sold
FROM sales
GROUP BY Category
ORDER BY SUM(Quantity) DESC;

# Distinct orders & total items sold of Sub-categories
SELECT
	Sub_Category,
    COUNT(DISTINCT Order_ID) as distinct_orders,
    SUM(Quantity) AS total_quantity_sold
FROM sales
GROUP BY Sub_Category
ORDER BY SUM(Quantity) DESC;

# Avg Profit by item
WITH product_profit AS (
SELECT
	Product_ID,
    SUM(Quantity) AS total_quantity_sold, 
    ROUND(SUM(Profit),2) As total_profit
FROM sales
GROUP BY Product_ID)
SELECT
	ROW_NUMBER() OVER(ORDER BY total_profit / total_quantity_sold DESC) AS Row_Num,
    Product_ID,
    total_profit / total_quantity_sold AS average_profit
FROM product_profit;

# Avg Profit by category
WITH category_profit AS (
SELECT
	Category,
    SUM(Quantity) AS total_quantity_sold, 
    ROUND(SUM(Profit),2) As total_profit
FROM sales
GROUP BY Category)
SELECT
	ROW_NUMBER() OVER(ORDER BY total_profit / total_quantity_sold DESC) As Row_Num,
    Category,
    total_profit / total_quantity_sold AS avg_profit
FROM category_profit;

# Avg Profit by subcategory
WITH sub_category_profit AS (
SELECT
	Sub_Category,
    SUM(Quantity) AS total_quantity_sold, 
    ROUND(SUM(Profit),2) As total_profit
FROM sales
GROUP BY Sub_Category)
SELECT
	ROW_NUMBER() OVER(ORDER BY total_profit / total_quantity_sold DESC) As Row_Num,
    Sub_Category,
    total_profit / total_quantity_sold AS avg_profit
FROM sub_category_profit;

# Most used ship mode
SELECT
	RANK() OVER(ORDER BY COUNT(DISTINCT Order_ID) DESC) AS Row_Num,
    Ship_Mode,
    COUNT(DISTINCT Order_ID) As Orders
FROM sales
GROUP BY Ship_Mode;

# What is the average order to ship date?
SELECT * FROM sales;

SELECT
	AVG(days) AS Avg_days_to_ship
FROM (
SELECT
	DISTINCT(Order_ID),
    Order_Date,
    Ship_Date, 
    DATEDIFF(Ship_Date, Order_Date) AS days
FROM sales) a;

# Average ship date to order date based on ship mode
SELECT
	RANK() OVER(ORDER BY AVG(days)) As Row_Num,
    Ship_Mode,
    AVG(days) AS Avg_days_to_ship
FROM (
SELECT
	DISTINCT(Order_ID),
    Ship_Mode,
    Order_Date,
    Ship_Date, 
    DATEDIFF(Ship_Date, Order_Date) AS days
FROM sales) a
GROUP BY Ship_Mode;

# Quantity of items per order
SELECT
	Order_ID,
    SUM(Quantity) As Num_Items
FROM sales
GROUP BY Order_ID;

# Average quantity of items per order
SELECT
	AVG(Num_Items) AS avg_items_per_order
FROM (SELECT
	Order_ID,
    SUM(Quantity) As Num_Items
FROM sales
GROUP BY Order_ID) a;

# Average quantity of items per order by segment
SELECT
	Segment,
    AVG(Num_items) AS avg_items_per_order
FROM (
SELECT
	s.Order_ID,
    c.Segment,
    SUM(s.Quantity) As Num_Items
FROM sales s
JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY s.Order_ID, c.Segment)a
GROUP BY Segment;

# Orders that LOST profit
SELECT
	Order_ID,
    SUM(Profit) AS Order_Profit
FROM sales
GROUP BY Order_ID
HAVING SUM(Profit) < 0
ORDER BY SUM(Profit) DESC;

# Count of orders that lost profit
WITH lostprofits AS (
SELECT
	Order_ID,
    SUM(Profit) AS Order_Profit
FROM sales
GROUP BY Order_ID
HAVING SUM(Profit) < 0
ORDER BY SUM(Profit) DESC)
SELECT
	COUNT(*) AS Unprofitable_Orders
FROM lostprofits;

# Number Unprofitable orders by year
SELECT
	year,
    COUNT(*) AS Unprofitable_Orders
FROM (
SELECT
	Order_ID,
    YEAR(Order_Date) as year,
    SUM(Profit) AS Order_Profit
FROM sales
GROUP BY Order_ID, YEAR(Order_Date)
HAVING SUM(Profit) < 0
ORDER BY SUM(Profit) DESC) a
GROUP BY year
ORDER BY year;

# Number Unprofitable orders by segment
WITH unprofitableorders AS (
SELECT
	Order_ID,
    Segment,
    SUM(Profit) AS Order_Profit
FROM sales s
INNER JOIN customers c ON c.Customer_ID = s.Customer_ID
GROUP BY Order_ID, Segment
HAVING SUM(Profit) < 0
ORDER BY SUM(Profit) DESC)
SELECT
	Segment,
    COUNT(*) AS Unprofitable_Orders
FROM unprofitableorders
GROUP BY Segment
ORDER BY COUNT(*) DESC;

# MOST profitable orders
SELECT
	Order_ID,
    Order_Date,
    Customer_Name,
    Segment,
    ROUND(SUM(Profit),2) AS Profit
FROM sales s
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY Order_ID, Order_Date, Customer_Name, Segment
ORDER BY SUM(Profit) DESC
LIMIT 5;

