import SwiftUI

struct FilterDetailPriceView: View {
  let detail: FilterDetail

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(detail.priceText)
        .font(TypographyToken.mulgyeolTitle1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      Text("Coin")
        .font(TypographyToken.mulgyeolBody1.font)
        .foregroundStyle(ColorToken.grayScale60.color)
    }
  }
}
