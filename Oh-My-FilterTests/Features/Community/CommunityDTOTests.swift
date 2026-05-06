import Foundation
import Testing
@testable import Oh_My_Filter

struct CommunityDTOTests {
  @Test("post summary page decodes and maps to domain")
  func decodePostSummaryPage() throws {
    let dto = try decoder.decode(CommunityPostPageDTO.self, from: Self.postPageData)
    let page = dto.toDomain()

    #expect(dto.nextCursor == "cursor-2")
    #expect(page.posts.count == 1)
    #expect(page.posts[0].id == "post-1")
    #expect(page.posts[0].creator.nick == "sesac")
    #expect(page.posts[0].likeCount == 100)
    #expect(page.posts[0].imageURLs.first?.absoluteString.contains("/v1/data/posts/image_1.png") == true)
  }

  @Test("post search response decodes")
  func decodePostSearchResponse() throws {
    let dto = try decoder.decode(CommunityPostListDTO.self, from: Self.postSearchData)
    let posts = dto.toDomain()

    #expect(posts.map(\.id) == ["post-1"])
  }

  @Test("post detail comments decode shared comment schema")
  func decodePostDetailComments() throws {
    let dto = try decoder.decode(CommunityPostDTO.self, from: Self.postDetailWithCommentsData)
    let post = dto.toDomain()

    #expect(post.comments.first?.id == "comment-1")
    #expect(post.comments.first?.creator.nick == "sesac")
    #expect(post.comments.first?.replies.first?.id == "reply-1")
    #expect(post.comments.first?.replies.first?.creator.nick == "crayon")
  }

  @Test("video page decodes")
  func decodeVideoPage() throws {
    let dto = try decoder.decode(CommunityVideoPageDTO.self, from: Self.videoPageData)
    let page = dto.toDomain()

    #expect(page.nextCursor == "video-cursor")
    #expect(page.videos[0].id == "video-1")
    #expect(page.videos[0].thumbnailURL?.absoluteString.contains("/v1/data/videos/video-name.jpg") == true)
    #expect(page.videos[0].availableQualities == ["1080p", "720p"])
  }

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
}

private extension CommunityDTOTests {
  static let postPageData = Data(
    """
    {
      "data": [
        {
          "post_id": "post-1",
          "category": "핫스팟",
          "title": "사진 찍기 좋은 곳",
          "content": "창가 자리 추천",
          "creator": {
            "user_id": "user-1",
            "nick": "sesac",
            "name": "김새싹",
            "profileImage": "/data/profiles/1.png",
            "hashTags": ["#맑음"]
          },
          "files": ["/data/posts/image_1.png"],
          "is_like": false,
          "like_count": 100,
          "createdAt": "2024-07-21T14:00:00.000Z",
          "updatedAt": "2024-07-21T15:30:00.000Z"
        }
      ],
      "next_cursor": "cursor-2"
    }
    """.utf8
  )

  static let postSearchData = Data(
    """
    {
      "data": [
        {
          "post_id": "post-1",
          "category": "핫스팟",
          "title": "사진 찍기 좋은 곳",
          "content": "창가 자리 추천",
          "creator": {
            "user_id": "user-1",
            "nick": "sesac",
            "hashTags": []
          },
          "files": [],
          "is_like": false,
          "like_count": 0,
          "createdAt": "2024-07-21T14:00:00.000Z",
          "updatedAt": "2024-07-21T15:30:00.000Z"
        }
      ]
    }
    """.utf8
  )

  static let videoPageData = Data(
    """
    {
      "data": [
        {
          "video_id": "video-1",
          "file_name": "video-name",
          "title": "안녕하세요 :)",
          "description": "같이 공부해요",
          "duration": 120.5,
          "thumbnail_url": "/data/videos/video-name.jpg",
          "available_qualities": ["1080p", "720p"],
          "view_count": 1234,
          "like_count": 42,
          "is_liked": true,
          "createdAt": "2024-01-15T10:30:00.000Z"
        }
      ],
      "next_cursor": "video-cursor"
    }
    """.utf8
  )

  static let postDetailWithCommentsData = Data(
    """
    {
      "post_id": "post-1",
      "category": "핫스팟",
      "title": "사진 찍기 좋은 곳",
      "content": "창가 자리 추천",
      "creator": {
        "user_id": "user-1",
        "nick": "sesac",
        "hashTags": []
      },
      "files": [],
      "is_like": false,
      "like_count": 0,
      "comments": [
        {
          "comment_id": "comment-1",
          "content": "와 너무 멋있어요!",
          "createdAt": "2026-02-08T14:55:45.508Z",
          "creator": {
            "user_id": "user-1",
            "nick": "sesac",
            "hashTags": []
          },
          "replies": [
            {
              "comment_id": "reply-1",
              "content": "저도 가봐야겠어요",
              "createdAt": "2026-02-08T15:55:45.508Z",
              "creator": {
                "user_id": "user-2",
                "nick": "crayon",
                "hashTags": []
              }
            }
          ]
        }
      ],
      "createdAt": "2026-02-08T14:55:45.508Z",
      "updatedAt": "2026-02-08T14:55:45.508Z"
    }
    """.utf8
  )
}
