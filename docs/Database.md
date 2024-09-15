## Database
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