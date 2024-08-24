#!/bin/bash

# Prompt for username, password, and database name
read -p "Enter username: " USERNAME
read -sp "Enter password: " PASSWORD
echo
read -p "Enter database name: " DATABASE

DB_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE'")

# If database does not exist, create it
if [ "$DB_EXISTS" = "1" ]
then
    echo "Database already exists."
else
    echo "Database does not exist. Creating..."
    sudo -u postgres createdb $DATABASE
fi

# Switch to postgres user and run psql commands
sudo -u postgres psql -v ON_ERROR_STOP=1 << EOF || exit
-- Create user if it doesn't exist
DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles 
      WHERE  rolname = '$USERNAME') THEN
      CREATE ROLE $USERNAME LOGIN PASSWORD '$PASSWORD';
   ELSE
      ALTER ROLE $USERNAME WITH PASSWORD '$PASSWORD';
   END IF;
END
\$\$;

-- Grant all privileges on database to user
GRANT ALL PRIVILEGES ON DATABASE $DATABASE TO $USERNAME;
EOF

if [ $? -eq 0 ]
then
  echo "Done."
else
  echo "An error occurred while executing the script."
fi

