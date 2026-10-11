import Foundation
import Supabase
import UIKit

final class SupabaseRecetaRepository: RecetaRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseProvider.client) {
        self.client = client
    }

    func fetchAll() async throws -> [Receta] {
        do {
            let recetas: [Receta] = try await client
                .from(SupabaseConfig.recipesTable)
                .select()
                .order("id", ascending: false)
                .execute()
                .value
            return recetas
        } catch {
            throw Self.mensaje(error)
        }
    }

    func create(nombre: String, ingredientes: String, pasos: String, imagen: Data) async throws -> Receta {
        do {
            let url = try await subirImagen(imagen)
            let payload = RecetaWrite(
                nombre: nombre,
                ingredientes: ingredientes,
                pasos: pasos,
                imagenURL: url
            )
            let creada: Receta = try await client
                .from(SupabaseConfig.recipesTable)
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return creada
        } catch let error as RecetaServiceError {
            throw error
        } catch {
            throw Self.mensaje(error)
        }
    }

    func update(id: Int, nombre: String, ingredientes: String, pasos: String, imagen: Data?) async throws -> Receta {
        do {
            let imagenAnterior = try await imagenActual(id: id)
            let nuevaURL: String?
            if let imagen {
                nuevaURL = try await subirImagen(imagen)
            } else {
                nuevaURL = nil
            }

            let payload = RecetaWrite(
                nombre: nombre,
                ingredientes: ingredientes,
                pasos: pasos,
                imagenURL: nuevaURL
            )
            let actualizada: Receta = try await client
                .from(SupabaseConfig.recipesTable)
                .update(payload)
                .eq("id", value: id)
                .select()
                .single()
                .execute()
                .value

            if nuevaURL != nil, let imagenAnterior, imagenAnterior != nuevaURL {
                await borrarImagenSiEsNuestra(imagenAnterior)
            }
            return actualizada
        } catch let error as RecetaServiceError {
            throw error
        } catch {
            throw Self.mensaje(error)
        }
    }

    func delete(id: Int) async throws {
        do {
            let imagen = try await imagenActual(id: id)
            try await client
                .from(SupabaseConfig.recipesTable)
                .delete()
                .eq("id", value: id)
                .execute()
            if let imagen {
                await borrarImagenSiEsNuestra(imagen)
            }
        } catch {
            throw Self.mensaje(error)
        }
    }

    private func imagenActual(id: Int) async throws -> String? {
        struct Fila: Decodable {
            let imagenURL: String?
            enum CodingKeys: String, CodingKey { case imagenURL = "imagen_url" }
        }

        let fila: Fila = try await client
            .from(SupabaseConfig.recipesTable)
            .select("imagen_url")
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return fila.imagenURL
    }

    private func subirImagen(_ data: Data) async throws -> String {
        guard let jpeg = Self.jpegPreparado(from: data) else {
            throw RecetaServiceError.imagenInvalida
        }

        let path = "\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString).jpg"
        try await client.storage
            .from(SupabaseConfig.imageBucket)
            .upload(
                path,
                data: jpeg,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try client.storage
            .from(SupabaseConfig.imageBucket)
            .getPublicURL(path: path)
        return publicURL.absoluteString
    }

    private func borrarImagenSiEsNuestra(_ publicURL: String) async {
        guard let path = Self.rutaEnBucket(publicURL) else { return }
        try? await client.storage
            .from(SupabaseConfig.imageBucket)
            .remove(paths: [path])
    }

    private static func rutaEnBucket(_ publicURL: String) -> String? {
        guard let url = URL(string: publicURL) else { return nil }
        let marker = "/\(SupabaseConfig.imageBucket)/"
        guard let range = url.path.range(of: marker) else { return nil }
        let path = String(url.path[range.upperBound...])
        guard !path.isEmpty else { return nil }
        return path.removingPercentEncoding ?? path
    }

    private static func jpegPreparado(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide: CGFloat = 1600
        let longest = max(image.size.width, image.size.height)
        let rendered: UIImage

        if longest > maxSide, longest > 0 {
            let scale = maxSide / longest
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            rendered = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            rendered = image
        }

        return rendered.jpegData(compressionQuality: 0.82)
    }

    private static func mensaje(_ error: Error) -> Error {
        let text = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return RecetaServiceError.sinRespuesta
        }
        return RecetaServiceError.mensaje(text)
    }
}

private struct RecetaWrite: Encodable {
    let nombre: String
    let ingredientes: String
    let pasos: String
    let imagenURL: String?

    enum CodingKeys: String, CodingKey {
        case nombre
        case ingredientes
        case pasos
        case imagenURL = "imagen_url"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nombre, forKey: .nombre)
        try container.encode(ingredientes, forKey: .ingredientes)
        try container.encode(pasos, forKey: .pasos)
        if let imagenURL {
            try container.encode(imagenURL, forKey: .imagenURL)
        }
    }
}
