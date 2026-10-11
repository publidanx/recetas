import SwiftUI

struct RecetaPlaceholder: View {
    var body: some View {
        ZStack {
            AppTheme.coralSoft
            Image(systemName: "fork.knife")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.coral)
        }
        .accessibilityHidden(true)
    }
}

struct RecetaRemoteImage: View {
    let url: URL?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RecetaPlaceholder()
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ProgressView()
                                .tint(AppTheme.coral)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }
}

struct RecetaCard: View {
    let receta: Receta

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecetaRemoteImage(url: receta.imagen)
                .frame(height: 168)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(receta.nombre.isEmpty ? "Sin nombre" : receta.nombre)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if !receta.ingredientesLista.isEmpty {
                    Text(etiquetaIngredientes)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .softCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(receta.nombre)
        .accessibilityHint("Abre el detalle de la receta")
    }

    private var etiquetaIngredientes: String {
        let cantidad = receta.ingredientesLista.count
        return cantidad == 1 ? "1 ingrediente" : "\(cantidad) ingredientes"
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.28), value: configuration.isPressed)
    }
}
