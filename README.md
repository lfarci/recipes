# Recipes
[![Infrastructure](https://github.com/lfarci/recipes/actions/workflows/recipes.infra.yml/badge.svg?branch=master)](https://github.com/lfarci/recipes/actions/workflows/recipes.infra.yml) [![Website](https://github.com/lfarci/recipes/actions/workflows/recipes.web.yml/badge.svg)](https://github.com/lfarci/recipes/actions/workflows/recipes.web.yml) [![API](https://github.com/lfarci/recipes/actions/workflows/recipes-api.yml/badge.svg)](https://github.com/lfarci/recipes/actions/workflows/recipes-api.yml)

This repository contains a simple recipe application that allows users to create, read, update, and delete recipes. The application is composed of a web frontend, a RESTful API, and a database.

## Architecture
The application is composed of three main components:
- **Web Frontend**: A simple web application that allows users to interact with the API.
- **API**: A RESTful API that exposes endpoints to create, read, update and delete recipes.
- **Database**: A Cosmos DB instance that stores the recipes.

## Infrastructure
The infrastructure is defined using Bicep and includes the following resources:
- **Azure App Service**: Hosts the API.
- **Azure Static Web App**: Hosts the web frontend.
- **Azure Cosmos DB**: Stores the recipes.
- **Azure Key Vault**: Stores the API client secret and the Cosmos DB connection string.

## CI/CD
The repository is configured with GitHub Actions to deploy the infrastructure, and the application. The CI/CD pipeline is composed of the following workflows:
- **Infrastructure**: Deploys the infrastructure using Bicep.
- **API**: Deploys the API to Azure App Service.
- **Web**: Deploys the web frontend to Azure Static Web App.