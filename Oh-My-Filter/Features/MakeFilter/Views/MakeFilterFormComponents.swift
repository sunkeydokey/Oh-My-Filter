import SwiftUI

struct MakeFilterTextInputSection: View {
  let title: String
  let placeholder: String
  let text: Binding<String>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      MakeFilterSectionTitle(title)

      TextField(placeholder, text: text)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .tint(ColorToken.mainAccent.color)
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(ColorToken.brandDeepSprout.color, lineWidth: 2)
        }
    }
  }
}

struct MakeFilterCategorySection: View {
  let selectedCategory: FilterMakeCategory
  let onCategorySelected: (FilterMakeCategory) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      MakeFilterSectionTitle("카테고리")

      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          ForEach(FilterMakeCategory.allCases, id: \.self) { category in
            Button {
              onCategorySelected(category)
            } label: {
              Text(category.rawValue)
                .font(TypographyToken.pretendardBody3.font)
                .fontWeight(selectedCategory == category ? .bold : .medium)
                .foregroundStyle(selectedCategory == category ? ColorToken.grayScale15.color : ColorToken.grayScale60.color)
                .padding(.horizontal, 17)
                .frame(height: 28)
                .background(
                  selectedCategory == category ? ColorToken.sesacFilterDeepTurquoise.color : ColorToken.brandDeepSprout.color,
                  in: Capsule()
                )
                .buttonHitArea(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }
}

struct MakeFilterPriceSection: View {
  let priceInput: Binding<String>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      MakeFilterSectionTitle("판매 가격")

      HStack {
        TextField("1,000", text: priceInput)
          .keyboardType(.numberPad)
          .font(TypographyToken.pretendardBody3.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .tint(ColorToken.mainAccent.color)

        Text("원")
          .font(TypographyToken.pretendardBody3.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale60.color)
      }
      .padding(.horizontal, 12)
      .frame(height: 42)
      .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .stroke(ColorToken.brandDeepSprout.color, lineWidth: 2)
      }
    }
  }
}

struct MakeFilterSubmitButton: View {
  let title: String
  let canSubmit: Bool
  let isSubmitting: Bool
  let onSubmit: () -> Void

  var body: some View {
    Button(action: onSubmit) {
      HStack(spacing: 8) {
        if isSubmitting {
          ProgressView()
            .tint(ColorToken.grayScale0.color)
        }

        Text(title)
          .font(TypographyToken.pretendardBody2.font)
          .bold()
      }
      .foregroundStyle(ColorToken.grayScale0.color)
      .frame(maxWidth: .infinity)
      .frame(height: 52)
      .background(submitButtonBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .padding(.horizontal, 20)
      .padding(.top, 12)
      .padding(.bottom, 8)
      .background(ColorToken.brandBlackSprout.color)
    }
    .buttonStyle(.plain)
    .disabled(canSubmit == false)
  }

  private var submitButtonBackground: Color {
    canSubmit
      ? ColorToken.sesacFilterDeepTurquoise.color
      : ColorToken.grayScale90.color
  }
}

struct MakeFilterSectionTitle: View {
  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some View {
    Text(title)
      .font(TypographyToken.mulgyeolCaption1.font)
      .foregroundStyle(ColorToken.grayScale45.color)
  }
}
