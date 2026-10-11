import SwiftUI

struct LineEditor: View {
    let title: String
    let symbol: String
    let placeholder: String
    let addLabel: String
    @Binding var lines: [EditableLine]
    let onAdd: () -> Void
    let onRemove: (EditableLine.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 10) {
                ForEach($lines) { $line in
                    HStack(alignment: .center, spacing: 10) {
                        TextField(placeholder, text: $line.text, axis: .vertical)
                            .lineLimit(1...4)
                            .foregroundStyle(AppTheme.ink)

                        if lines.count > 1 {
                            Button {
                                onRemove(line.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.inkSecondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Quitar línea")
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppTheme.field, in: RoundedRectangle(cornerRadius: AppTheme.radiusControl, style: .continuous))
                }
            }

            Button(action: onAdd) {
                Label(addLabel, systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.coral)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}
