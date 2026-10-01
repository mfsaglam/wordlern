//
//  AboutScreen.swift
//  thousand
//
//  Created by Fatih Sağlam on 30.09.2026.
//

import SwiftUI

/// Step 13: pays the attribution debt step 03 took on. CC BY is a licence
/// condition, not a nicety — the app may not ship the Leipzig-derived word
/// list without carrying this notice. Deliberately plain: one scrollable
/// text stack, no web view, no bundled HTML.
struct AboutScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Section(title: "Word list") {
                    Text(verbatim: "German word frequencies derived from the Leipzig Corpora Collection (deu_news_2024, deu-de_web-public_2019, deu_wikipedia_2021).")
                    Text(verbatim: "© 2024 Universität Leipzig / Sächsische Akademie der Wissenschaften / InfAI. Licensed under CC BY 4.0.")
                    Text(verbatim: "D. Goldhahn, T. Eckart & U. Quasthoff: Building Large Monolingual Dictionaries at the Leipzig Corpora Collection: From 100 to 200 Languages. In: Proceedings of the 8th International Language Resources and Evaluation (LREC'12), 2012.")
                }

                Section(title: "Word meanings") {
                    Text(verbatim: "English meanings drafted from Wiktionary's German entries, licensed under CC BY-SA.")
                }

                Section(title: "Software") {
                    Text(verbatim: "LeitnerSwift. Copyright © 2024 Fatih Sağlam. MIT License.")
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

/// A heading and its body text, stacked. The only structure this screen has.
private struct Section<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
    }
}

#Preview {
    AboutScreen()
}
