use [Mobile_manufacture];

--1. List all the states in which we have customers who have bought cellphones from 2005 till today. 


select [Customer_Name],YEAR(Date) as [Year],[State] 
from [dbo].[DIM_LOCATION] as dl 
inner join
[dbo].[FACT_TRANSACTIONS] as ft
on 
dl.IDLocation = ft.IDLocation
inner join 
[dbo].[DIM_CUSTOMER] as dc 
on 
dc.IDCustomer = ft.IDCustomer
where year(Date) between (2005) and  year(Getdate());

--2. What state in the US is buying the most 'Samsung' cell phones? 

Select top 1 state,country,manufacturer_name, count(manufacturer_name) as MAX_SALES
from [dbo].[DIM_LOCATION] as dl
inner join
[dbo].[FACT_TRANSACTIONS] as ft
on 
dl.IDLocation = ft.IDLocation
inner join 
[dbo].[DIM_MODEL] as dm
on
ft.IDModel = dm.IDModel
inner join
[dbo].[DIM_MANUFACTURER] as dma
on
dma.IDManufacturer=dm.IDManufacturer
where dl.Country='US' and dma.Manufacturer_Name='Samsung'
group by Country,State,Manufacturer_Name 
order by MAX_SALES desc;

--3. Show the number of transactions for each model per zip code per state. 

select dm.IDModel,model_name,ZipCode,State, count(TotalPrice) as Total_transactions
from 
[dbo].[FACT_TRANSACTIONS] as ft
left join
[dbo].[DIM_LOCATION] as dl
on
ft.IDLocation=dl.IDLocation
left join
[dbo].[DIM_MODEL] as dm
on 
ft.IDModel = dm.IDModel
group by Model_Name,ZipCode,State,dm.IDModel;

--4. Show the cheapest cellphone (Output should contain the price also)

select top 1 idmodel,model_name,manufacturer_name,min(unit_price) as Price 
from 
[dbo].[DIM_MODEL] as dm 
inner join 
[dbo].[DIM_MANUFACTURER] as dma 
on
dm.IDManufacturer=dma.IDManufacturer 
group by manufacturer_name,idmodel, model_name 
order by Price asc;

--5. Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price. 

select top 5 manufacturer_name,model_name,count(quantity) as Total_sales,AVG(unit_price) as AVG_price
from [dbo].[FACT_TRANSACTIONS] as ft
inner join
[dbo].[DIM_MODEL] as dmo
on
dmo.IDModel=ft.IDModel
inner join
[dbo].[DIM_MANUFACTURER] as dma
on
dma.IDManufacturer=dmo.IDManufacturer
group by manufacturer_name,model_name
order by Total_sales desc, AVG_price desc;

--6. List the names of the customers and the average amount spent in 2009, where the average is higher than 500 

select customer_name,date, avg(totalprice) as AVG_spent 
from 
[dbo].[DIM_CUSTOMER] as dc
inner join
[dbo].[FACT_TRANSACTIONS] as ft
on 
dc.IDCustomer=ft.IDCustomer
where year(Date) = '2009' 
group by date,Customer_Name 
having avg(totalprice) > 500;

--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010 

SELECT top 5 model_name,count(model_name) as count, year(date) as year
FROM 
[dbo].[DIM_MODEL] as dm
inner join
[dbo].[FACT_TRANSACTIONS] as ft
on ft.IDModel = dm.IDModel
WHERE year([date]) IN (2008, 2009, 2010)
GROUP BY model_name,year(date)
HAVING COUNT(DISTINCT year(date)) >= 3
ORDER BY SUM(quantity) DESC;

--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010. 

select * from
(select ROW_NUMBER() OVER(ORDER BY sum(totalprice) DESC) AS RNUM, Manufacturer_Name, sum(totalprice) as Price
from 
[dbo].[FACT_TRANSACTIONS] as ft
inner join
[dbo].[DIM_MODEL] as dmo
on ft.IDModel=dmo.IDModel
inner join
[dbo].[DIM_MANUFACTURER] as dma
on
dmo.IDManufacturer = dma.IDManufacturer
where year(date) in('2009','2010') 
group by Manufacturer_Name)
as t1 where RNUM=2;

--9. Show the manufacturers that sold cellphones in 2010 but did not in 2009. 

SELECT Manufacturer_Name, '2009' AS NOT_SLOD_IN, '2010' AS SLOD_IN  FROM 
(SELECT Manufacturer_Name 
FROM 
DIM_MANUFACTURER AS DMR 
INNER JOIN 
DIM_MODEL AS DM 
ON 
DMR.IDManufacturer=DM.IDManufacturer 
INNER JOIN 
FACT_TRANSACTIONS AS FT 
ON 
FT.IDModel=DM.IDModel 
WHERE YEAR([DATE]) = '2010'
EXCEPT
SELECT Manufacturer_Name 
FROM 
DIM_MANUFACTURER AS DMR 
INNER JOIN 
DIM_MODEL AS DM 
ON
DMR.IDManufacturer=DM.IDManufacturer 
INNER JOIN 
FACT_TRANSACTIONS AS FT 
ON 
FT.IDModel=DM.IDModel 
WHERE YEAR([DATE]) = '2009') AS T1;

--10. Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend. 

WITH CTE AS 
(SELECT top 100 ROW_NUMBER() OVER (ORDER BY DATE) AS RNUM, [Date] , CU.IDCustomer, CUSTOMER_NAME, AVG(TOTALPRICE) AS AVG_SPEND, 
AVG(QUANTITY) AS AVG_QUANTITY  
FROM 
DIM_CUSTOMER AS CU 
LEFT JOIN 
FACT_TRANSACTIONS AS FT 
ON
CU.IDCustomer=FT.IDCustomer 
GROUP BY [Date] , CU.IDCustomer, CUSTOMER_NAME)  
SELECT T5.RNUM, T5.Date, T5.IDCustomer, T5.Customer_Name, T5.AVG_QUANTITY, T5.AVG_SPEND, (T5.AVG_SPEND - T6.AVG_SPEND)*1.0/T6.AVG_SPEND*100 as [Percentage of change in spend]
FROM 
CTE AS T5
LEFT JOIN 
CTE AS T6 
ON
T5.RNUM=T6.RNUM+1;