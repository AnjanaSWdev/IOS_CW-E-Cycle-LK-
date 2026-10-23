//
//  OnboardingView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: String
        let text: String
    }

    private let pages = [
        Page(symbol: "shippingbox",
             title: "Know what to do with old electronics",
             text: "Record your unwanted phones, laptops, batteries and more, and get simple disposal guidance for each item."),
        Page(symbol: "mappin.and.ellipse",
             title: "Find a centre and plan your drop-off",
             text: "Discover collection centres near you, schedule a drop-off, get a reminder, and keep a history of what you've recycled.")
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    ScrollView {
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].symbol)
                                .font(.system(size: 72))
                                .foregroundStyle(Color.ecGreen)
                                .padding(.top, 60)
                                .accessibilityHidden(true)
                            Text(pages[index].title)
                                .font(.title.bold())
                                .foregroundStyle(Color.ecInk)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            Text(pages[index].text)
                                .font(.body)
                                .foregroundStyle(Color.ecMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation { page += 1 }
                }
            } label: {
                Text(isLastPage ? "Get started" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.ecGreen, in: Capsule())
            }
            .padding(.horizontal, 24)

            Button("Skip", action: onFinish)
                .foregroundStyle(Color.ecMuted)
                .frame(minHeight: 44)
                .opacity(isLastPage ? 0 : 1)
                .disabled(isLastPage)
                .padding(.bottom, 8)
        }
        .background(Color.ecBackground)
    }
}
