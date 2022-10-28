require "./expectations/match_ml"
require "./expectations/match_snapshot"
require "./expectations/match_json_snapshot"
require "./expectations/match_json_as_yaml_snapshot"
require "./expectations/be_html_res"
require "./expectations/be_html_fragment_res"
require "./expectations/be_json_any_body"
require "./expectations/be_json_res"
require "./expectations/be_json_just_id_res"
require "./expectations/be_json_500_res"
require "./expectations/be_png_res"
require "./expectations/be_redirect_login_res"
require "./expectations/be_redirect_res"

module Spec
  module Expectations
    def match_ml(value)
      Iom::Spec::MultilineEqualExpectation.new value
    end

    def match_snapshot(value)
      Iom::Spec::SnapshotExpectation.new value
    end

    def match_json_snapshot(value)
      Iom::Spec::JsonSnapshotExpectation.new value
    end

    def match_json_as_yaml_snapshot(value)
      Iom::Spec::JsonAsYamlSnapshotExpectation.new value
    end

    def be_json_res(expected_status_code = 200)
      Iom::Spec::BeJsonResponseAnyBodyExpectation.new expected_status_code
    end

    def be_json_200
      Iom::Spec::BeJsonResponseAnyBodyExpectation.new(expected_status_code: 200)
    end

    def be_json_res(expected_status_code, body)
      Iom::Spec::BeJsonResponseExpectation.new expected_status_code, body
    end

    def be_json_200_ok
      Iom::Spec::BeJsonResponseExpectation.new 200, JSON_MESSAGE_OK
    end

    def be_json_200_just_id
      Iom::Spec::BeJsonJustIdResponseExpectation.new
    end

    def be_json_401
      Iom::Spec::BeJsonResponseExpectation.new 401, JSON_MESSAGE_UNAUTHORIZED
    end

    def be_json_403
      Iom::Spec::BeJsonResponseExpectation.new 403, JSON_MESSAGE_FORBIDDEN
    end

    def be_json_404
      Iom::Spec::BeJsonResponseExpectation.new 404, JSON_MESSAGE_NOT_FOUND
    end

    def be_json_405
      Iom::Spec::BeJsonResponseExpectation.new 405, JSON_MESSAGE_METHOD_NOT_ALLOWED
    end

    def be_json_501
      Iom::Spec::BeJsonResponseExpectation.new 501, JSON_MESSAGE_NOT_IMPLEMENTED
    end

    def be_json_422(errors)
      Iom::Spec::BeJsonResponseExpectation.new 422, ({
        :message => "Failed Validation",
        :errors  => errors,
      }).to_json
    end

    def be_json_500
      Iom::Spec::BeJsonJustInternalServerErrorResponseExpectation.new
    end

    def be_html
      Iom::Spec::BeHtmlResponseExpectation.new
    end

    def be_png
      Iom::Spec::BePngResponseExpectation.new
    end

    def be_html_fragment
      Iom::Spec::BeHtmlFragmentResponseExpectation.new
    end

    def be_redirect_login
      Iom::Spec::BeHtmlRedirectLoginResponseExpectation.new
    end

    def be_redirect(expected_url : String)
      Iom::Spec::BeHtmlRedirectResponseExpectation.new(expected_url)
    end
  end
end
