-- Chuyển đổi kiểu dữ liệu phù hợp cho các trường ( sử dụng câu lệnh ALTER)--
ALTER TABLE public.sales_dataset_rfm_prj
ALTER COLUMN ordernumber TYPE integer USING (ordernumber::integer),
ALTER COLUMN quantityordered TYPE integer USING (quantityordered::integer),
ALTER COLUMN priceeach TYPE numeric USING (priceeach::numeric),
ALTER COLUMN orderlinenumber TYPE integer USING (orderlinenumber::integer),
ALTER COLUMN sales TYPE numeric USING (sales::numeric),
ALTER COLUMN orderdate TYPE date USING (orderdate::date),
ALTER COLUMN msrp TYPE integer USING (msrp::integer)
--Check NULL/BLANK (‘’)  ở các trường: ORDERNUMBER, QUANTITYORDERED, PRICEEACH, ORDERLINENUMBER, SALES, ORDERDATE--
select * from public.sales_dataset_rfm_prj
where ordernumber is null 
or priceeach is null
or orderlinenumber is null
or sales is null
or orderdate is null 
-- Update table--
alter table public.sales_dataset_rfm_prj
add column CONTACTLASTNAME varchar(50),
add column CONTACTFIRSTNAME varchar(50)
update public.sales_dataset_rfm_prj
set contactlastname=substring(contactfullname from 1 for position('-'in contactfullname)-1),
	contactfirstname=substring(contactfullname from (position('-'in contactfullname)+1) for length (contactfullname)-position('-'in contactfullname));
--update qtr, month, year--
alter table public.sales_dataset_rfm_prj
add column QTR_ID numeric, 
add column MONTH_ID numeric,
add column YEAR_ID numeric
update  public.sales_dataset_rfm_prj
set QTR_ID = extract(quarter from orderdate),
MONTH_ID = extract(month from orderdate),
YEAR_ID = extract(year from orderdate)
--Outlier--
with twt_min_max as
	(select q1-1,5*iqr as min_value,
q3+1,5*iqr as max_value
from
(select 
percentile_cont (0.25) within group (order by QUANTITYORDERED) as Q1,
percentile_cont (0.75) within group (order by QUANTITYORDERED) as Q3,
percentile_cont (0.75) within group (order by QUANTITYORDERED)- percentile_cont (0.25) within group (order by QUANTITYORDERED) as IQR
from public.sales_dataset_rfm_prj) as a),
twt_outlier as (select * from public.sales_dataset_rfm_prj
where QUANTITYORDERED <(select min_value from twt_min_max)
or QUANTITYORDERED >(select max_value from twt_min_max))
C1:update  public.sales_dataset_rfm_prj 
set QUANTITYORDERED=(select avg(QUANTITYORDERED) from public.sales_dataset_rfm_prj)
where QUANTITYORDERED in (select QUANTITYORDERED from twt_outlier )
C2:delete from public.sales_dataset_rfm_prj
where QUANTITYORDERED in (select QUANTITYORDERED from twt_outlier)
--create table--
create table SALES_DATASET_RFM_PRJ_CLEAN as
SELECT * FROM public.sales_dataset_rfm_prj
