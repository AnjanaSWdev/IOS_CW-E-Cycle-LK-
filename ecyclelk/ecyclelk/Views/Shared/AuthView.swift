//
//  AuthView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct AuthView: View{
    
    @Bindable var viewModel: AuthViewModel
    
    var body: some View{
        
        ScrollView{
            VStack(alignment: .leading, spacing: 20){
                VStack(alignment: .leading, spacing: 8){
                    Image(systemName: "arrow.3.trianlgepath")
                        .font(.largeTitle)
                        .foregroundStyle(Color.ecGreen)
                        .accessibilityHidden(true)
                    Text("E-Cycle LK")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.ecInk)
                        .accessibilityAddTraits(.isHeader)
                    Text("Give your old tech a better ending")
                        .font(.subheadline)
                        .foregroundStyle(Color.ecMuted)
                }
                
                Picker("Mode", selection: $viewModel.mode){
                    ForEach(AuthViewModel.Mode.allCases){
                        Text($0.rawValue).tag($0)}
                    }.pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing:16){
                    if viewModel.mode == .signUp{
                        TextField("Your name", text: $viewModel.name)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .fieldStyle()
                    }
                    
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .fieldStyle()
                        
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(viewModel.mode == .signUp ? .newPassword : .password)
                        .fieldStyle()
                    
                    if viewModel.mode == .signUp{
                        Text("Use at least 6 characters")
                            .font(.footnote)
                            .foregroundStyle(Color.ecMuted)
                    }
                    
                    if let message = viewModel.errorMessage{
                        
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error .\(message)")
                        
                        
                    }
                    
                    Button{
                        Task{await viewModel.submit()}
                        
                    } label: {
                        Group {
                            if viewModel.isWorking{
                                ProgressView().tint(.white)
                            }else{
                                Text(viewModel.mode == .signIn ? "Sign in" : "Create account")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(viewModel.canSubmit ? Color.ecGreen : Color.gray, in: Capsule())
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isWorking)
                    
                        
                }
                .ecCard()
            }
            .padding()
        }
        .background(Color.ecBackground)
        .scrollDismissesKeyboard(.interactively)
    }
}

private extension View{
    
    func fieldStyle() -> some View{
        self
            .padding(12)
            .frame(minHeight: 48)
            .background(Color.ecBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}


