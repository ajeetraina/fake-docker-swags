# VHS tape → renders demo/swag-lab-demo.gif (beats 2–6 of the Swag Lab loop).
#   Install VHS: brew install vhs
#   Render:      vhs demo/swag-lab-demo.tape
Output demo/swag-lab-demo.gif

Set Shell bash
Set FontSize 15
Set Width 1360
Set Height 760
Set Padding 24
Set Framerate 10
Set Theme "Dracula"

Hide
Type "bash demo/swag-lab-demo.sh"
Enter
Show

# End the recording exactly when the closing line appears, then hold it briefly.
Wait+Screen@180s /safely/
Sleep 2s
