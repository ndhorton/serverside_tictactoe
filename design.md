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

An important thing I had not considered:
When serializing and deserializing objects, as we need to in order to
store objects in the session, it is highly advisable to serialize and
store only standard Ruby classes. Storing objects of custom classes in
the session is fraught with both security and runtime problems (though
it is possible in theory). It is considered good practice in web
development to store e.g. an Array containing the board state in the
session, and then, on the next request, to re-instantiate a new Board
object from the retrieved Array.

So, we need not only to redesign the UI of the Tic Tac Toe game from
RB120, but also to redesign the Board, Player, etc classes.

It would be best simply to harvest the existing classes for methods,
and build the overall design from scratch. This may be relatively
simple, however. Most of the Board etc classes can still be used, but
they must be able to be instantiated from standard Ruby data structures
like Arrays and Hashes, containing the state of a mid-game board.

TTTGame class
-new_game
-player_move(square) -- presumably triggers next computer move
-board_state
-player_won?
-computer_won?
-draw?
-end_state?

So I think it is best to begin with the design of the routes and views.
In doing so, we need to think about what persistent state needs to be
serialized between request-response cycles.

For the most simple design to build upon we need to keep track of:
* the state of the board's squares
* whose turn it is? (or is this implicit in the request-response cycle?)
* whose marker is which

We could have a method called like `game = deserialize(session[:state])` which
goes through the `session[:state]` Hash and replaces the standard Ruby objects
tracking state with the custom class objects that contain the behaviour
and organize the state. We would then have a method that works in an inverse
way, called like `session[:state] = serialize(game)`.

E.g., the session hash might look something like:
```
{
    board: [[' ', ' ', ' '], [' ', 'X', ' '], ['O', ' ', ' ']],
    human_marker: 'X',
    computer_marker: 'O',
    ...
}
```
## Bonus feature: async requests and partial redraws ##

Now I have built the basic game functionality, there is one glaring UX
problem. Every time the player chooses, the response contains both the
player's marker and the computer's next move. This makes the game feel
very different to playing an actual opponent.

Essentially, I would like the following:
* When the user clicks a square, the human marker appears immediately
* There is a pause, and then the computer marker for the computer opponent's
next move appears.

The first part *could* be achieved through a bit of JavaScript to replace the
`&nbsp;` in the empty square with her marker while the request is made
asynchronously which...

If we break it down, the request in the existing system
* updates the board state
* if the board has reached an end state
    * redirects to end state route
* else
    * updates the board with computer move
    * if the board has reached an end state
        * redirects to end state route
    * else
        * assembles entire html page as response that results in full-page redraw

What we might do is
* user clicks on a square
* a JavaScript listener calls a function that 
    * replaces the `nbsp;` in the square with the human player's marker
    * sends a request to a route that
        * updates the board state

I think what confuses me is how much we should
be doing with JavaScript/jQuery. Say our JavaScript updates the board visually
and then sends an asynch request. What happens when there is an end state?
Also, how do we handle the computer move?
On one hand, there will be a slight delay between updating the DOM with the
player marker and the async response coming back, but this length of time
might be imperceptible. So, I imagine we'd need to do something like:
```
updateDOM(square, marker)
let t = (new Date()).getTime();
sendAsyncRequest(square, t, function foo(t))

function foo(t)
if ((new Date()).getTime() - t < a certain number of milliseconds) {
    wait for the difference of milliseconds
}
now draw the computer move in
```
The problem with this might be synchronous waiting.

Bonus Features:
* player logins with passwords
* player chooses from three different opponents, easy medium hard
* player chooses whether she goes first or second
* players scoreboard
