DECLARE @i int = 1;
DECLARE @max int = 500;
DECLARE @WarehouseID int;
DECLARE @OrderType varchar(50);
DECLARE @Customer varchar(100);
DECLARE @OrderDate date;
DECLARE @PlannedDeliveryDate date;
DECLARE @ActualDeliveryDate date;
DECLARE @Status varchar(50);
DECLARE @WarehouseType varchar(50);

WHILE @i <= @max
BEGIN
    -- Losowy warehouse bez faworyzowania jednego typu
    SELECT TOP 1
        @WarehouseID = WarehouseID,
        @WarehouseType = [Type]
    FROM LogisticsDB1.dbo.Warehouses
    ORDER BY NEWID();  -- losowe wybranie

    -- OrderType zależnie od typu magazynu
    IF @WarehouseType IN ('client B2C', 'client B2B')
        SET @OrderType = 'Outbound';  -- zamówienia do klienta
    ELSE
        -- dla innych magazynów w 70% Inbound, w 30% Outbound
        SET @OrderType = CASE WHEN RAND(CHECKSUM(NEWID())) < 0.7 THEN 'Inbound' ELSE 'Outbound' END;

    -- Losowy Customer (tylko dla Outbound)
    IF @OrderType = 'Outbound'
        SET @Customer = 'Customer_' + CAST(1 + CAST(RAND(CHECKSUM(NEWID())) * 50 AS int) AS varchar);
    ELSE
        SET @Customer = NULL;

    -- Losowa OrderDate październik/listopad 2025
    SET @OrderDate = DATEADD(DAY, CAST(RAND(CHECKSUM(NEWID())) * 61 AS int), '2025-10-01');

    -- PlannedDeliveryDate: 1-10 dni po OrderDate
    SET @PlannedDeliveryDate = DATEADD(DAY, 1 + CAST(RAND(CHECKSUM(NEWID())) * 10 AS int), @OrderDate);

    -- ActualDeliveryDate: czasem NULL
    IF RAND(CHECKSUM(NEWID())) < 0.7
        SET @ActualDeliveryDate = DATEADD(DAY, CAST(RAND(CHECKSUM(NEWID())) * 4 AS int), @PlannedDeliveryDate);
    ELSE
        SET @ActualDeliveryDate = NULL;

    -- Status
    SET @Status = CASE 
                    WHEN @ActualDeliveryDate IS NULL THEN 'Planned' 
                    WHEN RAND(CHECKSUM(NEWID())) < 0.05 THEN 'Cancelled'
                    ELSE 'Delivered'
                  END;

    -- Insert
    INSERT INTO LogisticsDB1.dbo.Orders
    (OrderType, WarehouseID, Customer, OrderDate, PlannedDeliveryDate, ActualDeliveryDate, Status)
    VALUES
    (@OrderType, @WarehouseID, @Customer, @OrderDate, @PlannedDeliveryDate, @ActualDeliveryDate, @Status);

    SET @i = @i + 1;
END
