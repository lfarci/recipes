CREATE TABLE [dbo].[Recipe]
(
	[Id] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Name] NVARCHAR(50) NOT NULL,
    [OwnerId] BIGINT NOT NULL,
    [Description] NVARCHAR(MAX) NULL, 
    CONSTRAINT [FK_Recipe_To_User] FOREIGN KEY ([OwnerId]) REFERENCES [User]([Id])
)
