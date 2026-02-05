import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var scale = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            splashContent
        }
    }
    
    private var splashContent: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "note.text")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundStyle(.blue)
                
                Text("JotJot")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isActive = true
                }
            }
        }
    }
}
