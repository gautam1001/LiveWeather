//
//  HTTPClient.swift
//  Data
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation

public protocol HTTPClient: Sendable {
    func get(url: URL) async throws -> (Data, HTTPURLResponse)
}
