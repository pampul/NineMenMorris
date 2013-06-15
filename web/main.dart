import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'package:web_ui/web_ui.dart';
import 'model/GameBoard.dart';
import 'model/Position.dart';
import 'model/Move.dart';
import 'model/Player.dart';
import 'model/BestPosition.dart';


@observable
String message;

// board of the game
GameBoard gameBoard;
// List of clickable elements
List<Element> listPositionsElements;
List<BestPosition> listBestPositionsNeeded;
// Player turn
int playerTurn = 0;


/**
 * Main class
 * Start the game
 */
void main() {
  
  message = 'Game started ...';
  
  // Create the game
  gameBoard = new GameBoard();
  gameBoard.init();
  
  // Select a game type
  gameBoard.selectScenariAndLevel(1, 1);
  
  // Select a level (1 or 2)
  gameBoard.level = 1;
  
  // Then, start the game
  init();
  
}


/**
 * Init the game
 */
void init(){
  
  // List all possible positions and make them clickable
  listPositionsElements = queryAll('.playable');
  listPositionsElements.forEach((Element e){
    e.onClick.listen((Event event){
      nodeClicked(e);
    });
  });
  
  // Echo game starting
  print('Game starting ...');
  
  // Set game step to 1
  gameBoard.gamePhase = 1;
  
  // If scenari 1 : let's IA play !!
  if(gameBoard.scenariType == 1)
    letIAPlay(gameBoard.player1);
  
}


/**
 * Action followed the clicked node
 */
void nodeClicked(Element e){
  
}


/**
 * Let's play the IA player
 */
void letIAPlay(Player player){
  
  // Check if it's his turn
  if(player.number == playerTurn || playerTurn == 0){
    
    // Set the player turn
    playerTurn = player.number;
    
    message = 'Player ' + player.name + ' will playing ...';
  
    // Check the game step
    if(gameBoard.gamePhase == 1){
      // The IA must place a user in the board
      // We check for the best position in the game
      BestPosition p = getBestPosition(gameBoard.player0, player, false);
      
      dropItem(p.emplacement, player);
    }
    
    
    
    
    // Then, check if a mill is built
    print('Check mill ...');
  
  }
  
}

/**
 * Get the index of the position
 */
int getPositionIndex(Position p){
  int indexNeeded;
  gameBoard.listPositions.firstWhere((Position p2){
    if(p.square == p2.square && p.value == p2.value){
      indexNeeded = gameBoard.listPositions.indexOf(p2);
      return true;
    }else
      return false;
  });
}


/**
 * Get a case by his position
 */
Element getCaseByPosition(Position p){
  for(int i=0;i<listPositionsElements.length;i++){
    if(listPositionsElements[i].attributes["data-square"] == p.square && listPositionsElements[i].attributes["data-value"] == p.value.toString()){
      return listPositionsElements[i];
      break;
    }
  };
}


/**
 * Function to remove an item to your adversary
 */
void IADeleteItem(Player adversary){
  
  /**
   * We get the best position to delete
   * First, we put the adversary to get all his cases
   * Then, we put adversary again, to get all best possibilities he has
   * Finally, we put the boolean to true, so specify that we want to delete an item
   */
  BestPosition bp = getBestPosition(adversary, adversary, true);
  
  // Then, we remove the item
  removeAnItem(bp.emplacement);
}


/**
 * Drop item function
 */
void dropItem(Position p, Player player){
  
  // We get the index of the item in the list
  int indexOfElem = gameBoard.listPositions.indexOf(p);
  // We get the DOM Element
  Element caseToPaint = getCaseByPosition(p);
  p.player = player;
  
  // We deleting the current index
  gameBoard.listPositions.removeAt(indexOfElem);
  gameBoard.listPositions.add(p);
  
  // Log to the server
  print('Drop item to : ' + p.square + '-' + p.value.toString());
  
  // Then we paint the case
  caseToPaint.classes.add(player.name);
  
}


/**
 * function to remove an item
 */
void removeAnItem(Position p){
  
  // Log to the server
  print('Remove item from player "' + p.player.name + '" in ' + p.square + '-' + p.value.toString());

  // We get the index of the item in the list
  int indexOfElem = gameBoard.listPositions.indexOf(p);
  // We get the DOM Element
  Element caseToPaint = getCaseByPosition(p);
  
  // We araise the case
  caseToPaint.classes.remove(p.player.name);
  
  // change the owner
  p.player = gameBoard.player0;
  
  // We deleting the current index
  gameBoard.listPositions.removeAt(indexOfElem);
  gameBoard.listPositions.add(p);
  
}



/**
 * Move item function
 */
void moveItem(Position pStart, Position pEnd){
  
  
  
}




/**
 * -----------------------------------
 * 
 * Algorithm places
 * 
 * -----------------------------------
 */

/**
 * Get the best position function
 * @param Player neededCasesPlayer # Player Cases we looking for
 * @param Player playerConcernedBy # Player who wants to make the best move
 */
BestPosition getBestPosition(Player neededCasesPlayer, Player playerConcernedBy, bool isAvailableToDelete){
  
  // We list the whole positions needed
  listBestPositionsNeeded = new List<BestPosition>();
  for(int i = 0;i < gameBoard.listPositions.length;i++){
    // If position concern the player, we add it
    if(gameBoard.listPositions[i].player.number == neededCasesPlayer.number){
      //print('Position checked : ' + gameBoard.listPositions[i].square + '-'+gameBoard.listPositions[i].value.toString());
      BestPosition bestPos = new BestPosition(0, gameBoard.listPositions[i]);
      //print('Position checked : ' + bestPos.emplacement.square + '-'+bestPos.emplacement.value.toString());
      listBestPositionsNeeded.add(bestPos);
      setPointsToPosition(bestPos, playerConcernedBy);
    }
  }
  
  // Display the number of positions founded
  print('Founded : ' + listBestPositionsNeeded.length.toString() + ' positions.');
  
  // Then, we check the best possibilities and take a random one
  // If we are in delete phase, we check if the position isn't a mill
  List<BestPosition> bpList = new List<BestPosition>();
  int maxPositionPoints = 0;
  for(int i = 0;i < listBestPositionsNeeded.length;i++){
    if(!isAvailableToDelete){
      if(listBestPositionsNeeded[i].points == maxPositionPoints){
        bpList.add(listBestPositionsNeeded[i]);
      }else if(listBestPositionsNeeded[i].points > maxPositionPoints){
        maxPositionPoints = listBestPositionsNeeded[i].points;
        bpList = new List<BestPosition>();
        bpList.add(listBestPositionsNeeded[i]);
      }
    }else{
      if(listBestPositionsNeeded[i].points == maxPositionPoints && !listBestPositionsNeeded[i].emplacement.isMorris){
        bpList.add(listBestPositionsNeeded[i]);
      }else if(listBestPositionsNeeded[i].points > maxPositionPoints && !listBestPositionsNeeded[i].emplacement.isMorris){
        maxPositionPoints = listBestPositionsNeeded[i].points;
        bpList = new List<BestPosition>();
        bpList.add(listBestPositionsNeeded[i]);
      }
    }
  }
  
  return getBestRandomPosition(bpList);
  
}

/**
 * Get random item if the list has many possibilities who has the same points
 */
BestPosition getBestRandomPosition(List<BestPosition> bpList){
  if(bpList.length == 1)
    return bpList[0];
  var random = new Random();
  for (var i = bpList.length - 1; i > 0; i--) {
    var n = random.nextInt(bpList.length);
    return bpList[n];
  }
}


/**
 * We go to set points by position and player
 * This function is the controller who called the two steps
 */
void setPointsToPosition(BestPosition bp, Player playerConcernedBy){
  
  // First step : check the best positions possibilities
  checkBestPositionPossibilities(bp, playerConcernedBy);
  
  
  // Second step : check the lines possibilities
  checkLinePossibilities(bp, playerConcernedBy);
  
}


/**
 * We check the best possibilities for now
 * 
 * First : we check environement
 *   => If the position has many junctions, we give it 1 point by junction
 *   => If that junction contain :
 *     --> friendly player  +5pts
 *     --> adversary player -4pts
 *     --> neutral player   +2pts
 */
void checkBestPositionPossibilities(BestPosition bp, Player playerConcernedBy){
  
  // First : list the possible moves in the position
  List<Position> possibleMoves = getPossibleMoves(bp);
  
  // We loop the positions to give points
  int totalPoints = 0;
  for(int i = 0;i < possibleMoves.length;i++){
    // One movement += 1 point
    totalPoints += 1;
    
    if(possibleMoves[i].player.number == playerConcernedBy.number)
      totalPoints+=5;
    else if(possibleMoves[i].player.number == 0)
      totalPoints+=2;
    else
      totalPoints+=4;
  }
  
  // Get the index
  int indexElem = listBestPositionsNeeded.indexOf(bp);
  
  // We add the points to the BestPosition
  bp.points += totalPoints;
  
  // uncomment to see each point by position
  //print('Position ' + bp.emplacement.square + '-' + bp.emplacement.value.toString() +
  //    ' have ' + bp.points.toString() + ' points');
  
  // Then we update the list
  listBestPositionsNeeded.removeAt(indexElem);
  listBestPositionsNeeded.add(bp);
}


/**
 * We check every point possibility and return a list of Positions
 */
List<Position> getPossibleMoves(BestPosition bp){
  
  // First : initialize the list
  List<Position> positionList = new List<Position>();
  
  // We loop the list of positions
  for(int i = 0;i < gameBoard.listPositions.length;i++){
    
    // If we got the same square, check the proximity of the point
    if(bp.emplacement.square == gameBoard.listPositions[i].square){
      if(increaseNumber(bp.emplacement.value, 1) == gameBoard.listPositions[i].value 
          || decreaseNumber(bp.emplacement.value, 1) == gameBoard.listPositions[i].value){
        positionList.add(gameBoard.listPositions[i]);
      }
    }
    
    // if we are on a possible multi-line
    if(bp.emplacement.value == 1 || bp.emplacement.value == 3 
        || bp.emplacement.value == 5 || bp.emplacement.value == 7){
      switch(bp.emplacement.square){
        case 'G':
          if(gameBoard.listPositions[i].square == 'M' && gameBoard.listPositions[i].value == bp.emplacement.value)
            positionList.add(gameBoard.listPositions[i]);
          break;
        case 'S':
          if(gameBoard.listPositions[i].square == 'M' && gameBoard.listPositions[i].value == bp.emplacement.value)
            positionList.add(gameBoard.listPositions[i]);
          break;
        case 'M':
          if(gameBoard.listPositions[i].square != 'M' && gameBoard.listPositions[i].value == bp.emplacement.value)
            positionList.add(gameBoard.listPositions[i]);
          break;
      }
    }
    
  }
  
  return positionList;
  
}


/**
 * We check the line possibilities for now
 */
void checkLinePossibilities(BestPosition bp, Player playerConcernedBy){
  
  
  
}

/**
 * Math function that applicate to the game
 * DecreaseNumber
 */
int decreaseNumber(int nbr, int nbrToS){
  if(nbr == 0){
    return 8 - nbrToS;
  }else{
    return nbr - nbrToS;
  }
}

/**
 * Math function that applicate to the game
 * IncreaseNumber
 */
int increaseNumber(int nbr, int nbrtoAdd){
  if(nbr + nbrtoAdd >= 8)
    return 0;
  else{
    return nbr + nbrtoAdd;
  }
}


