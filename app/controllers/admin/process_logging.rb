module Admin
  module ProcessLogging
    PROCESS_CONFIG = {
      "PROFAB" => { slug: "profab", title: "Fabrication Log" },
      "PROCUT" => { slug: "procut", title: "Cutting Log" },
      "PROFL" => { slug: "profl", title: "Folding Log" },
      "PROPRIME" => { slug: "proprime", title: "Priming Log" },
      "PROPB" => { slug: "propb", title: "Paint Booth Log" },
      "PRORO" => { slug: "proro", title: "Rolling Log" },
      "PROGUIL" => { slug: "proguil", title: "Guillotine Log" }
    }.freeze

    private

    def set_process_logging_config
      @process_code = params[:process_code].to_s
      @process_config = PROCESS_CONFIG.fetch(@process_code)
      @process_slug = @process_config.fetch(:slug)
      @process_title = @process_config.fetch(:title)
    end

    def process_log_index_path(date: nil)
      path_params = {}
      path_params[:date] = date if date.present?
      helpers.public_send("admin_#{@process_slug}_path", path_params)
    end

    def process_log_collection_path
      helpers.public_send("admin_#{@process_slug}_logs_path")
    end

    def process_log_member_path(log)
      helpers.public_send("admin_#{@process_slug}_log_path", log)
    end
  end
end
