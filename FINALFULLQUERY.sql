--Powerful query line that recognizes the database that I am using
USE [ProjectDB]

--inspecting data
Select * from [dbo].[sales_data_sample]

--checking unique values
select distinct status from [dbo].[sales_data_sample] --highlight a specifc line and run to see results for that query line (could be good to plot)
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample]--nice to plot
select distinct COUNTRY from [dbo].[sales_data_sample]--nice to plot
select distinct DEALSIZE from [dbo].[sales_data_sample]--nice to plot
select distinct TERRITORY from [dbo].[sales_data_sample]--nice to plot

--checking specific year which has good sales revenue
select distinct MONTH_ID from [dbo].[sales_data_sample]
where YEAR_ID = 2003 --full operations in 2003 & 2004 (full 12 months of valid sales), sales were low in 2005 

--Analysis
--Start by grouping sales by productline
select PRODUCTLINE, sum(sales) AS Revenue --this is the alias for sum of sales
from [dbo].[sales_data_sample] -- from our project db dataset
group by PRODUCTLINE --grouping by product line
order by 2 desc

--sales across the year (best sales year)
select YEAR_ID, sum(sales) AS Revenue --this is the alias for sum of sales
from [dbo].[sales_data_sample] -- from our project db dataset
group by YEAR_ID --grouping by product line
order by 2 desc


--checking which size is best == (Medium)
select DEALSIZE, sum(sales) AS Revenue --this is the alias for sum of sales
from [dbo].[sales_data_sample] -- from our project db dataset
group by DEALSIZE --grouping by product line
order by 2 desc

--What was the best month for sales in a specific year? How much was earned that month?
select MONTH_ID, sum(sales) AS Revenue, count(ORDERNUMBER) AS Frequency --individual order made in the month alias of frequency
from [dbo].[sales_data_sample] -- from our project db dataset
where YEAR_ID = 2004 -- specifying the year
group by MONTH_ID --grouping by month
order by 2 desc

--Novemeber seems to be best month, what product do they sell in November?
select MONTH_ID, PRODUCTLINE, sum(sales) AS Revenue, count(ORDERNUMBER) AS Frequency --individual order made in the month alias of frequency
from [dbo].[sales_data_sample] -- from our project db dataset
where YEAR_ID = 2004 AND MONTH_ID = 11-- specifying the year & month(Nov==11)
group by MONTH_ID, PRODUCTLINE --grouping by month
order by 3 desc --3 columns
--Classic cars were the best product in November

--TIMESTAMP @14:30


--Who is our best customer (RFM analysis)
--Recency-Frequency-Monetary(RFM)
--indexing technique that uses past purchase behavior to segment customers
--three segments to this report:
--Recency (how long was the customers last purchase)(last order date for this db)
--Frequency(how often do they purchase)(count of total orders for this db)
--Monetary Value(how much have they spent)(total spend for this db




--Who is our best customer (RFM analysis)



DROP TABLE IF EXISTS #rfm --one hash for local, two for global
;with rfm as
(
	Select 
		CUSTOMERNAME,
		sum(sales) AS MonetaryValue, --monetary
		avg(sales) AS AvgMonetaryValue, 
		count(ORDERNUMBER) AS Frequency, --frequency
		max(ORDERDATE) AS MostRecentOrder, --recency
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) Max_Order_Date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [ProjectDB].[dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as 
(
	select r.*, -- adding three columns for our rfm calculations
		NTILE(4) OVER(order by Recency desc) rfm_receny, --descending order for recency
		NTILE(4) OVER(order by Frequency) rfm_frequency,
		NTILE(4) OVER(order by AvgMonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_receny + rfm_frequency + rfm_monetary as rfm_cell, 
	cast(rfm_receny as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string --we used cast(column as varchar) to capture l three of the values from the rfm as a string
into #rfm -- allows our query to be split and ran in different sections
from rfm_calc c

select CUSTOMERNAME, rfm_receny, rfm_frequency, rfm_monetary, --condition to check when the rfm_cell_string then it will categorize them into different customer sections
	case
		when rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers' --finding lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- Big spenders who haven't puchased lately...slowly going away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333, 321, 422, 332, 432) then 'active' --Customers who buy often & recently, but at low price points
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from #rfm

--TIMESTAMP at 30:00


--What products are most often sold together?
--select * from [ProjectDB].[dbo].[sales_data_sample] where ORDERNUMBER = 10411

select DISTINCT OrderNumber, stuff( --arguments for the stuff function come after the xml, made into a string

	(select ',' + PRODUCTCODE -- add comma to append the productcode to the order
	from [ProjectDB].[dbo].[sales_data_sample] p --alias p
	where ORDERNUMBER in
		(


			select ORDERNUMBER --checking for two or more orders
			from(
				select ORDERNUMBER, count(*) rn
				FROM [ProjectDB].[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m --have to name this whole subquery
			where rn = 3 --amount of orders with 3 products
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path ('')), 1, 1, '')  ProductCodes--added to append the productline using xml code (you can click through the xml link to see  one line of the appended productlines)
from [ProjectDB].[dbo].[sales_data_sample] s --alias s
order by 2 desc --now you only see top orders with 2 products