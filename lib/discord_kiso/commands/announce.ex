defmodule DiscordKiso.Commands.Announce do
  import Din.Module
  import DiscordKiso.Util
  alias Din.Resources.{Channel, Guild}

  def announce(data) do
    guild_id = data.guild_id
    user_id = data.user.id
    member = Guild.get_member(guild_id, user_id)
    username = member.user.username
    db = query_data("guilds", guild_id)

    announce? = case db do
      nil -> true
      db ->
        case db.stream_role do
          nil -> true
          stream_role -> Enum.member?(for role <- member.roles do
            stream_role == role
          end, true)
        end
    end

    if data.game do
      if data.game.type do
        case data.game.type do
          0 -> remove_streamer(guild_id, user_id)
          1 ->
            if announce? do
              {rate, _} = ExRated.check_rate({guild_id, user_id}, 3_600_000, 1)

              case rate do
                :ok ->
                  stream_title = data.game.name
                  stream_url = data.game.url

                  twitch_username = data.game.url
                  |> String.split("/")
                  |> List.last

                  log_chan = db.log

                  stream_list = query_data("streams", guild_id)

                  stream_list = case stream_list do
                    nil -> []
                    streams -> streams
                  end

                  unless Enum.member?(stream_list, user_id) do
                    store_data("streams", guild_id, stream_list ++ [user_id])
                    alert_roles = db.mention_roles
                    alert_users = db.mention_users
                    role_mention = db.mention

                    is_alert? = cond do
                      Enum.member?(alert_users, user_id) -> true
                      true -> Enum.member?(for role <- member.roles do
                        Enum.member?(alert_roles, role)
                      end, true)
                    end

                    mention = case role_mention do
                      nil -> "@here"
                      role -> "<@&#{role}>"
                    end

                    here = cond do
                      is_alert? -> " #{mention}"
                      true -> ""
                    end

                    message = "**#{username}** is now live on Twitch!#{here}"

                    twitch_user = "https://api.twitch.tv/kraken/users?login=#{twitch_username}"
                    headers = %{"Accept" => "application/vnd.twitchtv.v5+json", "Client-ID" => "#{Application.get_env(:discord_kiso, :twitch_client_id)}"}

                    request = HTTPoison.get!(twitch_user, headers)
                    response = Poison.Parser.parse!((request.body), keys: :atoms)
                    user = response.users |> List.first

                    user_channel = "https://api.twitch.tv/kraken/channels/#{user._id}"
                    user_info_request = HTTPoison.get!(user_channel, headers)
                    user_info_response = Poison.Parser.parse!((user_info_request.body), keys: :atoms)

                    game = case user_info_response.game do
                      nil -> "streaming on Twitch.tv"
                      game -> "playing #{game}"
                    end

                    Channel.create_message log_chan, message, embed: %{
                      color: 0x4b367c,
                      title: "#{twitch_username} #{game}",
                      url: "#{stream_url}",
                      description: "#{stream_title}",
                      thumbnail: %{url: "#{user.logo}"},
                      timestamp: "#{DateTime.utc_now() |> DateTime.to_iso8601()}"
                    }
                  end
                :error -> nil
              end
            end
          _ -> nil
        end
      end
    end

    unless data.game, do: remove_streamer(guild_id, user_id)
  end

  defp remove_streamer(guild_id, user_id) do
    stream_list = query_data("streams", guild_id)

    stream_list = case stream_list do
      nil -> []
      streams -> streams
    end

    if Enum.member?(stream_list, user_id) do
      store_data("streams", guild_id, stream_list -- [user_id])
    end
  end

  def set_log_channel(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    db = Map.put(db, :log, data.channel_id)
    store_data("guilds", guild_id, db)
    reply "Okay, I will announce streams here!"
  end

  def del_log_channel(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    db = Map.put(db, :log, nil)
    store_data("guilds", guild_id, db)
    reply "Okay, I will no longer announce streams."
  end

  def set_mention_role(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)
    role = data.mention_roles |> List.first

    db = Map.put(db, :mention, role)
    store_data("guilds", guild_id, db)
    reply "Okay, I will alert members of that role when your selected users or roles go live."
  end

  def del_mention_role(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    db = Map.put(db, :mention, nil)
    store_data("guilds", guild_id, db)
    reply "Okay, I will `@here` when your selected users or roles go live."
  end

  def set_stream_announce(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)
    role = data.mention_roles |> List.first

    db = Map.put(db, :stream_role, role)
    store_data("guilds", guild_id, db)
    reply "Okay, I will only announce streams for members of that role."
  end

  def del_stream_announce(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    db = Map.put(db, :stream_role, nil)
    store_data("guilds", guild_id, db)
    reply "Okay, everyone on this server will be announced when they go live."
  end

  def alert_add_individual_users_or_roles(data) do
    commands = data.content |> String.split
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    case commands do
      [_ | ["role" | _roles]] ->
        case data.mention_roles do
          [] -> reply "You need to specify at least one role."
          roles ->
            db = Map.put(db, :mention_roles, db.mention_roles ++ roles |> Enum.uniq)
            store_data("guilds", guild_id, db)
            reply "Role(s) added. I will alert when they go live."
        end
      [_ | ["user" | _users]] ->
        case data.mentions do
          [] -> reply "You need to specify at least one user."
          users ->
            user_ids = for user <- users, do: user.id
            db = Map.put(db, :mention_users, db.mention_users ++ user_ids |> Enum.uniq)
            store_data("guilds", guild_id, db)
            reply "User(s) added. I will alert when they go live."
        end
      _ -> reply "Usage: `!alertfor user add {users}` or `!alertfor role add {roles}`"
    end
  end

  def alert_remove_individual_users_or_roles(data) do
    commands = data.content |> String.split
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    case commands do
      [_ | ["role" | _roles]] ->
        case data.mention_roles do
          [] -> reply "You need to specify at least one role to remove."
          roles ->
            db = Map.put(db, :mention_roles, db.mention_roles -- roles |> Enum.uniq)
            store_data("guilds", guild_id, db)
            reply "Role(s) removed, they will no longer alert online members."
        end
      [_ | ["user" | _users]] ->
        case data.mentions do
          [] -> reply "You need to specify at least one user to remove."
          users ->
            user_ids = for user <- users, do: user.id
            db = Map.put(db, :mention_users, db.mention_users -- user_ids |> Enum.uniq)
            store_data("guilds", guild_id, db)
            reply "User(s) removed, they will no longer alert online members."
        end
      _ -> reply "Usage: `!alertfor user del {users}` or `!alertfor role del {roles}`"
    end
  end
end
