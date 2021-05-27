/****** SSMS 的 SelectTopNRows 命令的脚本  ******/
SELECT TOP (1000) [transaction_id]
      ,[cust_id]
      ,[tran_date]

      ,[prod_cat_code]
      ,[Qty]
      ,[Rate]
      ,[Tax]
      ,[total_amt]
      ,[Store_type]
      ,[id]
  FROM [chaoshi].[dbo].[Transactions]

  /******  一：数据清理  ******/

  --删除不需要的列
  Alter table [chaoshi].[dbo].[prod_cat_info] drop column prod_sub_cat_code
  Alter table [chaoshi].[dbo].[Transactions] drop column prod_subcat_code
  --对transaction_id进行查重
  SELECT transaction_id,COUNT(transaction_id) AS count FROM [chaoshi].[dbo].[Transactions] 
  GROUP BY transaction_id HAVING COUNT(transaction_id)>1
  --对transaction_id进行去重
  ALTER TABLE [chaoshi].[dbo].[Transactions] ADD id BIGINT IDENTITY(1,1) NOT NULL
  DELETE FROM [chaoshi].[dbo].[Transactions] WHERE id
  NOT IN(SELECT MIN(id) FROM [chaoshi].[dbo].[Transactions] GROUP BY transaction_id HAVING COUNT(transaction_id)>1)
  --对Qty、Rate、total_amt正负转换
  alter table [chaoshi].[dbo].[Transactions] alter column Qty INT 
  alter table [chaoshi].[dbo].[Transactions] alter column Rate INT 
  alter table [chaoshi].[dbo].[Transactions] alter column total_amt REAL 
  UPDATE [chaoshi].[dbo].[Transactions] SET Qty = -Qty WHERE Qty<0
  UPDATE [chaoshi].[dbo].[Transactions] SET Rate = -Rate WHERE Rate<0
  UPDATE [chaoshi].[dbo].[Transactions] SET total_amt = -total_amt WHERE total_amt<0

  /****** 二：数据分析 ******/

  /****** 1、用户画像分析 ******/
  --查出交易订单中消费金额最多的前500位顾客的id，出生日期，性别，城市:
  SELECT customer_Id,DOB,Gender,city_code FROM [chaoshi].[dbo].[Customer] A
  JOIN (SELECT TOP(500) cust_id,SUM(total_amt)AS sumsmoney FROM [chaoshi].[dbo].[Transactions]
  GROUP BY cust_id ORDER BY sumsmoney DESC) B
  ON A.customer_Id=B.cust_id 

  --查出消费金额前500位顾客的性别分布：
  SELECT Gender,COUNT(Gender)as counts FROM 
  (SELECT customer_Id,DOB,Gender,city_code FROM [chaoshi].[dbo].[Customer] A
  JOIN (SELECT TOP(500) cust_id,SUM(total_amt)AS sumsmoney FROM [chaoshi].[dbo].[Transactions]
  GROUP BY cust_id ORDER BY sumsmoney DESC) B
  ON A.customer_Id=B.cust_id) as test GROUP BY Gender

  --查出消费金额前500位顾客的地域分布：
  SELECT city_code,COUNT(city_code)as counts FROM 
  (SELECT customer_Id,DOB,Gender,city_code FROM [chaoshi].[dbo].[Customer] A
  JOIN (SELECT TOP(500) cust_id,SUM(total_amt)AS sumsmoney FROM [chaoshi].[dbo].[Transactions]
  GROUP BY cust_id ORDER BY sumsmoney DESC) B
  ON A.customer_Id=B.cust_id) as test GROUP BY city_code

  --男女平均消费金额对比：
  SELECT Gender,ROUND(SUM(sumsmoney)/COUNT(Gender),0) AS avgsummoney FROM
  (SELECT customer_Id,DOB,Gender,city_code,sumsmoney FROM [chaoshi].[dbo].[Customer] A
  JOIN (SELECT cust_id,SUM(total_amt)AS sumsmoney FROM [chaoshi].[dbo].[Transactions]
  GROUP BY cust_id ) B
  ON A.customer_Id=B.cust_id) as test GROUP BY Gender

  --不同城市零售平均消费金额对比：
  SELECT city_code,ROUND(AVG(sumsmoney),0)as cityavgmon FROM 
  (SELECT customer_Id,DOB,Gender,city_code,sumsmoney FROM [chaoshi].[dbo].[Customer] A
  JOIN (SELECT  cust_id,SUM(total_amt)AS sumsmoney FROM [chaoshi].[dbo].[Transactions]
  GROUP BY cust_id ) B
  ON A.customer_Id=B.cust_id) as test GROUP BY city_code

  /****** 2、商品热度分析 ******/
  --查出各商品销售数量和销售额：
  SELECT prod_cat_code,SUM(Qty) AS countprod,ROUND(SUM(total_amt),0) AS sumamt FROM [chaoshi].[dbo].[Transactions]
  GROUP BY prod_cat_code

  /****** 3、销售平台分析 ******/
  --查询每种销售渠道的销售总额并排序：
  SELECT Store_type,ROUND(SUM(total_amt),0) AS sumamt FROM [chaoshi].[dbo].[Transactions]
  GROUP BY Store_type ORDER BY sumamt ASC