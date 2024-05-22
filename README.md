# janky godot motion blur

requires godot 4.3 or higher

uses compositoreffects but also outputs to a texture because idk how to directly output the results of the shader to the main rendering buffer thingy

it's per pixel and should work well with linear motion
angular motion is not so great with this unfortunately

there are also lots of bugs and glitches with this implementation so you probably don't wanna use this in your projects, but feel free to contribute code if u made it better

![image](https://github.com/dingusreal/janky-godot-motion-blur/assets/148672705/bf624a5a-757b-4688-8612-29fa9ad7b434)
