//
//  NEIAuthView.swift
//  Neighborly
//

import SwiftUI

struct NEIAuthView: View {
    @State private var showSignUp = false
    @State private var vm: NEIAuthViewModel

    init(authService: NEIAuthService) {
        _vm = State(initialValue: NEIAuthViewModel(authService: authService))
    }

    var body: some View {
        if showSignUp {
            NEISignUpView(vm: vm) {
                withAnimation { showSignUp = false }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .trailing)
            ))
        } else {
            NEISignInView(vm: vm) {
                withAnimation { showSignUp = true }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .leading)
            ))
        }
    }
}
