-- Q1: Quarterly Furniture Sales Analysis
select 'Q' + Cast(datepart(Quarter, O.ORDER_DATE) as Varchar) + '-' + cast(datepart(YEAR, O.ORDER_DATE) as Varchar) as Quarter_Year, round(Sum(O.SALES),0) as Total_Sales
from ORDERS O, PRODUCT P
where O.PRODUCT_ID = P.ID and P.NAME = 'Furniture'
Group by Year(O.ORDER_DATE), DATEPART(Quarter,O.ORDER_DATE)
ORDER BY Year(O.ORDER_DATE), DATEPART(Quarter, O.ORDER_DATE)

-- Q2: Discount Tier and Profit Analysis
select P.CATEGORY, Case when O.DISCOUNT = 0 then ' No Discount'
When O.DISCOUNT <=0.20 then 'Low'
when O.DISCOUNT <= 0.50 then 'Medium'
else 'High'
END As Discount_Tier,

COUNT(*) as Total_Order_Line,
Round(Sum(O.PROFIT),2) as Total_Profit

From ORDERS O, PRODUCT P
where O.PRODUCT_ID = P.ID
 group by  P.CATEGORY, Case when O.DISCOUNT = 0 then ' No Discount'
When O.DISCOUNT <=0.20 then 'Low'
when O.DISCOUNT <= 0.50 then 'Medium'
else 'High'
END

Order by P.CATEGORY, Discount_Tier  

-- Q3: Top Product Categories by Customer Segment
With CategoryProfit as ( 
select C.SEGMENT, P.CATEGORY , round(sum(O.SALES),2) as Total_Sales , round(sum(O.PROFIT),2) as Total_Profit 
from CUSTOMER C, ORDERS O, PRODUCT P
Where C.ID = O.CUSTOMER_ID  and P.ID = O.PRODUCT_ID 
GROUP by C.SEGMENT, P.CATEGORY 
),

RankSegment as (select SEGMENT, CATEGORY, Total_Sales, Total_Profit,
Rank() Over( PARTITION by SEGMENT ORDER by Total_Profit DESC ) as Profit_Rank
from CategoryProfit
)

Select *
from RankSegment
where Profit_Rank <= 2
-- Q4: Employee Profit Contribution by Product Category
With EmployeeCategoryProfit as(
select E.ID_EMPLOYEE , E.NAME, P.CATEGORY, ROUND(sum(O.PROFIT),2) as Profit
from EMPLOYEES E, PRODUCT P, ORDERS O
where P.ID = O.PRODUCT_ID and E.ID_EMPLOYEE = O.ID_EMPLOYEE
group by  E.ID_EMPLOYEE , E.NAME, P.CATEGORY
)

select ID_EMPLOYEE,NAME, CATEGORY , PROFIT, ROUND(Profit *100/ sum(Profit) Over(PARTITION by ID_EMPLOYEE),2) as Profit_Contribution_Percentage
from   EmployeeCategoryProfit
order by ID_EMPLOYEE, Profit_Contribution_Percentage

-- Q5: Employee-Category Profitability Ratio
ALTER FUNCTION dbo.GetProfitabilityRatio
(
    @EmployeeID TINYINT,
    @Category VARCHAR(100)
)
RETURNS DECIMAL(18,4)
AS
BEGIN

    DECLARE @TotalSales DECIMAL(18,2);
    DECLARE @TotalProfit DECIMAL(18,2);
    DECLARE @Ratio DECIMAL(18,4);

    SELECT
        @TotalSales = SUM(O.SALES),
        @TotalProfit = SUM(O.PROFIT)
    FROM ORDERS O, PRODUCT P
    WHERE O.PRODUCT_ID = P.ID
      AND O.ID_EMPLOYEE = @EmployeeID
      AND P.CATEGORY = @Category;

    IF @TotalSales IS NULL OR @TotalSales = 0
        SET @Ratio = NULL;
    ELSE
        SET @Ratio = @TotalProfit / @TotalSales;

    RETURN @Ratio;

END;

GO 

SELECT
    E.ID_EMPLOYEE,
    E.NAME,
    P.CATEGORY,
    ROUND(SUM(O.SALES), 2) AS Total_Sales,
    ROUND(SUM(O.PROFIT), 2) AS Total_Profit,
    dbo.GetProfitabilityRatio(
        E.ID_EMPLOYEE,
        P.CATEGORY
    ) AS Profitability_Ratio

FROM EMPLOYEES E, ORDERS O, PRODUCT P

WHERE E.ID_EMPLOYEE = O.ID_EMPLOYEE
AND P.ID = O.PRODUCT_ID

GROUP BY
    E.ID_EMPLOYEE,
    E.NAME,
    P.CATEGORY

ORDER BY
    E.ID_EMPLOYEE,
    Profitability_Ratio DESC;

  -- Q6: Employee Sales and Profit by Date Range

AlTER  PROCEDURE GetEmployeeSalesProfit
    @EmployeeID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
 
    SELECT
        E.ID_EMPLOYEE AS Employee_ID,
        E.NAME AS Employee_Name,
        ROUND(SUM(O.SALES), 2) AS Total_Sales,
        ROUND(SUM(O.PROFIT), 2) AS Total_Profit
 
    FROM EMPLOYEES E, ORDERS O
 
    WHERE E.ID_EMPLOYEE = O.ID_EMPLOYEE
      AND E.ID_EMPLOYEE = @EmployeeID
      AND O.ORDER_DATE BETWEEN @StartDate AND @EndDate
 
    GROUP BY
        E.ID_EMPLOYEE,
        E.NAME;
 
END;
go 
EXEC   GetEmployeeSalesProfit
    @EmployeeID = 3,
    @StartDate = '2016-12-01',
    @EndDate = '2016-12-31';

