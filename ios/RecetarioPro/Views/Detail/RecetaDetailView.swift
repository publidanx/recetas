import SwiftUI

struct RecetaDetailView: View {
    let receta: Receta
    let onEdit: () -> Void
    let onDelete: () async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var confirmandoBorrado = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                cabecera

                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(receta.nombre.isEmpty ? "Sin nombre" : receta.nombre)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        metadatos
                    }

                    seccionLista(titulo: "Ingredientes") {
                        ingredientes
                    }

                    seccionLista(titulo: "Preparación") {
                        pasos
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 36)
            }
        }
        .background(AppTheme.background)
        .ignoresSafeArea(edges: .top)
        .coordinateSpace(name: "detalle")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                botonBarra(simbolo: "chevron.left", etiqueta: "Volver") {
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                botonBarra(simbolo: "pencil", etiqueta: "Editar receta", action: onEdit)
                botonBarra(simbolo: "trash", etiqueta: "Eliminar receta") {
                    confirmandoBorrado = true
                }
            }
        }
        .confirmationDialog(
            "¿Eliminar \(receta.nombre)?",
            isPresented: $confirmandoBorrado,
            titleVisibility: .visible
        ) {
            Button("Eliminar receta", role: .destructive) {
                Task {
                    if await onDelete() {
                        dismiss()
                    }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("La receta y su foto dejarán de estar en el recetario.")
        }
    }

    private var cabecera: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("detalle")).minY
            let extra = max(minY, 0)

            RecetaRemoteImage(url: receta.imagen)
                .frame(width: geo.size.width, height: 420 + extra)
                .clipped()
                .offset(y: minY > 0 ? -minY : 0)
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [.black.opacity(0.38), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                    .allowsHitTesting(false)
                }
        }
        .frame(height: 420)
    }

    @ViewBuilder
    private var metadatos: some View {
        if !receta.ingredientesLista.isEmpty || !receta.pasosLista.isEmpty {
            HStack(spacing: 8) {
                if !receta.ingredientesLista.isEmpty {
                    chip(simbolo: "list.bullet", texto: etiqueta(receta.ingredientesLista.count, singular: "ingrediente", plural: "ingredientes"))
                }
                if !receta.pasosLista.isEmpty {
                    chip(simbolo: "flame", texto: etiqueta(receta.pasosLista.count, singular: "paso", plural: "pasos"))
                }
            }
        }
    }

    private func chip(simbolo: String, texto: String) -> some View {
        Label(texto, systemImage: simbolo)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.coral)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.coralSoft, in: Capsule())
    }

    private func seccionLista<Content: View>(
        titulo: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .softCard()
        }
    }

    @ViewBuilder
    private var ingredientes: some View {
        if receta.ingredientesLista.isEmpty {
            Text("Esta receta no tiene ingredientes.")
                .font(.body)
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.vertical, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(receta.ingredientesLista.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Circle()
                            .fill(AppTheme.coral)
                            .frame(width: 8, height: 8)
                            .alignmentGuide(.firstTextBaseline) { dimensions in
                                dimensions[VerticalAlignment.center] + 4
                            }
                        Text(item)
                            .font(.body)
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)

                    if index < receta.ingredientesLista.count - 1 {
                        Divider().overlay(AppTheme.ink.opacity(0.08))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var pasos: some View {
        if receta.pasosLista.isEmpty {
            Text("Esta receta no tiene pasos.")
                .font(.body)
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.vertical, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(receta.pasosLista.enumerated()), id: \.offset) { index, paso in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(index + 1)")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.coral, in: Circle())

                        Text(paso)
                            .font(.body)
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 3)
                    }
                    .padding(.vertical, 12)

                    if index < receta.pasosLista.count - 1 {
                        Divider().overlay(AppTheme.ink.opacity(0.08))
                    }
                }
            }
        }
    }

    private func botonBarra(simbolo: String, etiqueta: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: simbolo)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel(etiqueta)
    }

    private func etiqueta(_ cantidad: Int, singular: String, plural: String) -> String {
        cantidad == 1 ? "1 \(singular)" : "\(cantidad) \(plural)"
    }
}

#Preview("Detalle") {
    NavigationStack {
        RecetaDetailView(receta: Receta.muestras[0], onEdit: {}, onDelete: { true })
    }
}

#Preview("Detalle oscuro") {
    NavigationStack {
        RecetaDetailView(receta: Receta.muestras[0], onEdit: {}, onDelete: { true })
    }
    .preferredColorScheme(.dark)
}
