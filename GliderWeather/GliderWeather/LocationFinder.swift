//
//  LocationFinder.swift
//  GliderWeather
//
//  Created by Simon Seyer on 28.06.22.
//

import Foundation
import MapKit
import Combine

struct LocationSearchResult: Identifiable, Hashable {
    let title: AttributedString
    let subtitle: AttributedString
    let id: String

    fileprivate init(searchCompletion: MKLocalSearchCompletion) {
        id = "\(searchCompletion.title), \(searchCompletion.subtitle)"
        title = Self.highligted(string: searchCompletion.title, ranges: searchCompletion.titleHighlightRanges)
        subtitle = Self.highligted(string: searchCompletion.subtitle, ranges: searchCompletion.subtitleHighlightRanges)
    }

    private static func highligted(string: String, ranges: [NSValue]) -> AttributedString {
        var attributes = AttributeContainer()
        attributes.inlinePresentationIntent = .stronglyEmphasized

        var attributedString = AttributedString(string)
        for range in ranges.map({ $0.rangeValue }) {
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: range.lowerBound)
            let endIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: range.upperBound)
            attributedString[Range(uncheckedBounds: (startIndex, endIndex))].setAttributes(attributes)
        }
        return attributedString
    }
}

@MainActor
class LocationFinder: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {

    @Published var searchText: String = ""
    @Published var results: [LocationSearchResult] = []
    @Published var selectedResult: LocationSearchResult?
    @Published var location: CLLocation?

    private var isResolvedLocation = false
    private var subscriptions: Set<AnyCancellable> = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        $searchText
            .sink { text in
                guard !self.isResolvedLocation else {
                    self.isResolvedLocation = false
                    return
                }
                self.completer.queryFragment = text
            }
            .store(in: &subscriptions)
        $selectedResult
            .compactMap { $0 }
            .sink { result in
                Task {
                    await self.select(searchResult: result)
                }
            }
            .store(in: &subscriptions)
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.map {
            LocationSearchResult(searchCompletion: $0)
        }
    }

    private func select(searchResult: LocationSearchResult) async {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchResult.id
        searchRequest.resultTypes = .address

        let search = MKLocalSearch(request: searchRequest)
        do {
            let response = try await search.start()
            let placemark =  response.mapItems.first?.placemark
            isResolvedLocation = true
            searchText = placemark?.title ?? "Couldn't resolve location"
            results = []
            location = placemark?.location
        } catch {
            print(error)
        }
    }
}
