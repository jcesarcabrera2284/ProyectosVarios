SELECT SalesOrderID,
       RevisionNumber,
       OrderDate
FROM   Sales.SalesOrderHeader
WHERE  EXISTS (SELECT 1
               FROM   sales.SalesPerson
               WHERE  SalesYTD > 3000000
                      AND SalesOrderHeader.SalesPersonID 
                        = Sales.SalesPerson.BusinessEntityID)