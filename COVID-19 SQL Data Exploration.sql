/*
Created By: Wan Mohd Fahmi Bin Fauzi
Created on: 29/08/2023
Version: 1.0
Description: SQL Data Exploration with COVID-19 Dataset
*/


--Checking data that have been imported

SELECT *
FROM CovidDeaths
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4



-- Data that I'm going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Total Cases vs. Total Deaths/ Percentage of Deaths
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS percent_of_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Percentage of Deaths from COVID-19 in Malaysia over time
-- Shows the likelihood of dying if you contract COVID in Malaysia
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS percent_of_deaths
FROM CovidDeaths
WHERE location = 'Malaysia' AND continent IS NOT NULL
ORDER BY 1,2;



-- Total Cases vs. Population
-- Percentage of population got COVID 
SELECT
	location, 
	date, 
	population, 
	total_cases, 
	(CAST(total_cases AS int)/population)*100 AS percent_inf_pop
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Percentage of population got COVID in Malaysia
SELECT 
	location, 
	date, 
	population, 
	total_cases, 
	(CAST(total_cases AS int)/population)*100 AS percent_inf_pop
FROM CovidDeaths
WHERE location = 'Malaysia' AND continent IS NOT NULL
ORDER BY 1,2;


--Countries with the highest infection rate compared to population
SELECT 
	location, 
	population, 
	MAX(CAST(total_cases AS int)) AS highest_inf_num, 
	MAX(CAST(total_cases AS int)/population)*100 AS percent_inf_pop
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;


--Countries with the highest death count per population
SELECT 
	location, 
	MAX(CAST(total_deaths AS int)) AS highest_death_num
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;





--Breaking things down by continent

-- Continents with the highest death count per population
SELECT 
	location, 
	MAX(CAST(total_deaths AS int)) AS highest_death_num
FROM CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY 2 DESC;



-- Global Numbers of Death Percentage from 1st Jan, 2020 to 24th August, 2023
SELECT (total_deaths/total_cases) * 100 AS death_percentage
FROM(
SELECT  
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths 
FROM CovidDeaths
WHERE continent IS NOT NULL AND new_cases != 0 AND new_deaths != 0
) AS temp




-- Total Population vs. Vaccinations
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



--USING CTE

--Looking at the percentage of RollingPeopleVaccinated vs. Population
WITH VaccinatedPopulations (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
)
SELECT *, ROUND((rolling_people_vaccinated/population)*100, 2) AS percent_of_vaccinated
FROM VaccinatedPopulations




-- Creating View to store data for later visualization
CREATE VIEW PopulationvsVaccination AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

