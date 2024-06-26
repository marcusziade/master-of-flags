import Combine
import Foundation
import SwiftUI

final class CountryListVM: ObservableObject {

    @Published var filteredCountries: [Country] = []
    @Published var selectedRegion: Int = 0

    let regions = [Region.europe, Region.asia, Region.africa, Region.oceania, Region.americas]

    init(countriesManager: CountriesManaging = CountriesManager()) {
        self.countriesManager = countriesManager
        
        loadCountries()

        $selectedRegion
            .removeDuplicates()
            .map { [unowned self] in
                switch $0 {
                case 0: filteredCountries = filterAndSort(countries, .europe)
                case 1: filteredCountries = filterAndSort(countries, .asia)
                case 2: filteredCountries = filterAndSort(countries, .africa)
                case 3: filteredCountries = filterAndSort(countries, .oceania)
                default: filteredCountries = filterAndSort(countries, .americas)
                }
            }
            .sink { _ in UIImpactFeedbackGenerator().impactOccurred() }
            .store(in: &subscriptions)
    }

    // MARK: - Private

    private let countriesManager: CountriesManaging
    private var subscriptions = Set<AnyCancellable>()
    private var countries: [Country] = []

    private func loadCountries() {
        countriesManager.getCountries()
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                countries = $0
                filteredCountries = filterAndSort(countries, .europe)
            }
            .store(in: &subscriptions)
    }

    private func filterAndSort(_ countries: [Country], _ region: Region) -> [Country] {
        return
            countries
            .filter { $0.region == region.title }
            .sorted { $0.name.common < $1.name.common }
    }
}
