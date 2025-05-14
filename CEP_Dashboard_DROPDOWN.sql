USE [BOB_LEGAL_PLUS_TEST]
GO
/****** Object:  StoredProcedure [dbo].[CEP_Dashboard_DROPDOWN]    Script Date: 14-05-2025 12:32:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Author: Tushar Jadhav ******/
/****** Purpose: CEP Dashboard Dropdown Values ******/

ALTER PROCEDURE  [dbo].[CEP_Dashboard_DROPDOWN]  
      @UserLoginId VARCHAR(50)
     ,@TimeKey INT
     ,@Screen VARCHAR(20) =NULL
     ,@Zone VARCHAR(MAX) = NULL
     ,@RegionType VARCHAR(MAX)=NULL
     ,@Region VARCHAR(MAX)=NULL
     ,@Branch VARCHAR(MAX)=NULL
     ,@CustomerID VARCHAR(MAX)=NULL
AS

--DECLARE 
--@UserLoginId VARCHAR(50)='userZM'
--,@TimeKey	AS INT=49999
--,@Screen    AS VARCHAR(20)='SARFAESI'
--,@Zone   AS VARCHAR(MAX)=''
--,@RegionType AS VARCHAR(MAX)=NULl
--,@Region AS VARCHAR(MAX)=NULL---'202'
--,@Branch	Varchar(MAX)=NULL---''
--,@CustomerID AS VARCHAR(MAX)=NULL---''


BEGIN
	DECLARE @UserLocationCode varchar(30),@UserLocation Varchar(10)--, @ZoneAlt_Key INT
	
	IF (ISNULL(@UserLocation,'')='' AND ISNULL(@UserLocationCode,'')='')
	BEGIN 
		SELECT @UserLocation=UserLocation,@UserLocationCode=UserLocationCode 
		FROM DimUserInfo 
		WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
		AND  UserLoginID=@UserLoginId
	END

	print  @UserLocationCode 
	print @UserLocation

	IF(OBJECT_ID('TEMPDB..#TEMPBRANCH')IS NOT NULL) 
       DROP TABLE #TEMPBRANCH
	
	SELECT * INTO #TEMPBRANCH FROM (

	SELECT DISTINCT DimBranch.BranchCode 
		,DimBranch.BranchCode2  
		,DimBranch.BranchName 
		,CONCAT(DimRegion.RegionName,' - ',CASE 
			WHEN DimBranch.SplBranchDesc = 'CFS' THEN 'CFS'
			WHEN DimBranch.SplBranchDesc = 'ARMB' THEN 'ARMB'
			WHEN DimBranch.SplBranchDesc = 'SAMB' THEN 'SAMB'
			WHEN DimBranch.SplBranchDesc = 'ROSARB' THEN 'ROSARB'
			WHEN DimBranch.SplBranchDesc = 'ZOSARB' THEN 'ZOSARB'
			ELSE 'OTHERS'
				END) AS RegionName
		--,DimBranch.BranchRegionAlt_Key  
		,CAST(DimBranch.BranchRegionAlt_Key AS VARCHAR(100)) BranchRegionAlt_Key
  		,DimZone.ZoneName AS ZoneName			-- Logic added by tushar
		,CAST(DimBranch.BranchZoneAlt_Key AS VARCHAR(100)) BranchZoneAlt_Key
		,DimBranch.SplBranchDesc	
		,CONCAT(DimBranch.BranchRegionAlt_Key,' - '
			,CASE 
				WHEN DimBranch.SplBranchDesc = 'CFS' THEN '1'
				WHEN DimBranch.SplBranchDesc = 'ARMB' THEN '2'
				WHEN DimBranch.SplBranchDesc = 'SAMB' THEN '3'
				WHEN DimBranch.SplBranchDesc = 'ROSARB' THEN '4'
				WHEN DimBranch.SplBranchDesc = 'ZOSARB' THEN '5'
				ELSE '6' END) AS CombinedSplbranchDesc

		,CASE WHEN  SplBranchDesc ='CFS'	THEN 1
			  WHEN  SplBranchDesc ='ARMB'   THEN 2
			  WHEN  SplBranchDesc ='SAMB'   THEN 3
			  WHEN  SplBranchDesc ='ROSARB' THEN 4
			  WHEN  SplBranchDesc ='ZOSARB' THEN 5
			  ELSE 6
			  END AS CODE

	FROM dbo.DimBranch  
  
	INNER JOIN DimZone      
	ON DimBranch.BranchZoneAlt_Key=DimZone.ZoneAlt_Key  
		AND DimBranch.EffectiveFromTimeKey<=@TimeKey AND DimBranch.EffectiveToTimeKey>=@TimeKey  
		AND DimZone.EffectiveFromTimeKey<=@TimeKey AND DimZone.EffectiveToTimeKey>=@TimeKey  
  
	INNER JOIN DimRegion     
	ON DimBranch.BranchRegionAlt_Key=DimRegion.RegionAlt_Key  
		AND DimRegion.EffectiveFromTimeKey<=@TimeKey AND DimRegion.EffectiveToTimeKey>=@TimeKey  
	WHERE ISNULL(SplBranchDesc,'') IN ('','ROSARB')
	AND (
		(@UserLocation='HO') OR  
		(@UserLocation='ZO' AND DimBranch.BranchZoneAlt_Key IN(SELECT * FROM dbo.Split(@UserLocationCode,','))) OR  
		(@UserLocation='RO' AND DimBranch.BranchRegionAlt_Key IN(SELECT * FROM dbo.Split(@UserLocationCode,','))) OR  
		(@UserLocation='BO' AND DimBranch.BranchCode IN(SELECT * FROM dbo.Split(@UserLocationCode,',')))
		)

	UNION

	SELECT DISTINCT DimBranch.BranchCode 
		,DimBranch.BranchCode2  
		,DimBranch.BranchName 
		,CONCAT(DimRegion.RegionName,' - ',CASE 
		WHEN DimBranch.SplBranchDesc = 'CFS' THEN 'CFS'
		WHEN DimBranch.SplBranchDesc = 'ARMB' THEN 'ARMB'
		WHEN DimBranch.SplBranchDesc = 'SAMB' THEN 'SAMB'
		WHEN DimBranch.SplBranchDesc = 'ROSARB' THEN 'ROSARB'
		WHEN DimBranch.SplBranchDesc = 'ZOSARB' THEN 'ZOSARB'
		ELSE 'OTHERS'
			END) AS RegionName
		--,DimBranch.BranchRegionAlt_Key  
		,CONCAT(CAST(DimBranch.BranchRegionAlt_Key AS VARCHAR(100)),DimBranch.Branch_Key) BranchRegionAlt_Key
  		--,DimZone.ZoneName AS ZoneName			
		,DimBranch.BranchName AS ZoneName		-- Logic added by tushar
		--,DimBranch.BranchZoneAlt_Key  
		,CONCAT(CAST(DimBranch.BranchZoneAlt_Key AS VARCHAR(100)),DimBranch.Branch_Key) BranchZoneAlt_Key
		,DimBranch.SplBranchDesc	
		,CONCAT(DimBranch.BranchRegionAlt_Key,DimBranch.Branch_Key,' - '
			,CASE 
					WHEN DimBranch.SplBranchDesc = 'CFS' THEN '1'
					WHEN DimBranch.SplBranchDesc = 'ARMB' THEN '2'
					WHEN DimBranch.SplBranchDesc = 'SAMB' THEN '3'
					WHEN DimBranch.SplBranchDesc = 'ROSARB' THEN '4'
					WHEN DimBranch.SplBranchDesc = 'ZOSARB' THEN '5'
					ELSE '6' END) AS CombinedSplbranchDesc

		,CASE WHEN  SplBranchDesc ='CFS'	THEN 1
			  WHEN  SplBranchDesc ='ARMB'   THEN 2
			  WHEN  SplBranchDesc ='SAMB'   THEN 3
			  WHEN  SplBranchDesc ='ROSARB' THEN 4
			  WHEN  SplBranchDesc ='ZOSARB' THEN 5
			  ELSE 6
			  END AS CODE
	FROM dbo.DimBranch  
  
	INNER JOIN dbo.DimZone  
	ON DimBranch.BranchZoneAlt_Key=DimZone.ZoneAlt_Key  
		AND DimBranch.EffectiveFromTimeKey<=@TimeKey AND DimBranch.EffectiveToTimeKey>=@TimeKey  
		AND DimZone.EffectiveFromTimeKey<=@TimeKey AND DimZone.EffectiveToTimeKey>=@TimeKey  
  
	INNER JOIN dbo.DimRegion 
	ON DimBranch.BranchRegionAlt_Key=DimRegion.RegionAlt_Key  
		AND DimRegion.EffectiveFromTimeKey<=@TimeKey AND DimRegion.EffectiveToTimeKey>=@TimeKey  

	WHERE ISNULL(DimBranch.SplBranchDesc,'') IN ('CFS','SAMB','ZOSARB')

	AND (
		(@UserLocation='HO') OR  
		(@UserLocation='ZO' AND DimBranch.BranchZoneAlt_Key IN(SELECT * FROM dbo.Split(@UserLocationCode,','))) OR  
		(@UserLocation='RO' AND DimBranch.BranchRegionAlt_Key IN(SELECT * FROM dbo.Split(@UserLocationCode,','))) OR  
		(@UserLocation='BO' AND DimBranch.BranchCode IN(SELECT * FROM dbo.Split(@UserLocationCode,',')))
		)

	) TAB

	--SELECT * FROM #TEMPBRANCH WHERE ISNULL(SplBranchDesc,'') IN ('','ROSARB')

	------------------------ZONE TYPE SELECTION------------------------------ 
	SELECT 'ZoneTypeSelect' TableName, '1' ZoneTypeCode, 'CFS' ZoneTypeName
	UNION
	SELECT 'ZoneTypeSelect' TableName, '3' ZoneTypeCode, 'SAMB' ZoneTypeName
	UNION
	SELECT 'ZoneTypeSelect' TableName, '5' ZoneTypeCode, 'ZOSARB' ZoneTypeName
	UNION
	SELECT 'ZoneTypeSelect' TableName, '6' ZoneTypeCode, 'OTHERS' ZoneTypeName

	------------------------ZONE CODE SELECTION---------------------------------
	--SELECT DISTINCT 'ZoneSelect' AS TableName	
	--	,BranchZoneAlt_Key AS ZoneCode	
	--	,ZoneName AS ZoneName
	--FROM #TEMPBRANCH
	--ORDER BY ZoneName

	SELECT DISTINCT 'ZoneSelect' AS TableName,* FROM
	(
		SELECT BranchZoneAlt_Key ZoneCode 
			--BranchZoneAlt_Key AS ZoneCode	
			,ZoneName AS ZoneName
			,6 AS ZoneTypeCode
			,'N' AS SplBranch
		FROM #TEMPBRANCH
		WHERE SplBranchDesc IN ('','ROSARB')

		UNION

		SELECT BranchZoneAlt_Key ZoneCode 
			 --BranchCode AS ZoneCode
			,BranchName AS ZoneName
			,CODE AS ZoneTypeCode
			,'Y' AS SplBranch
		FROM #TEMPBRANCH
		WHERE SplBranchDesc IN ('CFS','ZOSARB','SAMB')
	)TAB
	ORDER BY ZoneName

	------------------------REGION  TYPE SELECTION------------------------------ 
	
	--SELECT 'RegionTypeSelect' TableName, '1' RegionTypeCode, 'CFS' RegionTypeName
	--UNION 
	--SELECT 'RegionTypeSelect' TableName, '2' RegionTypeCode, 'ARMB' RegionTypeName
	--UNION
	--SELECT 'RegionTypeSelect' TableName, '3' RegionTypeCode, 'SAMB' RegionTypeName
	--UNION
	SELECT 'RegionTypeSelect' TableName, '4' RegionTypeCode, 'ROSARB' RegionTypeName
	UNION
	--SELECT 'RegionTypeSelect' TableName, '5' RegionTypeCode, 'ZOSARB' RegionTypeName
	--UNION
	SELECT 'RegionTypeSelect' TableName, '6' RegionTypeCode, 'OTHERS' RegionTypeName

	------------------------REGION  SELECTION------------------------------ 
	SELECT DISTINCT
		 'RegionSelect' AS TableName	
		,BranchZoneAlt_Key AS ZoneCode	
		,CombinedSplbranchDesc AS RegionCode	
		,CONCAT(ZoneName,' - ',RegionName) AS RegionName
		,CODE AS RegionTypeCode
	FROM #TEMPBRANCH
	WHERE ISNULL(SplBranchDesc,'') IN ('','ROSARB')
	ORDER BY RegionName


	------------------------BRANCH  SELECTION------------------------------ 
	SELECT DISTINCT
		 'BranchSelect' AS TableName	
		,BranchZoneAlt_Key AS ZoneCode	
		,BranchRegionAlt_Key AS RegionCode	
		,BranchCode	
		,BranchName
	FROM #TEMPBRANCH
	WHERE ISNULL(SplBranchDesc,'') IN ('','ROSARB')
	ORDER BY ZoneCode

END