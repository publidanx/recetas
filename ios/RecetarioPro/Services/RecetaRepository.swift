import Foundation

protocol RecetaRepository: AnyObject {
    func fetchAll() async throws -> [Receta]
    func create(nombre: String, ingredientes: String, pasos: String, imagen: Data) async throws -> Receta
    func update(id: Int, nombre: String, ingredientes: String, pasos: String, imagen: Data?) async throws -> Receta
    func delete(id: Int) async throws
}

enum RecetaServiceError: LocalizedError {
    case imagenInvalida
    case sinRespuesta
    case mensaje(String)

    var errorDescription: String? {
        switch self {
        case .imagenInvalida:
            return "No se pudo preparar la foto. Prueba con otra imagen de la galería."
        case .sinRespuesta:
            return "No se pudo completar la operación en el servidor."
        case .mensaje(let texto):
            return texto
        }
    }
}

final class PreviewRecetaRepository: RecetaRepository {
    private var recetas = Receta.muestras

    func fetchAll() async throws -> [Receta] {
        recetas
    }

    func create(nombre: String, ingredientes: String, pasos: String, imagen: Data) async throws -> Receta {
        let receta = Receta(
            id: (recetas.map(\.id).max() ?? 0) + 1,
            nombre: nombre,
            ingredientes: ingredientes,
            pasos: pasos,
            imagenURL: nil
        )
        recetas.insert(receta, at: 0)
        return receta
    }

    func update(id: Int, nombre: String, ingredientes: String, pasos: String, imagen: Data?) async throws -> Receta {
        guard let index = recetas.firstIndex(where: { $0.id == id }) else {
            throw RecetaServiceError.sinRespuesta
        }
        recetas[index].nombre = nombre
        recetas[index].ingredientes = ingredientes
        recetas[index].pasos = pasos
        return recetas[index]
    }

    func delete(id: Int) async throws {
        recetas.removeAll { $0.id == id }
    }
}
