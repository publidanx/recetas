import Foundation

struct Receta: Identifiable, Codable, Hashable {
    let id: Int
    var nombre: String
    var ingredientes: String
    var pasos: String
    var imagenURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nombre
        case ingredientes
        case pasos
        case imagenURL = "imagen_url"
    }

    init(id: Int, nombre: String, ingredientes: String, pasos: String, imagenURL: String?) {
        self.id = id
        self.nombre = nombre
        self.ingredientes = ingredientes
        self.pasos = pasos
        self.imagenURL = imagenURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        nombre = try container.decodeIfPresent(String.self, forKey: .nombre) ?? ""
        ingredientes = try container.decodeIfPresent(String.self, forKey: .ingredientes) ?? ""
        pasos = try container.decodeIfPresent(String.self, forKey: .pasos) ?? ""
        imagenURL = try container.decodeIfPresent(String.self, forKey: .imagenURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nombre, forKey: .nombre)
        try container.encode(ingredientes, forKey: .ingredientes)
        try container.encode(pasos, forKey: .pasos)
        try container.encodeIfPresent(imagenURL, forKey: .imagenURL)
    }

    var imagen: URL? {
        guard let imagenURL, !imagenURL.isEmpty else { return nil }
        return URL(string: imagenURL)
    }

    var ingredientesLista: [String] {
        Self.lineas(ingredientes, dividirComas: true)
    }

    var pasosLista: [String] {
        Self.lineas(pasos, dividirComas: false)
    }

    static let muestras: [Receta] = [
        Receta(
            id: 1,
            nombre: "Tortilla de patatas",
            ingredientes: "4 huevos\n3 patatas\n1 cebolla\nAceite de oliva\nSal",
            pasos: "Pela y corta las patatas en láminas finas.\nFríelas a fuego medio con la cebolla.\nBate los huevos, mezcla y cuaja la tortilla por ambos lados.",
            imagenURL: nil
        ),
        Receta(
            id: 2,
            nombre: "Gazpacho",
            ingredientes: "Tomate, pepino, pimiento, ajo, aceite, vinagre, sal",
            pasos: "Lava y trocea las hortalizas.\nTrútalas con el aceite, el vinagre y la sal.\nPasa la mezcla por un colador y enfría.",
            imagenURL: nil
        ),
        Receta(
            id: 3,
            nombre: "Arroz con leche",
            ingredientes: "1 l de leche\n150 g de arroz\n100 g de azúcar\nCanela en rama\nPiel de limón",
            pasos: "Cuece el arroz en la leche con la canela y el limón.\nAñade el azúcar cuando el arroz esté tierno.\nReposa en frío y espolvorea canela.",
            imagenURL: nil
        )
    ]

    private static func lineas(_ texto: String, dividirComas: Bool) -> [String] {
        let partes = texto
            .components(separatedBy: .newlines)
            .map(limpiarPrefijo)
            .filter { !$0.isEmpty }

        guard dividirComas, partes.count == 1, partes[0].contains(",") else {
            return partes
        }

        return partes[0]
            .split(separator: ",")
            .map { limpiarPrefijo(String($0)) }
            .filter { !$0.isEmpty }
    }

    private static func limpiarPrefijo(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in ["- ", "• ", "* ", "– "] where text.hasPrefix(prefix) {
            text.removeFirst(prefix.count)
            text = text.trimmingCharacters(in: .whitespaces)
        }
        if let range = text.range(of: #"^\d+[\.\)]\s+"#, options: .regularExpression) {
            text.removeSubrange(range)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
