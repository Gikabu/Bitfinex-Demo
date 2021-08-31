//
//  ProfileSetupView.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 29/08/2021.
//

import SwiftUI

struct ProfileSetupView: View {
    var editProfile: Bool = false
    @State private var name: String = ""
    
    var isProceedDisabled: Bool {
        return name.isEmptyOrWhitespace
    }
    
    var body: some View {
        VStack(spacing: 50) {
            Image("bitfinex-avatar")
                .resizable()
                .frame(width: 120, height: 120, alignment: .center)
                .clipShape(Circle())
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
                GroupBox {
                    TextField("Enter username", text: $name)
                        .lineLimit(1)
                        .padding(.trailing, 60)
                }
                .frame(height: 50)
                
                Button (action: { updateProfile() }, label: {
                    Image(systemName: "arrow.right.square.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                })
                .padding(.trailing, 5)
                .disabled(isProceedDisabled)
            }
            
            
            Spacer()
        }
        .navigationBarTitle(editProfile ? "Edit Profile" : "Profile", displayMode: .inline)
        .padding()
        .padding(.top, 30)
        
    }
    
    func updateProfile() {
        Preferences().setUserName(name: name)
    }
}

struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView()
    }
}
