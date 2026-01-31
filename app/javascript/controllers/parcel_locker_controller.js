import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "name", "address", "city", "postCode", "selected", "selectedName", "selectedAddress", "selectButton"]

  connect() {
    this.loadFurgonetkaScript()
  }

  loadFurgonetkaScript() {
    if (window.Furgonetka) {
      this.scriptLoaded = true
      return
    }

    const script = document.createElement('script')
    script.src = 'https://furgonetka.pl/js/dist/map/map.js'
    script.onload = () => {
      this.scriptLoaded = true
      console.log('Furgonetka Map script loaded')
    }
    script.onerror = () => {
      console.error('Failed to load Furgonetka Map script')
    }
    document.head.appendChild(script)
  }

  openMap(event) {
    event.preventDefault()

    if (!window.Furgonetka) {
      console.error('Furgonetka Map script not loaded yet')
      alert('Mapa paczkomatów jeszcze się ładuje. Spróbuj ponownie za chwilę.')
      return
    }

    try {
      new window.Furgonetka.Map({
        courierServices: ['inpost'],            // Tylko InPost
        type: 'parcel_machine',                 // Tylko paczkomaty
        pointTypesFilter: ['parcel_machine'],   // Filtr tylko na automaty
        callback: (params) => this.onPointSelected(params),
        zoom: 14,
      }).show()
    } catch (error) {
      console.error('Error opening Furgonetka Map:', error)
      alert('Błąd podczas otwierania mapy. Spróbuj odświeżyć stronę.')
    }
  }

  onPointSelected(params) {
    if (!params || !params.point) {
      console.error('No point data received')
      return
    }

    const { code, name, type, address } = params.point

    // Debug: Log the full response to understand the structure
    console.log('Full Furgonetka response:', JSON.stringify(params, null, 2))
    console.log('Point data:', params.point)
    console.log('Address object:', address)

    // Weryfikacja czy to paczkomat InPost
    const lockerType = (type || '').toLowerCase()
    if (lockerType !== 'inpost') {
      alert('Proszę wybrać paczkomat InPost')
      return
    }

    // Zapisz dane paczkomatu
    this.codeTarget.value = code || ''
    this.nameTarget.value = name || ''

    // Sprawdź czy mamy strukturalny address object
    let street = address?.street || address?.line2 || address?.line1 || ''
    let city = address?.city || ''
    let postCode = address?.postCode || address?.post_code || address?.zipCode || address?.zip_code || ''

    // Jeśli nie ma danych w address object, spróbuj wyciągnąć z name
    // Format name z Furgonetka to często: "KOD - Ulica, kod_pocztowy Miasto"
    if (!street && !city && !postCode && name) {
      const nameWithoutCode = name.includes(' - ') ? name.split(' - ')[1] : name

      // Szukaj kodu pocztowego (format XX-XXX)
      const postCodeMatch = nameWithoutCode.match(/(\d{2}-\d{3})/)
      if (postCodeMatch) {
        postCode = postCodeMatch[1]

        // Wszystko po kodzie pocztowym to miasto
        const afterPostCode = nameWithoutCode.substring(nameWithoutCode.indexOf(postCode) + postCode.length).trim()
        city = afterPostCode

        // Wszystko przed kodem pocztowym to adres
        street = nameWithoutCode.substring(0, nameWithoutCode.indexOf(postCode)).replace(/,\s*$/, '').trim()
      }
    }

    this.addressTarget.value = street
    this.cityTarget.value = city
    this.postCodeTarget.value = postCode

    // Pokaż wybrany paczkomat
    this.selectedTarget.classList.remove('hidden')
    // Name już zawiera kod (np. "KYW01M - Rynek 4, 64-010 Krzywiń")
    this.selectedNameTarget.textContent = name

    // Stwórz adres tylko jeśli mamy dane
    const addressParts = [city, postCode].filter(Boolean)
    this.selectedAddressTarget.textContent = addressParts.join(', ')

    // Ukryj przycisk "Wybierz paczkomat na mapie"
    if (this.hasSelectButtonTarget) {
      this.selectButtonTarget.classList.add('hidden')
    }

    console.log('Parcel locker selected:', { code, name, address })
    console.log('Parsed values:', { street, city, postCode })
  }
}
