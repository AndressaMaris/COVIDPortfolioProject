SELECT *
FROM CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your Country
SELECT location, date, total_cases, total_deaths, ROUND((Total_deaths/total_cases)*100,2) AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT location, date, population, total_cases, ROUND((total_cases/population)*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(ROUND((total_cases/population)*100,2)) AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationinfected DESC


-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL AND TRIM(continent) <> ''
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Showing Continents with the Highest Death Count
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE TRIM(continent) = '' AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

-- Global Death Percentage
SELECT  
    SUM(new_cases) as Total_Cases, 
    SUM(cast(new_deaths as int)) as Total_Deaths, 
    ROUND(SUM(cast(new_deaths as int))/SUM(new_cases)*100, 2) AS DeathPercentage
FROM 
    CovidDeaths
WHERE 
    TRIM(continent) <> '' 
    AND location NOT LIKE '%income%'
HAVING
    SUM(cast(new_deaths as int)) > 0
ORDER BY 1, 2


-- Global Death Percentage across Timeline
SELECT 
    date, 
    SUM(new_cases) as Total_Cases, 
    SUM(cast(new_deaths as int)) as Total_Deaths, 
    ROUND(SUM(cast(new_deaths as int))/SUM(new_cases)*100, 2) AS DeathPercentage
FROM 
    CovidDeaths
WHERE 
    TRIM(continent) <> '' 
    AND location NOT LIKE '%income%'
GROUP BY 
    date
HAVING
    SUM(cast(new_deaths as int)) > 0
ORDER BY 1, 2


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    TRIM(dea.continent) <> '' 
    AND dea.location NOT LIKE '%income%'
    AND cast(vac.new_vaccinations as int) <> 0
ORDER BY 2, 3


--USING CTE (COMMON TABLE EXPRESSION)
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        TRIM(dea.continent) <> '' 
        AND dea.location NOT LIKE '%income%'
        AND cast(vac.new_vaccinations as int) <> 0
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


-- Using TEMP TABLE
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations as int),
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    TRIM(dea.continent) <> '' 
    AND dea.location NOT LIKE '%income%'
    AND cast(vac.new_vaccinations as int) <> 0

SELECT 
    *, 
    (RollingPeopleVaccinated/Population)*100
FROM 
    PercentPopulationVaccinated
    

--CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATIONS
Create View PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    TRIM(dea.continent) <> '' 
    AND dea.location NOT LIKE '%income%'
    AND cast(vac.new_vaccinations as int) <> 0

