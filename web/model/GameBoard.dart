library GameBoard;
import 'Position.dart';
import 'Player.dart';

class GameBoard{
  
  List<Position> listPositions;
  Player player0;
  Player player1;
  Player player2;
  // Type of scenari
  int scenariType;
  // Step of the game
  int gamePhase;
  // Level of the game
  int level;
  
  // getters
  List<Position> get getListPositions => listPositions;
  
  
  void init(){
    createPlayers();
    createListPositions();
  }
  
  /**
   * We create the positions
   */
  void createListPositions(){
    
    // On créé une liste de positions
    // Chaque position est numérotée et appartient à un carré (G,M,S)
    //
    // O-----------1-----------2
    // |           |           |
    // |   0-------1-------2   |
    // |   |       |       |   |
    // |   |   0---1---2   |   |
    // |   |   |       |   |   |
    // 7---7---7       3---3---3
    // |   |   |       |   |   |
    // |   |   6---5---4   |   |
    // |   |       |       |   |
    // |   6-------5-------4   |
    // |           |           | 
    // 6-----------5-----------4
    
    // Ajout des Positions du carré grand
    Position pg0 = new Position(0, "G", player0, false);
    Position pg1 = new Position(1, "G", player0, false);
    Position pg2 = new Position(2, "G", player0, false);
    Position pg3 = new Position(3, "G", player0, false);
    Position pg4 = new Position(4, "G", player0, false);
    Position pg5 = new Position(5, "G", player0, false);
    Position pg6 = new Position(6, "G", player0, false);
    Position pg7 = new Position(7, "G", player0, false);
    
    // Ajout des Positions du carré moyen
    Position pm0 = new Position(0, "M", player0, false);
    Position pm1 = new Position(1, "M", player0, false);
    Position pm2 = new Position(2, "M", player0, false);
    Position pm3 = new Position(3, "M", player0, false);
    Position pm4 = new Position(4, "M", player0, false);
    Position pm5 = new Position(5, "M", player0, false);
    Position pm6 = new Position(6, "M", player0, false);
    Position pm7 = new Position(7, "M", player0, false);
    
    // Ajout des Positions du carré petit
    Position ps0 = new Position(0, "S", player0, false);
    Position ps1 = new Position(1, "S", player0, false);
    Position ps2 = new Position(2, "S", player0, false);
    Position ps3 = new Position(3, "S", player0, false);
    Position ps4 = new Position(4, "S", player0, false);
    Position ps5 = new Position(5, "S", player0, false);
    Position ps6 = new Position(6, "S", player0, false);
    Position ps7 = new Position(7, "S", player0, false);
    
    // On instancie listPositions
    listPositions = new List<Position>();
    
    // Ajout des Positions à la liste
    listPositions.add(pg0);
    listPositions.add(pg1);
    listPositions.add(pg2);
    listPositions.add(pg3);
    listPositions.add(pg4);
    listPositions.add(pg5);
    listPositions.add(pg6);
    listPositions.add(pg7);
    
    listPositions.add(pm0);
    listPositions.add(pm1);
    listPositions.add(pm2);
    listPositions.add(pm3);
    listPositions.add(pm4);
    listPositions.add(pm5);
    listPositions.add(pm6);
    listPositions.add(pm7);
    
    listPositions.add(ps0);
    listPositions.add(ps1);
    listPositions.add(ps2);
    listPositions.add(ps3);
    listPositions.add(ps4);
    listPositions.add(ps5);
    listPositions.add(ps6);
    listPositions.add(ps7);
    
  }
  
  /**
   * We create the 3 players
   */
  void createPlayers(){
    player0 = new Player(0, true, "neutral");
    player1 = new Player(1, true, "khaleesi");
    player2 = new Player(2, true, "snow");
  }
  
  
  /**
   * Select a game scenari
   */
  void selectScenariAndLevel(int typeScenari, int lvl){
    
    level = lvl;
    if(typeScenari == 1){
      // Scenari 1 : we play with 2 IA
      player1.isIA = true;
      player1.level = 3;
      player2.isIA = true;
      player2.level = 1;
      scenariType = 1;
    }else if(typeScenari == 2){
      // Scenari 2 : we play with one player / one IA
      player1.isIA = false;
      player1.level = 3;
      player2.isIA = true;
      player2.level = 3;
      scenariType = 2;
    }else if(typeScenari == 3){
      // Scenari 3 : Player VS IA level 2
      player1.isIA = false;
      player1.level = 3;
      player2.isIA = true;
      player2.level = 2;
      scenariType = 3;
    }else{
      // Scenari 3 : we play with 2 players
      player1.isIA = false;
      player1.level = 3;
      player2.isIA = false;
      player2.level = 3;
      scenariType = 3;
    }
    
  }
  
}