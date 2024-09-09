CREATE DATABASE arproxy_test;
GO
USE arproxy_test;
GO
CREATE LOGIN arproxy WITH PASSWORD = '4rpr0*y#2024';
GO
CREATE USER arproxy FOR LOGIN arproxy;
GO
ALTER ROLE db_owner ADD MEMBER arproxy;
GO
