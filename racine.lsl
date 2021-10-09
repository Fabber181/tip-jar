/* ------------------------------------------------------------------------------------------------
                             Racine du projet de tip jar
--------------------------------------------------------------------------------------------------
Auteur : Fabber Resident (Fabrice TOUPET)
Mail : fabtoupet@gmail.com
Facebook : Fabrice TOUPET 

Descriptif : Ce script est la racine du projet c'est à partir d'elle que transite les communications entre les autres scripts : 
Elle gère les droit en fonction des utilisateurs et le timer de la tip jar. 

Elle communique avec les autres script via des message link */

// ============================== Constantes =======================================
// Paramètre géneraux
integer debugActif = TRUE;
list param_admin = [];


// Gestion des notescarts
/* Nom des notes */
string note_param = "TipJar_Param";
string note_admin = "TipJar_Admin";
string note_exclu = "TipJar_ExlusionRepartition";
/* Gestion des paramètres */
string note_code_param = "PARAM";
string note_code_admin = "ADMIN";
string note_code_exclu = "EXCLU";
string note_lecture = "";
integer note_ligne = 0;
/* Key des notescarts */
key note_key_param;
key note_key_admin;
key note_key_exclu;

// Paramètre lié au script de tip Jar
list param_tipjar_excluRepartition = [];
integer param_tipJar_Repart = 0;
integer param_tipJar_montantLimite = 300;
integer param_tipJar_tempslimite = 160;
key param_tipJar_keyDJ;
key param_tipJar_club;

// Paramètre global
integer timerChangementAnim = 15;

// Menu et interface 
integer chanelMenu = 2051;
string menuTextBoxData = "x";

string menuOuvertureAdmMainDesc = "Voulez vous utiliser la Tip-Jar pour vous ou quelqu'un d'autre";
list menuOuvertureAdmMainBout = ["Pour moi", "Pour quelqu'un"];

string menuOuvertureAdmIdUserDesc = "Saisisez l'UUID de l'avatars en question";
string menuOuvertureAdmIdUser = "AVATAR";

string menuOuvertureTextureDesc = "Quel Image de profil voulez vous afficher sur la tipJar ";
list menuOuvertureTextureBout = ["Profil", "UUID", "Aucune"];

string menuOuvertureTextureIdDesc = "Veillez saisir l'UUID de la texture que vous voulez appliquer.";
string menuOuvertureTextureId ="TEXTURE";

string menuOuvertureUserDesc = "Voulez-vous Utiliser la tip jar ?";
list menuOuvertureUserBout=["oui", "non"];

// Commandes element : 
key commandeIdDj;
key commandeIdClub;
key commandeIdTexture; 
integer commandeRepartition;
integer commandeLimiteRepartition;

// =========================== Fonctions générales  ================================
/* Fonction de debug */
debug(string methode, string message)
{
    if (debugActif == TRUE)
        llOwnerSay("[Racine] " + methode + " → " + message);
}

// Fonction de getter
/* Méthode qui test si c'est un admin*/
integer isAdmin(key utilisateur)
{
    return llListFindList(param_admin, [(string) utilisateur]) >= 0 ;
}

// ============================ Foncitons =========================

//----------------------------------------------------------------------------------------------
//                                     Gestion des notes cartes 
//----------------------------------------------------------------------------------------------
/* Métdhode qui vérifie à l'unité */
integer testNotecarteValide(string codeNote)
{
   string message = "La note suivante n'existe pas ou est mal paramétrée. Vérifiez le nom ou la présence de la notecarte :";
   if (llGetInventoryKey(codeNote) == NULL_KEY)
   {
       llSay(0, message + codeNote);
       return FALSE;
   } 
   else 
    return TRUE;
}

/* Permet de tester su c'est un commentaire */
integer testNoteCarteCommentaire(string data)
{
    return llSubStringIndex(data, "#") >= 0 || data == "";
}

/* Permet d'extraire le code et sa valeur dans une liste */
list lectureParam(string data)
{
    list paramList;
    integer codeIndexFin = llSubStringIndex(data, "=");
    integer codeIndexCommentaire = llSubStringIndex(data, "//");

    // Récuperation du code : 
    paramList += llGetSubString(data, 0, codeIndexFin-1);

    // Récuperation de la valeur : 
    paramList += llStringTrim(llGetSubString(data, codeIndexFin+1, codeIndexCommentaire-1), STRING_TRIM);

    //debug("lecture Param", " Les paramètres sont " + (string) paramList + ".");
    return paramList;

}

/* Permet de lire les notes cartes */
lectureParams(string data)
{
    list donnes;
    if (testNoteCarteCommentaire(data) == FALSE)
    {
        donnes = lectureParam(data);
        string code = llList2String(donnes, 0);

        // Récuperation de la repartition
        if(code == "repartitionClub")
        {
            param_tipJar_Repart = llList2Integer(donnes, 1);
            //debug("LectureParams", "La repartitionClub est de " + (string) param_tipJar_Repart);
        }
        // Récuperation de l limite de repartition
        else if (code == "limiteTipJar")
        {
            param_tipJar_montantLimite = llList2Integer(donnes, 1);
        }
        // Recuperation de l'UUID de l'avatars a qui faire" le paiement
        else if (code == "keyPaiementClub")
        {
            // Si la personne n'est pas renseigné
            if (llList2String(donnes, 1) == "")
                param_tipJar_club=llGetOwner();
            else
                param_tipJar_club=llList2Key(donnes, 1);
        }
        else if (code == "limiteTimer")
        {
            param_tipJar_tempslimite = llList2Integer(donnes, 1);
        }
    }

}

/* Methode qui charge les valeurs des administrateur */
lectureAdmin(string data)
{
    if (testNoteCarteCommentaire(data) == FALSE)
    {
        key codeAdmin = (key) llGetSubString(data, 0, 36);
        //debug("lectureAdmin", "Les codes d'administrateur donnen :" + (string) codeAdmin);
        param_admin += llStringTrim(codeAdmin, STRING_TRIM);
    }
}


/* Methode qui charge les valeurs des exlusions de tipJar */
lectureExclu(string data)
{
    if (testNoteCarteCommentaire(data) == FALSE)
    {
        integer dataLength = llStringLength(data);
        key codeExclu = (key) llGetSubString(data, 0, 36);
        
       // debug("lectureAdmin", "Les codes des DJ qui ne sont pas soumis à la repartition sont :" + (string) codeExclu + " pour une data de "+ data );
        param_tipjar_excluRepartition += codeExclu;

       
        string repartitionCode = "repartition=";
        integer repartitionLength = llStringLength(repartitionCode);
        integer repartitionStart = llSubStringIndex(data, repartitionCode);

        string maxCode = "max=";
        integer maxLength = llStringLength(maxCode);
        integer maxStart = llSubStringIndex(data, maxCode);
        integer maxEnd = llSubStringIndex(data, "//");

        integer repartitionValeur = (integer) llStringTrim(llGetSubString(data, repartitionStart+repartitionLength, maxStart-1), STRING_TRIM);
        integer maxValeur = (integer) llStringTrim(llGetSubString(data, maxStart+maxLength, maxEnd-1), STRING_TRIM);

        param_tipjar_excluRepartition += repartitionValeur;
        param_tipjar_excluRepartition += maxValeur;

     //   debug("lectureExclu", "La valeur de la repartition est de " + (string) repartitionValeur + " et la valeur du amx est de " + (string) maxValeur);
    }
}


//----------------------------------------------------------------------------------------------
//                                     Commandes entre les scripts
//----------------------------------------------------------------------------------------------
commandeAnimation(string commande)
{
    llMessageLinked(LINK_ROOT, 1, commande, "");
}

commandeTipJar(string commande)
{
     llMessageLinked(LINK_ROOT, 2, commande, "");
}

//----------------------------------------------------------------------------------------------
//                                     Menu
//----------------------------------------------------------------------------------------------
/* Méthode qui supprime les écouteurs */


/* Menu qui demande si l'utilisateur veux prendre le contrôle de la tip jar. */
 menuOuvertureTipJar(key utilisateur)
 {
     /* --  SI c'est un administrateur -- */
    if(isAdmin(utilisateur) == TRUE)
    {
        ouvertureMenuBouton(utilisateur, menuOuvertureAdmMainDesc, menuOuvertureAdmMainBout);
    }
     /* -- Si c'est un utilisateur -- */
     else
     {
         ouvertureMenuBouton(utilisateur, menuOuvertureUserDesc, menuOuvertureUserBout);
     }
     llListen(2051 , "", utilisateur, "");
 }

/* Ouverture du menu avec des boutons */
ouvertureMenuBouton(key avatar, string descriptif, list bouton)
{
    llDialog(avatar, descriptif, bouton, chanelMenu);
    llListen(chanelMenu, "", avatar, "");
    llSetTimerEvent(timerChangementAnim);
}

/* Ouverture du menu avec du texte */
ouvertureMenuText(key avatar, string descriptif, string type)
{
    menuTextBoxData = type;
    llTextBox(avatar, descriptif, chanelMenu);
    llListen(chanelMenu, "", avatar, "");
    llSetTimerEvent(timerChangementAnim);
}

// =====================================================================================================================
// ------------------------------ Etat par défaut ----------------------------------------------------------------------
// =====================================================================================================================
// Cet état permet le chargement des données stockés dans les notes cartes.
default
{
    changed( integer change )
    {
        llResetScript();
    }
    state_entry()
    {
        if(testNotecarteValide(note_param)==TRUE)
            note_key_param = llGetNotecardLine(note_param, note_ligne);
    }
    dataserver( key id_notecart, string data )
    {
        //debug("dataserver", "Lecture de la ligne → " + data);
        /* --------- Lecture des paramètres ----------- */
        if (id_notecart == note_key_param)
        {
            // Lecture de la note suivante
            if (data == EOF)
            {
              note_ligne =0;
              if (testNotecarteValide(note_admin) == TRUE)
                note_key_admin = llGetNotecardLine(note_admin, note_ligne);
            }
            // Lecture des lignes
            else
            {
                lectureParams(data);
                note_ligne++;
                note_key_param = llGetNotecardLine(note_param, note_ligne);
            }
        }
         /* --------- Lecture des utilisateur administrateurs ----------- */
        else if (id_notecart == note_key_admin)
        {
           if (data == EOF)
           {
                note_ligne = 0;
                if (testNotecarteValide(note_exclu) == TRUE)
                note_key_exclu = llGetNotecardLine(note_exclu, note_ligne);
           } 
           else
           {
               lectureAdmin(data);
               note_ligne ++;
               note_key_admin = llGetNotecardLine(note_admin, note_ligne);
           }
        }
        /* --------- Lecture des DJ exclus ----------- */
        else if (id_notecart == note_key_exclu)
        {
            if(data == EOF)
            {
                // Fin de l'initialsiaiton
                //debug("lecture des notes cartes fin ", (string) param_tipjar_excluRepartition);
                llOwnerSay("Fin de l'initialisation");
                llOwnerSay("♦ Paramètres generaux :\n    - Valeur Repartition = " + (string) param_tipJar_Repart + "% \n" +
                    "    - Limite Repartition = " + (string) param_tipJar_montantLimite + "l$ \n" +
                    "    - Limite de temps = "+(string) param_tipJar_tempslimite + " minutes");
                
                // On va vers l'animaiton 
                state animation;
            }
            else
            {
                lectureExclu(data);
                note_ligne ++;
                note_key_exclu = llGetNotecardLine(note_exclu, note_ligne);
            }

        }
    }
}

state animation
{
    changed( integer change )
    {
        llResetScript();
        llSetTimerEvent(timerChangementAnim);
    }
    state_entry()
    {
        commandeAnimation("ecran_animation");
    }
    touch_start( integer num_detected )
    {
        key idUtilisateur = llDetectedKey(0);
        menuOuvertureTipJar(idUtilisateur);
    }
    listen( integer channel, string name, key id, string message )
    {
        /* --- Gestion des bouton pour les administrateurs ------ */
        if(isAdmin(id) == TRUE)
        {
            if(message == "Pour moi")
            {

                ouvertureMenuBouton(id, menuOuvertureTextureDesc, menuOuvertureTextureBout);
            }
            else if (message == "Pour quelqu'un")
            {
                ouvertureMenuText(id, menuOuvertureAdmIdUserDesc, menuOuvertureAdmIdUser);
            }
            else if (menuTextBoxData == menuOuvertureAdmIdUser)
            {
                menuTextBoxData = "x";
                ouvertureMenuBouton(id, menuOuvertureTextureDesc, menuOuvertureTextureBout);  
            }
        }
        else
        {
            if(message == "oui")
            {
               ouvertureMenuBouton(id, menuOuvertureTextureDesc, menuOuvertureTextureBout);   
            }
        }

        // Commun sur la modification des textures. 
        if (message == "profil")
        {
            llSay(0, "Texture du profile");
        }
        else if (message == "aucune")
        {
            llSay(0, "On applique pas de texture");
        }
        else if (message == "UUID")
        { 
             ouvertureMenuText(id, menuOuvertureTextureIdDesc, menuOuvertureTextureId);
        }
        else if (menuTextBoxData == menuOuvertureTextureId)
        {
            llSay(0, "Application de la texture de l'utilisateur.");
        }
    }
    timer()
    {
        llListenRemove(chanelMenu);
        commandeAnimation("ecran_animation");
    }

}
