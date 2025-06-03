//
//  ContentView.swift
//  FantasyAppGithub
//
//  Created by Nadia Yilmaz on 12/25/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameModelView: GameModelView
    var body: some View {
        VStack {
            AppState(gameModelView: gameModelView)
        }
        .padding()
    }
}
