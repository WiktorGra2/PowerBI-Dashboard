DECLARE @OrderID int;
DECLARE @numProducts int;
DECLARE @j int;
DECLARE @ProductID int;
DECLARE @Quantity int;
DECLARE @UnitPrice decimal(10,2);

-- Cursor po wszystkich istniejących OrderID
DECLARE order_cursor CURSOR FOR
SELECT OrderID FROM LogisticsDB1.dbo.Orders;

OPEN order_cursor;
FETCH NEXT FROM order_cursor INTO @OrderID;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 90% zamówień ma 1-5 produktów, 10% zamówień ma 6-30 produktów
    IF RAND(CHECKSUM(NEWID())) < 0.9
        SET @numProducts = 1 + CAST(RAND(CHECKSUM(NEWID())) * 5 AS int); -- 1-5 produktów
    ELSE
        SET @numProducts = 6 + CAST(RAND(CHECKSUM(NEWID())) * 25 AS int); -- 6-30 produktów

    SET @j = 1;
    WHILE @j <= @numProducts
    BEGIN
        -- Losowy ProductID z istniejących produktów
        SELECT TOP 1 @ProductID = ProductID
        FROM LogisticsDB1.dbo.Products
        WHERE Active = 1
        ORDER BY NEWID();

        -- Losowa Quantity 1-50
        SET @Quantity = 1 + CAST(RAND(CHECKSUM(NEWID())) * 50 AS int);

        -- Losowa UnitPrice: między 10 a 1000
        SET @UnitPrice = CAST(10 + RAND(CHECKSUM(NEWID())) * 990 AS decimal(10,2));

        -- Insert do OrderDetails
        INSERT INTO LogisticsDB1.dbo.OrderDetails
        (OrderID, ProductID, Quantity, UnitPrice)
        VALUES
        (@OrderID, @ProductID, @Quantity, @UnitPrice);

        SET @j = @j + 1;
    END

    FETCH NEXT FROM order_cursor INTO @OrderID;
END

CLOSE order_cursor;
DEALLOCATE order_cursor;
