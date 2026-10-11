import Foundation

@MainActor
final class RecetasViewModel: ObservableObject {
    @Published private(set) var recetas: [Receta] = []
    @Published var busqueda = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository: RecetaRepository

    init(repository: RecetaRepository) {
        self.repository = repository
    }

    var recetasFiltradas: [Receta] {
        let consulta = busqueda.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !consulta.isEmpty else { return recetas }
        return recetas.filter { $0.nombre.localizedCaseInsensitiveContains(consulta) }
    }

    var resumen: String {
        let visibles = recetasFiltradas.count
        if !busqueda.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return visibles == 1 ? "1 resultado" : "\(visibles) resultados"
        }
        return visibles == 1 ? "1 receta" : "\(visibles) recetas"
    }

    func receta(id: Int) -> Receta? {
        recetas.first { $0.id == id }
    }

    func cargar() async {
        let primeraCarga = recetas.isEmpty
        if primeraCarga { isLoading = true }
        defer { isLoading = false }

        do {
            recetas = try await repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reemplazar(_ receta: Receta) {
        if let index = recetas.firstIndex(where: { $0.id == receta.id }) {
            recetas[index] = receta
        } else {
            recetas.insert(receta, at: 0)
        }
    }

    @discardableResult
    func eliminar(id: Int) async -> Bool {
        do {
            try await repository.delete(id: id)
            recetas.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
