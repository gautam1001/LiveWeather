//
//  ContentView.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import SwiftUI
import Presentation

struct ContentView: View {
    private let viewModel: WeatherOverviewViewModel
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

//#Preview {
//    ContentView()
//}
