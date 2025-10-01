
# cs50\_sql\_final: SQLite3 Database Project 💾

This repository contains the final project for the **CS50's Introduction to Databases with SQL** course, implemented using **SQLite3**.

The project involves designing and implementing a relational database, populating it with data, and demonstrating querying capabilities. The primary database file created will be named `project.db` (a convention for this setup).

-----

## Files Overview

| File | Description |
| :--- | :--- |
| **`schema.sql`** | Defines the complete database structure (tables and constraints). |
| **`insert_data.sql`** | SQL statements to populate the database with initial data. |
| **`queries.sql`** | A collection of SQL queries to demonstrate data retrieval and analysis. |
| **`diagram.png`** | The Entity-Relationship Diagram (ERD) for the database. |
| **`DESIGN.md`** | Detailed documentation of the database design and justification. |
| **`rebuild.sql`** | Script to drop all tables, recreate the schema, and insert data. |
| **`connect.sh`** | A shell script to quickly connect to the database environment. |

-----

## How to Set Up and Run (using SQLite3)

To run this project, you will need the `sqlite3` command-line tool installed.

### 1\. Rebuild the Database

Use the following command to completely set up (or reset) the database. This will create the `project.db` file and populate it with data:

```bash
sqlite3 project.db < rebuild.sql
```

### 2\. Run Queries

To execute the prepared demonstration queries and view their output:

```bash
sqlite3 project.db < queries.sql
```

### 3\. Connect to the Database

For interactive exploration, you can use the provided shell script or connect directly:

```bash
# Using the connect.sh script (if available and configured)
./connect.sh

# Or connecting directly
sqlite3 project.db
```