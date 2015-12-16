# Flash AS2 SWF Navigation Player for e-Learning with JS SCORM 1.2 & 2004 connection

These are source code of a Flash navigation player that can be used for e-Learning purposes. It plays swf slides, allowing navigation between slides, with menu, glossary, sound control, etc. It is easely configurable with XML files and establishes SCORM connection when on a LMS. (1.2 or 2004), using the [Pipwerks classes](http://pipwerks.com/)..

Please note that this is a wip repository. FLA, AS and folders are not cleaned, but works perfectly. It has been tested many times on LMS by beta testers for professional purposes.

**:warning: It is in Flash AS2, that means that all the slides have to be in Flash AS2 too. Flash AS2 is not supported anymore on Flash CC IDE, if you intend to use this, you have to work with Flash CS6 IDE or older versions.**

### AS2 pros for e-Learning
* Direct access to functions and variables between swf, allowing navigation functions execution directly from loaded swf using the ```_parent``` or ```_root``` terminology
* Quick and easy declaration of mouse events, like ```.onRelease``` ```.onRollOver```, etc.
* Similar performances than AS3, possibility to use movieclip filters like shadows (available since Flash 9)

### AS2 cons
* No standard error-handling mechanism and possibility to incorpore snippets in buttons, meaning that AS2 requires discipline to maintain a clean and reusable code
* Not a OOP, meaning that it can be a difficulty for those who first think in Classes and Objects for elaborating functionalities or activities


## :electric_plug: CONFIGURATION
**playerMain.xml:** List of swf to play, scorm version, navigation chosen, ... (see comments)
**playerLexique.xml:** Glossary items
**playerPdf.xml:** Ressources files, as pdf
**playerScores.xml:** Score(s) that goes to the LMS (possibility to have multiple scores using ponderations - total of ponderations must be 1)

**In index.html, don't forget to indicate the swf dimensions in px** (```// Dimensions du flash:```)


## :star: FUNCTIONALITIES
* Stores and get bookmark suspend datas
* If bookmark found, ask if learner wants to take back its course or not
* Catch LMS error connections at launch and on commits and display error alerts
* SCORM connection for LMS, 1.2 and 2004 versions
* HTML index with centered Flash and dynamic shrinking in case of browser window is smaller than Flash, using jQuery
* Possibility to set score on LMS for quizzes
* Loads and display swf slides, with loading progression indicator
* Navigation between slides with buttons (prev, next)
* Pause and Play loaded swf and movieclips inside
* Navigation between slides from Menu
* Possibility to disable slides before previous ones are not readed completly
* Sound control on/off
* Fullscreen toggle
* Glossary from XML file
* Ressources center


## :star2: FUNCTIONS OF THE NAV THAT YOU CAN CALL FROM LOADED SWF (using  ```_parent.theFunction()``` or ```_root.theFunction()```)
* **finishEcran() :** To tell the navigation that the slide reached its end
* **nextEcran() :** Used to go to the next slide directly, without user to click on the next button (can be useful in some cases)
* **goEcran(n:Number) :** Go to slide ```n```, where first slide = 1
* **disablePrevious() :** Disable previous button (inside quizzes for example)
* **disableNext() :** Disable next button (inside quizzes for example)
* **setScore(indice:Number,pct:Number) :** Store the score ```indice``` at a pourcent value of ```pct```
* **activePdf(indice:Number) :** Enable the Pdf ```indice``` for reading
* **openPdf(indice:Number) :** Open the pdf ```indice``` in a new tab of the browser


## :sparkles: VARIABLES OF THE NAV THAT YOU CAN GET OR SET FROM LOADED SWF (using  ```_parent.theVariable``` or ```_root.theVariable```)
* **learnerData:String :** Complementary optional data that is automatically stored in LMS SCORM suspend_data
* **learnerName:String :** Learner information (usually name) that is get from LMS at launch
* **forceCompletion:Boolean :** If set to ```true```, the SCORM completion will be set to Completed on next commit


**See samples slides FLA inside medias/swf to see working examples of slides**
