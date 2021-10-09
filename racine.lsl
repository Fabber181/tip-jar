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


// =========================== Fonctions générales  ================================
/* Fonction de debug */
debug(string methode, string message)
{
    if (debugActif == TRUE)
        llOwnerSay("[Racine]" + methode + " : " + message);
}

// ============================ Foncitons =========================

// ------- Gestion des notes cartes ---------------
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
        param_admin += codeAdmin;
    }
}


/* Methode qui charge les valeurs des exlusions de tipJar */
lectureExclu(string data)
{
    if (testNoteCarteCommentaire(data) == FALSE)
    {
        key codeExclu = (key) llGetSubString(data, 0, 36);
        //debug("lectureAdmin", "Les codes des DJ qui ne sont pas soumis à la repartition sont :" + (string) codeExclu);
        param_tipjar_excluRepartition += codeExclu;
    }
}


// =====================================================================================================================
// ------------------------------ Etat par défaut ----------------------------------------------------------------------
// =====================================================================================================================
default
{
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
