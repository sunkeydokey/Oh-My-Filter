import Foundation
import Observation

@MainActor
@Observable
final class FilterEditViewModel {
  private(set) var state: FilterEditState
  private let renderer: any ImageFilterRendering
  private var renderTask: Task<Void, Never>?

  init(
    draft: FilterMakeDraft,
    filterParameterValues: [FilterEditParameter: Double]? = nil,
    renderer: any ImageFilterRendering = CoreImageFilterRenderer()
  ) {
    self.renderer = renderer
    state = FilterEditState(draft: draft)
    renderPreview(with: filterParameterValues ?? draft.filterParameterValues)
  }

  func send(
    _ action: FilterEditAction,
    values: [FilterEditParameter: Double]
  ) -> [FilterEditParameter: Double] {
    switch action {
    case let .parameterSelected(parameter):
      state.selectedParameter = parameter
      return values
    case let .valueChanged(value):
      let updatedValues = updateSelectedValue(value, in: values)
      renderPreview(with: updatedValues)
      return updatedValues
    case .undo:
      let updatedValues = undo(currentValues: values)
      renderPreview(with: updatedValues)
      return updatedValues
    case .redo:
      let updatedValues = redo(currentValues: values)
      renderPreview(with: updatedValues)
      return updatedValues
    case .reset:
      state.history.append(values)
      state.redoStack = []
      let updatedValues = FilterEditParameter.defaultValues
      renderPreview(with: updatedValues)
      return updatedValues
    }
  }

  func renderPreview(with values: [FilterEditParameter: Double]) {
    schedulePreviewRender(with: values)
  }

  private func updateSelectedValue(
    _ value: Double,
    in values: [FilterEditParameter: Double]
  ) -> [FilterEditParameter: Double] {
    let clampedValue = state.selectedParameter.clamped(value)
    guard values[state.selectedParameter] != clampedValue else { return values }
    var updatedValues = values
    state.history.append(values)
    updatedValues[state.selectedParameter] = clampedValue
    state.redoStack = []
    return updatedValues
  }

  private func undo(currentValues: [FilterEditParameter: Double]) -> [FilterEditParameter: Double] {
    guard let previousValues = state.history.popLast() else { return currentValues }
    state.redoStack.append(currentValues)
    return previousValues
  }

  private func redo(currentValues: [FilterEditParameter: Double]) -> [FilterEditParameter: Double] {
    guard let nextValues = state.redoStack.popLast() else { return currentValues }
    state.history.append(currentValues)
    return nextValues
  }

  private func schedulePreviewRender(with values: [FilterEditParameter: Double]) {
    guard let imageData = state.draft.representativeImageData else {
      state.previewImage = nil
      return
    }

    let filterValues = FilterEditParameter.filterValues(from: values)
    renderTask?.cancel()
    renderTask = Task { [renderer, imageData, filterValues] in
      do {
        let images = try await renderer.render(originalImageData: imageData, filterValues: filterValues)
        try Task.checkCancellation()
        self.state.previewImage = images.filtered
      } catch is CancellationError {
      } catch {
        self.state.previewImage = nil
      }
    }
  }
}
