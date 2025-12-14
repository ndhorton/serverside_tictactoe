# Server-side Web-based Tic Tac Toe #

## Client-server architecture ##
The design for this TTT game will be server-side in the sense that
the game logic will take place entirely on the server and the player
will interact with it purely through request and response cycles,
rather than having JavaScript game logic running in the browser.

What I could do is get the synchronous, full-page redraw version working
first and then add asynchronous board-state requests and partial page
redraws to smooth out the feel of the game for the player once I have a
working version to modify.

## Data store ##
We aren't using a database. I doubt a database would make sense for this
project anyway. The player scoreboard would be easily implemented as a
CSV or YAML file, and the same goes for the bcrypt hashed passwords.

The game state will be stored in the session.

## Sinatra app: OOP style vs regular style ##
One thing that occurs to me is that it might make sense to use the OOP
way to structure the Sinatra app, since we will be using classes for the
game logic. But this is not necessary and it might be best to learn
that way of structuring a Sinatra app with a much more basic tutorial
project.

## Design ##
So essentially, we could use the existing game logic from RB120, but
rework it without the curses-based UI. It might be best to write the
route logic first and, in so doing, specify the interface for the
TTTGame class.

* `get '/'`: 
    * we check if the player or computer has won, or if there is a
    draw, redirecting to `/player_won`, `/computer_won`, or `/draw`
    if necessary
    * Otherwise,we draw the board using a view template and the game state
    stored in the session. Each square that the player has the option of
    selecting for their next move will be a link with a URL like '/move/8'
* `get '/move/:square_index'`: we update the game state with a method
like TTTGame#player_move(square_index). Then we redirect to `/`
* `get '/player_won'`: redraw the board with a winning message.

TTTGame class
-new_game
-player_move(square) -- presumably triggers next computer move
-board_state
-player_won?
-computer_won?
-draw?
-end_state?

The first thing to do is to design the main board view.
We need 

Bonus Features:
* player logins with passwords
* players scoreboard
* asynch requests and partial redraws
