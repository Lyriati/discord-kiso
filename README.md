# DiscordKiso

[Add this bot to your server!](https://discordapp.com/oauth2/authorize?&client_id=338421678579122186&scope=bot&permissions=0)

## Setup

Type `!setup` to add your server to my database. From there you should set tell me what roles can edit my settings by using `!adminrole add`.

## Stream Alerts

I will always announce everyone in the server when they go live. Just set which channel to announce to by going to that channel and typing `!announce here`.

## Commands

### Administrative

These commands will check to see if the user's role is part of the administrative ones you provided. If none were provided, ANYONE can use these, so be careful!

That being said, if you ever lose control of me, removing me from your server and re-adding me will reinitialize the administrative list.

`!ping`, `!kiso` - Generic ping, outputs debug info to the console  
`!setup` - Initializes your server to the database  
`!adminrole add :roles` - Adds mentioned roles to allow modification to settings  
`!adminrole del :roles` - Removes mentioned roles to allow modification to settings  
`!announce here` - Sets the log channel for stream announcements  
`!announce stop` - Completely stops stream announcements for the server  
  
`!alertfor user add :users` - Bot will @here everytime these users go live  
`!alertfor user del :users` - Bot will not @here everytime these users go live  
`!alertfor role add :roles` - Bot will @here everytime users of this role go live  
`!alertfor role del :roles` - Bot will not @here everytime users of this role go  live  
`!at role :role` - Bot will mention this role instead of @here for alerted streams  
`!at here` - Bot will mention @here for alerted streams  
`!announce role :role` - Bot will only announce streams for members of this role  
`!announce everyone` - Bot will announce streams for everyone on the server  

`!command add :command ~text` - Adds a custom command with the given text  
`!command del :command` - Removes a custom command  

### General Commands

`!avatar :user` - Shows a big version of the avatar of a user  
`!coin`, `!flip` - Flips a coin  
`!pick :options`, `!choose :options` - Chooses from a comma separated list  
`!roll :number` - Rolls dice by number or by `xdy` format  
`!predict :question` - 8ball prediction  
`!smug` - Posts a random smug anime girl  
`!guidance` - Random Dark Souls guidance message  
`!safe :tag` - Posts a random sfw anime image, with or without a tag (Uses Danbooru. See: `!safe help`)

### NSFW Commands

`!dan :tag1 :tag2` - Default command  
`!ecchi :tag1` - Applies `rating:questionable` tag  
`!lewd :tag1` - Applies `rating:explicit` tag  

Danbooru is a anime imageboard. You can search up to two tags with this command or you can leave it blank for something random. For details on tags, see [here](https://danbooru.donmai.us/wiki_pages/43037).

`!doujin :search` - Posts a doujin from a search term from nhentai
