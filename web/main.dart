import 'dart:async';
import 'dart:html';
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
// State of the game
bool gameOver = false;

// List of clickable elements
List<Element> listPositionsElements;
List<BestPosition> listBestPositionsNeeded;
// Player turn
int playerTurn = 0;
bool millWaiting = false;
Element selectedItem;

// -----------------------------------
// Game constants
const TIMEOUT = const Duration(seconds: 0);
// Set to 17 for the real game
final int MIN_ITEMS_TO_DROP = 17;

final int POINTS_FOR_OWN_MILL = 26;
final int POINTS_FOR_ADV_MILL = 10;
final int POINTS_FOR_NEUTRAL_POINT = 2;
final int POINTS_FOR_OWN_POINT = 6;
final int POINTS_FOR_ADV_POINT = 5;
final int POINTS_FOR_ONE_POINT = 1;
// -----------------------------------

@observable
int round = 0;
int droppedItems = 0;
Player currentPlayer;

Position pos1 = new Position();
Position pos2 = new Position();
Position pos3 = new Position();
Position pos4 = new Position();


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
  gameBoard.selectScenariAndLevel(2, 1);
  
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
  
  round++;
  
  // If player 1 is IA : let's IA play !!
  if(gameBoard.player1.isIA)
    letIAPlay(gameBoard.player1);
  else{
    currentPlayer = gameBoard.player1;
    message = 'Your turn : click on a node to drop an item !';
  }
    
  
}


/**
 * Action followed the clicked node
 */
void nodeClicked(Element e){
  
  if(!gameOver){
    // Check if it's his turn
    if(playerTurn == 0){
      
      if(gameBoard.gamePhase == 1){
        // The only possibility is to drop an item if no mill detected
        if(!millWaiting)
          dropPlayerItem(currentPlayer, e);
        else
          millDeleteItem(currentPlayer, e);
        return;
      }else{
        
        // We want to select, unselect, move or delete an item !
        if(!millWaiting){
          
          // Check if there is a selected item
          if(selectedItem != null){
            checkForMovePlayerItem(currentPlayer, e);
          }else{
            playerSelectAnItem(currentPlayer, e);
          }
          
          
        }else
          millDeleteItem(currentPlayer, e);
        return;
        
      }
  
    }else{
      window.alert('Wait for your turn !');
      return;
    }
  }else
    return;
  
}


/**
 * Check if the position selected is a move
 */
void checkForMovePlayerItem(Player player, Element e){
  
// We get the position thanks to the Element
  Position p = getPosition(e);
  
  if(p.square != null){
    
    // If the player select his own position
    if(p.player.number == player.number){
      playerSelectAnItem(player, e);
    }else if(p.player.number == 0){
      // We check if we can move
      BestPosition fakeBp = new BestPosition(0, getPosition(selectedItem));
      fakeBp.startEmplacement = getPosition(selectedItem);
      
      if(player.isGamePhase3){
        // We can move here !
        BestPosition bp = new BestPosition(0, p);
        bp.startEmplacement = getPosition(selectedItem);
        // If the position is empty, we can drop !
        moveItem(bp, player);
        
        // position become a BestPosition
        BestPosition bpFake = new BestPosition(0, p);
        
        // Then, check if a mill is freshly built
        //print('Check mill ...');
        if(checkLinePossibilities(bpFake, player, true, true)){
          // If it's a new mill, update items
          updatePositionsToMill(bpFake.emplacement, true);
          
          print('We have a mill ... Delete a player item now !');
          message = 'Mill detected ... You can delete an adversary item !';
          
          millWaiting = true;
          unSelectAllItems();
          
        }else{
          finishYourTurn();
        }
      }else{
        
        List<Position> listPossiblePositions = getPossibleMoves(fakeBp, true);
        
        if(listPossiblePositions.length > 0){
          
          if(listPossiblePositions.contains(p)){
            // We can move here !
            BestPosition bp = new BestPosition(0, p);
            bp.startEmplacement = getPosition(selectedItem);
            // If the position is empty, we can drop !
            moveItem(bp, player);

            // position become a BestPosition
            BestPosition bpFake = new BestPosition(0, p);
            
            // Then, check if a mill is freshly built
            //print('Check mill ...');
            if(checkLinePossibilities(bpFake, player, true, true)){
              // If it's a new mill, update items
              updatePositionsToMill(bpFake.emplacement, true);
              
              print('We have a mill ... Delete a player item now !');
              message = 'Mill detected ... You can delete an adversary item !';
              
              millWaiting = true;
              unSelectAllItems();
              
            }else{
              finishYourTurn();
            }
          }
          
        }else{
          print('No possible moves ...');
          window.alert('No possible moves ...');
        }
        
      }
      
    }else{
      print('Position is owned by an adversary : impossible move');
      window.alert('Position is owned by an adversary : impossible move');
    }
    
  }else{
    print('No position !');
    window.alert('Erreur !');
  }
  
}


/**
 * Select an item you want to move
 */
void playerSelectAnItem(Player player, Element e){
  
  // We get the position thanks to the Element
  Position p = getPosition(e);
  
  if(p.square != null){
    
    if(p.player.number == player.number){
      if(selectedItem != null && selectedItem.attributes["data-square"] == e.attributes["data-square"] 
      && selectedItem.attributes["data-value"] == e.attributes["data-value"]){
        // We unselect the element
        unSelectAllItems();
      }else{
        unSelectAllItems();
        e.classes.add("selected");
        selectedItem = e;
      }
    }
    
  }else{
    print('No position !');
    window.alert('Erreur !');
  }
  
}


void unSelectAllItems(){
  
  // First : set to null the element
  selectedItem = null;
  
  // Then, unSelect all cases
  queryAll('.playable').forEach((Element e){
    if(e.classes.contains("selected"))
      e.classes.remove("selected");
  });
  
}


/**
 * Drop player item function
 */
void dropPlayerItem(Player player, Element e){
  
  // We get the position thanks to the Element
  Position p = getPosition(e);
  
  if(p.square != null){
    
    if(p.player.number == 0){
    
      // If the position is empty, we can drop !
      dropItem(p, player);
      
      // position become a BestPosition
      BestPosition bpFake = new BestPosition(0, p);
      
      // Then, check if a mill is freshly built
      //print('Check mill ...');
      if(checkLinePossibilities(bpFake, player, true, true)){
        // If it's a new mill, update items
        updatePositionsToMill(bpFake.emplacement, true);
        
        print('We have a mill ... Delete a player item now !');
        message = 'Mill detected ... You can delete an adversary item !';
        
        millWaiting = true;
        
      }else{
        finishYourTurn();
      }
    
    }else{
      print('Position not empty !');
      window.alert('Please select an empty position');
    }
    
    
  }else{
    print('No position !');
    window.alert('Erreur !');
  }
  
}

/**
 * Drop a player item
 */
void millDeleteItem(Player player, Element e){
  
  // We get the position thanks to the Element
  Position p = getPosition(e);
  
  if(p.square != null){
    
    // Check if the position is deletable
    if(p.player.number != 0 && p.player.number != player.number){
      
      // Check if the position is on a mill
      if(!p.isMorris){
        
        // Delete the item
        removeAnItem(p);
        
        // Finish your turn and stop the mill check
        millWaiting = false;
        finishYourTurn();
        
      }else{
        print('Position is on a mill !');
        window.alert('That item is on a mill : You can\'t delete it !');
        
        // Check if there is only mill for the adversary
        checkOnlyMill(player);
      }
      
      
    }else{
      print('Position is not an adversary !');
      window.alert('That position isn\'t an adversary !');
    }
    
    
  }else{
    print('No position !');
    window.alert('Erreur !');
  }
  
}


/**
 * Check if there is only mills to adversary
 */
void checkOnlyMill(Player p){
  
  var countFree = 0;
  for(int i = 0;i < gameBoard.listPositions.length;i++){
    
    if(gameBoard.listPositions[i].player.number != p.number && gameBoard.listPositions[i].player.number != 0
        && !gameBoard.listPositions[i].isMorris)
      countFree++;
    
  }
  
  if(countFree == 0){
    window.alert('There is only mill on the game ... You can\'t delete an item !');
    millWaiting = false;
    finishYourTurn();
  }
  return;
  
}


/**
 * Mothership who detect who's the next player
 */
void executeMothership(Player oldPlayer){
  
  round++;
  
  switch(oldPlayer.number){
    
    case 1:
      if(gameBoard.player2.isIA)
        letIAPlay(gameBoard.player2);
      else
        currentPlayer = gameBoard.player2;
      break;
      
    case 2:
      if(gameBoard.player1.isIA)
        letIAPlay(gameBoard.player1);
      else
        currentPlayer = gameBoard.player1;
      break;
    
  }
  
  return;
  
}


/**
 * Let's play the IA player
 */
void letIAPlay(Player player){
  
  if(!gameOver){
  
    // Check if it's his turn
    if(player.number == playerTurn || playerTurn == 0){
      
      // Set the current player
      currentPlayer = player;
      
      // Set a timeout
      Timer timer = new Timer(TIMEOUT, () => doIAStuffWithTimer(player));
      
    }
  
  }
  return;
  
}

void doIAStuffWithTimer(Player player){
  
  doIAStuff(player);
  return;
  
}


void finishYourTurn(){
  // Then, let the player play
  playerTurn = 0;
  message = 'Next gamer will play ...';
  
  unSelectAllItems();
  
  // Check the gameStep
  checkGameStep();

  // Execute mothership to know who plays next
  executeMothership(currentPlayer);
}


/**
 * Check the state of the game
 */
void checkGameStep(){
  // We check the current round
  //print('Nbr of items dropped : ' + droppedItems.toString());
  
  if(droppedItems > MIN_ITEMS_TO_DROP && gameBoard.gamePhase != 2){
    gameBoard.gamePhase = 2;
    round = 0;
    print('Game step 2 enclenched ...');
  }
  
  if(gameBoard.gamePhase > 1){
    int count1 = 0;
    int count2 = 0;
    for(int i=0;i<gameBoard.listPositions.length;i++){
      if(gameBoard.listPositions[i].player.number == 1)
        count1++;
      else if(gameBoard.listPositions[i].player.number == 2)
        count2++;
    }
    
    if(count1 < 3 || count2 < 3){
      doGameOver(false);
      return;
    }else if(count1 < 4){
      gameBoard.player1.isGamePhase3 = true;
    }else if(count2 < 4){
      gameBoard.player2.isGamePhase3 = true;
    }
    
    if(round > 49){
      doGameOver(false);
      return;
    }
  }
  
}

/**
 * Do game over
 */
void doGameOver(bool cantMove){
  gameOver = true;
  
  String msg = "";
  int count1 = 0;
  int count2 = 0;
  for(int i=0;i<gameBoard.listPositions.length;i++){
    if(gameBoard.listPositions[i].player.number == 1)
      count1++;
    else if(gameBoard.listPositions[i].player.number == 2)
      count2++;
  }
  
  if(count1 < 3){
    msg += "Game Over !!\n\nPlayer 2 win the game !!";
  }else if(count2 < 3){
    msg += "Game Over !!\n\nPlayer 1 win the game !!";
  }
  
  if(round > 49)
    msg += "Too long game ... \n\nDraw !!!";
  
  if(cantMove){
    msg += "The player "+currentPlayer.number.toString()+" can't move !! \n\n He lose the game !";
  }
  
  message = msg;
  window.alert(msg);
  return;
}


/**
 * do IA stuff
 */
void doIAStuff(Player player){
  
  // Create a BestPosition
  BestPosition bp = new BestPosition();
  
  // Set the player turn
  playerTurn = player.number;
  
  message = 'Player ' + player.name + ' will playing ... ';
  
  // Check the game step
  if(gameBoard.gamePhase == 1){
    // The IA must place a user in the board
    // We check for the best position in the game
    bp = getBestPosition(gameBoard.player0, player, false);
    
    dropItem(bp.emplacement, player);
  }else if(gameBoard.gamePhase == 2){
    // The IA must move an item in the board
    // We check for the best position in the game
    bp = getBestPosition(player, player, false);
    
    moveItem(bp, player);
  }
  
  if(bp != null){
  
    // Then, check if a mill is freshly built
    //print('Check mill ...');
    if(checkLinePossibilities(bp, player, true, true)){
      // If it's a new mill, update items
      updatePositionsToMill(bp.emplacement, true);
      
      print('We have a mill ... Delete a player item now !');
      message = 'Mill detected ... We go to delete an item !';
      
      // Then, delete an adversary item
      switch(player.number){
        case 1:
          Timer timer = new Timer(TIMEOUT, () => IADeleteItem(gameBoard.player2));
          return;
          break;
          
        case 2:
          Timer timer = new Timer(TIMEOUT, () => IADeleteItem(gameBoard.player1));
          return;
          break;
      }
    }else{
      Timer timer = new Timer(TIMEOUT, finishYourTurn);
      return;
    }
  
  }else{
    Timer timer = new Timer(TIMEOUT, finishYourTurn);
    return;
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
 * Get a position by case element
 */
Position getPosition(Element e){
  return gameBoard.listPositions.firstWhere((Position position){
    if(position.square == e.attributes["data-square"] && position.value.toString() == e.attributes["data-value"]){
      return true;
    }else
      return false;
  }, orElse: (){
    print('No position founded for the case ...');
    return new Position();
  });
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
  
  // If we can delete an item
  if(bp.emplacement != null){
    // Then, we remove the item
    removeAnItem(bp.emplacement);
  }else{
    print('Cannot delete an item : there are only mills !');
  }
  
  finishYourTurn();
}


/**
 * Drop item function
 */
void dropItem(Position p, Player player){
  
  if(gameBoard.gamePhase == 1)
    droppedItems++;
  
  // We get the index of the item in the list
  int indexOfElem = gameBoard.listPositions.indexOf(p);
  // We get the DOM Element
  Element caseToPaint = getCaseByPosition(p);
  p.player = player;
  
  // We deleting the current index
  gameBoard.listPositions.removeAt(indexOfElem);
  gameBoard.listPositions.add(p);
  
  // Log to the server
  if(gameBoard.gamePhase == 1)
    print('Drop item to : ' + p.square + '-' + p.value.toString());
  
  // Then we paint the case
  caseToPaint.classes.add(player.name);
  return;
  
}


/**
 * function to remove an item
 */
void removeAnItem(Position p){
  
  // We get the index of the item in the list
  int indexOfElem = gameBoard.listPositions.indexOf(p);
  //print('Want to delete : ' + p.square + '-' + p.value.toString() + ' | ' 
  //    + gameBoard.listPositions[indexOfElem].square + '-' + gameBoard.listPositions[indexOfElem].value.toString());
  // We get the DOM Element
  Element caseToPaint = getCaseByPosition(p);
  
  // We araise the case
  caseToPaint.classes.remove(p.player.name);
  
  // change the owner
  p.player = gameBoard.player0;
  
  // We deleting the current index
  gameBoard.listPositions.removeAt(indexOfElem);
  gameBoard.listPositions.add(p);
  return;
  
}



/**
 * Move item function
 */
void moveItem(BestPosition bp, Player p){
  
  if(bp != null && bp.startEmplacement != null && bp.emplacement != null){
    // Display the next move
    print('Move item from : ' + bp.startEmplacement.square + '-'+bp.startEmplacement.value.toString()+' to : '+bp.emplacement.square + '-'+bp.emplacement.value.toString());
    
    // We break the mill, if there is a mill
    BestPosition fakeBp = new BestPosition(0, bp.startEmplacement);
    if(checkLinePossibilities(fakeBp, p, true, true)){
      print('We break a mill ...');
      // If we break a mill, update items
      updatePositionsToMill(fakeBp.emplacement, false);
    }
      
    // We remove an item
    removeAnItem(bp.startEmplacement);
    
    // --------------------------------
    // Then, we set the new position
    dropItem(bp.emplacement, p);
    
    return;
  }else{
    doGameOver(true);
    return;
  }
  
}


/**
 * Function to update mill status
 */
void updatePositionsToMill(Position p, bool newVal){
  
  int indexOfElement = gameBoard.listPositions.indexOf(p);
  p.isMorris = false;
  gameBoard.listPositions[indexOfElement] = p;
  
  if(pos1.player != null){
    indexOfElement = gameBoard.listPositions.indexOf(pos1);
    pos1.isMorris = newVal;
    gameBoard.listPositions[indexOfElement] = pos1;
  }
  if(pos2.player != null){
    indexOfElement = gameBoard.listPositions.indexOf(pos2);
    pos2.isMorris = newVal;
    gameBoard.listPositions[indexOfElement] = pos2;
  }
  if(pos3.player != null){
    indexOfElement = gameBoard.listPositions.indexOf(pos3);
    pos3.isMorris = newVal;
    gameBoard.listPositions[indexOfElement] = pos3;
  }
  if(pos4.player != null){
    indexOfElement = gameBoard.listPositions.indexOf(pos4);
    pos4.isMorris = newVal;
    gameBoard.listPositions[indexOfElement] = pos4;
  }
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

  BestPosition worstEnv = new BestPosition();
  if(gameBoard.gamePhase == 2 && currentPlayer.isGamePhase3)
    worstEnv = getWorstEnv(currentPlayer);
  
  listBestPositionsNeeded = new List<BestPosition>();
  
  /**
   * If the player wants to drop item 
   * OR
   * player wants to move his piece and he is in the last phase
   * OR
   * player wants to delete an item
   */
  if(gameBoard.gamePhase == 1 || isAvailableToDelete){
    // We list the whole positions needed
    for(int i = 0;i < gameBoard.listPositions.length;i++){
      // If position concern the player, we add it
      if(gameBoard.listPositions[i].player.number == neededCasesPlayer.number){
        if(isAvailableToDelete && gameBoard.listPositions[i].isMorris == false){
          //print('Position checked : ' + gameBoard.listPositions[i].square + '-'+gameBoard.listPositions[i].value.toString());
          BestPosition bestPos = new BestPosition(0, gameBoard.listPositions[i]);
          //print('Position checked : ' + bestPos.emplacement.square + '-'+bestPos.emplacement.value.toString());
          listBestPositionsNeeded.add(bestPos);
          setPointsToPosition(bestPos, playerConcernedBy, true);
        }else if(!isAvailableToDelete){
          //print('Position checked : ' + gameBoard.listPositions[i].square + '-'+gameBoard.listPositions[i].value.toString());
          BestPosition bestPos = new BestPosition(0, gameBoard.listPositions[i]);
          //print('Position checked : ' + bestPos.emplacement.square + '-'+bestPos.emplacement.value.toString());
          listBestPositionsNeeded.add(bestPos);
          setPointsToPosition(bestPos, playerConcernedBy, true);
        }
      }
    }
  }
  /**
   * Player wants to move his piece
   */
  else{
    // We list the whole positions needed
    for(int i = 0;i < gameBoard.listPositions.length;i++){
      
      if(gameBoard.gamePhase == 2 && currentPlayer.isGamePhase3){
        // We get an empty case
        if(gameBoard.listPositions[i].player.number == 0){
          BestPosition bpNew = new BestPosition();
          bpNew.emplacement = gameBoard.listPositions[i];
          bpNew.points = 0;
          // If it's his case, we list the positions where he can move
          List<Position> possibleMoves = getPossibleMoves(bpNew, true);
          
          // Then, we loop the positions to set points
          if(possibleMoves.length > 0){
            for(var j = 0;j<possibleMoves.length;j++){
              // If the position is an empty position
              if(possibleMoves[j].player.number == 0){
                //print('Get the possible moves from  : '+ gameBoard.listPositions[i].square + '-' + gameBoard.listPositions[i].value.toString() 
                //    + ' to : ' + possibleMoves[j].square + '-' + possibleMoves[j].value.toString());
                
                BestPosition bestPos = new BestPosition(0, possibleMoves[j]);
                bestPos.startEmplacement = worstEnv.emplacement;
                listBestPositionsNeeded.add(bestPos);
                setPointsToPosition(bestPos, playerConcernedBy, false);
              }
            }
          }
        }
      }else{
        // We get the player case
        if(gameBoard.listPositions[i].player.number == neededCasesPlayer.number){
          
          BestPosition bpNew = new BestPosition();
          bpNew.emplacement = gameBoard.listPositions[i];
          bpNew.points = 0;
          // If it's his case, we list the positions where he can move
          List<Position> possibleMoves = getPossibleMoves(bpNew, true);
          
          // Then, we loop the positions to set points
          if(possibleMoves.length > 0){
            for(var j = 0;j<possibleMoves.length;j++){
              // If the position is an empty position
              if(possibleMoves[j].player.number == 0){
                //print('Get the possible moves from  : '+ gameBoard.listPositions[i].square + '-' + gameBoard.listPositions[i].value.toString() 
                //    + ' to : ' + possibleMoves[j].square + '-' + possibleMoves[j].value.toString());
                
                BestPosition bestPos = new BestPosition(0, possibleMoves[j]);
                bestPos.startEmplacement = gameBoard.listPositions[i];
                listBestPositionsNeeded.add(bestPos);
                setPointsToPosition(bestPos, playerConcernedBy, false);
              }
            }
          }
        }
      }
    }
  }
  
  // Display the number of positions founded
  //print('Founded : ' + listBestPositionsNeeded.length.toString() + ' positions.');
  
  // Then, we check the best possibilities and take a random one
  // If we are in delete phase, we check if the position isn't a mill
  List<BestPosition> bpList = new List<BestPosition>();
  int maxPositionPoints = 0;
  //print('Player : '+currentPlayer.number.toString() + ' - level : ' +currentPlayer.level.toString());
  for(int i = 0;i < listBestPositionsNeeded.length;i++){
    if(!isAvailableToDelete){
      if(currentPlayer.level == 3){
        if(listBestPositionsNeeded[i].points == maxPositionPoints){
          bpList.add(listBestPositionsNeeded[i]);
        }else if(listBestPositionsNeeded[i].points > maxPositionPoints){
          maxPositionPoints = listBestPositionsNeeded[i].points;
          bpList = new List<BestPosition>();
          bpList.add(listBestPositionsNeeded[i]);
        }
      }else{
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
  else if(bpList.length == 0){
    print('Unable to delete/move an item !!');
    return new BestPosition();
  }
    
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
void setPointsToPosition(BestPosition bp, Player playerConcernedBy, bool ignoreStep2){
  
  // First step : check the best positions possibilities
  checkBestPositionPossibilities(bp, playerConcernedBy, ignoreStep2);
  
  // Second step : check the lines possibilities
  checkLinePossibilities(bp, playerConcernedBy, false, ignoreStep2);
  
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
void checkBestPositionPossibilities(BestPosition bp, Player playerConcernedBy, bool ignoreStep2){
  
  // First : list the possible moves in the position
  List<Position> possibleMoves = getPossibleMoves(bp, ignoreStep2);
  
  // We loop the positions to give points
  int totalPoints = 0;
  for(int i = 0;i < possibleMoves.length;i++){
    // One movement += 1 point
    totalPoints += POINTS_FOR_ONE_POINT;
    
    if(possibleMoves[i].player.number == playerConcernedBy.number)
      totalPoints+=POINTS_FOR_OWN_POINT;
    else if(possibleMoves[i].player.number == 0)
      totalPoints+=POINTS_FOR_NEUTRAL_POINT;
    else
      totalPoints+=POINTS_FOR_ADV_POINT;
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
List<Position> getPossibleMoves(BestPosition bp, bool ignoreStep2){
  
  // First : initialize the list
  List<Position> positionList = new List<Position>();
  
  // We loop the list of positions
  for(int i = 0;i < gameBoard.listPositions.length;i++){
    
    // If we got the same square, check the proximity of the point
    if(bp.emplacement.square == gameBoard.listPositions[i].square){
      if(increaseNumber(bp.emplacement.value, 1) == gameBoard.listPositions[i].value 
          || decreaseNumber(bp.emplacement.value, 1) == gameBoard.listPositions[i].value){
        if(gameBoard.gamePhase == 2 && !ignoreStep2){
          // Check if the point is the started point to move
          if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
            positionList.add(gameBoard.listPositions[i]);
        }else{
          positionList.add(gameBoard.listPositions[i]);
        }
      }
    }
    
    // if we are on a possible multi-line
    if(bp.emplacement.value == 1 || bp.emplacement.value == 3 
        || bp.emplacement.value == 5 || bp.emplacement.value == 7){
      switch(bp.emplacement.square){
        case 'G':
          if(gameBoard.listPositions[i].square == 'M' && gameBoard.listPositions[i].value == bp.emplacement.value){
            if(gameBoard.gamePhase == 2 && !ignoreStep2){
              // Check if the point is the started point to move
              if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
                positionList.add(gameBoard.listPositions[i]);
            }else{
              positionList.add(gameBoard.listPositions[i]);
            }
          }
          break;
        case 'S':
          if(gameBoard.listPositions[i].square == 'M' && gameBoard.listPositions[i].value == bp.emplacement.value){
            if(gameBoard.gamePhase == 2 && !ignoreStep2){
              // Check if the point is the started point to move
              if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
                positionList.add(gameBoard.listPositions[i]);
            }else{
              positionList.add(gameBoard.listPositions[i]);
            }
          }
          break;
        case 'M':
          if(gameBoard.listPositions[i].square != 'M' && gameBoard.listPositions[i].value == bp.emplacement.value){
            if(gameBoard.gamePhase == 2 && !ignoreStep2){
              // Check if the point is the started point to move
              if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
                positionList.add(gameBoard.listPositions[i]);
            }else{
              positionList.add(gameBoard.listPositions[i]);
            }
          }
          break;
      }
    }
    
  }
  
  return positionList;
  
}


/**
 * We check the line possibilities for now
 */
bool checkLinePossibilities(BestPosition bp, Player playerConcernedBy, bool isMillCheck, bool ignoreStep2){
  
  int totalPoints = 0;
  List<int> listVals = [0,2,4,6];
  pos1 = new Position();
  pos2 = new Position();
  pos3 = new Position();
  pos4 = new Position();
  
  /** 
   * First : if the point is on 0-2-4 or 6 :
   *   => We go to check the entire line :
   *     --> with incrementation +1 and +2 
   *     --> with decrementation -1 and -2
   */
  if(listVals.contains(bp.emplacement.value)){
    
    List<Position> positivePositionChecked = new List<Position>();
    List<Position> negativePositionChecked = new List<Position>();
    // We loop the list of positions
    for(int i = 0;i < gameBoard.listPositions.length;i++){
      
      // We add the positive values
      if(gameBoard.listPositions[i].square == bp.emplacement.square && 
          (increaseNumber(bp.emplacement.value, 1) == gameBoard.listPositions[i].value || (increaseNumber(bp.emplacement.value, 2)) == gameBoard.listPositions[i].value)){
        if(gameBoard.gamePhase == 2 && !ignoreStep2){
          // Check if the point is the started point to move
          if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
            positivePositionChecked.add(gameBoard.listPositions[i]);
        }else{
          positivePositionChecked.add(gameBoard.listPositions[i]);
        }
      }
      
      // We add the negative values
      if(gameBoard.listPositions[i].square == bp.emplacement.square && 
          (decreaseNumber(bp.emplacement.value, 1) == gameBoard.listPositions[i].value || (decreaseNumber(bp.emplacement.value, 2)) == gameBoard.listPositions[i].value)){
        if(gameBoard.gamePhase == 2 && !ignoreStep2){
          // Check if the point is the started point to move
          if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
            negativePositionChecked.add(gameBoard.listPositions[i]);
        }else{
          negativePositionChecked.add(gameBoard.listPositions[i]);
        }
      }
      
    }
    
    if(positivePositionChecked.length == 2){
      if(positivePositionChecked[0].player.number != 0 && positivePositionChecked[0].player.number == positivePositionChecked[1].player.number){
        if(positivePositionChecked[0].player.number == playerConcernedBy.number){
          totalPoints += POINTS_FOR_OWN_MILL;
          if(isMillCheck){
            pos1 = positivePositionChecked[0];
            pos2 = positivePositionChecked[1];
            return true;
          }
        }else{
          totalPoints += POINTS_FOR_ADV_MILL;
        }
      }
    }
    
    if(negativePositionChecked.length == 2){
      if(negativePositionChecked[0].player.number != 0 && negativePositionChecked[0].player.number == negativePositionChecked[1].player.number){
        if(negativePositionChecked[0].player.number == playerConcernedBy.number){
          totalPoints += POINTS_FOR_OWN_MILL;
          if(isMillCheck){
            pos3 = positivePositionChecked[0];
            pos4 = positivePositionChecked[1];
            return true;
          }
        }else{
          totalPoints += POINTS_FOR_ADV_MILL;
        }
      }
    }
    
  }
  
  /**
   * Second : if the point is on 1-3-5 or 7
   *   --> We check the 'G' sup and minus (square, point +1) and (square, point - 1)
   *   
   *   => If the point is on 'G'
   *     --> We check the 'M' and equal point number/We check the 'S' and equal point number
   *   => If the point is on 'S'
   *     --> We check the 'M' and equal point number/We check the 'S' and equal point number
   *   => If the point is on 'M'
   *     --> We check the 'S' and equal point number/We check the 'G' and equal point number
   */
  else{
    
    // First : we get the +1 position and the -1 position
    List<Position> minusAndPlusPositions = new List<Position>();
    List<Position> sameSquarePositions = new List<Position>();
    
    // We loop the list of positions
    for(int i = 0;i < gameBoard.listPositions.length;i++){
      
      // in the same square
      if(gameBoard.listPositions[i].square == bp.emplacement.square){
        
        if(increaseNumber(bp.emplacement.value, 1) == gameBoard.listPositions[i].value
            || decreaseNumber(bp.emplacement.value, 1) == gameBoard.listPositions[i].value){
          if(gameBoard.gamePhase == 2 && !ignoreStep2){
            // Check if the point is the started point to move
            if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
              minusAndPlusPositions.add(gameBoard.listPositions[i]);
          }else{
            minusAndPlusPositions.add(gameBoard.listPositions[i]);
          }
        }
        
        
      }else{
        
        switch(bp.emplacement.square){
          case 'G':
            if((gameBoard.listPositions[i].square == 'M' || gameBoard.listPositions[i].square == 'S') && gameBoard.listPositions[i].value == bp.emplacement.value){
              if(gameBoard.gamePhase == 2 && !ignoreStep2){
                // Check if the point is the started point to move
                if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
                  sameSquarePositions.add(gameBoard.listPositions[i]);
              }else{
                sameSquarePositions.add(gameBoard.listPositions[i]);
              }
            }
            break;
          case 'S':
            if((gameBoard.listPositions[i].square == 'M' || gameBoard.listPositions[i].square == 'G') && gameBoard.listPositions[i].value == bp.emplacement.value){
              if(gameBoard.gamePhase == 2 && !ignoreStep2){
                // Check if the point is the started point to move
                if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
                  sameSquarePositions.add(gameBoard.listPositions[i]);
              }else{
                sameSquarePositions.add(gameBoard.listPositions[i]);
              }
            }
            break;
          case 'M':
            if((gameBoard.listPositions[i].square == 'G' || gameBoard.listPositions[i].square == 'S') && gameBoard.listPositions[i].value == bp.emplacement.value){
              if(gameBoard.gamePhase == 2 && !ignoreStep2){
                // Check if the point is the started point to move
                if(gameBoard.listPositions[i].value != bp.startEmplacement.value && gameBoard.listPositions[i].square != bp.startEmplacement.square)
                  sameSquarePositions.add(gameBoard.listPositions[i]);
              }else{
                sameSquarePositions.add(gameBoard.listPositions[i]);
              }
            }
            break;
        }
      }
      
    }
    
    if(minusAndPlusPositions.length == 2){
      if(minusAndPlusPositions[0].player.number != 0 && minusAndPlusPositions[0].player.number == minusAndPlusPositions[1].player.number){
        if(minusAndPlusPositions[0].player.number == playerConcernedBy.number){
          totalPoints += POINTS_FOR_OWN_MILL;
          if(isMillCheck){
            pos1 = minusAndPlusPositions[0];
            pos2 = minusAndPlusPositions[1];
            return true;
          }
        }else{
          totalPoints += POINTS_FOR_ADV_MILL;
        }
      }
    }
    
    if(sameSquarePositions.length == 2){
      if(sameSquarePositions[0].player.number != 0 && sameSquarePositions[0].player.number == sameSquarePositions[1].player.number){
        if(sameSquarePositions[0].player.number == playerConcernedBy.number){
          totalPoints += POINTS_FOR_OWN_MILL;
          if(isMillCheck){
            pos3 = sameSquarePositions[0];
            pos4 = sameSquarePositions[1];
            return true;
          }
        }else{
          totalPoints += POINTS_FOR_ADV_MILL;
        }
      }
    }
  }
  
  if(!isMillCheck){
      
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
    
  }else{
    return false;
  }
  
}


/**
 * Get the worst env
 */
BestPosition getWorstEnv(Player p){
  
  listBestPositionsNeeded = new List<BestPosition>();
  
  // We list the whole positions needed
  for(int i = 0;i < gameBoard.listPositions.length;i++){
    // If position concern the player, we add it
    if(gameBoard.listPositions[i].player.number == p.number){
        //print('Position checked : ' + gameBoard.listPositions[i].square + '-'+gameBoard.listPositions[i].value.toString());
        BestPosition bestPos = new BestPosition(0, gameBoard.listPositions[i]);
        //print('Position checked : ' + bestPos.emplacement.square + '-'+bestPos.emplacement.value.toString());
        listBestPositionsNeeded.add(bestPos);
        setPointsToPosition(bestPos, p, true);
      
    }
  }
  
  List<BestPosition> bpList = new List<BestPosition>();
  int minPositionPoints = 1000;
  //print('Player : '+currentPlayer.number.toString() + ' - level : ' +currentPlayer.level.toString());
  for(int i = 0;i < listBestPositionsNeeded.length;i++){
      if(currentPlayer.level == 3){
        if(listBestPositionsNeeded[i].points == minPositionPoints){
          bpList.add(listBestPositionsNeeded[i]);
        }else if(listBestPositionsNeeded[i].points < minPositionPoints){
          minPositionPoints = listBestPositionsNeeded[i].points;
          bpList = new List<BestPosition>();
          bpList.add(listBestPositionsNeeded[i]);
        }
      }else{
        bpList.add(listBestPositionsNeeded[i]);
      }
  }
  
  return getBestRandomPosition(bpList);
  
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



