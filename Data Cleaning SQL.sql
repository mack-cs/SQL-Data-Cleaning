--Cleaning Data in SQL Queres
Select * 
From [portfolioproject].[dbo].[nashville_housing]
----------------------------------------------------------------------------------------------------------------------------

-- Standardise Date Format
Select SaleDate, CONVERT(Date,SaleDate)
From [portfolioproject].[dbo].[nashville_housing]

ALTER TABLE [portfolioproject].[dbo].[nashville_housing]
ADD SalesDateConverted Date;

UPDATE nashville_housing  SET
SalesDateConverted = CONVERT(Date,SaleDate);

Select SaleDate,SalesDateConverted, CONVERT(Date,SaleDate)
From [portfolioproject].[dbo].[nashville_housing]

----------------------------------------------------------------------------------------------------------------------------
--Populate Property Address Data

----- Using ParcelID to check if we can get PropertyAddress in another row as seen during data checks
Select a.ParcelID,a.ParcelID,a.PropertyAddress,b.PropertyAddress,ISNULL(a.PropertyAddress, b.PropertyAddress)
From [portfolioproject].[dbo].[nashville_housing] a
JOIN [portfolioproject].[dbo].[nashville_housing] b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID -- To make sure that now row  links to itself
WHERE a.PropertyAddress IS NULL


--Updating NULL addresses with the found addresses.

----ISNULL function helps us replace null values in Column with values of another or a specified value.
UPDATE a 
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From [portfolioproject].[dbo].[nashville_housing] a
JOIN [portfolioproject].[dbo].[nashville_housing] b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID -- To make sure that now row  links to itself
WHERE a.PropertyAddress IS NULL


----------------------------------------------------------------------------------------------------------------------------
-- Breaking Out Address Into Individual Columns (Address, City)

Select PropertyAddress
From [portfolioproject].[dbo].[nashville_housing]

-- Address is separated using a coma(,) delimiter to seperate Address, City: For example "1808  FOX CHASE DR, GOODLETTSVILLE"
---- Action: I'm going to seperate the 3 mentioned above using coma delimeter

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as Address
From [portfolioproject].[dbo].[nashville_housing]

-- Creating the Address Column
ALTER TABLE [portfolioproject].[dbo].[nashville_housing]
ADD PropertySplitAddress Varchar(255);

-- Update the newly created address column with the 1st part of PropertyAddress
UPDATE nashville_housing  SET
PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1);

-- Creating the Address Column
ALTER TABLE [portfolioproject].[dbo].[nashville_housing]
ADD PropertySplitCity Varchar(255);

-- Update the newly created address column with the 1st part of PropertyAddress
UPDATE nashville_housing  SET
PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress));


----------------------------------------------------------------------------------------------------------------------------
-- Breaking Out Address Into Individual Columns (Address, City, State) - On OwnerAddress

Select OwnerAddress
From [portfolioproject].[dbo].[nashville_housing]

--Using the PARSENAME() Function that only see dots instead of comas hence REPLACE() to replace comas with dots
SELECT
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress,',','.'), 3) as Address,
	PARSENAME(REPLACE(OwnerAddress,',','.'), 2) as City,
	PARSENAME(REPLACE(OwnerAddress,',','.'), 1) as State
FROM [nashville_housing]

-- Adding OwnerSplitAddress
ALTER TABLE [portfolioproject].[dbo].[nashville_housing]
ADD OwnerSplitAddress Varchar(255);

-- Update the newly created address column with the 1st part of OwnerAddress
UPDATE nashville_housing  SET
OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3);

-- Adding OwnerSplitCity
ALTER TABLE [portfolioproject].[dbo].[nashville_housing]
ADD OwnerSplitCity Varchar(255);

-- Update the newly created address column with the 1st part of OwnerAddress
UPDATE nashville_housing  SET
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 3);

-- Adding OwnerSplitState
ALTER TABLE [portfolioproject].[dbo].[nashville_housing]
ADD OwnerSplitState Varchar(255);

-- Update the newly created address column with the 1st part of OwnerAddress
UPDATE nashville_housing  SET
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1);


----------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes No in "Sold as Vacant" field

-- Checking column cotains

SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2

-- The column contains 4 different value Y,N,Yes,No

SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y'
		THEN 'Yes'
		WHEN SoldAsVacant = 'N'
		THEN 'No'
		ELSE SoldAsVacant
	END as SoldAsVacantNew
FROM nashville_housing


-- Updating SoldAsVacant with Yes insted of 'Y' and No instead of 'N'
UPDATE nashville_housing  SET
SoldAsVacant = CASE
		WHEN SoldAsVacant = 'Y'
		THEN 'Yes'
		WHEN SoldAsVacant = 'N'
		THEN 'No'
		ELSE SoldAsVacant
	END ;


----------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates

-- Finding Duplicates
WITH RowNumCTE as (
	SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
						UniqueID
					) row_num
	FROM nashville_housing
)
DELETE FROM RowNumCTE WHERE row_num > 1

----------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict,SaleDate