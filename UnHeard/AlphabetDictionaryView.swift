//
//  AlphabetDictionaryView.swift
//  UnHeard
//
//  Created by Avya Rathod on 04/02/24.
//

import SwiftUI

struct Sign: Identifiable {
    let id = UUID()
    let word: String
    let imageName: String?
}

extension Sign {
    static let Alphabets = [
        Sign(word: "A", imageName: "A"),
        Sign(word: "B", imageName: "B"),
        Sign(word: "C", imageName: "C"),
        Sign(word: "D", imageName: "D"),
        Sign(word: "E", imageName: "E"),
        Sign(word: "F", imageName: "F"),
        Sign(word: "G", imageName: "G"),
        Sign(word: "H", imageName: "H"),
        Sign(word: "I", imageName: "I"),
        Sign(word: "J", imageName: "J"),
        Sign(word: "K", imageName: "K"),
        Sign(word: "L", imageName: "L"),
        Sign(word: "M", imageName: "M"),
        Sign(word: "N", imageName: "N"),
        Sign(word: "O", imageName: "O"),
        Sign(word: "P", imageName: "P"),
        Sign(word: "Q", imageName: "Q"),
        Sign(word: "R", imageName: "R"),
        Sign(word: "S", imageName: "S"),
        Sign(word: "T", imageName: "T"),
        Sign(word: "U", imageName: "U"),
        Sign(word: "V", imageName: "V"),
        Sign(word: "W", imageName: "W"),
        Sign(word: "X", imageName: "X"),
        Sign(word: "Y", imageName: "Y"),
        Sign(word: "Z", imageName: "Z")
    ]
    
    static let TypeClass = [
        Sign(word:"Alphabets", imageName: nil),
        Sign(word:"Days of the week", imageName: nil),
        Sign(word:"People", imageName: nil),
        Sign(word:"Weather", imageName: nil),
        Sign(word:"Pronouns", imageName: nil),
        Sign(word:"Family", imageName: nil),

    ]
    
}

struct AlphabetPlacardView: View {
    let sign: Sign
    
    var backgroundColor: Color {
        Color(
            red: Double.random(in: 0.4...0.8),
            green: Double.random(in: 0.4...0.8),
            blue: Double.random(in: 0.4...0.8),
            opacity: 1.0
        )
    }
    
    var body: some View {
        VStack {
            Image(sign.imageName!)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
            
            Text(sign.word)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 5)
    }
}

struct TypePlacard: View {
    let sign: Sign
    
    var backgroundColor: Color {
        Color(
            red: Double.random(in: 0.4...0.8),
            green: Double.random(in: 0.4...0.8),
            blue: Double.random(in: 0.4...0.8),
            opacity: 1.0
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 15)
                .fill(backgroundColor)
                .shadow(radius: 5)
            
            // Only show the image if imageName is not nil
            if let imageName = sign.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120) // Adjusted for broader appearance
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    .padding([.bottom, .trailing]) // Adjust padding as needed
            }
            
            // Position the text at the bottom-right corner
            Text(sign.word)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding([.bottom, .trailing], 10) // Adjust padding to position the text
        }
        .frame(width: 160, height: 120) // Increased size for broader appearance
    }
}



struct AlphabetDictionaryView: View {
    let alphabets = Sign.Alphabets
    let typeClasses = Sign.TypeClass
    @State private var searchQuery = ""
    @State private var selectedSign: Sign?
    @State private var isShowingDetail = false
    @State private var showingTypeClassContent: String?

    var searchResults: [Sign] {
        if let typeClass = showingTypeClassContent {
            var results = [Sign]()
            switch typeClass {
                case "Alphabets":
                    results = alphabets
                // Implement logic for other type classes when their data is defined
                default:
                    break
            }
            // If there's a search query, filter the results within the selected type class
            if !searchQuery.isEmpty {
                results = results.filter { $0.word.lowercased().contains(searchQuery.lowercased()) }
            }
            return results
        } else if searchQuery.isEmpty {
            // If no type class is selected and there's no search query, show all type classes
            return typeClasses
        } else {
            // If there's a search query but no type class is selected, search globally
            let filteredAlphabets = alphabets.filter { $0.word.lowercased().contains(searchQuery.lowercased()) }
            let filteredTypeClasses = typeClasses.filter { $0.word.lowercased().contains(searchQuery.lowercased()) }
            return filteredAlphabets + filteredTypeClasses
        }
    }

    
    private var backButton: some View {
        Group {
            if showingTypeClassContent != nil || !searchQuery.isEmpty {
                Button(action: {
                    showingTypeClassContent = nil
                    searchQuery = ""
                    self.isShowingDetail = false
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                }
            }
        }
    }
    
    private var closeButton: some View {
            Button(action: {
                self.isShowingDetail = false
                self.selectedSign = nil
            }) {
                Image(systemName: "xmark")
                    .imageScale(.large)
            }
        }
    
    var columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                TextField(showingTypeClassContent != nil ? "Search in \(showingTypeClassContent!)" : "Search", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                    

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(searchResults) { sign in
                        if showingTypeClassContent == nil, typeClasses.contains(where: { $0.word == sign.word }) {
                            TypePlacard(sign: sign)
                                .onTapGesture {
                                    self.showingTypeClassContent = sign.word
                                    self.searchQuery = ""
                                }
                        } else {
                            AlphabetPlacardView(sign: sign)
                                .onTapGesture {
                                    self.selectedSign = sign
                                    self.isShowingDetail = true
                                }
                        }
                    }
                }
                .padding()
            }
            .blur(radius: isShowingDetail ? 20 : 0)
            .navigationBarTitle(showingTypeClassContent ?? "Sign Dictionary", displayMode: .inline)
            .navigationBarItems(leading: isShowingDetail ? nil : backButton,
                                trailing: isShowingDetail ? closeButton : nil)
            .overlay(
                Group {
                    if isShowingDetail, let sign = selectedSign {
                        SignDetailOverlayView(sign: sign) {
                            self.isShowingDetail = false
                            self.selectedSign = nil
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: isShowingDetail)
                    }
                }
            )
        }
    }
}


struct SignDetailOverlayView: View {
    let sign: Sign
    var onClose: () -> Void
    @State private var animateImage = false

    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all).onTapGesture {
                onClose()
            }

            // Container for the image and text
            VStack {
                Spacer()

                // Image and Text overlay
                VStack {
                    Text(sign.word)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)

                    Image(sign.imageName!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: animateImage ? 200 : 100, height: animateImage ? 200 : 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                        .padding()
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                animateImage = true
                            }
                        }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}



struct AlphabetDictionaryView_Previews: PreviewProvider {
    static var previews: some View {
        AlphabetDictionaryView()
    }
}
