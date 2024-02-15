WITH
months AS (
    SELECT
        calendar_date AS date_month
    FROM
        {{ ref('int_dates') }}
    WHERE
        day_of_month = 1
),

-- Bring in int model
subscription_periods AS (
    SELECT * FROM {{ ref('int_subscription_periods') }}
),

-- Determine when given subscription plan's first and most recent months
subscribers AS (
    SELECT
        user_id,
        subscription_id,
        MIN(start_month) AS first_start_month,
        MAX(end_month) AS last_end_month
    FROM
        subscription_periods
    GROUP BY
        1, 2
),

-- Create one record per month between a subscriber's first and last month
subscriber_months AS (
    SELECT
        subscribers.user_id,
        subscribers.subscription_id,
        months.date_month
    FROM
        subscribers
        INNER JOIN months
            -- All months after start date
            ON months.date_month >= subscribers.first_start_month
                -- and before end date
                AND subscribers.last_end_month > months.date_month
),

-- Join together to create base CTE for MRR calculations
mrr_base AS (
    SELECT
        subscriber_months.date_month,
        subscriber_months.user_id,
        subscriber_months.subscription_id,
        COALESCE(subscription_periods.monthly_amount, 0.0) AS mrr
    FROM
        subscriber_months
        LEFT JOIN subscription_periods
            ON subscriber_months.user_id = subscription_periods.user_id
                AND subscriber_months.subscription_id = subscription_periods.subscription_id
                -- The month is on or after the subscription start date...
                AND subscriber_months.date_month >= subscription_periods.start_month
                -- and the month is before the subscription end date (and handle NULL case)
                AND (subscriber_months.date_month < subscription_periods.end_month
                    OR subscription_periods.end_month IS NULL)
),

-- Calculate subscriber level MRR (monthly recurring revenue)
subscription_revenue_by_month AS (
    SELECT
        date_month,
        user_id,
        subscription_id,
        mrr > 0 AS is_subscribed_current_month,

        -- Find the subscriber's first month and last subscription month
        MIN(CASE WHEN is_subscribed_current_month THEN date_month END) OVER (PARTITION BY user_id, subscription_id) AS first_subscription_month,
        MAX(CASE WHEN is_subscribed_current_month THEN date_month END) OVER (PARTITION BY user_id, subscription_id) AS last_subscription_month,
        first_subscription_month = date_month AS is_first_subscription_month,
        last_subscription_month = date_month AS is_last_subscription_month,
        mrr
    FROM
        mrr_base
)

SELECT * FROM subscription_revenue_by_month
