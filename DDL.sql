CREATE TABLE Carriers (
    CarrierID INT IDENTITY(1,1) PRIMARY KEY,
    CarrierName VARCHAR(100) NOT NULL,
    Type VARCHAR(50) CHECK (Type IN ('Internal', 'External', 'Courier')),
    ContactEmail VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Rating DECIMAL(3,2) CHECK (Rating BETWEEN 0 AND 5)
);

CREATE TABLE Costs (
    CostID INT IDENTITY(1,1) PRIMARY KEY,
    ShipmentID INT NULL,          -- koszt związany z transportem
    WarehouseID INT NULL,         -- koszt związany z magazynowaniem
    CostType VARCHAR(50) NOT NULL CHECK (CostType IN ('Transport', 'Storage', 'Fuel', 'Handling', 'Other')),
    Amount DECIMAL(12,2) NOT NULL CHECK (Amount >= 0),
    Currency VARCHAR(10) DEFAULT 'PLN',
    CostDate DATE NOT NULL,
    Description VARCHAR(255),
    
    CONSTRAINT FK_Costs_Shipments FOREIGN KEY (ShipmentID)
        REFERENCES Shipments(ShipmentID),
    CONSTRAINT FK_Costs_Warehouses FOREIGN KEY (WarehouseID)
        REFERENCES Warehouses(WarehouseID)
);

CREATE TABLE Inventory (
    InventoryID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT CHECK (Quantity >= 0),
    LastUpdated DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Inventory_Warehouses FOREIGN KEY (WarehouseID)
        REFERENCES Warehouses(WarehouseID),
    CONSTRAINT FK_Inventory_Products FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID)
);

CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) CHECK (UnitPrice >= 0),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID)
);

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderType VARCHAR(50) CHECK (OrderType IN ('Inbound', 'Outbound')) NOT NULL
    Customer VARCHAR(100),         -- Odbiorca lub dostawca
    OrderDate DATE NOT NULL,
    PlannedDeliveryDate DATE,
    ActualDeliveryDate DATE,
    Status VARCHAR(50) DEFAULT 'Planned',  -- np. Planned, In Progress, Completed
    CONSTRAINT FK_Orders_Warehouses FOREIGN KEY (WarehouseID)
        REFERENCES Warehouses(WarehouseID)
);

CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(150) NOT NULL,
    SKU VARCHAR(50) UNIQUE NOT NULL,
    Category VARCHAR(50),
    WeightKG DECIMAL(10,2) CHECK (WeightKG > 0),
    VolumeM3 DECIMAL(10,5) CHECK (VolumeM3 > 0),
    Active BIT DEFAULT 1
);

CREATE TABLE Shipments (
    ShipmentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    CarrierID INT NOT NULL,
    VehicleID INT NOT NULL,
    TrailerID INT NULL,  -- NULL jeśli transport bez naczepy (np. van)
    DriverName VARCHAR(100),
    OriginWarehouseID INT NOT NULL,
    DestinationCity VARCHAR(100),
    DepartureDate DATETIME,
    ArrivalDate DATETIME,
    DistanceKM DECIMAL(10,2) CHECK (DistanceKM >= 0),
    TransportCost DECIMAL(10,2) CHECK (TransportCost >= 0),
    Status VARCHAR(50) DEFAULT 'Planned', -- Planned, In Transit, Delivered, Delayed
    GPSLastLocation VARCHAR(100),
    ShipmentType VARCHAR(50) DEFAULT 'Outbound' 
        CONSTRAINT CK_Shipments_Type CHECK (ShipmentType IN ('Inbound', 'Outbound', 'Interwarehouse', 'Other')),
    
    CONSTRAINT FK_Shipments_Orders FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID),
    CONSTRAINT FK_Shipments_Carriers FOREIGN KEY (CarrierID)
        REFERENCES Carriers(CarrierID),
    CONSTRAINT FK_Shipments_Vehicles FOREIGN KEY (VehicleID)
        REFERENCES Vehicles(VehicleID),
    CONSTRAINT FK_Shipments_Trailers FOREIGN KEY (TrailerID)
        REFERENCES Trailers(TrailerID),
    CONSTRAINT FK_Shipments_OriginWarehouse FOREIGN KEY (OriginWarehouseID)
        REFERENCES Warehouses(WarehouseID)
);

INSERT INTO Shipments (OrderID, CarrierID, VehicleID, TrailerID, DriverName, OriginWarehouseID, DestinationCity, DepartureDate, ArrivalDate, DistanceKM, TransportCost, Status, GPSLastLocation, ShipmentType)
VALUES
(1, 1, 1, 1, 'Jan Nowak', 1, 'Warszawa', '2025-11-02 08:00', '2025-11-02 12:00', 50, 800, 'Delivered', 'Warszawa Centrum', 'Inbound'),
(2, 1, 2, NULL, 'Anna Zielińska', 1, 'Warszawa', '2025-11-03 09:00', NULL, 45, 400, 'Planned', NULL, 'Outbound'),
(3, 2, 3, 3, 'Marek Wiśniewski', 2, 'Gdańsk', '2025-11-03 07:00', '2025-11-03 12:30', 80, 900, 'Delivered', 'Gdańsk', 'Inbound'),
(4, 2, 3, NULL, 'Piotr Kowalczyk', 3, 'Poznań', '2025-11-04 08:00', NULL, 60, 500, 'Planned', NULL, 'Interwarehouse');

-- usuwanie starych kolumn
ALTER TABLE LogisticsDB1.dbo.Shipments
DROP COLUMN OriginWarehouseID, DestinationCity;

ALTER TABLE LogisticsDB1.dbo.Shipments
DROP COLUMN DepartureDate, ArrivalDate;

-- dodawanie nowych kolumnn
ALTER TABLE LogisticsDB1.dbo.Shipments
ADD OriginID int NOT NULL DEFAULT 0,
    DestinationID int NOT NULL DEFAULT 0;

ALTER TABLE LogisticsDB1.dbo.Shipments
ADD 
    PlannedLoadArrival datetime NULL,
    PlannedLoadDeparture datetime NULL,
    PlannedUnloadArrival datetime NULL,
    PlannedUnloadDeparture datetime NULL,
    ActualLoadArrival datetime NULL,
    ActualLoadDeparture datetime NULL,
    ActualUnloadArrival datetime NULL,
    ActualUnloadDeparture datetime NULL;

   
CREATE TABLE Trailers (
    TrailerID INT IDENTITY(1,1) PRIMARY KEY,
    CarrierID INT NOT NULL,
    LicensePlate VARCHAR(20) NOT NULL UNIQUE,
    TrailerType VARCHAR(50) CHECK (TrailerType IN ('Standard', 'Refrigerated', 'Tanker', 'Container', 'Mega')),
    CapacityKG INT NOT NULL,
    VolumeM3 DECIMAL(10,2),
    TemperatureControlled BIT DEFAULT 0,
    Active BIT DEFAULT 1,
    LastServiceDate DATE,
    CONSTRAINT FK_Trailers_Carriers FOREIGN KEY (CarrierID)
        REFERENCES Carriers(CarrierID)
);

CREATE TABLE Warehouses (
    WarehouseID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseName VARCHAR(100) NOT NULL,
    LocationCity VARCHAR(100),
    LocationRegion VARCHAR(100),
    Capacity INT NOT NULL,
    Manager VARCHAR(100),
    Active BIT DEFAULT 1
);
