
/****** Customers  ******/
SELECT *
    FROM [warehouse].[dbo].[dim_Customer]
    WHERE [N-central ParentID] = '50' AND [CustomerName] NOT LIKE 'DELETED%'
    ORDER BY [N-central CustomerID]

/****** Services  ******/
SELECT *
    FROM [warehouse].[dbo].[dim_Service]

/****** ScheduledTasks  ******/
SELECT *
    FROM [warehouse].[dbo].[fact_ScheduledTasks]

/****** Devices  ******/
SELECT *
    FROM [warehouse].[dbo].[dim_Device]
    WHERE [DeviceName] NOT LIKE 'Deleted:%'
	ORDER BY [N-central CustomerID], [DeviceName]

/****** DeviceProperties  ******/
SELECT *
	FROM [warehouse].[dbo].[DimDeviceProperties]
	ORDER BY [DeviceID]