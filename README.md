# Welcome to the Bingeflix Data Team

### Coding Conventions
#### General
- Use UPPER case for all keywords
- Use trailing commas in SELECT statements
- Use Snowflake dialect
- Use consistent style in GROUP BY and ORDER BY (either names or numbers, not both)


### Testing Conventions
#### Source
- Tests removed from source. Tests only at staging.
#### Staging
- The primary key source column must have not_null and unique generic tests.
- All boolean columns must have an accepted_values schema test. The accepted values are true and false.
- Columns that contain category values must have an accepted_values schema test.
- Columns that should be unique must have a unique schema test.
#### Models
- The primary key column must have not_null and unique schema tests.
- All boolean columns must have an accepted_values schema test. The accepted values are true and false.
- Columns that contain category values must have an accepted_values schema test.
- Columns that should never be null must have a not_null schema test.
- Columns that should be unique must have a unique schema test.
- Where possible, use schema tests from the dbt_utils or dbt_expectations packages to perform extra verification.


## Projects
### Week 1
- Task 2: Documentation added to doc blocks for all Bingeflix source models. Focussing on the subscriptions source table, documentation was added for all downstream models of subscriptions.
- Task 3: Dbt Project Evaluator was run. All documentation and test issues were addressed, as these are important for project organisation. Only two exceptions were added to the exceptions file: (1) mrr will remain in the model/mart/finance folder as there was no need to add a new reporting folder for this model, (2) stg_events has multiple children models, this is acceptable / expected as the events table is a key table
- Task 4: SQLFluff run and linting issues addressed
### Week 2
- Task 1: Added SQLFluff to pree-commit hook
-- Notes: Run either command below to check that the pre-commit hook is working properly:
--- pre-commit run --hook-stage commit sqlfluff-lint --all-files (This just lints)
--- pre-commit run --hook-stage manual sqlfluff-fix --all-files (This will provide an option to automatically fix any issues)
- Task 2: Added additional project checks from dbt-checkpoint
- Task 3: Generalized the custom macro and applied to two models
- Task 4: Wrote a custom macro, focussing on looping through columns to change white spaces to null
### Week 3
- Task 1: Redundant tests removed from the source yaml if it is covered by staging or further upstream
- Task 2: Custom generic test added to address test events
- Task 3: unit testing of rpt_mrr. A sample of input and output seed files used


## dbt-Snowflake monitorinng
### Top 5 costliest dbt queries you've run in the last 30 days
``with
max_date as (
    select max(date(end_time)) as date
    from dev.dbt_jasmintanbrooklyndataco.query_history_enriched
    where user_name = 'jasmintanbrooklyndataco'
)
select
    md5(query_history_enriched.query_text_no_comments) as query_signature,
    any_value(query_history_enriched.query_text) as query_text,
    sum(query_history_enriched.query_cost) as total_cost_last_30d,
    total_cost_last_30d*12 as estimated_annual_cost,
    max_by(warehouse_name, start_time) as latest_warehouse_name,
    max_by(warehouse_size, start_time) as latest_warehouse_size,
    max_by(query_id, start_time) as latest_query_id,
    avg(execution_time_s) as avg_execution_time_s,
    count(*) as num_executions
from dev.dbt_jasmintanbrooklyndataco.query_history_enriched
cross join max_date
where
    query_history_enriched.start_time >= dateadd('day', -30, max_date.date)
    and query_history_enriched.start_time < max_date.date -- don't include partial day of data
    and user_name = 'jasmintanbrooklyndataco'
group by 1
order by total_cost_last_30d desc
limit 5;``

### Top 5 costliest dbt models you've run in the last 30 days
``with
max_date as (
    select max(date(end_time)) as date
    from dev.dbt_jasmintanbrooklyndataco.dbt_queries
)
select
    dbt_queries.dbt_node_id,
    sum(dbt_queries.query_cost) as total_cost_last_30d,
    total_cost_last_30d*12 as estimated_annual_cost
from dev.dbt_jasmintanbrooklyndataco.dbt_queries
cross join max_date
where
    dbt_queries.start_time >= dateadd('day', -30, max_date.date)
    and dbt_queries.start_time < max_date.date -- don't include partial day of data
group by 1
order by total_cost_last_30d desc
limit 5;``

### Daily cost of running your most expensive dbt model
``select
    date(start_time) as date,
    sum(query_cost) as cost
from dev.dbt_jasmintanbrooklyndataco.dbt_queries
where dbt_node_id = 'model.dbt_snowflake_monitoring.stg_query_history'
group by 1
order by 1 desc;``
