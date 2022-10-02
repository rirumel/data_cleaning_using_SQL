----------------------------------Cleaning Data in SQL Queries--------------------------
-- Let's first look into the table

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------------------------------------------------------
-- **Standardize Date Format of Sale Date data**

SELECT SaleDate, CONVERT(Date, SaleDate) as SaleDateConverted
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)

SELECT SaleDate
FROM PortfolioProject.dbo.NashvilleHousing --Unfortunately the UPDATE query didn't really make the changes

-- Let's add a new column to our table

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

SELECT SaleDateConverted
FROM PortfolioProject.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------------------------------------------------------
-- **Property Address Data**

-- There are Null values in PropertyAdress column
-- Let's do a little research if we can find any important insights

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is NULL
Order by ParcelID

-- What we notice here is that for every specific ParcelID there is a specific address and in this dataset 
-- we see same ParcelID is appeared more than once (in most of the cases)
-- So our plan is if there is a ParcelID for which we have the PropertyAddress (Not Null)
-- Then there is the same ParcelID appeared but with no PropertyAddress (Null)
-- We will simply replace the Null PropertyAddress with the Not Null information

SELECT nash1.ParcelID, nash1.PropertyAddress, nash2.ParcelID, nash2.PropertyAddress, ISNULL(nash1.PropertyAddress, nash2.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing nash1
INNER JOIN PortfolioProject.dbo.NashvilleHousing nash2
	ON nash1.ParcelID = nash2.ParcelID
	AND nash1.[UniqueID ] <> nash2.[UniqueID ]
Where nash1.PropertyAddress is NULL

--Let's update all the null values from nash1 property address with all the not null values from nash2 property address
UPDATE nash1
SET PropertyAddress = ISNULL(nash1.PropertyAddress, nash2.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing nash1
INNER JOIN PortfolioProject.dbo.NashvilleHousing nash2
	ON nash1.ParcelID = nash2.ParcelID
	AND nash1.[UniqueID ] <> nash2.[UniqueID ]
Where nash1.PropertyAddress is NULL

---------------------------------------------------------------------------------------------------------------------------------------------
-- *Split the address into Individual Columns (Address, City State)*

-- Split Property Address (Using Substring)

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is NULL
--Order by ParcelID

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Addresss
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress )) as City

FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertyConvertedAddress nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertyConvertedCity nvarchar(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertyConvertedAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertyConvertedCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress ))

SELECT PropertyConvertedAddress, PropertyConvertedCity
FROM PortfolioProject.dbo.NashvilleHousing

-- Split Owner Address (Using Parse)

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

-- Let's add the new columns into the table

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerConvertedAddress nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerConvertedCity nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerConvertedState nvarchar(255);

-- Let's add the new columns with the values

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerConvertedAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerConvertedCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerConvertedState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Let's look into the table again to see the changes
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------------------------------------------------------
-- **Rename the values of SoldAsVacant from Y/ N to Yes/No**

-- Let's look into the distinct values and their count first
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant) as CountSoldAsVacant
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY CountSoldAsVacant

-- Case Statement to change the values
SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing

-- Since we know to update the values, let's now update the table
UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END

-- Let's look into the distinct values and their count of SoldAsVacant column again
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant) as CountSoldAsVacant
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY CountSoldAsVacant

---------------------------------------------------------------------------------------------------------------------------------------------
--*Remove Duplicates*

-- Ideally it's not recommended to delete duplicates. Maybe it's better to use temp tables with unique rows only

-- Let's first figure out the duplicate rows by using Row number and Partition by and then use CTE to delete the duplicate the rows
WITH RowNumCTE as(
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 LandUse,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference,
				 SoldAsVacant
				 Order by 
					ParcelID
) as row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
Where row_num > 1


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------------------------------------------------------
-- **Since we have splitted Property Address and Owner Address, lets delete those unused columns from the table and also Tax District**

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate

-- Let's look into the table if these columns are still in the table
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing