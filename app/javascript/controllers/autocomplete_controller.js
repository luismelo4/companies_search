import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "template"]
  
  connect() {
    this.timeout = null
  }

  search(event) {
    const query = event.target.value.trim()
    
    clearTimeout(this.timeout)
    
    if (query.length < 2) {
      this.hideDropdown()
      return
    }
    
    this.timeout = setTimeout(() => {
      this.fetchSuggestions(query)
    }, 300)
  }

  async fetchSuggestions(query) {
    try {
      const response = await fetch(`/companies/autocomplete?q=${encodeURIComponent(query)}`)
      const data = await response.json()
      this.showSuggestions(data.suggestions)
    } catch (error) {
      console.error('Autocomplete error:', error)
    }
  }

  showSuggestions(suggestions) {
    const dropdown = this.dropdownTarget
    const template = this.templateTarget
    
    dropdown.innerHTML = ''
    
    if (suggestions.length === 0) {
      this.hideDropdown()
      return
    }
    
    suggestions.forEach(suggestion => {
      const item = template.cloneNode(true)
      item.style.display = 'block'
      
      item.querySelector('.suggestion-text').textContent = suggestion.text
      item.querySelector('.suggestion-type').textContent = suggestion.type
      
      item.addEventListener('click', () => {
        this.inputTarget.value = suggestion.text
        this.hideDropdown()
        this.searchResults(suggestion.text)
      })
      
      dropdown.appendChild(item)
    })
    
    dropdown.style.display = 'block'
  }

  async searchResults(query) {
    try {
      const response = await fetch(`/companies/search?q=${encodeURIComponent(query)}`)
      const html = await response.text()
      document.getElementById('search-results').innerHTML = html
    } catch (error) {
      console.error('Search error:', error)
    }
  }

  hideDropdown() {
    this.dropdownTarget.style.display = 'none'
  }

  clear() {
    this.inputTarget.value = ''
    this.hideDropdown()
    document.getElementById('search-results').innerHTML = '<div class="alert alert-secondary text-center">Start typing to search companies</div>'
  }
}
