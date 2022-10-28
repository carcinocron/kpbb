enum Kpbb::ChannelAction : Int16
  Create    = 17
  Publish   = 18
  Unpublish = 19
  Approve   = 20
  Remove    = 21
  Lock      = 20
  Unlock    = 21
  Dead      = 22
  Undead    = 23

  UpdateTitle    = 100
  UpdateUrl      = 101
  UpdateBodyMd   = 102
  UpdateTags     = 103
  UpdateMask     = 104
  UpdatePostType = 105

  CreateWebhookInboundEndpoint            = 600
  UpdateWebhookInboundEndpointBio         = 601
  UpdateWebhookInboundEndpointActive      = 602
  UpdateWebhookInboundPayloadResetResult  = 603
  UpdateWebhookInboundEndpointUrl         = 604
  UpdateWebhookInboundEndpointMask        = 605
  UpdateWebhookInboundEndpointDefaultBody = 606

  CreateFeedInboundEndpoint            = 700
  UpdateFeedInboundEndpointBio         = 701
  UpdateFeedInboundEndpointActive      = 702
  UpdateFeedInboundPayloadResetResult  = 703
  UpdateFeedInboundEndpointUrl         = 704
  UpdateFeedInboundEndpointMask        = 705
  UpdateFeedInboundEndpointDefaultBody = 706
end
