# Bingo-game

- An Admin can create a new game using the function ```createGame()``` function. This emits a ```GameStarted(gameId)``` event.
- A player can join a game by passing the ```gameId``` into the ```joinGame(gameId)``` function. The entryFee is transfered from the player into the contract. This emits a ```PlayerJoined(gameId, player_address)``` event.
- An Admin can draw a random number using the function ```drawNumber(gameId)``` function. This also checks if there is a winning player and transfers the total entry fees to the player.
- Anyone can get game/player info by calling public/external methods such as ```checkIfGameExists()```, ```checkIfPlayerAlreadyJoinedGame() ```, ```viewPlayers()``` and ```viewPlayerBoard```.

## Gas Estimates
 {
 
    "Creation": {
        "codeDepositCost": "2870600",
        "executionCost": "infinite",
        "totalCost": "infinite"
    }
    
     "External": {
        "checkIfGameExists(uint256)": "infinite",
        "checkIfPlayerAlreadyJoinedGame(address,uint256)": "infinite",
        "createGame()": "infinite",
        "currentGameId()": "2474",
        "drawNumber(uint256)": "infinite",
        "entryFee()": "2475",
        "game(uint256)": "infinite",
        "games(uint256)": "infinite",
        "joinGame(uint256)": "infinite",
        "minJoinDuration()": "2519",
        "minTurnDuration()": "2452",
        "players(address,uint256)": "3173",
        "token()": "2599",
        "updateParams(uint256,uint256,uint256)": "infinite",
        "viewPlayerBoard(uint256)": "infinite",
        "viewPlayers(uint256)": "infinite"
    },
    "Internal": {
        "checkIfNumberHasBeenDrawn(uint256,uint256)": "infinite",
        "isWinningColumn(uint256[5] memory[5] memory,uint256)": "infinite",
        "isWinningDiagonal(uint256[5] memory[5] memory)": "infinite",
        "isWinningRow(uint256[5] memory[5] memory,uint256)": "infinite",
        "randomBoard(uint256,uint256)": "infinite"
    }
}

NB: The functions with computation are hard to estimate gas since it is dependent on the size of the game/players and state of the blockchain.

## Improvements
- Due to time contraint, I concentrated on making the contract functional, as such, the elegance and performance of some functions such as the checks for winnings can be made better.
