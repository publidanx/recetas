import Foundation

enum FormularioModo: Identifiable {
    case crear
    case editar(Receta)

    var id: String {
        switch self {
        case .crear:
            return "crear"
        case .editar(let receta):
            return "editar-\(receta.id)"
        }
    }

    var titulo: String {
        switch self {
        case .crear:
            return "Nueva receta"
        case .editar:
            return "Editar receta"
        }
    }
}

struct EditableLine: Identifiable, Equatable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String = "") {
        self.id = id
        self.text = text
    }
}

@MainActor
final class RecetaFormViewModel: ObservableObject {
    @Published var nombre: String
    @Published var ingredientes: [EditableLine]
    @Published var pasos: [EditableLine]
    @Published var imagenData: Data?
    @Published private(set) var isSaving = false
    @Published var mensaje: String?

    let modo: FormularioModo
    private let repository: RecetaRepository

    init(modo: FormularioModo, repository: RecetaRepository) {
        self.modo = modo
        self.repository = repository

        switch modo {
        case .crear:
            nombre = ""
            ingredientes = [EditableLine()]
            pasos = [EditableLine()]
        case .editar(let receta):
            nombre = receta.nombre
            ingredientes = Self.lineasEditables(receta.ingredientes)
            pasos = Self.lineasEditables(receta.pasos)
        }
    }

    var imagenExistente: URL? {
        guard imagenData == nil, case .editar(let receta) = modo else { return nil }
        return receta.imagen
    }

    func asignarImagen(_ data: Data) {
        imagenData = data
        mensaje = nil
    }

    func informar(_ texto: String) {
        mensaje = texto
    }

    func agregarIngrediente() {
        ingredientes.append(EditableLine())
    }

    func quitarIngrediente(_ id: EditableLine.ID) {
        ingredientes.removeAll { $0.id == id }
        if ingredientes.isEmpty { ingredientes = [EditableLine()] }
    }

    func agregarPaso() {
        pasos.append(EditableLine())
    }

    func quitarPaso(_ id: EditableLine.ID) {
        pasos.removeAll { $0.id == id }
        if pasos.isEmpty { pasos = [EditableLine()] }
    }

    func guardar() async -> Receta? {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nombreLimpio.isEmpty else {
            mensaje = "Escribe el nombre del plato."
            return nil
        }
        if case .crear = modo, imagenData == nil {
            mensaje = "Selecciona una foto de la galería."
            return nil
        }

        mensaje = nil
        isSaving = true
        defer { isSaving = false }

        do {
            switch modo {
            case .crear:
                guard let imagenData else { return nil }
                return try await repository.create(
                    nombre: nombreLimpio,
                    ingredientes: Self.texto(ingredientes),
                    pasos: Self.texto(pasos),
                    imagen: imagenData
                )
            case .editar(let receta):
                return try await repository.update(
                    id: receta.id,
                    nombre: nombreLimpio,
                    ingredientes: Self.texto(ingredientes),
                    pasos: Self.texto(pasos),
                    imagen: imagenData
                )
            }
        } catch {
            mensaje = error.localizedDescription
            return nil
        }
    }

    private static func lineasEditables(_ texto: String) -> [EditableLine] {
        let partes = texto
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if partes.isEmpty { return [EditableLine()] }
        return partes.map { EditableLine(text: $0) }
    }

    private static func texto(_ lineas: [EditableLine]) -> String {
        lineas
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
