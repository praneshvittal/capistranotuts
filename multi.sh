# test script will take a task like 'dev:postgres_status' and run on all environments
cap staging  $1
cap model $1
