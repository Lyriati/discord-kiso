defmodule DiscordKiso.Commands.Image do
  import Din.Module
  import DiscordKiso.Util

  def avatar(data) do
    user = data.mentions |> List.first
    url = "https://cdn.discordapp.com/avatars/#{user.id}/#{user.avatar}?size=1024"

    reply "", embed: %{
      color: 0x00b6b6,
      image: %{url: url}
    }
  end

  def smug(data) do
    url = "https://api.imgur.com/3/album/zSNC1"
    auth = %{"Authorization" => "Client-ID #{Application.get_env(:discord_kiso, :imgur_client_id)}"}

    request = HTTPoison.get!(url, auth)
    response = Poison.Parser.parse!((request.body), keys: :atoms)
    result = response.data.images |> Enum.random

    reply "", embed: %{
      color: 0x00b6b6,
      image: %{url: result.link}
    }
  end

  def danbooru(data) do
    {tag1, tag2} = case length(data.content |> String.split) do
      1 -> {"order:rank", ""}
      2 ->
        [_ | [tag1 | _]] = data.content |> String.split
        {tag1, ""}
      _ ->
        [_ | [tag1 | [tag2 | _]]] = data.content |> String.split
        {tag1, tag2}
    end

    reply_danbooru(data, tag1, tag2)
  end

  def safebooru(data) do
    {tag1, tag2} = case length(data.content |> String.split) do
      1 -> {"order:rank", "rating:s"}
      _ ->
        [_ | [tag1 | _]] = data.content |> String.split
        {tag1, "rating:s"}
    end

    reply_danbooru(data, tag1, tag2)
  end

  def ecchibooru(data) do
    {tag1, tag2} = case length(data.content |> String.split) do
      1 -> {"order:rank", "rating:q"}
      _ ->
        [_ | [tag1 | _]] = data.content |> String.split
        {tag1, "rating:q"}
    end

    reply_danbooru(data, tag1, tag2)
  end

  def lewdbooru(data) do
    {tag1, tag2} = case length(data.content |> String.split) do
      1 -> {"order:rank", "rating:e"}
      _ ->
        [_ | [tag1 | _]] = data.content |> String.split
        {tag1, "rating:e"}
    end

    reply_danbooru(data, tag1, tag2)
  end

  defp reply_danbooru(data, tag1, tag2) do
    case tag1 do
      "help" -> reply "Danbooru is a anime imageboard. You can search up to two tags with this command or you can leave it blank for something random. For details on tags, see <https://danbooru.donmai.us/wiki_pages/43037>.\n\n**Available Danbooru commands**\n`!dan :tag1 :tag2` - default command\n`!safe :tag1` - applies `rating:safe` tag\n`!ecchi :tag1` - applies `rating:questionable` tag\n`!lewd :tag1` - applies `rating:explicit` tag\n\n`!safe` will work anywhere, but the other commands can only be done in NSFW channels."
    _ ->
      case danbooru(tag1, tag2) do
        {post_id, image, result} ->
          character = result.tag_string_character |> String.split
          copyright = result.tag_string_copyright |> String.split

          artist = result.tag_string_artist |> String.split("_") |> Enum.join(" ")
          {char, copy} =
            case {length(character), length(copyright)} do
              {2, _} ->
                first_char =
                  List.first(character)
                  |> String.split("(")
                  |> List.first
                  |> titlecase("_")

                second_char =
                  List.last(character)
                  |> String.split("(")
                  |> List.first
                  |> titlecase("_")

                {"#{first_char} and #{second_char}",
                 List.first(copyright) |> titlecase("_")}
              {1, _} ->
                {List.first(character)
                 |> String.split("(")
                 |> List.first
                 |> titlecase("_"),
                 List.first(copyright) |> titlecase("_")}
              {_, 1} -> {"Multiple", List.first(copyright) |> titlecase("_")}
              {_, _} -> {"Multiple", "Various"}
            end

          extension = image |> String.split(".") |> List.last

          cond do
            Enum.member?(["jpg", "png", "gif"], extension) ->
              reply "", embed: %{
                color: 0x00b6b6,
                title: "danbooru.donmai.us",
                url: "https://danbooru.donmai.us/posts/#{post_id}",
                description: "#{char} - #{copy}\nDrawn by #{artist}",
                image: %{url: image}
              }
            true ->
              thumbnail = "http://danbooru.donmai.us#{result.preview_file_url}"
              reply "", embed: %{
                color: 0x00b6b6,
                title: "danbooru.donmai.us",
                url: "https://danbooru.donmai.us/posts/#{post_id}",
                description: "#{char} - #{copy}\nDrawn by #{artist}",
                image: %{url: thumbnail}
              }
          end
        message -> reply message
      end
    end
  end

  defp danbooru(tag1, tag2) do
    require Logger

    dan = "danbooru.donmai.us"
    blacklist = ["what", "scat", "guro", "gore", "loli", "shota"]

    safe1 = Enum.member?(blacklist, tag1)
    safe2 = Enum.member?(blacklist, tag2)

    {tag1, tag2} = case {safe1, safe2} do
      {_, true}       -> {"shangguan_feiying", "meme"}
      {true, _}       -> {"shangguan_feiying", "meme"}
      {false, false}  -> {tag1, tag2}
    end

    tag1 = tag1 |> String.split |> Enum.join("_") |> URI.encode_www_form
    tag2 = tag2 |> String.split |> Enum.join("_") |> URI.encode_www_form

    request = "https://#{dan}/posts.json?limit=50&page=1&tags=#{tag1}+#{tag2}" |> HTTPoison.get!

    #try do
      results = Poison.Parser.parse!((request.body), keys: :atoms)
      result = results |> Enum.shuffle |> Enum.find(fn post -> is_image?(post.file_url) == true && is_dupe?("dan", post.file_url) == false end)

      post_id = Integer.to_string(result.id)
      image = if URI.parse(result.file_url).host do
        result.file_url
      else
        "http://#{dan}#{result.file_url}"
      end

      {post_id, image, result}
    #rescue
    #  Enum.EmptyError -> "Nothing found!"
    #  UndefinedFunctionError -> "Nothing found!"
    #  error ->
    #    "fsdafsd"
    #end
  end

  def nhentai(data) do
    [_ | tags] = data.content |> String.split

    case tags do
      [] -> reply "You must search with at least one tag."
      tags ->
        tags = for tag <- tags do
          tag |> URI.encode_www_form
        end |> Enum.join("+")

        request = "https://nhentai.net/api/galleries/search?query=#{tags}&sort=popular" |> HTTPoison.get!
        response = Poison.Parser.parse!((request.body), keys: :atoms)

        try do
          result = response.result |> Enum.shuffle |> Enum.find(fn doujin -> is_dupe?("nhentai", doujin.id) == false end)

          filetype = case List.first(result.images.pages).t do
            "j" -> "jpg"
            "g" -> "gif"
            "p" -> "png"
          end

          artists_tag = result.tags |> Enum.filter(fn(t) -> t.type == "artist" end)
          artists = for tag <- artists_tag, do: tag.name

          artist = case artists do
            [] -> ""
            artists -> "by #{artists |> Enum.sort |> Enum.join(", ")}\n"
          end

          cover = "https://i.nhentai.net/galleries/#{result.media_id}/1.#{filetype}"

          reply "", embed: %{
            color: 0x00b6b6,
            title: result.title.pretty,
            url: "https://nhentai.net/g/#{result.id}",
            description: "#{artist}",
            image: %{url: cover}
          }
      rescue
        KeyError -> reply "Nothing found!"
      end
    end
  end
end
