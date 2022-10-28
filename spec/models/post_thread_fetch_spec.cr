require "../spec_helper"

describe "Models::Kpbb::Post::Thread::Fetch" do
  it "fetches related" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel1 = Kpbb::Channel.factory(creator_id: user1.id)
    p0 = Kpbb::Post.factory(posted: true, creator_id: user2.id, channel_id: channel1.id, draft: false)

    p1 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: p0.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id],
    })
    thread.context.id.should eq p0.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    p2 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: p1.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id],
      p1.id => [p2.id],
    })
    thread.context.id.should eq p0.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    p3 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: nil)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id],
      p1.id => [p2.id],
    })
    thread.context.id.should eq p0.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    p4 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: p0.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id, p4.id],
      p1.id => [p2.id],
    })
    thread.context.id.should eq p0.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    p5 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: p4.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id, p4.id],
      p1.id => [p2.id],
      p4.id => [p5.id],
    })
    thread.context.id.should eq p0.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    p6 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: p0.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id, p4.id, p6.id],
      p1.id => [p2.id],
      p4.id => [p5.id],
    })
    thread.context.id.should eq p0.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    p7 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: p5.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id, p4.id, p6.id],
      p1.id => [p2.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
    })
    thread.context.id.should eq p0.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    p8 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: p7.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id, p4.id, p6.id],
      p1.id => [p2.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
      p7.id => [p8.id],
    })
    thread.context.id.should eq p0.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    thread = Kpbb::Post::Thread.fetch(post_id: p1.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id],
      p1.id => [p2.id],
    })
    thread.context.id.should eq p1.id
    thread.parents.map(&.id).should eq ([p0.id])

    thread = Kpbb::Post::Thread.fetch(post_id: p2.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id],
      p1.id => [p2.id],
    })
    thread.context.id.should eq p2.id
    # oldest first, because that's the order we render it
    thread.parents.map(&.id).should eq ([p0.id, p1.id])

    thread = Kpbb::Post::Thread.fetch(post_id: p3.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p3.id],
    })
    thread.context.id.should eq p3.id
    thread.parents.map(&.id).should eq ([] of Array(Int64))

    thread = Kpbb::Post::Thread.fetch(post_id: p4.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p4.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
      p7.id => [p8.id],
    })
    thread.context.id.should eq p4.id
    thread.parents.map(&.id).should eq ([p0.id])

    thread = Kpbb::Post::Thread.fetch(post_id: p5.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p4.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
      p7.id => [p8.id],
    })
    thread.context.id.should eq p5.id
    thread.parents.map(&.id).should eq ([p0.id, p4.id])

    thread = Kpbb::Post::Thread.fetch(post_id: p6.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p6.id],
    })
    thread.context.id.should eq p6.id
    thread.parents.map(&.id).should eq ([p0.id])

    thread = Kpbb::Post::Thread.fetch(post_id: p7.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p4.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
      p7.id => [p8.id],
    })
    thread.context.id.should eq p7.id
    thread.parents.map(&.id).should eq ([p0.id, p4.id, p5.id])

    thread = Kpbb::Post::Thread.fetch(post_id: p8.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p4.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
      p7.id => [p8.id],
    })
    thread.context.id.should eq p8.id
    thread.parents.map(&.id).should eq ([p0.id, p4.id, p5.id, p7.id])

    # this guy is a genius who decided his reply is also posted
    p9 = Kpbb::Post.factory(posted: true, creator_id: user1.id, channel_id: channel1.id, parent_id: p8.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id, p4.id, p6.id],
      p1.id => [p2.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
      p7.id => [p8.id],
      p8.id => [p9.id],
    })

    # this guy is a reply to a posted thread
    # we expect it to be cut off
    p10 = Kpbb::Post.factory(posted: false, creator_id: user1.id, channel_id: channel1.id, parent_id: p9.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p1.id, p4.id, p6.id],
      p1.id => [p2.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
      p7.id => [p8.id],
      p8.id => [p9.id],
    })

    thread = Kpbb::Post::Thread.fetch(post_id: p9.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      0_i16 => [p0.id],
      p0.id => [p4.id],
      p4.id => [p5.id],
      p5.id => [p7.id],
      p7.id => [p8.id],
      p8.id => [p9.id],
      p9.id => [p10.id],
    })

    # we also expect excessive parents to get cut
    thread = Kpbb::Post::Thread.fetch(post_id: p10.id)
    # pp ({:thread => thread.to_ids_only_hash_array})
    thread.to_ids_only_hash_array.should eq (Hash(Int64, Array(Int64)){
      # 0_i16 => [p0.id],
      # p0.id => [p4.id],
      # p4.id => [p5.id],
      # p5.id => [p7.id],
      # p7.id => [p8.id],
      p8.id => [p9.id],
      p9.id => [p10.id],
    })
  end
end
