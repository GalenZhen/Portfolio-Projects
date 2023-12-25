SELECT * 
FROM nashville_housing;

-- Populate Property Address data

SELECT * 
FROM nashville_housing
-- WHERE propertyaddress IS NULL
ORDER BY parcelid


SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, COALESCE(a.propertyaddress, b.propertyaddress)
FROM nashville_housing a
JOIN nashville_housing b
	ON a.parcelid = b.parcelid
	AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NULL;

BEGIN; -- Start the transaction

UPDATE nashville_housing a
SET propertyaddress = (
	SELECT b.propertyaddress
	FROM nashville_housing b
	WHERE a.parcelid = b.parcelid
		AND a.uniqueid <> b.uniqueid
		AND b.propertyaddress IS NOT NULL
	LIMIT 1
)
WHERE a.propertyaddress IS NULL;

-- ROLLBACK; -- Undo changes within the transaction
COMMIT; -- Commit to the change

-- Double check if the property address correctly changed
SELECT *
FROM nashville_housing
WHERE parcelid LIKE '026 01 0 069.00';

-- Breaking out Address into Individual columns
SELECT propertyaddress
FROM nashville_housing
-- WHERE propertyaddress IS NULL
-- ORDER BY parcelid

SELECT
SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1) AS address,
SPLIT_PART(propertyaddress, ',', 2) AS city
FROM nashville_housing;

-- OR

SELECT
SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1) AS address,
SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress) + 2) AS city
FROM nashville_housing;

BEGIN;

ALTER TABLE nashville_housing
ADD propertysplitaddress VARCHAR(255);

UPDATE nashville_housing
SET propertysplitaddress = SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1)

ALTER TABLE nashville_housing
ADD propertysplitcity VARCHAR(255);

UPDATE nashville_housing
SET propertysplitcity = SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress) + 2)

COMMIT;



SELECT owneraddress
FROM nashville_housing;

SELECT 
SUBSTRING(owneraddress FROM 1 FOR POSITION(',' IN owneraddress) - 1) AS address,
SPLIT_PART(owneraddress, ',', 2) AS city,
SPLIT_PART(owneraddress, ',', 3) AS state
FROM nashville_housing;

BEGIN;

ALTER TABLE nashville_housing
ADD ownersplitaddress VARCHAR(255);

UPDATE nashville_housing
SET ownersplitaddress = SUBSTRING(owneraddress FROM 1 FOR POSITION(',' IN owneraddress) - 1)

ALTER TABLE nashville_housing
ADD ownersplitcity VARCHAR(255);

UPDATE nashville_housing
SET ownersplitcity = SPLIT_PART(owneraddress, ',', 2)

ALTER TABLE nashville_housing
ADD ownersplitstate VARCHAR(255);

UPDATE nashville_housing
SET ownersplitstate = SPLIT_PART(owneraddress, ',', 3)

COMMIT;

-- Change Y and N and No in "Sold as Vacant" field

SELECT DISTINCT(soldasvacant), COUNT(soldasvacant)
FROM nashville_housing
GROUP BY soldasvacant
ORDER BY 2

SELECT soldasvacant,
CASE WHEN soldasvacant = 'Y' THEN 'Yes'
	WHEN soldasvacant = 'N' THEN 'No'
	ELSE soldasvacant
	END
FROM nashville_housing

UPDATE nashville_housing
SET soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes'
	WHEN soldasvacant = 'N' THEN 'No'
	ELSE soldasvacant
	END

-- Remove duplicates
BEGIN;
WITH rownumcte AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY 
		parcelid,
		propertyaddress,
		saleprice,
		saledate,
		legalreference
		ORDER BY uniqueid
				) row_num
		
FROM nashville_housing
-- ORDER BY parcelid
)
DELETE FROM nashville_housing
WHERE (parcelid, propertyaddress, saleprice, saledate, legalreference, uniqueid) IN (
	SELECT parcelid, propertyaddress, saleprice, saledate, legalreference,uniqueid
	FROM rownumcte
WHERE row_num > 1
);

WITH rownumcte AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY 
		parcelid,
		propertyaddress,
		saleprice,
		saledate,
		legalreference
		ORDER BY uniqueid
				) row_num
		
FROM nashville_housing
-- ORDER BY parcelid
)
SELECT *
FROM rownumcte
WHERE row_num > 1
-- ORDER BY propertyaddress

COMMIT;

-- Delete Unused Columns

SELECT *
FROM nashville_housing
ORDER BY parcelid

BEGIN;
ALTER TABLE nashville_housing
DROP COLUMN owneraddress, 
DROP COLUMN taxdistrict, 
DROP COLUMN propertyaddress,
DROP COLUMN saledate;

COMMIT;


