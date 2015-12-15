//////////////////////////////////////////////////////////////////////////////////
///////////////////PLAYER UNIVERSEL JCK AS2 VERSION 2015-10-20////////////////////
//////////////////////////////////////////////////////////////////////////////////

var verbose:Boolean = true;//indique si le Flash doit executer les trace (visualiser save bookmarks, etc.)

/*
FONCTIONS
---------
finishEcran() // à appeler à la fin de chaque écran
setScore(indice:Number,pct:Number) //enregistre un score. le premier score possède l'indice 1
activePdf(indice:Number) //active un pdf. le premier pdf possède l'indice 1
openPdf(indice:Number) //ouvre un pdf. le premier pdf possède l'indice 1
goEcran(n:Number) // va a l'écran n (où premier écran = 1, etc.)
disablePrevious() // vérouille le buton précédent, utilisé par exemple dans les quiz
disableNext() // vérouille le buton next, utilisé par exemple dans les quiz

//obsolete:
	valideEcran() //valide l'écran sans passer au suivant
	waitClickNext() //fait clignoter le bouton suivant
	nextEcran() //valide et passe à l'écran suivant
	
VARIABLES
---------
learnerData:String // Valeur optionelle qui sera enregistré sur le LMS à chaque commit (pour d'éventuelles données supplémentaires)
learnerName:String // récupération du nom apprenant depuis LMS
forceCompletion:Boolean // en mettant cette valeur à true, le module sera completed au prochain saveBookmark

*/
import com.greensock.*;
import mx.transitions.Tween;
import mx.transitions.easing.*;
import com.pipwerks.SCORM;
import flash.external.*;

var choisiSon:Boolean = true;
var navigationLibre:Boolean;
var ecransFiles:Array = new Array();
var ecransNames:Array = new Array();
var ecransVus:Array = new Array();
var currentEcran:Number;
var btNames:Array = new Array();
btNames = ["aide", "sommaire", "lexique","pdf", "rejouer", "previous_screen", "play_pause", "next_screen","narration", "sound", "fullscreen"];
var lexiqueMots:Array = new Array();
var lexiqueDefinitions:Array = new Array();
var lexiqueRange:Array = new Array();
var g_audioOn:Boolean = true;
var g_globalSound:Sound = new Sound();
var g_audioVolume:Number = g_globalSound.getVolume();
var mc:MovieClip = mc_conteneur;
var positionMonSon:Number;
var currentIntervalId:Number =0;
var intervalId:Array = new Array;
var monSon:Sound = new Sound();
var isNarration:Boolean = true;
var myTimerOn;
var myTimerOff;
var nbChapsParPage:Number = 0;
var currentChapPage:Number;
var isScores:Boolean;
var scores:Array = new Array();
var ponderations:Array = new Array();
var scoreGlobal:Number;
var scoreSucces:Number;
var scorm:SCORM = new SCORM();
var scormVersion:String;
var largeurForeone:Number = mc_progression.progression_foreone._width;
var largeurBackone:Number = mc_progression.progression_backone._width;
var isPdf:Boolean;
var pdfUrl:Array = new Array();
var pdfName:Array = new Array();
var pdfActive:Array = new Array();
var learnerName:String;
var isWaitClickNext:Boolean;
var istoc:Array = new Array();
var learnerData:String = "";
var forceCompletion:Boolean = false;

var timerInactivite:Number = 0;
var timerInactiviteMax:Number = 300;//temps de deconnexion inactivité en secondes
var timerInactivite;
var mouseListener:Object = new Object();
var inactiviteTrigger:Boolean = false;

String.prototype.replace = function(searchStr, replaceStr):String { 
	return this.split(searchStr).join(replaceStr); 
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Splashscreen avec sélection son ou pas son//////////////////////////////////////////////////////////////////
/*
function buildSplashscreen() {
	mc_choix_syst_sonore.btson1.onRelease = function() {
		choisiSon = true;
		mc_choix_syst_sonore._visible = false;
		loadBookmarks();
	}
	mc_choix_syst_sonore.btson2.onRelease = function() {
		choisiSon = false;
		bt_narration.gotoAndStop("enabled");
		bt_sound.gotoAndStop("disabled");
		mc_choix_syst_sonore._visible = false;
		loadBookmarks();
	}
}
*/
mc_choix_syst_sonore._visible = false;

mc_confirmation_bookmark._visible = false;
//confirmation bookmark:
mc_confirmation_bookmark.bt_oui.onRelease = function() {
	mc_confirmation_bookmark._visible = false;
	loadEcran();
}
mc_confirmation_bookmark.bt_non.onRelease = function() {
	mc_confirmation_bookmark._visible = false;
	currentEcran = 0;
	loadEcran();
}

//error
mc_error2._visible = false;
mc_error._visible = false;
mc_error.bg.onRelease = null;
mc_error.bg.useHandCursor = false;

//fermeture
mc_confirmation_fermeture._visible = false;
mc_confirmation_fermeture.bt_oui.onRelease = function() {
	functionCall_str = String(ExternalInterface.call("closeWindow"));
}
mc_confirmation_fermeture.bt_non.onRelease = function() {
	mc_confirmation_fermeture._visible = false;
}
bt_quitter.onRelease = function() {
	mc_confirmation_fermeture._visible = true;	
}
mc_confirmation_fermeture.bg.onRelease = null;
mc_confirmation_fermeture.bg.useHandCursor = false;

//systeme inactivite
mc_inactivite._visible = false;
mouseListener.onMouseMove = function() {
    timerInactivite = 0;
	inactiviteTrigger = false;
	mc_inactivite._visible = false;
	mc_inactivite.gotoAndStop(1);
};
Mouse.addListener(mouseListener);
timerInactivite = setInterval(incTimerInactivite, 1000);
function incTimerInactivite() {
	timerInactivite++;
	if (timerInactivite >= timerInactiviteMax) {
		if (!inactiviteTrigger) {
			inactiviteTrigger = true;
			mc_inactivite._visible = true;
			mc_inactivite.gotoAndPlay("start");
		}
	}
}

//chargement du XML///////////////////////////////////////////////////////////////////////////////////////////
var contenu:XML = new XML();
contenu.ignoreWhite=true;
contenu.load("playerMain.xml");
contenu.onLoad = function(success) {
	if (success) {
		tmp = this.firstChild.childNodes;
		//config
		if ((tmp[0].childNodes[0].firstChild.nodeValue) == "libre") {
			navigationLibre = true;
		} else {
			navigationLibre = false;
		}
		if ((tmp[0].childNodes[1].firstChild.nodeValue) != "on") {
			bt_lexique._visible = false;
		} else {
			buildLexique();
		}
		if ((tmp[0].childNodes[2].firstChild.nodeValue) != "on") {
			bt_pdf._visible = false;
		} else {
			buildPdf();
			isPdf = true;
		}
		if ((tmp[0].childNodes[3].firstChild.nodeValue) == "on") {
			isScores = true;
			buildScores();
		} else {
			isScores = false;
		}
		scormVersion = tmp[0].childNodes[4].firstChild.nodeValue;
		if (scormVersion == "local") {
			functionCall_str = String(ExternalInterface.call("setLocal"));
		}
		//mise en mémoire des écrans files, names, etc.
		for (i = 0; i < tmp[1].childNodes.length; i++) {
			ecransNames[i] = tmp[1].childNodes[i].firstChild.nodeValue;
			ecransFiles[i] = tmp[1].childNodes[i].attributes.file;
			istoc[i] = tmp[1].childNodes[i].attributes.istoc;
		}
		//on masque les écrans aide lexique et sommaire pause...
		mc_aide._visible = false;
		mc_sommaire._visible = false;
		mc_lexique._visible = false;
		mc_pdf._visible = false;
		mc_pause._visible = false;
		//on Builde le sommaire
		buildSommaire();
		//et on active les boutons du splashscreen
		//buildSplashscreen();
		//bypass système sous-titres
		choisiSon = true;
		mc_choix_syst_sonore._visible = false;
		loadBookmarks();
	}
}

//Création du lexique///////////////////////////////////////////////////////////////////////////////////////////
function buildLexique() {
	//charge XML
	var contenuLexique:XML = new XML();
	contenuLexique.ignoreWhite = true;
	contenuLexique.load("playerLexique.xml");
	contenuLexique.onLoad = function (success) {
		if (success) {
			tmp = this.firstChild.childNodes;
			//enregistre les mots
			for (i = 0; i < tmp.length; i++) {
				lexiqueMots[i] = tmp[i].attributes.mot;
			}
			//trie les mots
			lexiqueMots.sort();
			//enregistre les définitions correspondantes
			for (i = 0; i < tmp.length; i++) {
				for (j = 0; j < tmp.length; j++) {
					if (lexiqueMots[i] == tmp[j].attributes.mot) {
						lexiqueDefinitions[i] = tmp[j].firstChild.nodeValue;
					}
				}
			}
			var alphabet:Array = new Array();
			alphabet = [0, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];
			//rangement du lexique
			//d'abord les chiffres
			var arrayTmp:Array = new Array();
			for (i = 0; i < lexiqueMots.length; i++) {
				firstLettreMot = lexiqueMots[i].substr(0, 1);
				if (!isNaN(firstLettreMot)) {
					arrayTmp.push(i);
				}
			}
			lexiqueRange[0] = arrayTmp;
			//ensuite les lettres
			for (i = 1; i < alphabet.length; i++) {
				arrayTmp = [];
				for (j = 0; j < lexiqueMots.length; j++) {
					firstLettreMot = lexiqueMots[j].substr(0, 1);
					if (firstLettreMot.toUpperCase() == alphabet[i]) {
						arrayTmp.push(j);
					}
				}
				lexiqueRange[i] = arrayTmp;
			}
			//on construit le champ "lettres"
			var tmpStr:String = new String();
			if (lexiqueRange[0].length > 0) {
				tmpStr += "<a href='asfunction:_parent.afficheLexiqueMots,0'><u>0-9</u></a> ";
			} else {
				tmpStr += "0-9 ";
			}
			for (i = 1; i < alphabet.length; i++) {
				if (lexiqueRange[i].length > 0) {
					tmpStr += "<a href='asfunction:_parent.afficheLexiqueMots,"+i+"'><u>" + alphabet[i] + "</u></a> ";
				} else {
					tmpStr += alphabet[i] + " ";
				}
			}
			mc_lexique.lettres.htmlText = tmpStr;
		}
	}
}
function afficheLexiqueMots(id:Number) {
	var tmpStr:String = new String();
	for (i = 0; i < lexiqueRange[id].length; i++) {
		tmpStr += "\u2022 <a href='asfunction:_parent.afficheLexiqueDefinition,"+lexiqueRange[id][i]+"'><u>"+lexiqueMots[lexiqueRange[id][i]] + "</u></a><br><br>";
	}
	mc_lexique.mots.htmlText = tmpStr;
	mc_lexique.definition.htmlText = "";
}
function afficheLexiqueDefinition(id:Number) {
	mc_lexique.definition.htmlText = lexiqueDefinitions[id];
}

//Création des PDFS//////////////////////////////////////////////////////////////////////////////////////////
function buildPdf() {
	//charge XML
	var contenuPdf:XML = new XML();
	contenuPdf.ignoreWhite = true;
	contenuPdf.load("playerPdf.xml");
	contenuPdf.onLoad = function (success) {
		if (success) {
			tmp = this.firstChild.childNodes;
			for (i = 0; i < tmp.length; i++) {
				//parse xml
				pdfName[i] = tmp[i].firstChild.nodeValue;
				pdfUrl[i] = tmp[i].attributes.url;
				if (tmp[i].attributes.actif == "true") {
					pdfActive[i] = true;
					activeBtPdf(i + 1);
				} else {
					pdfActive[i] = false;
				}
				//met à jour boutons
				mc_pdf["btn" + (i + 1)].text.text = pdfName[i];	
			}
		}
	}
}
function activeBtPdf(numPdf:Number) {
	mc_pdf["btn" + numPdf].gotoAndStop("on");
	mc_pdf["btn" + numPdf].n = numPdf;
	mc_pdf["btn" + numPdf].onRelease = function() {
		openPdf(this.n);
	}
}
function activePdf(numPdf:Number) {
	pdfActive[numPdf - 1] = true;
	activeBtPdf(numPdf);
	saveBookmarks();
}
function openPdf(numPdf:Number) {
	getURL(pdfUrl[numPdf - 1], "_blank");
}


//Scoring////////////////////////////////////////////////////////////////////////////////////////////////////
function buildScores() {
	//charge XML
	var contenuScores:XML = new XML();
	contenuScores.ignoreWhite = true;
	contenuScores.load("playerScores.xml");
	contenuScores.onLoad = function (success) {
		if (success) {
			tmp = this.firstChild.childNodes;
			scoreSucces = tmp[0].firstChild.nodeValue;
			for (i = 0; i < tmp[1].childNodes.length; i++) {
				ponderations[i] = tmp[1].childNodes[i].firstChild.nodeValue;
				scores[i] = 0;
			}
		}
	}
}
function setScore(ind:Number,pct:Number) {
	scores[ind - 1] = pct;
	calculeScoreGlobal();
	switch (scormVersion) {
		case "1.2":
			scorm.set("cmi.core.score.raw", scoreGlobal.toString());
		break;

		case "2004": 
			scorm.set("cmi.score.scaled", (scoreGlobal/100).toString());
		break;
	}
	saveBookmarks();
}
function calculeScoreGlobal() {
	var totalScores:Number = 0;
	var totalPonderations:Number = 0;
	for (i = 0; i < ponderations.length; i++) {
		totalScores += (scores[i] * ponderations[i]);
		totalPonderations += (100 * ponderations[i]);
	}
	scoreGlobal = Math.round(totalScores / totalPonderations * 100);
}
//Chargement des écrans///////////////////////////////////////////////////////////////////////////////////////
function loadEcran() {
	TweenMax.killAll();
	resetNarration();//////FONCTION DE narration.as
	isWaitClickNext = false;
	clearInterval(myTimerOn);
	clearInterval(myTimerOff);
	stopAllSounds();
	initializeButtons();
	chp_text_nom_scene.text = ecransNames[currentEcran];
	chp_text_num_scene.text = (currentEcran+1);
	chp_text_num_total.text = ecransNames.length;
	for(i = 0; i < ecransNames.length; i++) {
		mc_sommaire.content["btn_" + i].gotoAndStop(1);
	}
	mc_sommaire.content["btn_" + currentEcran].gotoAndStop(2);
	var mcl:MovieClipLoader = new MovieClipLoader();
	var listener:Object = new Object();
	mc_loading._visible = true;
	mc_loading.gotoAndStop("etq_default");
	mcl.loadClip(ecransFiles[currentEcran], mc);
	mcl.addListener(listener);
	listener.onLoadProgress = function()
	{
		mc._visible = false;
		mc.stop();
		lb = mc.getBytesLoaded();
		tb = mc.getBytesTotal();
		pc = Math.floor(lb/tb*100);
		mc_loading.updateLoadingBar(pc);//////////////////////////FONCTION A INCLURE DANS LE PLAYER
	
	}
	listener.onLoadComplete = function()
	{
		saveBookmarks();
		mc._visible = true;
		mc.gotoAndPlay(1);
		mc_loading.gotoAndPlay("etq_open");
	}
	//progressbar
	mc_progression.progression_foreone._width = (currentEcran + 1) / ecransNames.length * largeurForeone;
	var progvalide:Number = 0;
	while (ecransVus[progvalide]&&(progvalide<ecransNames.length)) {
		progvalide++;
	}
	mc_progression.progression_backone._width = (progvalide) / ecransNames.length * largeurBackone;
}

//chargement des bookmarks///////////////////////////////////////////////////////////////////////////////
function loadBookmarks() {
	if (scormVersion != "local") {
		if (!scorm.connect()) {
			functionCall_str = String(ExternalInterface.call("setLocal"));
			mc_error._visible = true;
			mc_error.wait_and_deconnect.gotoAndPlay("start");
			return;
		}
		var bmStr:String = scorm.get("cmi.suspend_data");
		if ((bmStr != "") && (bmStr != undefined)) {
			currentEcran = Number(bmStr.split(",")[0]);
			for (i = 0; i < ecransNames.length; i++) {
				if (bmStr.split(",")[1].substr(i, 1) == "1") {
					ecransVus[i] = true;
				} else ecransVus[i] = false;
			}
			if (isScores) {
				for (i = 0; i < scores.length; i++) {
					scores[i] = (bmStr.split(",")[2]).split("|")[i];
				}
				calculeScoreGlobal();
			}
			if (isPdf) {
				var pdfStr:String = bmStr.split(",")[3];
				for (i = 0; i < pdfName.length; i++) {
					if (pdfStr.substr(i, 1) == "1") {
						activePdf(i + 1);
					}
				}
			}
			learnerData = bmStr.split(",")[4];
			//affiche écran choix reprise
			mc_confirmation_bookmark._visible = true;
		} else {
			EmptyBookmark();
			loadEcran();
		}
		switch (scormVersion) {
				case "1.2":
					learnerName = scorm.get("cmi.core.student_name");
				break;

				case "2004": 
					learnerName = scorm.get("cmi.learner_name");
					scorm.set("cmi.exit", "suspend");
					scorm.save();
				break;
		}
	} else {
		EmptyBookmark();
		learnerName = "John Doe";
		loadEcran();
	}
}
function EmptyBookmark() {
	currentEcran = 0;
	for (i = 0; i < ecransNames.length; i++) {
		ecransVus[i] = false;
	}
}

//sauvegarde des bookmarks et checke completion////////////////////////////////////////////////////////////////
function saveBookmarks() {
	var bmStr:String = "";
	bmStr += currentEcran.toString();
	bmStr += ",";
	var allEcransVus:Boolean = true;
	var tmpStr:String = "";
	for (i = 0; i < ecransNames.length; i++) {
		if (ecransVus[i]) {
			tmpStr += "1";
		} else {
			tmpStr += "0";
			allEcransVus = false;
		}
	}
	bmStr += tmpStr;
	//scores
	bmStr += ",";
	if (isScores) {
		for (i = 0; i < scores.length; i++) {
			bmStr += scores[i];
			if (i < scores.length - 1) {
				bmStr += "|";
			}
		}
	}
	//pdfs
	bmStr += ",";
	if (isPdf) {
		tmpStr = "";
		for (i = 0; i < pdfName.length; i++) {
			if (pdfActive[i]) {
				tmpStr += "1";
			}else {
				tmpStr += "0";
			}
		}
		bmStr += tmpStr;
	}
	//learnerData
	bmStr += ",";
	learnerData = learnerData.replace(",", "");//suppression des éventuelles virgules
	bmStr += learnerData;
	//
	if (verbose) {
		trace ("*** SAVE BOOKMARK : " + bmStr);
	}
	if (scormVersion != "local") {
		scorm.set("cmi.suspend_data", bmStr);
		if (allEcransVus || forceCompletion) {
			if (isScores) {
				var reussiteStr:String;
				if (scoreGlobal >= scoreSucces) {
					reussiteStr = "passed";
				} else reussiteStr = "failed";
			}
			switch (scormVersion) {
				case "1.2":
					if (isScores) {
						scorm.set("cmi.core.lesson_status", reussiteStr);
					} else {
						scorm.set("cmi.core.lesson_status", "completed");
					}
				break;

				case "2004": 
					scorm.set("cmi.completion_status", "completed"); break;
					if (isScores) {
						scorm.set("cmi.success _status", reussiteStr);
					}
					scorm.set("cmi.exit", "normal");
				break;
			}
		}
		if (!scorm.save()) {
			mc_error2._visible = true;
			mc_error2.gotoAndPlay("start");
		}
	}
}


//construction du sommaire//////////////////////////////////////////////////////////////////////////////////////
function buildSommaire() {
	for (var mov in mc_sommaire.mc_btn_chapitres) {
		nbChapsParPage++;
	}
	var nbjump:Number = 0;
	for (i = 0; i <= ecransNames.length; i++) {
		if (istoc[i] == "false") {
			nbjump++;
		}
	}
	if ((ecransNames.length - nbjump) <= nbChapsParPage) {
		mc_sommaire.nav_previous._visible = false;
		mc_sommaire.nav_next._visible = false;
		mc_sommaire.nav_txt._visible = false;
	}
}

function initializeSommaire() {
	var nbjump:Number = 0;
	for (i = 0; i <= currentEcran; i++) {
		if (istoc[i] == "false") {
			nbjump++;
		}
	}
	currentChapPage = Math.floor((currentEcran-nbjump) / nbChapsParPage);
	initializePageSommaire();	
}

function initializePageSommaire() {
	var nbjump:Number = 0;
	for (i = 0; i < ecransNames.length; i++) {
		if (istoc[i] == "false") {
			nbjump++;
		}
	}
	mc_sommaire.nav_txt.text = (currentChapPage + 1) + " / " + Math.ceil((ecransNames.length -nbjump) / nbChapsParPage);
	//boutons nav
	if (currentChapPage > 0) {
		mc_sommaire.nav_previous.gotoAndStop("on");
		mc_sommaire.nav_previous.onRelease = function() {
			currentChapPage--;
			initializePageSommaire();
		}
		mc_sommaire.nav_previous.useHandCursor = true;	
	} else {
		mc_sommaire.nav_previous.gotoAndStop("off");
		mc_sommaire.nav_previous.onRelease = function() {}
		mc_sommaire.nav_previous.useHandCursor = false;	
	}
	if (currentChapPage+1 < Math.ceil((ecransNames.length -nbjump) / nbChapsParPage)) {
		mc_sommaire.nav_next.gotoAndStop("on");
		mc_sommaire.nav_next.onRelease = function() {
			currentChapPage++;
			initializePageSommaire();
		}
		mc_sommaire.nav_next.useHandCursor = true;	
	} else {
		mc_sommaire.nav_next.gotoAndStop("off");
		mc_sommaire.nav_next.onRelease = function() {}
		mc_sommaire.nav_next.useHandCursor = false;		
	}
	
	//boutons chp
	var jump:Number = 0;
	var nbjump:Number = 0;
	var nbnojump:Number = 0;
	i = 0;
	while (nbnojump < (currentChapPage * nbChapsParPage)) {
		if (istoc[i] == "false") {
			nbjump++;
		} else {
			nbnojump++;
		}
		i++;
	}
	var virtualCurrentEcran:Number;
	if (istoc[currentEcran] == "false") {
		virtualCurrentEcran = currentEcran;
		do {
			virtualCurrentEcran--;
		} while (istoc[virtualCurrentEcran] == "false")
	}
	for (i = 1; i <= nbChapsParPage + jump; i++) {
		var ind = i + (currentChapPage * nbChapsParPage) - 1 + nbjump;
		var btn:MovieClip = mc_sommaire.mc_btn_chapitres["btn_chapitre" + (i - jump)];
		if (istoc[ind] == "true") {
			btn.ind = ind;

			btn._visible = true;
			btn.label_txt.text = ecransNames[ind];
			if (!ecransVus[ind]) {
				btn.cocheVerte._visible = false;
			} else {
				btn.cocheVerte._visible = true;
			}
			if ((ind != currentEcran)&&(ind != virtualCurrentEcran)){

				btn.gotoAndStop("off");
				btn.label_txt.text = ecransNames[ind];
				if (navigationLibre || ecransVus[ind] || ecransVus[ind-1]) {
					btn.useHandCursor = true;
					btn.onRollOver = function() {
						this.gotoAndStop("on");
						this.label_txt.text = ecransNames[this.ind];
					}
					btn.onRollOut = btn.onReleaseOutside = function() {
						this.gotoAndStop("off");
						this.label_txt.text = ecransNames[this.ind];
					}
					btn.onRelease = function() {
						currentEcran = this.ind;
						mc_sommaire._visible = false;
						mc_conteneur._visible = true;

						initializeButtons();
						loadEcran();
					}
				} else {
					btn.useHandCursor = false;
					btn.onRollOver = btn.onRollOut = btn.onReleaseOutside = btn.onRelease = function() {}
				}
			} else {
				btn.gotoAndStop("on");
				btn.label_txt.text = ecransNames[ind];
				btn.useHandCursor = false;
				btn.onRollOver = btn.onRollOut = btn.onReleaseOutside = btn.onRelease = function() {}
			}
		} else if (istoc[ind] == "false"){
			jump++;
		} else {
			btn._visible = false;
		}
		
	}
}



//Tooltips//////////////////////////////////////////////////////////////////////////////////////////////////////
function removeAllTooltips() {
	for (i = 0; i < btNames.length; i++) {
		this["tooltip_bt_" + btNames[i]]._visible = false;
	}
}
function enableTooltips() {
	for (i = 0; i < btNames.length; i++) {
		if (!(((btNames[i] == "sound")||(btNames[i] == "narration")) && !choisiSon)) {
			this["bt_" + btNames[i]].name = btNames[i];
			this["bt_" + btNames[i]].onRollOver = function() {
				this._parent["tooltip_bt_" + this.name]._visible = true;
			}
			this["bt_" + btNames[i]].onRollOut = this["bt_" + btNames[i]].onReleaseOutside = function() {
				removeAllTooltips();
			}
		}	
	}
}
function disableTooltips() {
	removeAllTooltips();
	for (i = 0; i < btNames.length-3; i++) {
		this["bt_" + btNames[i]].onRollOver = function() {}
		this["bt_" + btNames[i]].onRollOut = this["bt_" + btNames[i]].onReleaseOutside = function() {}
	}
}
removeAllTooltips();

//Boutons/////////////////////////////////////////////////////////////////////////////////////////////////////////
function initializeButtons() {
	for (i = 0; i < btNames.length; i++) {
		if (!(((btNames[i] == "sound")||(btNames[i] == "narration")) && !choisiSon)) {
			this["bt_" + btNames[i]].useHandCursor = true;
		}
	}
	for (i = 0; i < btNames.length-3; i++) {
		this["bt_" + btNames[i]].gotoAndStop("on");
	}
	enableTooltips();
	
	bt_aide.onRelease = function() {
		afficheAide();
	}
	bt_sommaire.onRelease = function() {
		afficheSommaire();
	}
	bt_lexique.onRelease = function() {
		afficheLexique();
	}
	bt_pdf.onRelease = function() {
		affichePdf();
	}
	bt_rejouer.onRelease = function() {
		replayEcran();
	}
	if (currentEcran > 0) {
		bt_previous_screen.onRelease = function() {
			previousEcran();
		}
	} else {
		bt_previous_screen.onRelease = null;
		bt_previous_screen.gotoAndStop("off");
		bt_previous_screen.useHandCursor = false;
	}
	
	bt_play_pause.onRelease = function() {
		goPause();
	}
	var nextIsOn:Boolean = true;
	if (!navigationLibre) {
		if (!ecransVus[currentEcran]) {
			nextIsOn = false;
		}
	}
	if (currentEcran >= ecransFiles.length - 1) {
		nextIsOn = false;
	}
	if (nextIsOn) {
		bt_next_screen.onRelease = function() {
			nextEcran();
		}
	} else {
		bt_next_screen.onRelease = null;
		bt_next_screen.gotoAndStop("off");
		bt_next_screen.useHandCursor = false;
	}
	if (isWaitClickNext) {
		waitClickNext();
	}
	if (choisiSon) {
		bt_narration.onRelease = function() {
			narrationOnOff();
		}
		bt_sound.onRelease = function() {
			soundOnOff();
		}
	}
	bt_fullscreen.onRelease = function() {
		fullScreen();
	}
}

function disableButtons() {
	disableTooltips();
	for (i = 0; i < btNames.length-3; i++) {
		this["bt_" + btNames[i]].useHandCursor = false;
		this["bt_" + btNames[i]].gotoAndStop("off");
		this["bt_" + btNames[i]].onRelease = null;
		this["bt_" + btNames[i]].useHandCursor = false;
	}
}

function disablePrevious() {
	bt_previous_screen.onRelease = null;
	bt_previous_screen.useHandCursor = false;
	bt_previous_screen.gotoAndStop("off");
}

function disableNext() {
	bt_next_screen.onRelease = null;
	bt_next_screen.useHandCursor = false;
	bt_next_screen.gotoAndStop("off");
}
//fonctions des boutons////////////////////////////////////////////////////////////////////////////////////////////////
function afficheAide() {
	mainStop();
	mc_aide._visible = true;
	var myTween:Tween = new Tween(mc_aide, "_y", Regular.easeOut, yPosBas, yPosHaut, 0.5, true);
	disableButtons();
	bt_aide.useHandCursor = true;
	bt_aide.gotoAndStop("on");
	bt_aide.onRelease = function() {
		var myTween:Tween = new Tween(mc_aide, "_y", Regular.easeOut, yPosHaut, yPosBas, 0.5, true);
		initializeButtons();
		mainPlay();
	}
}

function afficheSommaire() {
	mainStop();
	mc_sommaire._visible = true;
	initializeSommaire();
	var myTween:Tween = new Tween(mc_sommaire, "_y", Regular.easeOut, yPosBas, yPosHaut, 0.5, true);
	disableButtons();
	bt_sommaire.useHandCursor = true;
	bt_sommaire.gotoAndStop("on");
	bt_sommaire.onRelease = function() {
		var myTween:Tween = new Tween(mc_sommaire, "_y", Regular.easeOut, yPosHaut, yPosBas, 0.5, true);
		initializeButtons();
		mainPlay();
	}
}

function afficheLexique() {
	mainStop();
	mc_lexique.mots.htmlText = "";
	mc_lexique.definition.htmlText = "";
	mc_lexique._visible = true;
	var myTween:Tween = new Tween(mc_lexique, "_y", Regular.easeOut, yPosBas, yPosHaut, 0.5, true);
	disableButtons();
	bt_lexique.useHandCursor = true;
	bt_lexique.gotoAndStop("on");
	bt_lexique.onRelease = function() {
		var myTween:Tween = new Tween(mc_lexique, "_y", Regular.easeOut, yPosHaut, yPosBas, 0.5, true);
		initializeButtons();
		mainPlay();
	}
}

function affichePdf() {
	mainStop();
	mc_pdf._visible = true;
	var myTween:Tween = new Tween(mc_pdf, "_y", Regular.easeOut, yPosBas, yPosHaut, 0.5, true);
	disableButtons();
	bt_pdf.useHandCursor = true;
	bt_pdf.gotoAndStop("on");
	bt_pdf.onRelease = function() {
		var myTween:Tween = new Tween(mc_pdf, "_y", Regular.easeOut, yPosHaut, yPosBas, 0.5, true);
		initializeButtons();
		mainPlay();
	}
}

function replayEcran() {
	loadEcran();
}

function previousEcran() {
	if (currentEcran > 0) {
		currentEcran--;
		loadEcran();
	}
}

function goPause() {
	mainStop();
	bt_play_pause.gotoAndStop("pause");
	mc_pause._visible = true;
	var myTween:Tween = new Tween(mc_pause, "_alpha", Regular.easeOut, 0, 100, 0.3, true);
}
mc_pause.onRelease = function() {
	bt_play_pause.gotoAndStop("on");
	var myTween:Tween = new Tween(this, "_alpha", Regular.easeOut, 100, 0, 0.3, true);
	myTween.onMotionFinished = function() {
		mc_pause._visible = false;
		mainPlay();
	}
}
function finishEcran() {
	if (currentEcran == ecransFiles.length - 1) {
		valideEcran();
	}else {
		waitClickNext();
	}
}
function waitClickNext() {
	isWaitClickNext = true;
	bt_next_screen.onRelease = function() {
		nextEcran();
	}
	bt_next_screen.useHandCursor = true;
	waitClickNextOff();
}
function waitClickNextOff() {
	clearInterval(myTimerOn);
	clearInterval(myTimerOff);
	bt_next_screen.gotoAndStop("off");
	myTimerOn = setInterval(waitClickNextOn, 600);
}
function waitClickNextOn() {
	clearInterval(myTimerOn);
	clearInterval(myTimerOff);
	bt_next_screen.gotoAndStop("on");
	myTimerOff = setInterval(waitClickNextOff, 600);
}
function valideEcran() {
	ecransVus[currentEcran] = true;
	saveBookmarks();
}
function nextEcran() {
	ecransVus[currentEcran] = true;
	if (currentEcran < ecransFiles.length-1) {
		currentEcran++;
		loadEcran();
	}
}
function goEcran(n:Number) {
	currentEcran = n - 1;
	loadEcran();
}

function narrationOnOff() {
	if (isNarration) {
		bt_narration.gotoAndStop("off");
		isNarration = false;
		narration_conteneur._visible = false;
		//oblige le son à revenir
		bt_sound.gotoAndStop(1);
		g_audioOn = true;
		g_globalSound.setVolume(g_audioVolume);
	} else {
		bt_narration.gotoAndStop("on");
		isNarration = true;
		narration_conteneur._visible = true;
	}
}

function soundOnOff() {
	if (g_audioOn) {
		bt_sound.gotoAndStop(2);
		g_audioOn = false;
		g_globalSound.setVolume(0);
		//oblige la narration à se mettre
		bt_narration.gotoAndStop("on");
		isNarration = true;
		narration_conteneur._visible = true;
	} else {
		bt_sound.gotoAndStop(1);
		g_audioOn = true;
		g_globalSound.setVolume(g_audioVolume);
	}
}

function fullScreen() {
	Stage.displayState = Stage.displayState == "normal" ? "fullScreen" : "normal";
}

//play/pause/////////////////////////////////////////////////////////////////////////////////////////////////////////////
function mainStop()
{
	positionMonSon = monSon.position;
	monSon.stop();
	stopMotion(mc);
	for (var mov in mc)
	{
		stopMotion(mc[mov]);
		mc[mov].enabled = false;
		for (var mov2 in mc[mov])
		{
			stopMotion(mc[mov][mov2]);
			mc[mov][mov2].enabled = false;
			for (var mov3 in mc[mov][mov2])
			{
				stopMotion(mc[mov][mov2][mov3]);
				mc[mov][mov2][mov3].enabled = false;
				for (var mov4 in mc[mov][mov2][mov3])
				{
					stopMotion(mc[mov][mov2][mov3][mov4]);
					mc[mov][mov2][mov3][mov4].enabled = false;
					for (var mov5 in mc[mov][mov2][mov3][mov4])
					{
						stopMotion(mc[mov][mov2][mov3][mov4][mov5]);
						mc[mov][mov2][mov3][mov4][mov5].enabled = false;
					}
				}
			}
		}
	}
}

function isPlay(mc:MovieClip):Boolean{
	if (mc._previousframe == undefined){
		mc._previousframe = mc._currentframe
	}
	if (mc._previousframe == mc._currentframe){
		var playing = false;
	}
	else{
		var playing = true;
	}
	
	mc._previousframe = mc._currentframe;
	
	return playing;

}

function stopMotion(mc:MovieClip)
{
	isPlay(mc);
	currentIntervalId++;
	intervalId[currentIntervalId] = setInterval(pauseIfPlay2,100,mc,currentIntervalId)
}

function pauseIfPlay2()
{
	var mc:MovieClip
	var currentId:Number
	mc = arguments[0];
	currentId = arguments[1];
	
	mc.stop();
	
	clearInterval(intervalId[currentId]);	
	if (isPlay(mc))
	{
		mc.isMotion=true;
	}
	else
	{
		mc.isMotion=false;
	}

}


function mainPlay()
{

	if (choisiSon)
	{
		if ((positionMonSon!=undefined) && (positionMonSon != monSon.duration))
		{
			monSon.start(positionMonSon/1000,1);
		}
	}

	playMotion(mc);
	for (var mov in mc)
	{
		playMotion(mc[mov]);
		mc[mov].enabled = true;
		for (var mov2 in mc[mov])
		{
			playMotion(mc[mov][mov2]);
			mc[mov][mov2].enabled = true;
			for (var mov3 in mc[mov][mov2])
			{
				playMotion(mc[mov][mov2][mov3]);
				mc[mov][mov2][mov3].enabled = true;
				for (var mov4 in mc[mov][mov2][mov3])
				{
					playMotion(mc[mov][mov2][mov3][mov4]);
					mc[mov][mov2][mov3][mov4].enabled = true;
					for (var mov5 in mc[mov][mov2][mov3][mov4])
					{
						playMotion(mc[mov][mov2][mov3][mov4][mov5]);
						mc[mov][mov2][mov3][mov4][mov5].enabled = true;
					}
				}
			}
		}
	}
}

function playMotion(mc)
{
	if (mc.isMotion)
	{
		mc.play();
	}
}
