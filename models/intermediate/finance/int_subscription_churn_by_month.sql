WITH
subscription_revenue_by_month AS (
    SELECT * FROM {{ ref('int_subscription_revenue_by_month') }}
),

-- Calculate subscriber level churn by month by getting row for month *after* last month of activity
subscription_churn_by_month AS (
    SELECT
        DATEADD(MONTH, 1, date_month)::DATE AS date_month,
        user_id,
        subscription_id,
        FALSE AS is_subscribed_current_month,
        first_subscription_month,
        last_subscription_month,
        FALSE AS is_first_subscription_month,
        FALSE AS is_last_subscription_month,
        0.0::DECIMAL(18, 2) AS mrr
    FROM
        subscription_revenue_by_month
    WHERE
        is_last_subscription_month = TRUE
)

SELECT * FROM subscription_churn_by_month
