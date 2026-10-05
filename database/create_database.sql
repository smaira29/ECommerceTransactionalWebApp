-- Smaira Arora | Quiz 1: Database completion
-- Execute in SSMS. No database is dropped or overwritten.
USE master;
GO
IF DB_ID(N'ECommerceDB') IS NULL
    EXEC(N'CREATE DATABASE ECommerceDB');
GO
USE ECommerceDB;
GO
