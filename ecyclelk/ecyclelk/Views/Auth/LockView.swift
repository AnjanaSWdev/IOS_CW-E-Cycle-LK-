//
//  LockView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct LockView: View{
    
    let lock: AppLockViewModel
    
    var body: some View {
        VStack(spacing: 20){
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.ecGreen)
                .accessibilityHidden(true)
            Text("E-Cycle LK is locked")
                .font(.title2.bold())
                .foregroundStyle(Color.ecInk)
                .accessibilityAddTraits(.isHeader)
            if lock.lastAttemptFailed {
                Text("Couldn't verify it's you. Try again.")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            Button{
                Task { await lock.unlock()}
            } label: {
                Label("Unlock", systemImage: "faceid")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .frame(minHeight: 50)
                    .background(Color.ecGreen, in: Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ecBackground)
        .task{ await lock.unlock() }
    }
}
