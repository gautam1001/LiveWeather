//
//  ContentView.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import CurrentWeatherFeatureAPI
import ForecastFeatureAPI
import SwiftUI

struct ContentView: View {
    typealias ForecastLoader = () async throws -> [ForecastDay]

    private enum ForecastState {
        case idle
        case loading
        case loaded([ForecastDay])
        case failed(String)
    }

    private let locationName = "New Delhi"

    @StateObject private var viewModel: CurrentWeatherViewModel
    let forecastLoader: ForecastLoader
    @State private var forecastState: ForecastState = .idle

    init(viewModel: CurrentWeatherViewModel, forecastLoader: @escaping ForecastLoader) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.forecastLoader = forecastLoader
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
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

    @MainActor
    private func loadWeather() async {
        await viewModel.loadWeather(for: locationName)
        await loadForecast()
    }

    @MainActor
    private func loadForecast() async {
        forecastState = .loading
        do {
            let days = try await forecastLoader()
            forecastState = .loaded(days)
        } catch {
            forecastState = .failed(error.localizedDescription)
        }
    }

    @ViewBuilder
    private var currentWeatherSection: some View {
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
                Text(locationName)
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
                Text(locationName)
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

    private var forecastSection: some View {
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

    private func symbolName(for summary: String) -> String {
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
    ContentView(
        viewModel: AppContainer().makeWeatherViewModel(),
        forecastLoader: {
            [
                ForecastDay(dateLabel: "Day 1", temperatureC: 27, summary: "Sunny"),
                ForecastDay(dateLabel: "Day 2", temperatureC: 26, summary: "Cloudy"),
                ForecastDay(dateLabel: "Day 3", temperatureC: 28, summary: "Sunny"),
                ForecastDay(dateLabel: "Day 4", temperatureC: 25, summary: "Rain"),
                ForecastDay(dateLabel: "Day 5", temperatureC: 27, summary: "Sunny"),
            ]
        }
    )
}
