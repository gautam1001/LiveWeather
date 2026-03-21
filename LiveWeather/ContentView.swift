//
//  ContentView.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import SwiftUI
import Presentation
import Domain

struct ContentView: View {
    
    @StateObject private var viewModel: WeatherOverviewViewModel
    
    init(viewModel: WeatherOverviewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Ghaziabad")
                .task {
                    await viewModel.load(for: "Ghaziabad")
                }
        }
    }
    // Custom view
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading weather...")
        case .failed(let message):
            VStack(spacing: 12) {
                Text("Failed to load")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        case .loaded(let overview):
            
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
