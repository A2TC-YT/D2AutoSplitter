# Destiny 2 AutoSplitter
This is an AutoSplitter made for Destiny 2

# INSTALLATION

To begin, you'll need to download the autosplitter. Just click on the top link in the description, which will take you to the GitHub page. From there, click on the most recent release on the right side and download the top file. You may get a warning saying it's potentially dangerous - just click the up arrow and then click "keep." Once the file is downloaded, move it to a folder on your computer and double click it to run it. If you get a pop up, click "more info" and then "run anyway." That's it - you're now ready to use the autosplitter.

# IN GAME SETTINGS

Next, let's make sure you have the right settings in the game. The autosplitter works best when hud opacity is set to full, chromatic aberration is turned off, and brightness is set as high as possible. To adjust these settings, just go to the game options and look for the corresponding options.

# KEYBINDS

Now that your game is set up, let's move on to keybinds. To do this, open up LiveSplit and right click on it. Then, click "settings" and look at the keybinds you already have set. If any of the top 4 are not set, go ahead and do that now. Then, open the autosplitter and click on the boxes that say "none." Press the key that corresponds with the action and then click the "set" button. Repeat this process for all 4 keybinds and you should be good to go.

 # SPLIT IMAGES


So how does the autosplitter work? It looks for specific images to appear on the screen and then presses the split button when it sees them. To create these images, click on "Open Split Image Maker." This window allows you to capture the images you'll use to split. These can be almost anything white that shows up on the screen - for example, the "New Objective" text, any text that appears in the bottom left of your screen, or the ghost under your health bar when an area becomes respawn restricted.

To use the Split Image Maker, click the "Freeze" button (or assign a hotkey to it and press that) to take a temporary screenshot of the screen. This will make it easier to capture the image you're trying to get. Then, click "Select Area" and use your mouse to draw a rectangle around the image you want to capture. On the right, you'll see the actual image, and on the left, you'll see what the autosplitter sees (it only differentiates between white pixels and non-white pixels).

Below the images, you'll see the percentage of white pixels in the image and the total pixels in the image. Aim for a percentage of white pixels as close to 50% as possible, and keep the total pixels between 500 and 1500. If you can't get 50% white pixels, just try to get it as high as possible - anything over about 12% is usually fine. When adjusting the image, try to cut off any solid black rows or columns. Once you have the image you want, click "save current image" and give it a name that you'll recognize.

If you're playing with other people and want to capture images while you're in the game, you can take an actual screenshot and save it for later. Just make sure to full screen the image and then select the area. 

# HEALTH BARS

The autosplitter can also split on boss health bars appearing and disappearing. To get the boss health bar color and position, click on the button in the bottom left of the autosplitter window. Unfortunately, boss health bars are always slightly transparent, so the best way to detect them is to get the darkest and lightest possible colors and have the program check for any shade between those two colors. In the first encounter of the Deep Stone Crypt raid, there's a perfectly white light and a perfectly black wall that you can use to do this.

To set the colors, start the encounter so the health bar appears, then put the health bar over the perfectly white light and click "find light color." Then, click on the part of the health bar over the light. Next, go to the dark side of the raid and put the health bar over the dark wall. Click "find dark color" and click on that part of the health bar. Finally, click "set bar location" and click just to the left of the top left corner of the health bar.

# SPLIT FILES

Now that you have your split images, you can create your splits by clicking the "edit/make new splits" button. This will open a new window where you can set the split name, choose an image for the autosplitter to find, select whether you want the split to be a dummy split (more on that later), set a custom threshold (the percentage of the image that needs to match for it to split), and set a custom delay (how long the program will wait after finding an image before it starts looking for the next one). Once you have your splits set up, click "save current splits as" and give them a name. If you need to go back and change something later, just click "load splits" and select the split file you want to edit.

# USING THE AUTOSPLITTER

Now that you have everything set up, you're ready to use the autosplitter. Click "Load Splits" and select a split file. When you press your start timer button, the autosplitter will start too. In the bottom left of the autosplitter window, you'll see the current FPS (frames per second) that the autosplitter is working at, and the percentage of the image that is correct. To the right of the image, you'll see where you are in the splits. When the autosplitter finds an image, it will wait the set amount of delay before moving on to the next image.

One annoying thing about boss health bars is that they can disappear for many reasons other than actually killing the boss, such as going into your inventory or pulling out your ghost. To account for this, the autosplitter is set up to continue looking for the health bar until it finds the next split. If it sees the health bar back on the screen for 2 seconds straight, it will undo the split and wait for the health bar to disappear again. This is where dummy splits come in handy. A dummy split is exactly like a normal split, except it doesn't press the button when it finds the image. You should put one of these after boss deaths, so the splitter doesn't falsely undo the boss death split. A good image to use for this is the season rank progress one that shows up after every encounter of every dungeon and raid.

While using the autosplitter, if it misses an image you can just press your skip split key and it will skip the current image and split in LiveSplit. However, if the autosplitter and LiveSplit get out of sync, you can skip and undo splits specifically in the autosplitter, as well as stop just the autosplitter but keep the timer running.

# DISCORD

If you have any more questions about using the autosplitter, you can join the Discord. I hope you enjoy using the autosplitter.
