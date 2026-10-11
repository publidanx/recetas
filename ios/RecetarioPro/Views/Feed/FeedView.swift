import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: RecetasViewModel
    @State private var formulario: FormularioModo?

    private let repository: RecetaRepository
    private let columns = [GridItem(.adaptive(minimum: 158), spacing: 14)]

    init(repository: RecetaRepository) {
        self.repository = repository
        _viewModel = StateObject(wrappedValue: RecetasViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.recetas.isEmpty {
                    ProgressView("Cargando recetas")
                        .tint(AppTheme.coral)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.recetasFiltradas.isEmpty {
                    estadoVacio
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(viewModel.resumen)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.inkSecondary)
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(viewModel.recetasFiltradas) { receta in
                                    NavigationLink(value: receta.id) {
                                        RecetaCard(receta: receta)
                                    }
                                    .buttonStyle(PressableCardStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 28)
                    }
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Recetario Pro")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.busqueda,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar por nombre"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        formulario = .crear
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel("Nueva receta")
                }
            }
            .navigationDestination(for: Int.self) { id in
                if let receta = viewModel.receta(id: id) {
                    RecetaDetailView(
                        receta: receta,
                        onEdit: { formulario = .editar(receta) },
                        onDelete: { await viewModel.eliminar(id: receta.id) }
                    )
                } else {
                    ContentUnavailableView("Receta no disponible", systemImage: "fork.knife")
                        .background(AppTheme.background.ignoresSafeArea())
                }
            }
            .sheet(item: $formulario) { modo in
                RecetaFormView(modo: modo, repository: repository) { guardada in
                    viewModel.reemplazar(guardada)
                }
            }
            .alert(
                "No se pudo completar",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.cargar()
            }
            .refreshable {
                await viewModel.cargar()
            }
        }
    }

    @ViewBuilder
    private var estadoVacio: some View {
        if viewModel.recetas.isEmpty {
            ContentUnavailableView(
                "Aún no hay recetas",
                systemImage: "fork.knife",
                description: Text("Añade tu primer plato con el botón +.")
            )
        } else {
            ContentUnavailableView.search(text: viewModel.busqueda)
        }
    }
}

#Preview("Inicio") {
    FeedView(repository: PreviewRecetaRepository())
}

#Preview("Inicio oscuro") {
    FeedView(repository: PreviewRecetaRepository())
        .preferredColorScheme(.dark)
}
