# CGRA 252 Assignment 1

Leonardo Riginelli
Blattle
[Video](https://youtu.be/fXHY7HlhPiA)

Blattle is a 2 player platform fighter where both players play on the same
keyboard similar to old flash era web games. Player 1 is my character and
Player 2 was made by Piper. We worked on the game together but created all the
aspects required for the assignment independently before combining them into
the final game.

The main game mechanic for Player 1 is the attack system. Attacking pushes the
player slightly in the opposite direction of the hit which can be used for
movement options. The attack can also be used to hit the bouncy ball and send
it flying. The ball deals damage based on its speed and can only be moved by
Player 1.

The hardest part of getting the game working in Godot was setting up the window
sizing and figuring out how the scene system works for loading certain
information and saving data such as audio volume.

The most interesting part of the game is how the ball can be used as a movement
option while also posing a risk. Touching it causes damage but hitting it from
above provides extra height. The same is true for the drones. They track the
player and deal tick damage on contact but can be destroyed in a few hits, and
hitting them from above also grants a height boost.

Through this project I learned how to use groups and signals in Godot, how the
GitHub branch system works, and how the audio bus system operates in Godot. I
also learned more about the structure and use of GDScript. Another useful skill
I developed was understanding how few sprites are actually needed to create a
convincing animation, as the hit effects in my game use only two frames but
still give a strong visual impact.

Also all bullet points were ticked from my portion of the assignment.
