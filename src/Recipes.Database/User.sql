CREATE TABLE [dbo].[User]
(
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [FirstName] NVARCHAR(100) NOT NULL,
    [LastName] NVARCHAR(100) NOT NULL,
    [Email] NVARCHAR(100) NOT NULL,

    CONSTRAINT [PK_User_Id] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_User_Email] UNIQUE ([Email]),
    CONSTRAINT [CK_User_FirstName_NotEmpty] CHECK ([FirstName] <> ''),
    CONSTRAINT [CK_User_LastName_NotEmpty] CHECK ([LastName] <> '')
)
