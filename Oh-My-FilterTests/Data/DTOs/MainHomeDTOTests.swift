import Foundation
import Testing
@testable import Oh_My_Filter

struct MainHomeDTOTests {
  @Test("today filter dto decodes nested creator payload")
  func decodeTodayFilterDTO() throws {
    let dto = try decoder.decode(MainTodayFilterDTO.self, from: Self.todayFilterData)

    #expect(dto.filterId == "698f4a592d826cebc45be870")
    #expect(dto.category == "풍경")
    #expect(dto.title == "오늘의 필터")
    #expect(dto.introduction == "새싹을 담은 필터")
    #expect(dto.description == "햇살 아래 돋아나는 새싹처럼, 맑고 투명한 빛을 담은 자연 감성 필터입니다. 너무 과하지 않게, 부드러운 색감으로 분위기를 살려줍니다. 새로운 시작, 순수한 감정을 담고 싶을 때 이 피어를 사용해보세요.")
    #expect(dto.files.count == 2)
    #expect(dto.creator?.nick == "크레용")
    #expect(dto.isLiked == false)
    #expect(dto.likeCount == 0)
    #expect(dto.buyerCount == 0)
    #expect(dto.createdAt == "2025-12-10T02:23:20.911Z")
  }

  @Test("main banners dto decodes nested banner payload")
  func decodeMainBannerDTO() throws {
    let response = try decoder.decode(MainBannersResponseDTO.self, from: Self.mainBannersData)

    #expect(response.data.count == 4)
    #expect(response.data[0].name == "banner4")
    #expect(response.data[0].imageUrl == "/data/banners/Filter_4.png")
    #expect(response.data[0].payload.type == .webview)
    #expect(response.data[0].payload.value == "/event-application")
  }

  @Test("hot trend dto decodes creator payload")
  func decodeHotTrendDTO() throws {
    let response = try decoder.decode(MainHotTrendFiltersResponseDTO.self, from: Self.hotTrendData)

    #expect(response.data.count == 2)
    #expect(response.data[0].filterId == "698f4a592d826cebc45be870")
    #expect(response.data[0].category == "풍경")
    #expect(response.data[0].creator?.userId == "698f49392d826cebc45be72f")
    #expect(response.data[0].files.first == "/data/filters/previews_original_1770998360980.jpg")
  }

  @Test("today author dto decodes user payload")
  func decodeTodayAuthorDTO() throws {
    let response = try decoder.decode(MainTodayAuthorResponseDTO.self, from: Self.todayAuthorData)

    #expect(response.author.userId == "author-1")
    #expect(response.author.nick == "SESAC YOON")
    #expect(response.author.name == "윤새싹")
    #expect(response.author.introduction == "자연의 섬세함을 담아내는 감성 사진작가")
  }

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
}

private extension MainHomeDTOTests {
  static let todayFilterData = Data(
    """
    {
      "filter_id": "698f4a592d826cebc45be870",
      "category": "풍경",
      "title": "오늘의 필터",
      "introduction": "새싹을 담은 필터",
      "description": "햇살 아래 돋아나는 새싹처럼, 맑고 투명한 빛을 담은 자연 감성 필터입니다. 너무 과하지 않게, 부드러운 색감으로 분위기를 살려줍니다. 새로운 시작, 순수한 감정을 담고 싶을 때 이 피어를 사용해보세요.",
      "files": [
        "/data/filters/filter_original_1770998360980.jpg",
        "/data/filters/filter_filtered_1770998361013.jpg"
      ],
      "creator": {
        "user_id": "698f49392d826cebc45be72f",
        "nick": "크레용",
        "name": "김민준",
        "introduction": "안녕하세요! 크레용입니다!",
        "profileImage": "/data/profiles/1770998531417.jpg",
        "hashTags": ["밝음", "긍정적"]
      },
      "like_count": 0,
      "buyer_count": 0,
      "createdAt": "2025-12-10T02:23:20.911Z",
      "updatedAt": "2026-02-08T14:55:45.508Z"
    }
    """.utf8
  )

  static let mainBannersData = Data(
    """
    {
      "data": [
        {
          "name": "banner4",
          "imageUrl": "/data/banners/Filter_4.png",
          "payload": {
            "type": "WEBVIEW",
            "value": "/event-application"
          }
        },
        {
          "name": "banner3",
          "imageUrl": "/data/banners/Filter_3.png",
          "payload": {
            "type": "WEBVIEW",
            "value": "/event-application"
          }
        },
        {
          "name": "banner2",
          "imageUrl": "/data/banners/Filter_2.png",
          "payload": {
            "type": "WEBVIEW",
            "value": "/event-application"
          }
        },
        {
          "name": "banner1",
          "imageUrl": "/data/banners/Filter_1.png",
          "payload": {
            "type": "WEBVIEW",
            "value": "/event-application"
          }
        }
      ]
    }
    """.utf8
  )

  static let hotTrendData = Data(
    """
    {
      "data": [
        {
          "filter_id": "698f4a592d826cebc45be870",
          "category": "풍경",
          "title": "Skyline Boost",
          "description": "고층 건물과 도시 라인을 선명하게 만듭니다",
          "files": [
            "/data/filters/previews_original_1770998360980.jpg",
            "/data/filters/previews_filtered_1770998361013.jpg"
          ],
          "creator": {
            "user_id": "698f49392d826cebc45be72f",
            "nick": "크레용",
            "name": "김민준",
            "introduction": "안녕하세요! 크레용입니다!",
            "profileImage": "/data/profiles/1770998531417.jpg",
            "hashTags": ["밝음", "긍정적"]
          },
          "is_liked": false,
          "like_count": 0,
          "buyer_count": 0,
          "createdAt": "2026-02-13T15:59:21.071Z",
          "updatedAt": "2026-02-13T15:59:21.071Z"
        },
        {
          "filter_id": "695761def1736c2b36c4e398",
          "category": "푸드",
          "title": "여름 안에서",
          "description": "무더운 여름, 카페에 앉아 시원한 음료 한 잔",
          "files": [
            "/data/filters/filter_original_1767334366912.jpg",
            "/data/filters/filter_filtered_1767334366946.jpg"
          ],
          "creator": {
            "user_id": "693f98ccc06140e4f9c4f28f",
            "nick": "andev",
            "name": "안대현",
            "introduction": "필터 만드는 개발자 andev 입니다.",
            "profileImage": "/data/profiles/1767519161456.jpg",
            "hashTags": ["포근함", "따뜻함"]
          },
          "is_liked": false,
          "like_count": 0,
          "buyer_count": 0,
          "createdAt": "2026-01-02T06:12:46.995Z",
          "updatedAt": "2026-01-28T08:40:30.065Z"
        }
      ]
    }
    """.utf8
  )

  static let todayAuthorData = Data(
    """
    {
      "author": {
        "user_id": "author-1",
        "nick": "SESAC YOON",
        "name": "윤새싹",
        "profileImage": "/data/profiles/1765346492791.jpg",
        "hashTags": ["#섬세함", "#자연", "#미니멀"],
        "introduction": "자연의 섬세함을 담아내는 감성 사진작가",
        "description": "윤새싹은 자연의 섬세한 아름다움을 포착하는 데 탁월한 감각을 지닌 사진작가입니다."
      },
      "filters": []
    }
    """.utf8
  )
}
