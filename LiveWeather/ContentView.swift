//
//  ContentView.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import CurrentWeatherFeatureAPI
import ForecastFeatureAPI
import SearchFeatureAPI
import SwiftUI

struct ContentView: View {
    private enum ForecastState {
        case idle
        case loading
        case loaded([ForecastDay])
        case failed(String)
    }

    @StateObject private var viewModel: CurrentWeatherViewModel
    private let container: AppContainer

    @State private var selectedLocation = "New Delhi"
    @State private var forecastState: ForecastState = .idle
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var searchErrorMessage: String?

    init(
        viewModel: CurrentWeatherViewModel,
        container: AppContainer
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.container = container
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    searchSection
                    currentWeatherSection
                    forecastSection
                }
                .padding(16)
            }
            .navigationTitle("Live Weather")
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.22),
                        Color.cyan.opacity(0.10),
                        Color.white,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .task {
                await loadWeather()
            }
        }
    }
}

private extension ContentView {
    var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Location")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("Enter city name", text: $searchQuery)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(
                        Color.white.opacity(0.9),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .onSubmit {
                        Task {
                            await performSearch()
                        }
                    }

                Button {
                    Task {
                        await performSearch()
                    }
                } label: {
                    if isSearching {
                        ProgressView()
                            .tint(.white)
                            .padding(.horizontal, 8)
                    } else {
                        Text("Search")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSearching)
            }

            if let searchErrorMessage {
                Text(searchErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @MainActor
    func performSearch() async {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchErrorMessage = nil
            return
        }

        isSearching = true
        searchErrorMessage = nil
        do {
            let safeQuery = String(trimmedQuery)
            let results = try await container.searchLocations(query: safeQuery)
            let resolvedLocation = results.first?.name ?? safeQuery
            selectedLocation = resolvedLocation
            searchQuery = resolvedLocation
            await loadWeather()
        } catch {
            searchErrorMessage = error.localizedDescription
        }
        isSearching = false
    }

    @MainActor
    func loadWeather() async {
        container.selectLocation(selectedLocation)
        await viewModel.loadWeather(for: selectedLocation)
        await loadForecast()
    }

    @MainActor
    func loadForecast() async {
        forecastState = .loading
        do {
            let days = try await container.fetchDefaultForecast()
            forecastState = .loaded(days)
        } catch {
            forecastState = .failed(error.localizedDescription)
        }
    }

    @ViewBuilder
    var currentWeatherSection: some View {
        let state = viewModel.screenState

        switch state {
        case .idle, .loading:
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading current weather...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        case let .failed(message):
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedLocation)
                    .font(.title2.weight(.semibold))
                Text("Current weather unavailable")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        case let .loaded(current):
            VStack(alignment: .leading, spacing: 12) {
                Text(selectedLocation)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .bottom) {
                    Text("\(current.temperatureC, specifier: "%.1f")°")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                    Text("C")
                        .font(.title3.weight(.semibold))
                        .padding(.bottom, 10)
                    Spacer()
                    Image(systemName: symbolName(for: current.conditionSummary))
                        .font(.system(size: 34))
                        .foregroundStyle(.orange)
                }

                Text(current.conditionSummary)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    var forecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("5-Day Forecast")
                .font(.headline)

            switch forecastState {
            case .idle, .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading forecast...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            case let .failed(message):
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case let .loaded(days):
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    HStack {
                        Image(systemName: symbolName(for: day.summary))
                            .frame(width: 24)
                            .foregroundStyle(.orange)
                        Text(day.dateLabel)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(day.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(day.temperatureC, specifier: "%.0f")°")
                            .font(.subheadline.weight(.semibold))
                            .frame(minWidth: 36, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    if day.dateLabel != days.last?.dateLabel {
                        Divider().opacity(0.35)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func symbolName(for summary: String) -> String {
        let lower = summary.lowercased()
        if lower.contains("sun") {
            return "sun.max.fill"
        }
        if lower.contains("rain") {
            return "cloud.rain.fill"
        }
        if lower.contains("cloud") {
            return "cloud.fill"
        }
        return "cloud.sun.fill"
    }
}

#Preview {
    let previewContainer = AppContainer()
    ContentView(
        viewModel: previewContainer.makeWeatherViewModel(),
        container: previewContainer
    )
}
