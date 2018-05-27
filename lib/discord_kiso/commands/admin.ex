defmodule DiscordKiso.Commands.Admin do
  import Din.Module
  import DiscordKiso.Util
  alias Din.Resources.Channel

  def setup(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    cond do
      db == nil ->
        store_data("guilds", guild_id, %{admin_roles: [], log: nil, mention_roles: [], mention_users: [], mention: nil, stream_role: nil})
        reply "Hey. Be sure to add an admin role to manage my settings using `!adminrole add <role>`."
      db.admin_roles == [] -> reply "No admin roles set, anyone can edit my settings! Change this with `!adminrole add <role>`."
      true -> reply "I'm already set up! Use `!adminrole add/del <role>` to update administrative settings."
    end
  end

  def remove_from_guild(data) do
    guild_id = data.id
    
    db = query_data("guilds", guild_id)
    db = Map.put(db, :admin_roles, [])
    
    nil
    # store_data("guilds", guild_id, db)
  end

  def add_role(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)
    role_ids = data.mention_roles

    case role_ids do
      [] -> reply "You didn't specify any roles."
      role_ids ->
        case db.admin_roles do
          [] ->
            db = Map.put(db, :admin_roles, role_ids)
            store_data("guilds", guild_id, db)
            reply "Added roles!"
          admin_roles ->
            db = Map.put(db, :admin_roles, admin_roles ++ role_ids |> Enum.uniq)
            store_data("guilds", guild_id, db)
            reply "Added administrative roles!"
        end
    end
  end

  def del_role(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    role_ids = data.mention_roles
    db = query_data("guilds", guild_id)

    case role_ids do
      [] -> reply "You didn't specify any roles."
      role_ids ->
        case db.admin_roles do
          [] -> reply "There aren't any roles to remove..."
          admin_roles ->
            db = Map.put(db, :admin_roles, admin_roles -- role_ids |> Enum.uniq)
            store_data("guilds", guild_id, db)
            reply "Removed administrative roles."
        end
    end
  end
end
