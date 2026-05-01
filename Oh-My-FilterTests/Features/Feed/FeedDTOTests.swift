import Foundation
import Testing
@testable import Oh_My_Filter

struct FeedDTOTests {
  @Test("filter page dto decodes pagination payload")
  func decodeFilterPageDTO() throws {
    let dto = try decoder.decode(FeedFilterPageDTO.self, from: Self.pageData)

    #expect(dto.nextCursor == "cursor-2")
    #expect(dto.data.count == 1)
    #expect(dto.data[0].filterId == "filter-1")
    #expect(dto.data[0].files.first == "/data/filters/previews_original_1.jpg")
    #expect(dto.data[0].creator?.nick == "크레용")
    #expect(dto.data[0].likeCount == 17)
    #expect(dto.data[0].buyerCount == 5)
  }

  @Test("filter page dto maps to feed domain")
  func mapFilterPageDTOToDomain() throws {
    let dto = try decoder.decode(FeedFilterPageDTO.self, from: Self.pageData)
    let page = dto.toDomain()

    #expect(page.nextCursor == "cursor-2")
    #expect(page.filters.first?.id == "filter-1")
    #expect(page.filters.first?.creatorNick == "크레용")
    #expect(page.filters.first?.imageURL?.absoluteString.contains("/v1/data/filters/previews_original_1.jpg") == true)
    #expect(page.filters.first?.likeCount == 17)
    #expect(page.filters.first?.buyerCount == 5)
  }

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
}

private extension FeedDTOTests {
  static let pageData = Data(
    """
    {
      "data": [
        {
          "filter_id": "filter-1",
          "category": "풍경",
          "title": "Skyline Boost",
          "description": "고층 건물과 도시 라인을 선명하게 만듭니다",
          "files": [
            "/data/filters/previews_original_1.jpg",
            "/data/filters/previews_filtered_1.jpg"
          ],
          "creator": {
            "user_id": "user-1",
            "nick": "크레용",
            "name": "김민준",
            "introduction": "안녕하세요! 크레용입니다!",
            "profileImage": "/data/profiles/1.jpg",
            "hashTags": ["밝음", "긍정적"]
          },
          "is_liked": false,
          "like_count": 17,
          "buyer_count": 5,
          "createdAt": "2026-02-13T15:59:21.071Z",
          "updatedAt": "2026-02-13T15:59:21.071Z"
        }
      ],
      "next_cursor": "cursor-2"
    }
    """.utf8
  )
}
