/*
Covid 19 Data Exploration

Skills used: Joins, CTE, Temp Table, Aggregate Functions, Windows Functions, Creating Views, Converting Data Types

*/


--Checking data that have been imported

SELECT *
FROM dbo.CovidDeaths
ORDER BY 3,4

SELECT *
FROM dbo.CovidVaccinations
ORDER BY 3,4


--Selecting data that I'm going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract Covid in Malaysia
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths as int)/CAST(total_cases as int))*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE location = 'Malaysia'
AND continent IS NOT NULL
ORDER BY 1,2


--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Looking at Countries with Highest Infection Rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


--Showing Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC


--GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeath, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL and new_cases <> 0 and new_deaths <> 0
GROUP BY date
ORDER BY date



-- Change the new_vaccinations column datatype to float
ALTER TABLE CovidVaccinations
ALTER COLUMN new_vaccinations float

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS dea
JOIN dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



-- USING CTE to perform Calculations on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS dea
JOIN dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PeopleVacPercent
FROM PopvsVac


-- Using Temp Table to perform Calculations on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS dea
JOIN dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PeopleVacPercent
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualization

CREATE VIEW PopulationvsVaccination AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS dea
JOIN dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
