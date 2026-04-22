import SwiftUI

/// Tokens imported from Figma file `oPqetVKRN2ukzdLpYKr11h`, node `2284:1345`.
enum TypographyToken: String, CaseIterable, Sendable {
  case pretendardTitle1 = "PretendardTitle1"
  case pretendardBody1 = "PretendardBody1"
  case pretendardBody2 = "PretendardBody2"
  case pretendardBody3 = "PretendardBody3"
  case pretendardCaption1 = "PretendardCaption1"
  case pretendardCaption2 = "PretendardCaption2"
  case pretendardCaption3 = "PretendardCaption3"
  case mulgyeolTitle1 = "MulgyeolTitle1"
  case mulgyeolBody1 = "MulgyeolBody1"
  case mulgyeolCaption1 = "MulgyeolCaption1"

  var figmaName: String {
    switch self {
    case .pretendardTitle1:
      "Pretendard/Title 1"
    case .pretendardBody1:
      "Pretendard/Body 1"
    case .pretendardBody2:
      "Pretendard/Body 2"
    case .pretendardBody3:
      "Pretendard/Body 3"
    case .pretendardCaption1:
      "Pretendard/Caption 1"
    case .pretendardCaption2:
      "Pretendard/Caption 2"
    case .pretendardCaption3:
      "Pretendard/Caption 3"
    case .mulgyeolTitle1:
      "학교안심 물결체/Title 1"
    case .mulgyeolBody1:
      "학교안심 물결체/Body 1"
    case .mulgyeolCaption1:
      "학교안심 물결체/Caption 1"
    }
  }

  var familyDisplayName: String {
    switch self {
    case .pretendardTitle1,
      .pretendardBody1,
      .pretendardBody2,
      .pretendardBody3,
      .pretendardCaption1,
      .pretendardCaption2,
      .pretendardCaption3:
      "Pretendard"
    case .mulgyeolTitle1, .mulgyeolBody1, .mulgyeolCaption1:
      "학교안심 물결체"
    }
  }

  var fontName: String {
    switch self {
    case .pretendardTitle1:
      "Pretendard-SemiBold"
    case .pretendardBody1,
      .pretendardBody2,
      .pretendardBody3,
      .pretendardCaption1,
      .pretendardCaption2,
      .pretendardCaption3:
      "Pretendard-Regular"
    case .mulgyeolTitle1, .mulgyeolBody1, .mulgyeolCaption1:
      "HakgyoansimMulgyeolB"
    }
  }

  var roleTitle: String {
    switch self {
    case .pretendardTitle1, .mulgyeolTitle1:
      "Title 1"
    case .pretendardBody1, .mulgyeolBody1:
      "Body 1"
    case .pretendardBody2:
      "Body 2"
    case .pretendardBody3:
      "Body 3"
    case .pretendardCaption1, .mulgyeolCaption1:
      "Caption 1"
    case .pretendardCaption2:
      "Caption 2"
    case .pretendardCaption3:
      "Caption 3"
    }
  }

  var pointSize: CGFloat {
    switch self {
    case .pretendardTitle1:
      20
    case .pretendardBody1:
      16
    case .pretendardBody2:
      14
    case .pretendardBody3:
      13
    case .pretendardCaption1:
      12
    case .pretendardCaption2:
      10
    case .pretendardCaption3:
      8
    case .mulgyeolTitle1:
      32
    case .mulgyeolBody1:
      20
    case .mulgyeolCaption1:
      14
    }
  }

  var relativeTextStyle: Font.TextStyle {
    switch self {
    case .pretendardTitle1:
      .title3
    case .pretendardBody1, .mulgyeolBody1:
      .body
    case .pretendardBody2:
      .callout
    case .pretendardBody3:
      .subheadline
    case .pretendardCaption1, .mulgyeolCaption1:
      .caption
    case .pretendardCaption2:
      .caption2
    case .pretendardCaption3:
      .caption2
    case .mulgyeolTitle1:
      .largeTitle
    }
  }

  var font: Font {
    .custom(fontName, size: pointSize, relativeTo: relativeTextStyle)
  }

  var sampleText: String {
    switch self {
    case .pretendardTitle1,
      .pretendardBody1,
      .pretendardBody2,
      .pretendardBody3,
      .pretendardCaption1,
      .pretendardCaption2,
      .pretendardCaption3:
      "새싹아 일어나 어서 일어나서 코딩 해야지"
    case .mulgyeolTitle1, .mulgyeolBody1, .mulgyeolCaption1:
      "새싹을 담은 필터"
    }
  }

  var sizeLabel: String {
    "\(Int(pointSize))px"
  }

  var sortOrder: Int {
    switch self {
    case .pretendardTitle1:
      0
    case .pretendardBody1:
      1
    case .pretendardBody2:
      2
    case .pretendardBody3:
      3
    case .pretendardCaption1:
      4
    case .pretendardCaption2:
      5
    case .pretendardCaption3:
      6
    case .mulgyeolTitle1:
      7
    case .mulgyeolBody1:
      8
    case .mulgyeolCaption1:
      9
    }
  }
}
