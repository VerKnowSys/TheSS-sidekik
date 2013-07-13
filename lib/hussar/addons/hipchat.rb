addon "HipChat" do
  option :room
  option :token

  generate do
    hooks do
      after :build_finish do
        set "hipchat_msg", %Q{"#{service_prefix.gsub(/-$/, "")} successfully deployed from branch #{opts.git_branch} on $HOST"}
        # set "hipchat_msg", %Q{$(echo -n "${hipchat_msg}" | perl -p -e 's/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg'}

        sh %Q{
          curl "http://api.hipchat.com/v1/rooms/message" -d \\
            "color=green&notify=1&from=Hussar&room_id=#{opts.room}&auth_token=#{opts.token}&message=$hipchat_msg"
        }, :novalidate
      end
    end
  end
end
