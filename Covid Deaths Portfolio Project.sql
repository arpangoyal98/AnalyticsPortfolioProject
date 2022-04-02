-- Death percentage by cases
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100  AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE [location] LIKE  '%India%'

-- Infection %age in India on a daily basis

SELECT location, date, total_cases, Population, CAST(total_cases*100 AS float)/CAST(Population AS int) AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE [location] LIKE  '%India%'


-- Showing countries with highest death count by population

SELECT location, population, MAX(CAST(total_deaths AS float))/population*100 AS DeathByPopulation
FROM PortfolioProject..CovidDeaths
GROUP BY [location], population
ORDER BY DeathByPopulation desc


-- Continent with highest death count 

SELECT [location], MAX(CAST(total_deaths AS float)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL AND location NOT IN ('Lower middle income', 'Low income', 'Upper middle income', 'High income', 'International')
GROUP BY [location]
ORDER BY TotalDeaths desc

-- Death Percentage by cases

SELECT date, SUM(new_cases) AS totalCases, SUM(new_deaths)*100/NULLIF(CAST(SUM(new_cases) AS float), 0) AS DeathPercentageByCases
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
GROUP BY [date]
ORDER by date asc


-- Total population vs Vaccination

SELECT dea.continent, dea.location, dea.[date], vac.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..[ CovidVaccinations] vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3



-- Rolling Vaccinations Done

SELECT dea.continent, dea.location,  dea.date, CAST(vac.new_vaccinations AS bigint) AS NewVaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..[ CovidVaccinations] vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- CTE

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
AS
(
    SELECT dea.continent, dea.location,  dea.date, dea.population, ISNULL(CAST(vac.new_vaccinations AS float),0) AS NewVaccinations,
    ISNULL(SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date),0) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..[ CovidVaccinations] vac
        ON dea.[location] = vac.[location]
        AND dea.[date] = vac.[date]
    WHERE dea.continent IS NOT NULL
--    ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100  
FROM PopvsVac



--TEMP TABLE

-- So that even if we have to change anything, we can directly run the whole query
DROP TABLE if EXISTS #PercentPeopleVaccinated  

CREATE TABLE #PercentPeopleVaccinated
(
    Continent nvarchar(255), 
    Location nvarchar(255), 
    Date datetime, 
    Population numeric, 
    New_Vaccinations numeric,
    RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPeopleVaccinated
SELECT dea.continent, dea.location,  dea.date, dea.population, ISNULL(CAST(vac.new_vaccinations AS float),0) AS NewVaccinations,
ISNULL(SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date),0) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..[ CovidVaccinations] vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*50 AS PercentVaccinated
FROM #PercentPeopleVaccinated
WHERE location like '%India%'
ORDER BY [Location]

GO

-- View 1

CREATE VIEW DeathPercentageByCases AS 
SELECT date, SUM(new_cases) AS totalCases, SUM(new_deaths)*100/NULLIF(CAST(SUM(new_cases) AS float), 0) AS DeathPercentageByCases
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
GROUP BY [date]
--ORDER by date asc
GO

SELECT * 
FROM DeathPercentageByCases
GO


-- View 2

CREATE VIEW RollingVaccinationsDone AS
SELECT dea.continent, dea.location,  dea.date, CAST(vac.new_vaccinations AS bigint) AS NewVaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..[ CovidVaccinations] vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
-- ORDER BY 2, 3
GO

SELECT * 
FROM RollingVaccinationsDone