import Foundation

nonisolated struct FilterMakeDraft: Equatable, Hashable, Sendable {
  let filterID: String?
  let name: String
  let category: FilterMakeCategory
  let introduction: String
  let price: Int
  let representativeImageData: Data?
  var photoMetadata = FilterDetailMetadata(
    camera: nil,
    lens: nil,
    focalLength: nil,
    aperture: nil,
    shutterSpeed: nil,
    iso: nil
  )
  var filterParameterValues: [FilterEditParameter: Double] = FilterEditParameter.defaultValues

  init(
    filterID: String? = nil,
    name: String,
    category: FilterMakeCategory,
    introduction: String,
    price: Int,
    representativeImageData: Data?,
    photoMetadata: FilterDetailMetadata = FilterDetailMetadata(
      camera: nil,
      lens: nil,
      focalLength: nil,
      aperture: nil,
      shutterSpeed: nil,
      iso: nil
    ),
    filterParameterValues: [FilterEditParameter: Double] = FilterEditParameter.defaultValues
  ) {
    self.filterID = filterID
    self.name = name
    self.category = category
    self.introduction = introduction
    self.price = price
    self.representativeImageData = representativeImageData
    self.photoMetadata = photoMetadata
    self.filterParameterValues = filterParameterValues
  }

  var priceText: String {
    price.formatted(.number)
  }

  var filterValues: FilterValues {
    FilterEditParameter.filterValues(from: filterParameterValues)
  }
}
