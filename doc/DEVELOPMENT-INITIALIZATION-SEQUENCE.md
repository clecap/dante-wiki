This document describes the initialization sequence.


We have two different initialization paths.

# Database Container

We need to provide the database container with a root password, if there is no database yet.






We check, if there exists a database container of the given name (not derived from the wikis name).
CASE yes: 
  We check whether its root password matches the root password in the configuration
    If it does not match, we abort with an error message.
    If it matches, we continue processing.
CASE no:
  We generate a fresh DB container from MariaDB, give it a name (not derived from the wikis name)
  We inject a root password from the configuration we are starting up.
  Then we continue processing.
Next we check whether there is a database matching the specific wiki and a LocalSettings file in the wiki container,
There can be 4 cases.

1. There is no database and no LocalSettings

2. There is a database and a LocalSettings

3. There is a database but no LocalSettings

4. There is no database but a LocalSettings

