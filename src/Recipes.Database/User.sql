CREATE TABLE [dbo].[User]
(
    [FirstName] NVARCHAR(100) NOT NULL,
    [LastName] NVARCHAR(100) NOT NULL,
    [Id] NVARCHAR(100) NOT NULL,

    CONSTRAINT [PK_User_Id] PRIMARY KEY ([Id]),
    CONSTRAINT [CK_User_FirstName_NotEmpty] CHECK ([FirstName] <> ''),
    CONSTRAINT [CK_User_LastName_NotEmpty] CHECK ([LastName] <> '')
)
