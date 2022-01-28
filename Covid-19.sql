/*


SQL Data Exploration -	.


SQL Queries include but are not limite to:
CTE's ,Joins ,Aggregate Functions ,Temp Tables ,Windows Functions ,Creating Views ,Converting Data Types ,Alter Tables and more!


*/
-------------------------------------------------------------------------------------

-- Overview on CovidDeaths, CovidVaccinations tables.

SELECT *
FROM CovidDeaths
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4

-------------------------------------------------------------------------------------

-- Selecting specific columns for further explorations

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-------------------------------------------------------------------------------------

-- Replacing Empty cells with Nulls.

UPDATE CovidDeaths
SET continent = NULL WHERE continent = ''

UPDATE CovidVaccinations
SET continent = NULL WHERE continent = ''

-------------------------------------------------------------------------------------

-- TotalCases Percentage of Population for each country.

WITH InfectionsVsPopulation AS (SELECT Location, MAX(total_cases) AS TotalCases , MAX(population) AS Populations
					FROM CovidDeaths
					WHERE continent is not null
					GROUP BY location) 

SELECT Location, TotalCases, Populations, TotalCases/NULLIF(Populations,0) AS DeathPercntage
FROM InfectionsVsPopulation 
ORDER BY 4 DESC

-------------------------------------------------------------------------------------

-- TotalDeath Percentage of Population for each country.

WITH DeathsVsPopulation AS (SELECT Location, MAX(total_deaths) AS TotalDeaths , MAX(population) AS Populations
					FROM CovidDeaths
					WHERE continent is not null
					GROUP BY location) 

SELECT Location, TotalDeaths, Populations, TotalDeaths/NULLIF(Populations,0) AS DeathPercntage
FROM DeathsVsPopulation 
ORDER BY 4 DESC

-------------------------------------------------------------------------------------

-- Converting Total_cases, Total_deaths Columns to Integr.
-- TotalDeath Percentage of Total Cases for each country.

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases INT

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths INT

WITH DeathsVsInfections AS (SELECT Location, MAX(Total_deaths) AS TotalDeaths , MAX(total_cases) AS TotalCases
					FROM CovidDeaths
					WHERE continent is not null
					GROUP BY location) 

SELECT Location, TotalDeaths, TotalCases, TotalDeaths/NULLIF(TotalCases,0) AS DeathPercntage
FROM DeathsVsInfections 
ORDER BY 4 DESC

-------------------------------------------------------------------------------------

-- Total Deaths count for each country.

SELECT Location, MAX(Total_deaths) as TotalDeath
FROM CovidDeaths
Where continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeath DESC

-------------------------------------------------------------------------------------

-- Total Cases count for each country.

SELECT Location, MAX(total_cases) as TotalCases
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalCases DESC

-------------------------------------------------------------------------------------

-- Contintents with the highest Total Deaths

SELECT continent, MAX(Total_deaths) as TotalDeaths
FROM CovidDeaths
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeaths desc

-------------------------------------------------------------------------------------

-- Global Death Percentage

ALTER TABLE CovidDeaths
ALTER COLUMN new_cases INT

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths INT

WITH DeathPercentage AS (SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths
						FROM CovidDeaths
						WHERE continent is not null)

SELECT TotalDeaths,TotalCases, (TotalDeaths/TotalCases) AS GlobalDeathPercentage
FROM DeathPercentage

-------------------------------------------------------------------------------------

-- Population Percentage that received atlest one Vaccine dose.

ALTER TABLE CovidVaccinations
ALTER COLUMN new_vaccinations BIGINT

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
		,SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL 
ORDER BY 2,3 

-------------------------------------------------------------------------------------

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
						,SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
					FROM CovidDeaths d
					JOIN CovidVaccinations v
					ON d.location = v.location
					AND d.date = v.date
					WHERE d.continent is not null )
SELECT *, (RollingPeopleVaccinated/Population)*100 AS RunningVacPercentage

-------------------------------------------------------------------------------------

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)

-------------------------------------------------------------------------------------

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
		,SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v
ON d.location = v.location
AND d.date = v.date

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RunningVacPercentage
FROM #PercentPopulationVaccinated

-------------------------------------------------------------------------------------

-- Creating View to store data for Visualizations purposes

CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
		,SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL

-----------------------------------------------------------------------------------------
/*

Here we go, Now we have Calculated the needed Statistics & KPIs, And Ready for the next step  Explanatory Analysis (Visualization).

*\