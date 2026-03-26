//
//  ContentView.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import Domain
import Presentation
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: WeatherOverviewViewModel

    init(viewModel: WeatherOverviewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content
                .navigationTitle("New Delhi")
                .task {
                    await viewModel.load(for: "New Delhi")
                }
        }
    }

    /// Custom view
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
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
        case let .loaded(overview):
            HStack {
                Text(overview.current.conditionSummary)
                Spacer()
                Text("\(overview.current.temperatureC, specifier: "%.1f")°C")
            }.padding()
        }
    }
}

#Preview {
    ContentView(viewModel: AppContainer().makeWeatherViewModel())
}
