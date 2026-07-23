//
//  TangramOdysseyApp.swift
//  TangramOdyssey
//
//  Created by Andy Hunt on 7/19/26.
//

import SwiftUI

@main
struct TangramOdysseyApp: App {
    @State private var progress = ProgressStore(cloud: NSUbiquitousKeyValueStore.default)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(progress)
        }
    }
}
