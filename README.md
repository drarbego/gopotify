# Gopotify - A spotify client for Godot Engine

## Connect to Spotify

- Go to your [Spotify Dashboard](https://developer.spotify.com/dashboard/applications)
- Click on create an app, now you'll be able to see your `Client Id` and `Client Secret`
- Click on `EDIT SETTINGS`
- Add `http://localhost:{port}/callback` to the `Redirect URIs` field, the default port is `8889`
- Click on `SAVE`


## Use the client

After [installing the plugin]() you'll find a new node called `Gopotify`
- Add a `Gopotify` node to your scene
- Select the `Gopotify` node and in the inspector paste the `Client Id` and `Client Secret` in their respective inputs under `Script Variables`

## Implemented Functionality

| Function           | Description                                             |
|--------------------|---------------------------------------------------------|
| play()             | Resumes music reproduction in the current active device |
| pause()            | Pauses music reproduction in the current active device  |
| next()             | Skips to next song                                      |
| previous()         | Returns to previous song                                |
| get_player_state() | Returns an object with the player state as a raw json   |
