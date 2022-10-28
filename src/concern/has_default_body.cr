module Kpbb::Concern::HasDefaultBody
  def default_body_s : String?
    @default_body
  end

  def default_body : Kpbb::BodyHash
    if json = @default_body
      if v = Kpbb::BodyHash.from_json(json)
        {% if @type.instance_vars.map(&.name.stringify).includes?("mask") %}
          unless v.has_key? "mask" && @mask
            v["mask"] = @mask.to_s
          end
        {% end %}
        return v
      end
    end
    Kpbb::BodyHash.new
  end
end
