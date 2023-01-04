// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract Bingo {
    using SafeMath for uint;

    // Game Params
    address public token;
    uint public minJoinDuration;
    uint public minTurnDuration;
    uint public entryFee;
    address admin;

    // Current game ID
    uint public currentGameId;

    event PlayerJoined(uint gameId, address player);
    event GameStarted(uint gameId);
    event NumberDrawn(uint gameId, uint number);
    event PlayerWon(uint gameId, address player);
    event GameEnded(uint gameId);

    // Struct representing a player in a particular game
    struct Player {
        uint[5][5] board;
        bool won;
    }
    mapping(address => mapping(uint => Player)) public players;

    // Struct representing a single Bingo game
    struct Game {
        address[] players;
        uint pot;
        uint[] drawnNumbers;
        uint startTime;
        uint endTime;
        uint lastDrawTime;
        bool ended;
    }

    // Mapping of game IDs to game states
    mapping(uint => Game) public game;

    // track the number of games
    uint[] public games;

        // Constructor
    constructor(address _token, uint _joinDuration, uint _turnDuration, uint _entryFee) {
        admin = msg.sender;
        token = _token;
        minJoinDuration = _joinDuration;
        minTurnDuration = _turnDuration;
        entryFee = _entryFee;
    }

    // Creates a new Bingo game
    function createGame() external {
        require(msg.sender == admin, "only an admin can create a game");

        currentGameId++;
        games.push(currentGameId);

        game[currentGameId] = Game({
            players: new address[](0),
            pot: 0,
            drawnNumbers: new uint[](0),
            startTime: block.timestamp + minJoinDuration,
            endTime: 0,
            lastDrawTime: 0,
            ended: false
        });

        emit GameStarted(currentGameId);
    }

    function joinGame(uint gameId) external {
        require(IERC20(token).balanceOf(msg.sender) >= entryFee, "Insufficient balance");
        require(block.timestamp <= game[gameId].startTime, "exceeded join time");
        bool doesGameExist = checkIfGameExists(gameId);
        require(doesGameExist == true, "game does not exist");
        require(game[gameId].ended == false, "game has already ended!");
        bool hasPlayerAlreadyJoined = checkIfPlayerAlreadyJoinedGame(msg.sender, gameId);
        require(hasPlayerAlreadyJoined == false, "player has already joined");

        IERC20(token).transferFrom(msg.sender, address(this), entryFee);

        game[gameId].pot += entryFee;
        game[gameId].players.push(msg.sender);

        for (uint col = 0; col < players[msg.sender][gameId].board[0].length; col++) {
            for (uint row = 0; row < players[msg.sender][gameId].board.length; row++) {
  
                if (row == 2 && col == 2) {
                                // Set the middle to "FREE"
                    players[msg.sender][gameId].board[row][col] = 0;
                } else {
                    players[msg.sender][gameId].board[row][col] = randomBoard(row, col);
                }
            }
        }

         emit PlayerJoined(gameId, msg.sender);
    }

    function drawNumber(uint gameId) external {
        require(msg.sender == admin, "only an admin can draw numbers");
        bool doesGameExist = checkIfGameExists(gameId);
        require(doesGameExist == true, "game does not exist");
        require(game[gameId].ended == false, "game has already ended!");
        require(block.timestamp > game[gameId].lastDrawTime.add(minTurnDuration), "minimum time between draws not yet elapsed");

        uint number = (uint(keccak256(abi.encodePacked(block.timestamp))) % 255) + 1;

        bool hasNumberBeenDrawn = checkIfNumberHasBeenDrawn(number, gameId);
        require(hasNumberBeenDrawn == false, "Number has already been drawn");

        game[gameId].drawnNumbers.push(number);

        game[gameId].lastDrawTime = block.timestamp;

        // Update the number on players' boards
        for (uint i = 0; i < game[gameId].players.length; i++){
            for (uint col = 0; col < players[game[gameId].players[i]][gameId].board[0].length; col++) {
                for (uint row = 0; row < players[game[gameId].players[i]][gameId].board.length; row++) {
                    if (players[game[gameId].players[i]][gameId].board[row][col] == number){
                        players[game[gameId].players[i]][gameId].board[row][col] = 0;
                    }
                }
            }
        }

        // Check each players' columns for winning sequence
        for (uint i = 0; i < game[gameId].players.length; i++){
            for (uint col = 0; col < players[game[gameId].players[i]][gameId].board[0].length; col++) {

                bool isWinningSequence = isWinningColumn(players[game[gameId].players[i]][gameId].board, col);

                if(isWinningSequence == true) {

                    IERC20(token).transfer(game[gameId].players[i], game[gameId].pot);
                    players[game[gameId].players[i]][gameId].won = true;
                    game[gameId].endTime = block.timestamp;
                    game[gameId].ended = true;

                     emit PlayerWon(gameId, game[gameId].players[i]);
                     emit GameEnded(gameId);
                }
            }
        }

        // Check each players' rows for winning sequence
        for (uint i = 0; i < game[gameId].players.length; i++){
            for (uint row = 0; row < players[game[gameId].players[i]][gameId].board.length; row++) {

                bool isWinningSequence = isWinningRow(players[game[gameId].players[i]][gameId].board, row);

                if(isWinningSequence == true) {

                    IERC20(token).transfer(game[gameId].players[i], game[gameId].pot);
                    players[game[gameId].players[i]][gameId].won = true;
                    game[gameId].endTime = block.timestamp;
                    game[gameId].ended = true;

                     emit PlayerWon(gameId, game[gameId].players[i]);
                     emit GameEnded(gameId);
                }
            }
        }

        // Check diagonal for winning sequence
         for (uint i = 0; i < game[gameId].players.length; i++){
             bool isWinningSequence = isWinningDiagonal(players[game[gameId].players[i]][gameId].board);

            if(isWinningSequence == true) {

                    IERC20(token).transfer(game[gameId].players[i], game[gameId].pot);
                    players[game[gameId].players[i]][gameId].won = true;
                    game[gameId].endTime = block.timestamp;
                    game[gameId].ended = true;

                     emit PlayerWon(gameId, game[gameId].players[i]);
                     emit GameEnded(gameId);
                }
         }

         emit GameEnded(gameId);
    }

     function updateParams(uint _minJoinDuration, uint _minTurnDuration, uint _entryFee) external {
        require(msg.sender == admin, "Only the admin can update the game parameters");
        minJoinDuration = _minJoinDuration;
        minTurnDuration = _minTurnDuration;
        entryFee = _entryFee;
    }

    function checkIfGameExists(uint gameId) public view returns(bool) {
         for(uint i = 0; i < games.length; i++){

            if(games[i] == gameId){

                return true;
            }
        }
        return false;
    }

    function checkIfPlayerAlreadyJoinedGame(address player, uint gameId) public view returns(bool) {
        for(uint i = 0; i < game[gameId].players.length; i++){

            if(game[gameId].players[i] == player){

                return true;
            }
        }
        return false;
    }

    function randomBoard(uint _row, uint _col) internal view returns (uint) {
        return (uint(keccak256(abi.encodePacked(block.timestamp, _row, _col))) % 255) + 1;
     }

    function checkIfNumberHasBeenDrawn(uint _number, uint gameId) internal view returns(bool){
        for(uint i = 0; i < game[gameId].drawnNumbers.length; i++){
            if (game[gameId].drawnNumbers[i] == _number) {
                return true;
            }
        }
        return false;
    }

    function isWinningRow(uint[5][5] memory board, uint row) internal pure returns (bool) {
        if (board[row][0] == 0 && board[row][1] == 0 &&  board[row][2] == 0 && board[row][3] == 0 && board[row][4] == 0) {
            return true;
        }
    return false;
    }

    function isWinningColumn(uint[5][5] memory board, uint col) internal pure returns (bool) {
        if (board[0][col] == 0 && board[1][col] == 0 &&  board[2][col] == 0 && board[3][col] == 0 && board[4][col] == 0) {
            return true;
        }
    return false;
    }

    function isWinningDiagonal(uint[5][5] memory board) internal pure returns (bool) {
        if (board[0][0] == 0 && board[1][1] == 0 && board[2][2] == 0 && board[3][3] == 0 && board[4][4] == 0) {
            return true;
        }
        if (board[0][4] == 0 && board[1][3] == 0 && board[2][2] == 0 && board[3][1] == 0 && board[4][0] == 0) {
            return true;
        }
    return false;
    }

    function viewPlayers(uint gameId) external view returns(address[] memory) {
        return game[gameId].players;
    }

    function viewPlayerBoard(uint gameId) external view returns(uint[5][5] memory) {
        return players[msg.sender][gameId].board;
    }

}
