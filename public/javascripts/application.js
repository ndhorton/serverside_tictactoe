// handle asynchronous requests and partial redraws

// TODO: we are eventually going to need to set the player marker dynamically
// and we will need to do so both here and on the server. Same goes for the
// starting player turn. I think if we have a class on the form that submits
// the player choices, then we could listen for the form submission and
// extract the player marker choice for client-side use. This would also
// be were the starting turn (`isHumanTurn`s initial value for a game) is set.

const delayTime = 800;

let isHumanTurn = true;
let humanMarker = 'X';

$( document ).ready(function(){

  $( '.square' ).click(function(event) {
    const $clickedSquare = $(this);
    if (!isHumanTurn || $clickedSquare.text().trim() !== '' ||
        $clickedSquare.hasClass( 'end-state' )) {
      return;
    }
    isHumanTurn = false;

    // insert player marker in DOM
    $clickedSquare.text(humanMarker);

    // prevent user clicking on more squares until the computer opponent has
    // moved

    // send async request to handle move server-side
    let squareNumber = $clickedSquare.data("position");
    let t = (new Date()).getTime();
    let request = $.ajax({
      url: `/game/${squareNumber}`,
      method: 'post',
    });

    request.done(function(data, textStatus, jqXHR) {
      // I think this logic for checking for an end state
      // might have to be more complex for situations where
      // the computer moves and that results in an end state

      let gameState = jqXHR['responseJSON'];
      if (gameState['status'] == 'end') {
        // if the human move ended the game, immediate redirect
        window.location.replace('/game/over');
        isHumanTurn = true;
        return;
      }

      let msEllapsed = (new Date()).getTime() - t;
      let thinkTime = Math.max(0, delayTime - msEllapsed);

      // mark the computer opponent's marker after 'thinking time' pause
      setTimeout( function() {
          let newSquareNumber = gameState['computer_move']
          let $targetSquare = $(`.square[data-position="${newSquareNumber}"]`);
          $targetSquare.text(gameState['computer_marker']);
          isHumanTurn = true;
          if (gameState['status'] == 'end_after') {
            window.location.replace('/game/over');
          }
        },
        thinkTime);
    });
  });

});
