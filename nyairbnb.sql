/*
New York City Airbnb Data Exploration 
*/

-- Minor data cleaning
-- Removing columns irrelevant to analysis
ALTER TABLE nylist
DROP COLUMN scrape_id, last_scraped, source, host_verifications, [host_has_profile_pic], [host_identity_verified],
			host_about, calendar_last_scraped, calendar_updated, host_thumbnail_url, host_url, column14, column21
-- Removing rows where price isn't listed
DELETE FROM nylist
WHERE price IS NULL;
-- Removing duplicate listings determined by matching IDs and names
DELETE FROM nylist
WHERE nylist.id in 
	(SELECT id
		FROM
		(SELECT id, name, ROW_NUMBER() OVER (PARTITION BY id, name order by name) as row
		FROM nylist) AS sub
	WHERE row > 1)


-- Creating a new column where prices are put into a bracket
 
 
 ALTER TABLE listings
 ADD Price_Range nvarchar(255)

 UPDATE nylist SET Price_Range =
	( CASE
	WHEN price BETWEEN 1 AND 100 THEN '[1 - 100]'
	WHEN price BETWEEN 101 AND 500 THEN '[100 - 500]'
	WHEN price BETWEEN 501 AND 1000 THEN '[500 - 1000]'
	WHEN price BETWEEN 1001 AND 5000 THEN '[1000 - 5000]'
	WHEN price BETWEEN 5001 AND 9999 THEN '[5000 - 9999]'
	ELSE '[1000 - )'
END )


-- NYC Borough's Share Airbnbs
-- There are 22268 properties listed in this dataset after cleansing

SELECT Borough, (COUNT(*)* 100) / 22268 AS Share
FROM nylist
GROUP BY Borough
ORDER BY Share DESC


--Number of Airbnb properties in price brackets


SELECT property_type, Price_Range, COUNT(*) AS Property_Count
FROM nylist
GROUP BY Price_Range, property_type
ORDER BY Property_Count DESC


--Most expensive NYC boroughs to rent an Airbnb by Average pricing
--(Price entry is in a Nightly rate)


SELECT Borough, AVG(Price) AS Average_pricing
FROM nylist
GROUP BY Borough
ORDER BY Average_pricing DESC

--Detailed look of the inner neighbourhoods Airbnb price ranking

SELECT Borough, neighbourhood, name, price AS nighty_rate
	, MIN(price) OVER (PARTITION BY Borough) AS Cheapest_Property
	, MAX(price) OVER (PARTITION BY Borough) AS Priciest_Property
	, AVG(price) OVER (PARTITION BY neighbourhood) AS AVG_nieghbourhood_pricing
	, RANK() OVER (PARTITION BY Borough ORDER BY price DESC) AS neighbourhood_AVG_ranking
FROM nylist


--Top 10 Most popular property type according to number of reviews


SELECT TOP(10) property_type, SUM(number_of_reviews) AS number_of_reviews
FROM nylist
GROUP BY property_type
ORDER BY number_of_reviews DESC


 -- Cheapest options with basic amenities in Manhattan
 -- According to earlier queries we know Manhattan is the most expensive and most occupied
 -- But what basic amenities can clients enjoy during their stay when they're on a budget?


 SELECT name, price, amenities,
 CASE
	WHEN amenities NOT LIKE '%Air conditioning%' THEN 'No AC'
	ELSE 'Has AC/s'
 END AS Air_Conditioning,
 CASE
	WHEN amenities NOT LIKE '%Wifi%' THEN 'No Wifi'
	ELSE 'Has Wifi'
 END AS Wifi_Access
 FROM nylist
 WHERE Borough = 'Manhattan' AND Price_Range = '[1 - 100]'


 -- Short Term vs Long Term stay properties in Percentage
 -- (Short Term Stay in NY is under 30 days)

 SELECT (COUNT(*) * 100) / 22268 AS Short_Stay, 100 - (COUNT(*) * 100) / 22268 AS Long_Stay
 FROM nylist
 WHERE minimum_nights < 30


 -- Creating a View of a joined table between "calender"and "nylist" and
 -- limiting the data to the last 3months of 2014

CREATE VIEW Q4 AS
SELECT name, Borough, neighbourhood, property_type, Price_Range,
	amenities, number_of_reviews, reviews_per_month, b.*
FROM nylist AS a
JOIN calendar AS b
ON a.id = b.listing_id
WHERE DATEPART(YEAR, date) = 2024 AND DATEPART(MONTH, date) > 9

-- Total Airbnb Revenue of NYC boroughs in the Final Quarter of 2024
-- (Based on future bookings marked on the calender table)


SELECT Borough, '$'+convert(varchar(MAX), SUM(price * Bookings), -1) AS Q4_Total_Revenue
FROM (
SELECT Borough, price, COUNT(*) AS Bookings
FROM Q4
GROUP BY Borough, price) AS sub
GROUP BY Borough
ORDER BY Q4_Total_Revenue DESC