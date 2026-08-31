//
//  NEIGuidelinesView.swift
//  Neighborly
//

import SwiftUI

struct NEIGuidelinesView: View {
    var body: some View {
        List {
            Section("Meeting Safely") {
                Label("Meet in a public or well-lit area for a first exchange when possible.", systemImage: "mappin.and.ellipse")
                Label("Bring someone with you if you're unsure.", systemImage: "person.2.fill")
                Label("Trust your instincts and cancel if something feels off.", systemImage: "exclamationmark.triangle.fill")
            }

            Section("Before You Agree") {
                Label("Check the other person's rating and reviews.", systemImage: "star.fill")
                Label("Read the offer details carefully.", systemImage: "doc.text.fill")
                Label("Message through the app first to confirm details.", systemImage: "message.fill")
            }

            Section("Payments") {
                Label("Neighborly doesn't process payments.", systemImage: "creditcard")
                Label("Never send money upfront through outside apps to someone you haven't met.", systemImage: "hand.raised.slash.fill")
                Label("Agree on any exchange in person.", systemImage: "hand.thumbsup.fill")
            }

            Section("Reporting a Problem") {
                Label("You can block a concerning user from their profile (Block User), which hides their offers from you.", systemImage: "hand.raised.fill")
            }
        }
        .navigationTitle("Community Guidelines")
        .navigationBarTitleDisplayMode(.inline)
    }
}
