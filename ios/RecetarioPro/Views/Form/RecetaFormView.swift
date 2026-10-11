import PhotosUI
import SwiftUI
import UIKit

struct RecetaFormView: View {
    @StateObject private var viewModel: RecetaFormViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?

    private let onSaved: (Receta) -> Void

    init(modo: FormularioModo, repository: RecetaRepository, onSaved: @escaping (Receta) -> Void) {
        _viewModel = StateObject(wrappedValue: RecetaFormViewModel(modo: modo, repository: repository))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    selectorFoto
                    campoNombre

                    LineEditor(
                        title: "Ingredientes",
                        symbol: "list.bullet",
                        placeholder: "Ej. 200 g de harina",
                        addLabel: "Añadir ingrediente",
                        lines: $viewModel.ingredientes,
                        onAdd: { viewModel.agregarIngrediente() },
                        onRemove: { viewModel.quitarIngrediente($0) }
                    )

                    LineEditor(
                        title: "Preparación",
                        symbol: "flame",
                        placeholder: "Describe el paso",
                        addLabel: "Añadir paso",
                        lines: $viewModel.pasos,
                        onAdd: { viewModel.agregarPaso() },
                        onRemove: { viewModel.quitarPaso($0) }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(viewModel.modo.titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .disabled(viewModel.isSaving)
                }
            }
            .safeAreaInset(edge: .bottom) {
                barraGuardar
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isSaving)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    viewModel.asignarImagen(data)
                } else {
                    viewModel.informar("No se pudo leer la foto seleccionada.")
                }
            }
        }
    }

    private var selectorFoto: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack {
                if let data = viewModel.imagenData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if viewModel.imagenExistente != nil {
                    RecetaRemoteImage(url: viewModel.imagenExistente)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32, weight: .semibold))
                        Text("Elegir foto de la galería")
                            .font(.system(.headline, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.coral)
                }

                if viewModel.imagenData != nil || viewModel.imagenExistente != nil {
                    Text("Cambiar foto")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.45), in: Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(14)
                }
            }
            .frame(height: 230)
            .frame(maxWidth: .infinity)
            .background(AppTheme.coralSoft)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay {
                if viewModel.imagenData == nil && viewModel.imagenExistente == nil {
                    RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                        .strokeBorder(
                            AppTheme.coral.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1.5, dash: [7, 6])
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Seleccionar foto de la galería")
    }

    private var campoNombre: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nombre")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            TextField("Nombre del plato", text: $viewModel.nombre)
                .textInputAutocapitalization(.sentences)
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(AppTheme.field, in: RoundedRectangle(cornerRadius: AppTheme.radiusControl, style: .continuous))
        }
        .padding(16)
        .softCard()
    }

    private var barraGuardar: some View {
        VStack(spacing: 8) {
            if let mensaje = viewModel.mensaje {
                Text(mensaje)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.coral)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task {
                    if let receta = await viewModel.guardar() {
                        onSaved(receta)
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isSaving ? "Guardando" : "Guardar receta")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: AppTheme.radiusControl, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview("Formulario") {
    RecetaFormView(modo: .crear, repository: PreviewRecetaRepository(), onSaved: { _ in })
}

#Preview("Formulario oscuro") {
    RecetaFormView(modo: .editar(Receta.muestras[0]), repository: PreviewRecetaRepository(), onSaved: { _ in })
        .preferredColorScheme(.dark)
}
