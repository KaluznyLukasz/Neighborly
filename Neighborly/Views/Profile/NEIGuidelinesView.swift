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

            Section {
                Label("Harassment, hate speech, threats or bullying.", systemImage: "exclamationmark.bubble.fill")
                Label("Sexual, violent or otherwise offensive content.", systemImage: "eye.slash.fill")
                Label("Scams, spam, or anything illegal, including weapons, drugs and stolen goods.", systemImage: "nosign")
                Label("Pretending to be someone else, or sharing other people's personal details.", systemImage: "person.crop.circle.badge.xmark")
            } header: {
                Text("Not Allowed")
            } footer: {
                Text("Neighborly has zero tolerance for this content. We remove it and may close the accounts that post it.")
            }

            Section {
                Label("Report an offer, alert or person from its page. Touch and hold a message or review to report it.", systemImage: "flag.fill")
                Label("Block someone from their profile. You won't see their posts or alerts, and they can't message you or respond to your posts.", systemImage: "hand.raised.fill")
                Link(destination: NEILegal.contactURL) {
                    Label("Email \(NEILegal.contactEmail)", systemImage: "envelope.fill")
                }
            } header: {
                Text("Reporting a Problem")
            } footer: {
                Text("Neighborly reviews every report within 24 hours. If someone is in danger, call 112.")
            }

            Section {
                Link("Terms of Use", destination: NEILegal.termsURL)
                Link("Privacy Policy", destination: NEILegal.privacyPolicyURL)
            }
        }
        .navigationTitle("Community Guidelines")
        .navigationBarTitleDisplayMode(.inline)
    }
}
