import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "folder.badge.gearshape",
            color: .blue,
            title: "Bienvenido a Tidy",
            description: "Organiza automáticamente tu carpeta Downloads en subcarpetas según el tipo de archivo."
        ),
        OnboardingPage(
            icon: "eye.fill",
            color: .green,
            title: "Vigilancia automática",
            description: "Activa el modo automático y Tidy organizará cada archivo nuevo en el momento que llegue."
        ),
        OnboardingPage(
            icon: "slider.horizontal.3",
            color: .purple,
            title: "Reglas personalizadas",
            description: "Crea reglas para mover archivos por nombre, tamaño o fecha a carpetas específicas."
        ),
        OnboardingPage(
            icon: "checkmark.shield.fill",
            color: .orange,
            title: "Solo archivos sueltos",
            description: "Tidy nunca toca tus carpetas existentes. Solo organiza archivos sueltos — lo que claramente necesita organización."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Page content
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(pages[currentPage].color.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(pages[currentPage].color)
                }
                .animation(.spring(response: 0.4), value: currentPage)

                VStack(spacing: 12) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(pages[currentPage].description)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                }
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }

            Spacer()

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? Color.blue : Color.primary.opacity(0.2))
                        .frame(width: i == currentPage ? 10 : 7, height: i == currentPage ? 10 : 7)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 28)

            // Buttons
            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button("Atrás") {
                        withAnimation { currentPage -= 1 }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }

                Button(currentPage < pages.count - 1 ? "Siguiente" : "¡Empezar!") {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        organizer.hasCompletedOnboarding = true
                        organizer.saveData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(width: 500, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let description: String
}
