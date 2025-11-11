DECLARE @WarehouseID int;
DECLARE @ProductID int;
DECLARE @Quantity int;
DECLARE @i int = 1;
DECLARE @numWarehouses int;
DECLARE @maxWarehouses int;

-- Dla każdego produktu losujemy w ilu magazynach się pojawi (0-5)
WHILE @i <= 200
BEGIN
    SET @ProductID = @i;

    -- Losowa liczba magazynów, w których produkt będzie dostępny
    -- większość produktów w 1-3 magazynach, kilka w 4-5, niektóre w 0
    DECLARE @rand float = RAND(CHECKSUM(NEWID()));

    IF @rand < 0.05
        SET @maxWarehouses = 0; -- produkt nie występuje w żadnym magazynie
    ELSE IF @rand < 0.75
        SET @maxWarehouses = 1 + CAST(RAND(CHECKSUM(NEWID())) * 3 AS int); -- 1-3 magazyny
    ELSE
        SET @maxWarehouses = 4 + CAST(RAND(CHECKSUM(NEWID())) * 2 AS int); -- 4-5 magazynów

    SET @numWarehouses = 1;

    WHILE @numWarehouses <= @maxWarehouses
    BEGIN
        -- Losowy magazyn z zakresu 34-64
        SET @WarehouseID = 34 + CAST(RAND(CHECKSUM(NEWID())) * 31 AS int);

        -- Losowa ilość produktów: 1-50 dla rzadkich, 50-500 dla częstych
        IF @rand < 0.1
            SET @Quantity = 1 + CAST(RAND(CHECKSUM(NEWID())) * 50 AS int);
        ELSE
            SET @Quantity = 50 + CAST(RAND(CHECKSUM(NEWID())) * 450 AS int);

        -- Wstawienie rekordu
        INSERT INTO LogisticsDB1.dbo.Inventory
        (WarehouseID, ProductID, Quantity)
        VALUES
        (@WarehouseID, @ProductID, @Quantity);

        SET @numWarehouses = @numWarehouses + 1;
    END

    SET @i = @i + 1;
END
