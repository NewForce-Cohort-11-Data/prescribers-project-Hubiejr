
--MVP PRESCRIBERS 

-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.


SELECT pr.npi, pr.nppes_provider_last_org_name, SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON pr.npi = ps.npi
GROUP BY pr.npi, pr.nppes_provider_last_org_name
ORDER BY total_claims DESC
LIMIT 1;


-- answer
SELECT npi,SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC;

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT pr.npi, pr.nppes_provider_first_name, pr.nppes_provider_last_org_name, pr.specialty_description, SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON pr.npi = ps.npi
GROUP BY pr.npi, pr.nppes_provider_last_org_name, pr.nppes_provider_first_name, pr.specialty_description
ORDER BY total_claims DESC
LIMIT 1;


-- answer

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY total_claims DESC;

-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

-- prescriber has specialty_description need to get there 

SELECT pr.specialty_description, SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
GROUP BY specialty_description
ORDER BY total_claims DESC;



-- b. Which specialty had the most total number of claims for opioids?

SELECT pr.specialty_description, d.drug_name AS d_name, SUM(ps.total_claim_count) AS total_claims 
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug d ON d.drug_name = ps.drug_name
WHERE d.drug_name LIKE '%OXYCODONE%'
GROUP BY specialty_description, d_name
ORDER BY total_claims DESC;

-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

-- use left join if there is no matching rows on the right
-- use inner join if there is matching rows otherwise you will be confused why it ran but nothing showed up

SELECT DISTINCT pr.specialty_description
FROM prescriber pr
LEFT JOIN prescription ps ON ps.npi = pr.npi
WHERE ps.npi IS NULL;

-- answer
SELECT specialty_description, SUM(total_claim_count) AS total_claims 
FROM prescriber pr
LEFT JOIN prescription
USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL;


-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT pr.specialty_description, d.drug_name AS d_name, SUM(ps.total_claim_count) AS total_claims 
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug d ON d.drug_name = ps.drug_name
WHERE d.drug_name LIKE '%OXYCODONE%'
GROUP BY specialty_description, d_name
ORDER BY total_claims DESC;

-- answer
SELECT
	specialty_description,
	ROUND((SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END)/ SUM(total_claim_count)),2) * 100
AS percent_opioid
FROM prescriber
LEFT JOIN prescription
USING(npi)
LEFT JOIN drug
USING(drug_name)
GROUP BY specialty_description
ORDER BY percent_opioid DESC NULLS LAST;

-- 3. a. Which drug (generic_name) had the highest total drug cost?

-- prescription has total_drug_cost
-- drug has generic_name
-- they both have the name drug_name

SELECT generic_name, SUM(ps.total_drug_cost)::MONEY AS t_drug_cost 
FROM drug
INNER JOIN prescription ps ON ps.drug_name = drug.drug_name
GROUP BY generic_name
ORDER BY t_drug_cost DESC
LIMIT 1;

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

-- Prescription has total_day_supply you need to divide total_drug_cost / total_day_supply

SELECT generic_name, ROUND(SUM(ps.total_drug_cost) / SUM(ps.total_day_supply),2)::MONEY AS cost_per_day
FROM drug
INNER JOIN prescription ps ON ps.drug_name = drug.drug_name
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 1;

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name,
CASE
	WHEN opioid_drug_flag = 'Y'  THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END drug_type
FROM drug;

-- USE CASE STATEMENT 
-- FROM dug table
-- SELECT drug_name

-- -- syntax for CASE 
-- -- SELECT
-- -- CASE
-- 		WHEN 'g' THEN 'general audiences'
-- -- FROM


-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

-- total_drug_costs is under prescription

SELECT
CASE
	WHEN opioid_drug_flag = 'Y'  THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END drug_type,  SUM(ps.total_drug_cost::MONEY) AS t_drug_cost
FROM drug 
INNER JOIN prescription ps ON ps.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y' OR antibiotic_drug_flag = 'Y' 
GROUP BY drug_type
ORDER BY t_drug_cost;

SELECT *
FROM cbsa

-- 5.a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa.cbsaname) AS cbsa_Tennessee
FROM cbsa
WHERE cbsaname LIKE '%, TN%';

-- answer
SELECT
	COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state ='TN';

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

-- inner join from population using fipscountry
SELECT cbsaname, SUM(pop.population) AS total_pop, MAX(cbsa) AS largest_pop_cbsa
FROM cbsa
INNER JOIN population pop ON pop.fipscounty = cbsa.fipscounty
GROUP BY cbsaname
ORDER BY largest_pop_cbsa DESC;


SELECT cbsaname, SUM(pop.population) AS total_pop, MIN(cbsa) AS smallest_pop_cbsa
FROM cbsa
INNER JOIN population pop ON pop.fipscounty = cbsa.fipscounty
GROUP BY cbsaname
ORDER BY smallest_pop_cbsa ASC;


-- answer
SELECT
	cbsaname, SUM(population) AS total_pop
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;


-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, pop.population
FROM fips_county fips
INNER JOIN population pop USING(fipscounty)
WHERE fipscounty NOT IN (SELECT fipscounty FROM cbsa)
ORDER BY pop.population DESC
LIMIT 1;

-- answer

SELECT
	county, population
FROM fips_county
INNER JOIN population
USING(fipscounty)
WHERE fipscounty NOT IN (SELECT fipscounty FROM cbsa)
ORDER BY population DESC;

-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
-- FROM prescription 
-- total_claim_count >= 3000 
SELECT drug_name, total_claim_count
FROM prescription ps
WHERE total_claim_count >= 3000;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug.drug_name, total_claim_count,
CASE
	WHEN opioid_drug_flag = 'Y'  THEN 'opioid'
	ELSE 'not_an_opioid'
END drug_opioid
FROM prescription ps
INNER JOIN drug ON drug.drug_name = ps.drug_name
WHERE total_claim_count >= 3000
GROUP BY drug.drug_name, total_claim_count,opioid_drug_flag
ORDER BY total_claim_count DESC;


-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT pr.nppes_provider_first_name, pr.nppes_provider_last_org_name, drug.drug_name, total_claim_count,
CASE
	WHEN opioid_drug_flag = 'Y'  THEN 'opioid'
	ELSE 'not_an_opioid'
END drug_opioid
FROM prescription ps
INNER JOIN drug ON drug.drug_name = ps.drug_name
INNER JOIN prescriber pr ON pr.npi = ps.npi
WHERE total_claim_count >= 3000
GROUP BY drug.drug_name, total_claim_count,opioid_drug_flag,  pr.nppes_provider_first_name, pr.nppes_provider_last_org_name
ORDER BY total_claim_count DESC;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


SELECT DISTINCT pr.npi, d.drug_name
FROM prescriber pr
INNER JOIN prescription ps ON pr.npi = ps.npi
INNER JOIN drug d ON d.drug_name = ps.drug_name
WHERE specialty_description = 'Pain Management'
	AND pr.nppes_provider_city = 'NASHVILLE' 
	AND d.opioid_drug_flag = 'Y'
ORDER BY pr.npi, d.drug_name ASC;


-- answer
SELECT npi, drug_name 
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';



-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi, drug.drug_name ,total_claim_count
FROM prescriber
CROSS JOIN drug
INNER JOIN prescription
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT DISTINCT pr.npi, d.drug_name, COALESCE(ps.total_claim_count,0) AS total_claim_count
FROM prescriber pr
CROSS JOIN drug d 
LEFT JOIN prescription ps ON pr.npi = ps.npi AND d.drug_name = ps.drug_name
WHERE specialty_description = 'Pain Management'
	AND pr.nppes_provider_city = 'NASHVILLE' 
	AND d.opioid_drug_flag = 'Y'
ORDER BY total_claim_count ASC;

-- answer

SELECT npi, drug.drug_name ,COALESCE(total_claim_count,0) AS total_claims
FROM prescriber
CROSS JOIN drug
INNER JOIN prescription
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY total_claims DESC;

-- GROUPING SETS

-- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this:

SELECT specialty_description, SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
WHERE pr.specialty_description IN ('Interventional Pain Management','Pain Management')
GROUP BY specialty_description
ORDER BY total_claims;


-- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

SELECT SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
WHERE specialty_description IN ('Interventional Pain Management','Pain Management')

UNION

SELECT SUM(ps.total_claim_count) AS total_claims
FROM prescription ps
INNER JOIN prescriber pr ON ps.npi = pr.npi
WHERE specialty_description IN ('Interventional Pain Management','Pain Management')

-- 3. Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.

SELECT SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
WHERE specialty_description IN ('Interventional Pain Management','Pain Management')
GROUP BY GROUPING SETS (specialty_description, ())
LIMIT 1;


-- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:

SELECT pr.specialty_description,
    d.opioid_drug_flag,
CASE
	WHEN opioid_drug_flag = 'Y'  THEN 'opioid'
	ELSE 'not_an_opioid'
END AS drug_opioid, SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug d ON d.drug_name = ps.drug_name
WHERE specialty_description IN ('Interventional Pain Management','Pain Management')
GROUP BY GROUPING SETS (pr.specialty_description,d.opioid_drug_flag,  ())
ORDER BY pr.specialty_description, d.opioid_drug_flag DESC;


-- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?

SELECT pr.specialty_description,
    d.opioid_drug_flag,
CASE
	WHEN opioid_drug_flag = 'Y'  THEN 'opioid'
	ELSE 'not_an_opioid'
END AS drug_opioid, SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug d ON d.drug_name = ps.drug_name
WHERE specialty_description IN ('Interventional Pain Management','Pain Management')
GROUP BY ROLLUP ( d.opioid_drug_flag, pr.specialty_description)
ORDER BY pr.specialty_description, d.opioid_drug_flag DESC;



-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?

SELECT pr.specialty_description,
    d.opioid_drug_flag,
CASE
	WHEN opioid_drug_flag = 'Y'  THEN 'opioid'
	ELSE 'not_an_opioid'
END AS drug_opioid, SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug d ON d.drug_name = ps.drug_name
WHERE specialty_description IN ('Interventional Pain Management','Pain Management')
GROUP BY ROLLUP (pr.specialty_description, d.opioid_drug_flag)
ORDER BY pr.specialty_description, d.opioid_drug_flag DESC;


-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?

SELECT pr.specialty_description,
    d.opioid_drug_flag,
CASE
	WHEN opioid_drug_flag = 'Y'  THEN 'opioid'
	ELSE 'not_an_opioid'
END AS drug_opioid, SUM(ps.total_claim_count) AS total_claims
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug d ON d.drug_name = ps.drug_name
WHERE specialty_description IN ('Interventional Pain Management','Pain Management')
GROUP BY CUBE (pr.specialty_description, d.opioid_drug_flag)
ORDER BY pr.specialty_description, d.opioid_drug_flag DESC;


-- 8. in this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.


-- Hint #1: First write a query which will label each drug in the drug table using the six categories listed above. Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column. Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.


-- COULD NOT FINISH
SELECT 
    fip.county AS city,
    CASE 
        WHEN UPPER(d.generic_name) LIKE '%CODEINE%' THEN 'codeine'
        WHEN UPPER(d.generic_name) LIKE '%FENTANYL%' THEN 'fentanyl'
        WHEN UPPER(d.generic_name) LIKE '%HYDROCODONE%' THEN 'hydrocodone'
        WHEN UPPER(d.generic_name) LIKE '%MORPHINE%' THEN 'morphine'
        WHEN UPPER(d.generic_name) LIKE '%OXYCODONE%' THEN 'oxycodone'
        WHEN UPPER(d.generic_name) LIKE '%OXYMORPHONE%' THEN 'oxymorphone'
        ELSE 'other'
    END AS opioid_category
FROM prescription ps
INNER JOIN prescriber pr ON ps.npi = pr.npi
INNER JOIN drug d ON ps.drug_name = d.drug_name
INNER JOIN fips_county fip ON pr.nppes_provider_city = fip.county
WHERE fip.county IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
AND UPPER(d.generic_name) LIKE '%CODEINE%' 
   OR UPPER(d.generic_name) LIKE '%FENTANYL%'
   OR UPPER(d.generic_name) LIKE '%HYDROCODONE%'
   OR UPPER(d.generic_name) LIKE '%MORPHINE%'
   OR UPPER(d.generic_name) LIKE '%OXYCODONE%'
   OR UPPER(d.generic_name) LIKE '%OXYMORPHONE%';


--BONUS
-- 1.How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(npi) AS npi_count
FROM prescriber

-- 2. a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT generic_name, total_claim_count, pr.specialty_description
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug ON ps.drug_name = drug.drug_name
WHERE pr.specialty_description LIKE '%Family Practice%'
ORDER BY pr.specialty_description, total_claim_count DESC
LIMIT 5;

-- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name, total_claim_count, pr.specialty_description
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug ON ps.drug_name = drug.drug_name
WHERE pr.specialty_description LIKE '%Cardiology%'
ORDER BY pr.specialty_description, total_claim_count DESC
LIMIT 5;

-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

(SELECT generic_name, total_claim_count, pr.specialty_description
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug ON ps.drug_name = drug.drug_name
WHERE pr.specialty_description LIKE '%Family Practice%'
ORDER BY total_claim_count DESC
LIMIT 5)

UNION ALL

(SELECT generic_name, total_claim_count, pr.specialty_description
FROM prescriber pr
INNER JOIN prescription ps ON ps.npi = pr.npi
INNER JOIN drug ON ps.drug_name = drug.drug_name
WHERE pr.specialty_description LIKE '%Cardiology%'
ORDER BY total_claim_count DESC
LIMIT 5)

ORDER BY specialty_description, total_claim_count DESC;

-- 3.Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee. 

--a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT DISTINCT npi, SUM(total_claim_count) OVER(PARTITION BY pr.npi) AS total_claims,
pr.nppes_provider_city
FROM prescription ps
INNER JOIN prescriber pr USING(npi)
WHERE pr.nppes_provider_city LIKE '%NASHVILLE%'
ORDER BY total_claims DESC
LIMIT 5;

-- b. Now, report the same for Memphis.

SELECT DISTINCT npi, SUM(total_claim_count) OVER(PARTITION BY pr.npi) AS total_claims,
pr.nppes_provider_city
FROM prescription ps
INNER JOIN prescriber pr USING(npi)
WHERE pr.nppes_provider_city LIKE '%MEMPHIS%'
ORDER BY total_claims DESC
LIMIT 5;

-- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT DISTINCT npi, SUM(total_claim_count) OVER(PARTITION BY pr.npi) AS total_claims,
pr.nppes_provider_city
FROM prescription ps
INNER JOIN prescriber pr USING(npi)
WHERE nppes_provider_city IN ('KNOXVILLE', 'CHATTANOOGA', 'NASHVILLE', 'MEMPHIS')
ORDER BY total_claims DESC;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT fc.county, fc.fipscounty, od.overdose_deaths
FROM overdose_deaths od
INNER JOIN fips_county fc ON fc.fipscounty::NUMERIC = od.fipscounty::NUMERIC
WHERE od.overdose_deaths > (SELECT AVG(overdose_deaths) FROM overdose_deaths)
ORDER BY od.overdose_deaths DESC;


-- 5. a. Write a query that finds the total population of Tennessee.

SELECT fc.state, SUM(population) AS sum_pop
FROM population pop
INNER JOIN fips_county fc USING(fipscounty)
WHERE fc.state LIKE '%TN%'
GROUP BY fc.state;


-- b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT fc.state, fc.county, pop.population * 100.00 / SUM(population) OVER() AS percentage_pop
FROM population pop
INNER JOIN fips_county fc USING(fipscounty)
INNER JOIN overdose_deaths od ON fc.fipscounty::NUMERIC = od.fipscounty::NUMERIC
WHERE fc.state LIKE '%TN%';

