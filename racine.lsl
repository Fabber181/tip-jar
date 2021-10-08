/* ------------------------------------------------------------------------------------------------
                             Racine du projet de tip jar
--------------------------------------------------------------------------------------------------
Auteur : Fabber Resident (Fabrice TOUPET)
Mail : fabtoupet@gmail.com
Facebook : Fabrice TOUPET 

Descriptif : Ce script est la racine du projet c'est à partir d'elle que transite les communications entre les uatres scripte : 
Elle gère les droit en fonction des utilisateurs et le timer de la tip jar. 

Elle communique avec les autres script via des message link */

// ============================== Constantes =======================================
// Paramètre géneraux
integer debugActif = TRUE;
list param_admin = [];
integer param_limite = 160;

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
integer param_tipJar_limite = 300;
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
    return llSubStringIndex(data, "#") >= 0 ;
}

/* Permet d'extraire le coe */
string codeNoteCarte(string data)
{
    //TODO : Ajouter le système de lecture de la note carte 
}

/* Permet de lire les notes cartes */
lectureParam(string data)
{
    if (testNoteCarteCommentaire(data) == FALSE)

}

default
{
    state_entry()
    {
        if(testNotecarteValide(note_param)==TRUE)
            note_key_param = llGetNotecardLine(note_param, note_ligne);
    }
    dataserver( key id_notecart, string data )
    {
        //debug("dataserver", "Lacture de la ligne → " + data);

        // Lecture des paramètres 
        if (id_notecart == note_key_param)
        {
            if (data == EOF)
            {

            }
            else
            {
                note_ligne++;
                note_key_param = llGetNotecardLine(note_param, note_ligne);
            }
        }
    }
}
