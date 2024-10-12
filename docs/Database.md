# About
Initially , the project was using a SQL Server database. Azure offers a free instance by subscription. It was migrated to Azure Cosmos DB for the sake of learning and testing.

# Azure Cosmos DB
## Setup
The Cosmos DB instance is created using a Bicep template and deployed using a new GitHub Action workflow. The new instance should contain a database named `Recipes` and a container named `Recipes`.

The API connects to the instance using the connection string stored in the application settings. The connection string is stored in the GitHub repository secrets. The connection string name is named `RecipesDocumentDatabase`.


## Documentation
- [EF Core Azure Cosmos DB Provider](https://learn.microsoft.com/en-us/ef/core/providers/cosmos/?tabs=dotnet-core-cli#get-started)
- [Tutorial: Develop an ASP.NET web application with Azure Cosmos DB for NoSQL](https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/tutorial-dotnet-web-app)

# Database (SQL Server, deprecated)
How to setup a database connection to a SQL Server instance on Azure: https://learn.microsoft.com/en-gb/azure/azure-sql/database/azure-sql-dotnet-entity-framework-core-quickstart?view=azuresql&tabs=visual-studio%2Cazure-portal%2Cportal.


## Authentication
The currently used database is a free tier one available for the subscription.

When deploying a new App Service, make sure to enable a new managed identity and create a new user on the targeted database:

For example if the app service is named `lfarci-recipes-api-dev`, run the following:

```sql
CREATE USER [lfarci-recipes-api-dev] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [lfarci-recipes-api-dev];
ALTER ROLE db_datawriter ADD MEMBER [lfarci-recipes-api-dev];
ALTER ROLE db_ddladmin ADD MEMBER [lfarci-recipes-api-dev];
```

Everything is documented in this guide: [Tutorial: Connect to SQL Database from .NET App Service without secrets using a managed identity](https://learn.microsoft.com/en-us/azure/app-service/tutorial-connect-msi-sql-database?tabs=windowsclient%2Cefcore%2Cdotnet).