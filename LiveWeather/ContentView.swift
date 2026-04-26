//
//  ContentView.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import AppComposition
import SwiftUI
import WeatherHomeFeatureAPI

struct ContentView<ViewModel: WeatherHomeScreenViewModeling>: View {
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                await viewModel.onAppear()
            }
            .onDisappear {
                viewModel.cancelSearch()
            }
        }
    }
}

private extension ContentView {
    var searchSection: some View {
        SearchSectionView(
            model: viewModel.searchSectionModel,
            onQueryChanged: viewModel.updateSearchQuery,
            onSearch: triggerSearch
        )
    }

    var currentWeatherSection: some View {
        CurrentWeatherSectionView(model: viewModel.currentWeatherSectionModel)
    }

    var forecastSection: some View {
        ForecastSectionView(model: viewModel.forecastSectionModel)
    }

    func triggerSearch() {
        viewModel.performSearch()
    }
}

private struct SearchSectionView: View {
    @ObservedObject var model: WeatherHomeSearchSectionModel
    let onQueryChanged: (String) -> Void
    let onSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Location")
                .font(.headline)

            HStack(spacing: 10) {
                TextField(
                    "Enter city name",
                    text: Binding(
                        get: { model.query },
                        set: { onQueryChanged($0) }
                    )
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(10)
                .background(
                    Color.white.opacity(0.9),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .onSubmit {
                    onSearch()
                }

                Button {
                    onSearch()
                } label: {
                    if model.isSearching {
                        ProgressView()
                            .tint(.white)
                            .padding(.horizontal, 8)
                    } else {
                        Text("Search")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isSearching)
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CurrentWeatherSectionView: View {
    @ObservedObject var model: WeatherHomeCurrentWeatherSectionModel

    var body: some View {
        Group {
            switch model.viewState {
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
                    Text(model.selectedLocation)
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
                    Text(current.locationName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .bottom) {
                        Text(current.temperatureText)
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                        Spacer()
                        Image(systemName: current.symbolName)
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
    }
}

private struct ForecastSectionView: View {
    @ObservedObject var model: WeatherHomeForecastSectionModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("5-Day Forecast")
                .font(.headline)

            switch model.viewState {
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
                ForEach(Array(days.enumerated()), id: \.offset) { indexedDay in
                    let day = indexedDay.element
                    HStack {
                        Image(systemName: day.symbolName)
                            .frame(width: 24)
                            .foregroundStyle(.orange)
                        Text(day.dateLabel)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(day.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(day.temperatureText)
                            .font(.subheadline.weight(.semibold))
                            .frame(minWidth: 36, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    if indexedDay.offset < days.count - 1 {
                        Divider().opacity(0.35)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    let previewContainer = AppContainer(
        weatherAPIKey: AppConfig.weatherAPIKey,
        weatherAPIURL: AppConfig.weatherAPIUrl
    )
    ContentView(viewModel: previewContainer.makeWeatherHomeViewModel())
}
