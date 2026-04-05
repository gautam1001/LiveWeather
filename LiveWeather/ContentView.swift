//
//  ContentView.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import CurrentWeatherFeatureAPI
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: CurrentWeatherViewModel

    init(viewModel: CurrentWeatherViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content
                .navigationTitle("New Delhi")
                .task {
                    await viewModel.loadWeather(for: "New Delhi")
                }
        }
    }

    /// Custom view
    @ViewBuilder
    private var content: some View {
        let state = viewModel.screenState

        switch state {
        case .idle, .loading:
            ProgressView("Loading weather...")
        case let .failed(message):
            VStack(spacing: 12) {
                Text("Failed to load")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        case let .loaded(weather):
            HStack {
                Text("Condition Summary: \(weather.conditionSummary)")
                Spacer()
                Text("\(weather.temperatureC, specifier: "%.1f")°C")
            }.padding()
        }
    }
}

#Preview {
    ContentView(viewModel: AppContainer().makeWeatherViewModel())
}
