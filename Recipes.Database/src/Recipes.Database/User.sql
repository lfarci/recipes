CREATE TABLE [dbo].[User]
(
    [Id] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [FirstName] NVARCHAR(100) NOT NULL,
    [LastName] NVARCHAR(100) NOT NULL,

    CONSTRAINT [CK_User_FirstName_NotEmpty] CHECK ([FirstName] <> ''),
    CONSTRAINT [CK_User_LastName_NotEmpty] CHECK ([LastName] <> '')
)
