SELECT * 
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- SELECT * 
-- FROM covidvaccinations
-- ORDER BY 3,4

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, 
(total_deaths::NUMERIC/total_cases)*100 as deathpercentage
FROM coviddeaths
WHERE location ILIKE '%Canada%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT location, date, population, total_cases,
(total_cases::NUMERIC/population)*100 as percentpopulationinfected
FROM coviddeaths
WHERE location ILIKE '%Canada%'
ORDER BY 1,2

-- Looking at Counties with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount,
MAX((total_cases::NUMERIC/population))*100 as percentpopulationinfected
FROM coviddeaths
-- WHERE location ILIKE '%Canada%'
GROUP BY location, population
ORDER BY percentpopulationinfected DESC NULLS LAST

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) as totaldeathcount
FROM coviddeaths
-- WHERE location ILIKE '%Canada%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totaldeathcount DESC NULLS LAST

-- Breaking Things Down by Continent


-- Showing continents with the highest death count per population

SELECT continent, MAX(total_deaths) as totaldeathcount
FROM coviddeaths
-- WHERE location ILIKE '%Canada%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totaldeathcount DESC NULLS LAST

-- GLOBAL NUMBERS

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths::NUMERIC)/SUM(new_cases)*100 as deathpercentage
FROM coviddeaths
--WHERE location ILIKE '%Canada%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE

WITH popvsvac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (rollingpeoplevaccinated/population)*100
FROM popvsvac

-- TEMP TABLE

DROP TABLE IF EXISTS percentpopulationvaccinated

CREATE TEMP TABLE percentpopulationvaccinated
(continent VARCHAR(255),
location VARCHAR(255),
date DATE,
population NUMERIC,
new_vaccinations NUMERIC,
rollingpeoplevaccinated NUMERIC
);

INSERT INTO percentpopulationvaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (rollingpeoplevaccinated/population)*100
FROM percentpopulationvaccinated;

-- Creating view to store data for later visualizations

CREATE VIEW percentpopulationvaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
--, (rollingpeoplevaccinated/population)*100
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM percentpopulationvaccinated




