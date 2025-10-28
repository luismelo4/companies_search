require 'csv'

class CompanyImportService
  DEFAULT_BUFFER_SIZE = 1000
  CSV_SEPARATOR = ';'

  class ImportResult
    attr_reader :total_processed, :duplicates_removed, :final_count, :error

    def initialize(total_processed: 0, duplicates_removed: 0, final_count: 0, error: nil)
      @total_processed = total_processed
      @duplicates_removed = duplicates_removed
      @final_count = final_count
      @error = error
    end

    def success?
      error.nil?
    end

    def success_message
      "CSV imported successfully! Processed #{total_processed} rows, " \
      "removed #{duplicates_removed} duplicates, " \
      "updated/inserted #{final_count} companies."
    end
  end

  def self.import_from_file(file_path, buffer_size: DEFAULT_BUFFER_SIZE)
    new(file_path, buffer_size).import
  rescue => e
    Rails.logger.error "CSV import error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    ImportResult.new(error: e.message)
  end

  def initialize(file_path, buffer_size = DEFAULT_BUFFER_SIZE)
    @file_path = file_path
    @buffer_size = buffer_size
    @total_processed = 0
    @duplicates_removed = 0
    @final_count = 0
  end

  def import
    companies_data = []

    CSV.foreach(@file_path, headers: true, col_sep: CSV_SEPARATOR) do |row|
      next if row["coc_number"].blank?

      companies_data << build_company_hash(row)

      # Process buffer when it reaches buffer_size
      if companies_data.length >= @buffer_size
        process_buffer(companies_data)
      end
    end

    # Process remaining data in buffer
    process_buffer(companies_data) if companies_data.any?

    ImportResult.new(
      total_processed: @total_processed,
      duplicates_removed: @duplicates_removed,
      final_count: @final_count
    )
  end

  private

  def build_company_hash(row)
    {
      coc_number: row["coc_number"],
      company_name: row["company_name"],
      city: row["city"],
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def process_buffer(companies_data)
    return if companies_data.empty?

    # Keep last occurrence of duplicates
    unique_companies = companies_data.reverse.uniq { |company| company[:coc_number] }.reverse
    
    Company.upsert_all(unique_companies, unique_by: :coc_number)

    @total_processed += companies_data.length
    @duplicates_removed += companies_data.length - unique_companies.length
    @final_count += unique_companies.length

    companies_data.clear
  end
end

