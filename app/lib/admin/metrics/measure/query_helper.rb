# frozen_string_literal: true

module Admin::Metrics::Measure::QueryHelper
  protected

  def perform_data_query
    measurement_data_rows.map { |row| { date: row['period'], value: row['value'].to_s } }
  end

  def measurement_data_rows
    ActiveRecord::Base.connection.select_all(sanitized_sql_string)
  end

  def sanitized_sql_string
    ActiveRecord::Base.sanitize_sql_array(sql_array)
  end
end
