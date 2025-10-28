class Company < ApplicationRecord
  validates :coc_number, presence: true, uniqueness: true
  validates :company_name, presence: true
  validates :city, presence: true

  # Scopes for better query organization
  scope :search_by_name, ->(query) { where("UPPER(company_name) LIKE UPPER(?)", "%#{query}%") }
  scope :search_by_city, ->(query) { where("UPPER(city) LIKE UPPER(?)", "%#{query}%") }
  scope :search_by_coc_number, ->(query) { where("UPPER(coc_number) LIKE UPPER(?)", "%#{query}%") }
  
  # Combined search scope
  scope :search, ->(query) {
    return none if query.blank?
    
    where(
      "UPPER(company_name) LIKE UPPER(?) OR UPPER(city) LIKE UPPER(?) OR UPPER(coc_number) LIKE UPPER(?)",
      "%#{query}%", "%#{query}%", "%#{query}%"
    )
  }
  
  # Pagination scope
  scope :paginated, ->(page: 1, per_page: 20) { page(page).per(per_page) }

  def as_json(options = {})
    {
      id: id,
      company_name: company_name,
      city: city,
      coc_number: coc_number,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
