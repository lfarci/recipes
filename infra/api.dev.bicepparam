using 'api.bicep'

param appName = 'lfarci-recipes-api-dev'

param entraIdClientId = '92eed23b-512e-4052-ba33-0baeca5b8211'
param entraIdDomain = 'lfarciava.onmicrosoft.com'
param entraIdInstance = 'https://login.microsoftonline.com/'

param recipesDatabaseConnectionString = 'Server=tcp:lfarci-sql-database-server.database.windows.net,1433;Initial Catalog=lfarci-sql-database;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication="Active Directory Default";'

param sku = 'F1'
