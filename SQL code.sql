/*1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region.*/


select market
from dim_customer
where customer="Atliq Exclusive" and region = "APAC"
group by market;

/*2.  What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg*/


select
 X.uniq_20 as unique_products_2020,
 Y.uniq_21 as unique_products_2021,
 Round((Y.uniq_21-X.uniq_20)*100/X.uniq_20,2) as percentage_chg
 from
(
(select count(distinct(product_code)) as Uniq_20
from fact_sales_monthly
where fiscal_year = 2020) as X,

(select count(distinct(product_code)) as Uniq_21
from fact_sales_monthly
where fiscal_year = 2021) as Y

);


/*3. Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count*/

select 
segment,
count(distinct(product_code)) as product_count
from dim_product
group by segment
order by product_count desc;

/*
  4.Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference

*/

with cte1 as
(select
p.segment as A1,
count(distinct(s.product_code)) as cnt1
from dim_product p, fact_sales_monthly s
where p.product_code=s.product_code
group by p.segment,s.fiscal_year
having s.fiscal_year = '2020'),

cte2 as
(select
p.segment as A2,
count(distinct(s.product_code)) as cnt2
from dim_product p, fact_sales_monthly s
where p.product_code=s.product_code
group by p.segment,s.fiscal_year
having s.fiscal_year = '2021')

select
cte1.A1 as segment,
cte1.cnt1 as product_count_2020,
cte2.cnt2 as product_count_2021,
(cte2.cnt2 - cte1.cnt1) as difference
from cte1, cte2
where cte1.A1=cte2.A2;


/*
  5.Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost */


SELECT F.product_code, P.product, F.manufacturing_cost 
FROM fact_manufacturing_cost F JOIN dim_product P
ON F.product_code = P.product_code
WHERE manufacturing_cost
IN (
	SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
    UNION
    SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
    ) 
ORDER BY manufacturing_cost DESC ;



/*
6.  Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage*/;


select
c.customer_code,c.customer,
Round(avg(pre_invoice_discount_pct)*100,2) as averag_discount_percentage
from fact_pre_invoice_deductions fp
join dim_customer c
on fp.customer_code=c.customer_code
where fp.fiscal_year = 2021 and c.market = 'India'
group by c.customer_code,c.customer
order by averag_discount_percentage desc
limit 5;




/*
7.  Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount*/

select monthname(s.date) as month,
year(s.date) as year,
round(sum(s.sold_quantity*g.gross_price),2) as gross_sales_amount
from fact_sales_monthly s
inner join fact_gross_price g
on g.product_code=s.product_code
inner join dim_customer c
on c.customer_code=s.customer_code
where c.customer = 'Atliq Exclusive'
group by monthname(s.date),
s.fiscal_year
order by s.fiscal_year;

		

/*
8.  In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity 

*/

/*another one this one correct */
Select 
case
	when month(date) in (9,10,11) then 'Q1'
    when month(date) in (12,1,2) then 'Q2'
    when month(date) in (3,4,5) then 'Q3'
    when month(date) in (6,7,8) then 'Q4'
    end as Quarters,
    sum(sold_quantity) as total_sold_qty
from fact_sales_monthly s
where fiscal_year = '2020'
group by quarters	
order by total_sold_qty desc;




/*9.  Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage */


with cte1 as (
select
c.channel,
sum(s.sold_quantity * g.gross_price) as total_sales
from fact_sales_monthly s
join fact_gross_price g
on s.product_code=g.product_code
join dim_customer c
on s.customer_code = c.customer_code
where s.fiscal_year = 2021
group by c.channel
order by total_sales desc)

select channel,
round((total_sales)/1000000,2) as gross_sales_mln,
round(total_sales/(sum(total_sales) over())*100,2) as percentage
from cte1;


/*
10.  Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code 
product 
total_sold_quantity 
rank_order
*/

with cte1 as (
select
p.division,s.product_code,p.product,
sum(s.sold_quantity) as total_sold_qty,
rank() over(partition by p.division order by sum(s.sold_quantity)desc) as rank_order
from dim_product p
join fact_sales_monthly s
on p.product_code=s.product_code
where s.fiscal_year = 2021
group by s.product_code,p.product,p.division
)

select * from cte1 
where rank_order in(1,2,3)
order by  division,
rank_order;
