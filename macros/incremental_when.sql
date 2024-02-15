{% macro incremental_when(column_name = 'created_at', lookback_window = -3, periods = 'day') -%}

{% if is_incremental() %}

    WHERE {{ column_name }} > (SELECT DATEADD('{{ periods }}' , {{ lookback_window }}, MAX( {{ column_name }} )) FROM {{ this }} )

{% endif %}

{%- endmacro -%}
