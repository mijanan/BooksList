//
//  HelpersView.swift
//  VisualAid
//
//  Created by Janarthanan on 14/08/24.
//

import SwiftUI

struct CustomTextFieldView: View {
    @Binding var textInput: String
    
    var placeHolderText: String
    
    var padding: EdgeInsets
    
    var textAlignment: TextAlignment
    
    var numberOfLines: Int = 1
    
    var body: some View {
        VStack {
            TextField(placeHolderText, text: $textInput)
                .font(.subheadline)
                .padding(padding)
                .multilineTextAlignment(textAlignment)
                .lineLimit(5)
            
        }
        .background(Color(red: 0.961, green: 0.965, blue: 0.973))
        .cornerRadius(3.0)
    }
}

#Preview {
    CustomTextFieldView(textInput: .constant(""), placeHolderText: "Email", padding: EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10), textAlignment: .center)
}
