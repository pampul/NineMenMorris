library Position;
import 'Player.dart';


class Position{
  
  Player player;
  String square;
  int value;
  bool isMorris;
  
  // constructor
  Position([this.value, this.square, this.player, this.isMorris]); 
  
}