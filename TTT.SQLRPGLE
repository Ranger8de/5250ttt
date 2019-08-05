**free
// zuerst wird das 'Hauptmodul' ttt generiert
//  <CODE>
// crtrpgmod module(prsorga1/ttt) dbgview(*source) srcfile(prsorga1/qrpglesrc)
//  </CODE>

// dann wird das Programm ttt erstellt und das Service-Programm ttt_init eingebunden
//  <CODE>
// CRTPGM PGM(PRSORGA1/TTT) BNDSRVPGM(TTT_INIT) ACTGRP(*NEW)
//  </CODE>

// #Region Control-Options
    CTL-OPT MAIN(main_pr);        // Die Hauptprozedur wird mit main_pr festgelegt
    CTL-OPT DFTACTGRP(*NO);       // es handelt sich um ein ILE Programm
    //CTL-OPT OPTION(*SRCSTMT);     // Die Zeilennummern werden im Format der Source zurückgegeben
    CTL-OPT DATFMT(*DMY);         // Datum wird im Tag-Monat-Jahr-Format angegeben
// #EndRegion Control-Options

// #Region External Procedure Prototypes
    ///
    // Title
    // QCMDEXC
    // Description
    // Aufruf der QCMDEXC-API, zum Absetzen von allgemeinen CMD calls
    // @param  der auszuführende Command
    // @param  Länge der Zeichenkete des Commands
    ///
    DCL-PR QCMDEXC extpgm;
        Cmd char(250) options(*varsize) const;
        Length packed(15:5) const ;
    END-PR;

    ///
    // Title
    // SendDataQ
    // Description
    // Aufruf der QSNDDTAQ-API, zum Schreiben von Daten in eine DataQ
    //  @param Bibliothek der DataQ
    // @param Name der DataQ
    // @param Länge des DataQ IOnhalts
    // @param DataQ Inhalt
    ///
    DCL-PR SendDataQ extpgm('QSNDDTAQ');
        QName char(10) options(*varsize) const;
        QLib char(10) options(*varsize) const;
        DtaLength packed(5:0) const ;
        Data char(65000) Options(*varsize);
    END-PR;

    ///
    // Title
    // GetDataQ
    // Description
    // Aufruf der QRCVDTAQ-API, zum Lesen von Daten aus einer DataQ
    // @param Bibliothek der DataQ
    // @param Name der DataQ
    // @param Länge des DataQ IOnhalts
    // @param DataQ Inhalt
    // @param Timeout: kleiner 0 = unendlich warten; 0 = nicht warten,
    // größer 0 warten in Sekunden
    ///
    DCL-PR GetDataQ extpgm('QRCVDTAQ');
        QName char(10) options(*varsize) const;
        QLib char(10) options(*varsize) const;
        DtaLength packed(5:0) const ;
        Data char(65000) Options(*varsize);
        WaitTime packed(5:0) const ;
    END-PR;

// #EndRegion External Procedure Prototypes


// #Region Global Variables
    // Variable für ein X
    DCL-S X Char(2);
    // Variable für ein O
    DCL-S O like(X);

    DCL-S iam like(X);

    DCL-S maxDataQLength zoned(5) inz(64512);

    DCL-S DatQLib     VarChar(10);
    DCL-S DatQName    VarChar(10);

    // Anzahl Gesamt-Siege für X und O
    DCL-S namePlyrX   Char(15);
    DCL-S namePlyrO   like(namePlyrX);

    // Anzahl Gesamt-Siege für X und O
    DCL-S totalWinX   Int(3);
    DCL-S totalWinO   like (totalWinX);

    // Definition für die Tabelle
    DCL-S gGrid       Char(2) Dim(9);

    // Definition des aktuellen Zuges
    DCL-S gTurn       Char(2);

    // Ausstiegsvariable
    DCL-S gExit       Ind;

    // AI oponent?
    DCL-S gAIT        Ind;

    // SpielId
    DCL-s GameId      Zoned(6);

    // Datenstuktur für Gesamtablauf
    DCL-DS GameStructure QUALIFIED INZ;
        // Spiel-ID für DTAARA Zugriff
        g_id          like (GameId);
        // Spieler 1
        g_PlayerX     likeds(PlayerInfo)  Dim(1) INZ;
        // Spieler 2
        g_PlayerO     likeds(PlayerInfo)  Dim(1) INZ;
        // der eigentliche Spielplan
        g_Board       Char(2)             Dim(9);
    END-DS GameStructure;

    // Datenstruktur für einen Spieler
    DCL-DS PlayerInfo QUALIFIED INZ;
        P_Tag         like(X);
        p_Name        like(namePlyrX);
        p_TotalWins   like(totalWinX);
    END-DS PlayerInfo;

    // Programm-Status Datenstruktur
    DCL-DS pgm_stat PSDS QUALIFIED;
        status        *STATUS;
        routine       *ROUTINE;
        library       Char(10) POS(81);
        user          Char(10) Pos(358);
        JobNo         Zoned(6) Pos(264);
    END-DS;

    // Definition der Displayfile
    DCL-F TTTDSP      Workstn;
// #EndRegion Global Variables


// #Region Procedures
    ///
    // Title
    // Haupt-Prozedur
    // Description
    // stellt die Haupteinstiegs-Prozedur dar
    ///
    DCL-PROC Main_pr;
        Init_Game();
        Board_Reset();
        Dow (gExit = *Off);
            RefreshScreen();


            // Wenn gegen die Machine gerspielt wird, und diese am Zug ist
            // gTurn entspricht dem Spieler der am Zug ist,
            // iam wird zu Spielbeginn festgelegt
            If (gTURN <> iam);
                IF (gAIT);
                    Text = 'wait for AI is moving...';
                 SetAiMove();
                 ELSE;
                     Text = 'wait for Opponent is moving...';
                     // Warte auf DTAQ
                     WaitForPlayerToMove();
                ENDIF;
            //  Ansonsten manuelle Eingabe
            ELSE;
                Board_Turn(gTurn:gAIT);
            ENDIF;



            Board_GridUpdate();
            Board_CheckWinner(gTurn);
            Board_CheckNoWin();

            Game_Turn();         //Switch turn

        ENDDO;

        EndGame();

        Return;
     END-PROC Main_pr;


    ///
    // <summary>
    // Bildschirm aktualisieren
    // </summary>
    ///
    DCL-PROC RefreshScreen;
        // Aktuelle Zeit
        TTIME = %XLATE('.' : ':' : %char(%time()));
        TDATE = %XLATE('/' : '.' : %char(%date() : *DMY));

        // Spielstand
        TWINX = %CHAR(totalWinX);
        TWINO = %CHAR(totalWinO);

        // Spielernamen
        NAME1 = namePlyrX;
        NAME2 = namePlyrO;

    END-PROC RefreshScreen;

    ///
    // <summary>
    // Beendet das Spiel
    // </summary>
    ///
    DCL-PROC EndGame;
        // Kommunikations-Datenbereich entfernen
        DropDataQ();

        // Zugriffe schiließen
        // Close TTTDSP;
        Close *all;

        // In last Record setzen
        *InLR = *On;
    END-PROC EndGame;

    ///
    // Title
    // Init_Game
    // Description
    // initialisiert das Spiel in bezug auf 1/2 Spieler
    // </summary>
    ///
    DCL-PROC Init_Game;
        // Die verwendete GameID ist die Nummer des Jobs
        GameId = GetJobNo();
        // Die Bibliothek der DtaQ ist fix
        DatQLib = 'PRSORGA1';
        // der Name der DtaQ lautet TTT + die Nummer des Jobs
        DatQName = 'TTT' + %trim(%char(GameId));

        // ein x ist blau
        X = x'3A' + 'X';
        // ein O ist rot
        O = x'28' + 'O';

        // initialer Spielstand lautet 0:0
        totalWinX = 0;
        totalWinO = 0;

        // X beginnt das Spiel
        gTurn = X;
        gExit = *Off;

        // Spielmodus festlegen
        SetGameModus();

        // Name des ersten Spielers stammt aus der pgm_DS
        namePlyrX = pgm_stat.User;
    END-PROC Init_Game;

    ///
    // <summary>
    // Ein Spieler Spiel initialisieren
    // </summary>
    ///
    DCL-PROC Init_Game_1Player;
        // Ein Spieler spielt immer gegen die Machine
        gAIT = *ON;
        namePlyrO = GetMachineName();
    END-PROC Init_Game_1Player;

    ///
    // <summary>
    // Zwei Spieler Spiel initialisieren
    // </summary>
    ///
    DCL-PROC Init_Game_2Player;

        DCL-S  gameModChoosen  ind inz(*off);
        DCL-S  tempGameID      zoned (6);
        DCL-DS struct          likeds(GameStructure);
        DCL-DS PlayerStruct    likeds(PlayerInfo);

        // Zwei Spieler spielt immer gegen einen Menschen
        gAIT = *OFF;

        // Solange loopen, bis der Richtige Wert ausgewählt wurde
        dow (gameModChoosen = *off);

            // Chooser einblenden
            CH_ROW1 = '     CCC         JJJJ';
            CH_ROW2 = '    C   C           J';
            CH_ROW3 = '    C               J';
            CH_ROW4 = '    C   C       J   J';
            CH_ROW5 = '     CCC         JJJ ';
            CH_ROW6 = ' F1=Create   F2=Join';
            ExFmt CHOOSER;

            Select;
                // F1 gedrückt, DataQ erstellen und warten
                When (*In01);
                    CreateDataQ();
                    WaitForPlayerToJoin();
                    gameModChoosen = *ON;
                    iam = X;
                //F2 gedrückt,
                When (*In02);
                    tempGameID =  InputGameId();
                   if (tempGameID > 0);
                        GameId = tempGameID;
                        DatQName = 'TTT' + %char(tempGameID);
                        struct.g_id = GameId;
                        PlayerStruct.P_NAME = pgm_stat.user;
                        struct.g_PlayerO = PlayerStruct;

                        iam = O;

                        SendDataQ(%trim(DatQName):%trim(DatQLib):maxDataQLength:struct);
                   ELSE;
                        *inlr = *ON;
                   EndIf;

                   gameModChoosen = *ON;
            ENDSL;
        ENDDO;
    END-PROC Init_Game_2Player;

    ///
    // titel
    // WaitForPlayerToMove
    // Description
    // Wartet auf eine Interaktion mit der erstellten DataQ
    // @author PRSORGA
    // @Date 16.07.2019
    ///
    DCL-PROC WaitForPlayerToMove;
        // Variable, die den Erhalt das DatQ-Inhalts darstellt
        DCL-S DtaqContent IND INZ(*OFF);
        DCL-S dataOut char(64512);
        Dcl-S lIndex Int(3);
        DCL-DS tempGameStruct likeds(GameStructure) INZ;
        DCL-DS tempPlayerOInfo likeds(PLayerInfo) INZ;

        // Solange Loopen, bis ein Inhalt angekommen ist
        DOW (DtaqContent = *OFF);
            GetDataQ(%trim(DatQName):%trim(DatQLib):maxDataQLength:dataOut:2);

            if (%trim(dataOut) <> *blank);
                // User hast joind
                tempGameStruct = dataOut;
                tempPlayerOInfo = tempGameStruct.g_PlayerO(1);
                namePlyrO = tempPlayerOInfo.p_name;

                 For lIndex = 1 to 9;
                     gGrid(lIndex) = tempGameStruct.g_Board(lIndex);
                 ENDFOR;

                DtaqContent = *ON;

            EndIf;

        ENDDO;


    END-PROC WaitForPlayerToMove;

    ///
    // <summary>
    // Zeigt ein Window, in dem die GameId eines bestehenden Spiels
    // eingetragen werden muss
    // </summary>
    // <returns>Gültige, vorhandene GameId</returns>
    ///
    DCL-PROC InputGameId;
        DCL-PI *N zoned(6);
        END-PI;

        dcl-s JobNo zoned(6);
        dcl-s validId ind inz(*off);

        // Solange loopen, bis eine gültige ID eingegeben wurde
        dow (validId = *off);

            // Eingabemöglichkeit anzeigen
            EXFMT INPID;
            GIDTEXT = 'Please input the ID:';

            Select;
                When (*In03); //F3 = Exit
                    JobNo = -1;
                OTHER;
                    Monitor;
                        JobNo = %DEC(GID:6:0);
                        // ValidId setzen um Schleife zu verlessen
                    On-ERROR;
                        iter;
                    Endmon;

                 IF (CheckIfDataqExists());
                    validId = *ON;
                 ELSE;

                 ENDIF;
            ENDSL;
        ENDDO;

        return JobNo;
    END-PROC InputGameId;

    ///
    // <summary>
    // Prüft, ob der Eingabewert ein numerischer Wert ist
    // </summary>
    // <returns>true wenn der Eingabewert numerisch ist<returns>
    ///
    DCL-PROC IsNumeric;
    DCL-PI *n IND;
        MyField       char(1000)    Options(*varsize);
    END-PI;

    DCL-S Numbers     char(10)      Inz('0123456789');
    DCL-S ReturnValue IND           INZ(*OFF);

    If (%check(Numbers:%trim(MyField)) > 0);
        ReturnValue = *OFF; // it has non-numerics in it
    ELSE;
        ReturnValue = *ON; // everything is numeric #huzzah!
    EndIf;

    return ReturnValue;
    END-PROC IsNumeric;

    ///
    // <summary>
    // Prüft, ob die erforderliche DataQueue vorhanden ist
    // </summary>
    ///
    DCL-PROC CheckIfDataqExists;
        DCL-PI *N ind;
        END-PI;

        dcl-s cmdString char(256);
        // CHKOBJ OBJ(*LIB/*OBJ) OBJTYPE(*DTAQ)
        cmdString = 'CHKOBJ OBJ(' + %trim(DatQLib) + '/' + %trim(DatQName) +
                    ') OBJTYPE(*DTAQ)' ;

        Monitor;
            callp MyQCmdExc(cmdString);
            return *On;
        On-ERROR;
            return *OFF;
        EndMon;
    END-PROC CheckIfDataqExists;

    ///
    // <summary>
    // Wartet darauf, dass ein zweiter User das Spiel betritt
    // </summary>
    ///
    DCL-PROC WaitForPlayerToJoin;
        DCL-S UserHasJoind Ind inz(*off);
        dcl-s dataOut char(1000) Inz(*blank);
        DCL-DS tempGameStruct likeds(GameStructure) INZ;
        DCL-DS tempPlayerOInfo likeds(PLayerInfo) INZ;

        Text = 'Wait for User to join...';
        Write INPID;

        GIDTEXT = 'Wait for User to join your game...';
        //GID     = x'A0' + %char(GetJobNo());
        GID     = %char(GameId);
        Write INPID;

        // Die Datenstruktur, wird erst durch den zweiten Spieler gefüllt
        // deswegen wird die Schleife solange durchlaufen, bis ein Wert ermittelt werden kann

        dow (UserHasJoind = *off);
             Text = 'Wait for User to join your game...';
            Write INPID;
            // DataQ wird gelesen und nach Sekunden verlassen
            GetDataQ(%trim(DatQName):%trim(DatQLib):maxDataQLength:dataOut:2);

            if (%trim(dataOut) <> *blank);
                // User hast joind
                tempGameStruct = dataOut;
                tempPlayerOInfo = tempGameStruct.g_PlayerO(1);
                namePlyrO = tempPlayerOInfo.p_name;
                //namePlyrO = tempGameStruct.g_PlayerO(1).p_name;
                UserHasJoind = *ON;

            EndIf;


            If (*in03);
                *inlr = *on;
            EndIf;
        EndDo;


    END-PROC WaitForPlayerToJoin;

    ///
    // <summary>
    // Schreibt einen Test-Eintrag in die Dataqueue
    // </summary>
    ///
    DCL-PROC WriteTestDataQ;
         //Todo SChreibe DTAq
         dcl-s dataIn char(100);
         dcl-s dataOut char(100);

         dataIn = 'Hallo Welt]';

         callp GetDataQ(%trim(DatQName):%trim(DatQLib):maxDataQLength:dataOut:3);

         callp SendDataQ(%trim(DatQName):%trim(DatQLib):maxDataQLength:dataIn);

         callp GetDataQ(%trim(DatQName):%trim(DatQLib):maxDataQLength:dataOut:3);

    END-PROC WriteTestDataQ;

    ///
    // <summary>
    // Stellt den Spielmodus ein (1/2 Spieler)
    // </summary>
    ///
    DCL-PROC SetGameModus;
        dcl-s gameModChoosen ind inz(*off);

        // Solange loopen, bis der Richtige Wert ausgewählt wurde
        dow (gameModChoosen = *off);

            // Window einblenden

            CH_ROW1 = '      1          222 ';
            CH_ROW2 = '     11         2   2';
            CH_ROW3 = '    1 1            2 ';
            CH_ROW4 = '      1           2  ';
            CH_ROW5 = '    11111       22222';
            CH_ROW6 = ' F1=1 Player  F2=2 Player';
            ExFmt CHOOSER;

            Select;
                When (*In01); //F1
                    //dsply 'F1 gedrückt';
                    gameModChoosen = *on;
                    Init_Game_1Player();
                When (*In02); //F2
                    //dsply 'F2 gedrückt';
                    gameModChoosen = *on;
                    Init_Game_2Player();
                OTHER;
                    // Enter: hier muss geloopt werden!
                    //dsply 'etwas anderes als F1 oder F2 wurde gedrückt!';
            ENDSL;
        ENDDO;

    END-PROC SetGameModus;

    ///
    // <summary>
    // Erstellt einen Datenbereich, indem ein zweiter Spieler spielen kann
    // </summary>
    // <returns>true oder false, ob die DTAQ erstellt werden konnte</returns>
    ///
    DCL-PROC CreateDataQ;
        DCL-PI *N Ind;
        END-PI;
        // Im Interface soll die Zufallszahl übergeben werden
        dcl-s cmdString char(256);

        cmdString = 'CRTDTAQ DTAQ(' + %trim(DatQLib) + '/' + %trim(DatQName) +
                    ') MAXLEN(' + %char(maxDataQLength) +
                    ') TEXT(''TTT DtaQ zum DatenAustausch'')';

        Monitor;
            callp MyQCmdExc(cmdString);
            return *On;
        On-ERROR;
            return *OFF;
        EndMon;

    END-PROC CreateDataQ;

    ///
    // Title
    // DropDataQ
    // Description
    // Erstellt einen Datenbereich, indem ein zweiter Spieler spielen kann
    // @return
    // <code>true</code> oder <code>false</code>,
    // ob die DTAQ gelöscht werden konnte</returns>
    ///
    DCL-PROC DropDataQ;
        DCL-PI *N Ind;
        END-PI;

        dcl-s cmdString char(256);

        cmdString = 'DLTDTAQ DTAQ(*CURLIB/'+ %trim(DatQName) + ')' ;

        Monitor;
            callp MyQCmdExc(cmdString);
            return *On;
        On-ERROR;
            return *OFF;
        EndMon;

    END-PROC DropDataQ;

    ///
    // <summary>
    // Ermittelt ein Zufallszahl
    // </summary>
    ///
    DCL-PROC GetRandomInt;
        DCL-Pi *N Zoned(6)
        End-Pi;

         DCL-S randInt Zoned(6) INZ(1);

         EXEC SQL SELECT int(CEILING(RAND()* 278564))
                    into :randInt FROM sysibm/sysdummy1;

         Return randInt;
     END-PROC GetRandomInt;

    ///
    // Title
    // GetJobNo
    // Description
    // Ermittelt die aktuelle JobNummer
    // @return
    // Gibt die Nummer des aktuellen Jobs zurück
    ///
    DCL-PROC GetJobNo;
        DCL-Pi *N Zoned(6)
        End-Pi;

         DCL-S JobNo Zoned(6) INZ(0);

         JobNo = pgm_stat.JobNo;

         Return JobNo;
     END-PROC GetJobNo;

    ///
    // Title
    // MyQCmdExc
    // Description
    // Ruft das QCMDEXC mit den richtigen Parametern auf
    // @return
    // <code>true</code> oder <code>false</code>
    // je nachdem, ob der Aufruf erfolgreich war
    ///
    DCL-PROC MyQCmdExc;
        DCL-Pi *N ind ;
            cmdString char(256);
        End-Pi;

        Monitor;
            callp QCMDEXC(%trim(cmdString):%len(%trim(cmdString)));
            return *On;
        On-ERROR;
            return *OFF;
        EndMon;
    END-PROC MyQCmdExc;

    ///
    // <summary>
    // Eingabe des jeweiligen Spielers
    // </summary>
    ///
    Dcl-Proc Input_Names;
        Dcl-Pi *N EXTPROC(*DCLCASE);
            pPlayer Char(2); // Player
            pPlayerName Char(15); // Name
        End-Pi;

        clear PLYRNAM;
        PLYRTXT = 'Plz input Player ' + %SUBST(pPlayer:2:1) + ' name:';

        EXFMT NAME;
        pPlayerName = PLYRNAM;

    END-PROC Input_Names;

    ///
    // <summary>
    // Brett neu aufbauen
    // </summary>
    ///
    Dcl-Proc Board_Reset;
        gGrid(1) = '1';
        gGrid(2) = '2';
        gGrid(3) = '3';
        gGrid(4) = '4';
        gGrid(5) = '5';
        gGrid(6) = '6';
        gGrid(7) = '7';
        gGrid(8) = '8';
        gGrid(9) = '9';

        Board_GridUpdate();
    END-PROC Board_Reset;

    ///
    // <summary>
    // Brett aktualisieren
    // </summary>
    ///
    Dcl-Proc Board_GridUpdate;
        P1 = gGrid(1);
        P2 = gGrid(2);
        P3 = gGrid(3);
        P4 = gGrid(4);
        P5 = gGrid(5);
        P6 = gGrid(6);
        P7 = gGrid(7);
        P8 = gGrid(8);
        P9 = gGrid(9);

        POS = ' ';

    END-PROC Board_GridUpdate;

    ///
    // <summary>
    // Spieler für Zug ermitteln
    // </summary>
    ///
    Dcl-Proc Game_Turn; //Current turn
        Dcl-Pi *N Char(2)
        End-Pi;

        // Wenn der aktuelle Spieler X ist, wird O gesetzt
        If (gTurn = X);
            gTurn = O;
        Else;
            gTurn = X;
        ENDIF;

        Return gTurn;

    END-PROC Game_Turn;

    ///
    // Title
    //
    // Description
    // Spieler für Zug ermitteln
    //
    // @param Stellt den Spierler dar der an der Reihe ist
    // @param Indicates wether the opponent is the machine
    ///
    Dcl-Proc Board_Turn; //Player move

        Dcl-Pi Board_Turn;
            pTurn Char(2) Const;
            pAI   Ind     Const;
        END-PI;

         DCL-DS tempDs likeds(GameStructure) INZ;
        Dcl-S lExit  Ind;
        Dcl-S lValid Ind;
        Dcl-S lIndex Int(3);


        lExit = *Off;

        TEXT = pTurn + ' to move.';

            Dow (lExit = *Off);
                EXFMT Main;
                RefreshScreen();

                Select;
                    When (*In03); //F3
                       gExit = *On;
                       lExit = *On;
                   When (*In07); //F7
                        JoinExternalGame();
                     Other; //Enter
                Monitor;
                    lIndex = %Int(POS);

                    lValid = (gGrid(lIndex) <> X AND
                              gGrid(lIndex) <> O);

                    If (lValid);
                        gGrid(lIndex) = pTurn;
                        lExit = *On;
                    Else;
                        TEXT = 'Please valid space.';
                    ENDIF;

                    On-Error;
                        TEXT = 'Please enter 1-9.';
                ENDMON;

                ENDSL;
            Enddo;

            // Sende GameStructure an Dataq, sofern kein AI-Gegner
            if (gAIT = *OFF);
                 tempDs.g_id = GameId;

                 For lIndex = 1 to 9;
                     tempDs.g_Board(lIndex) = gGrid(lIndex);
                 ENDFOR;
                 SendDataQ(DatQName:DatQLib:maxDataQLength:tempDs);
          ENDIF;
    END-PROC Board_Turn;

    ///
    // <summary>
    // Anhand einer Spiel-ID soll ein entferntes Spiel gespielt werden.
    // </summary>
    ///
    DCL-PROC JoinExternalGame;

    END-PROC JoinExternalGame;

    // <summary>
    // Setzt einen Spielzug
    // </summary>
    DCL-PROC SetAiMove;
        // ToDo: Algorhythmus zum setzen eines AI Zugs implementieren
        Dcl-S lIndex Int(3);
        Dcl-S GetEmptyField Ind Inz(*ON);

        // Planlos über das Feld latschen und das nächste freie ermitteln
        DOW (GetEmptyField);
            EXEC SQL SELECT int(CEILING(RAND()* 9))
                    into :lIndex FROM sysibm/sysdummy1;

            // Ist das Feld leer, übernehmen wir es
            if (gGrid(lIndex) = %char(lIndex));
                gGrid(lIndex) = O;

                GetEmptyField = *OFF;
            EndIf;

        ENDDO;
        Board_GridUpdate();
        Write Main;

    END-PROC SetAiMove;

    // <summary>
    // Ermittle Gewinner
    // </summary>
    DCL-PROC Board_CheckWinner;
          // Übergibt den aktuellen Spieler
        DCL-PI *N;
            pTurn Char(2) Const;
        END-PI;

        // definiert ob der aktueller Spieler drei Elemente in einer Reihe hält
        Dcl-S lWinner Ind Inz(*Off);

        // Checke erste Reihe
        If (gGrid(1) = pTurn AND
            gGrid(2) = pTurn AND
            gGrid(3) = pTurn);
            lWinner = *On;

        // checke zweite Reihe
        ELSEIF (gGrid(4) = pTurn AND
                gGrid(5) = pTurn AND
                gGrid(6) = pTurn);
            lWinner = *On;

        // Checke dritte Reihe
        ELSEIF (gGrid(7) = pTurn AND
                gGrid(8) = pTurn AND
                gGrid(9) = pTurn);
            lWinner = *On;

         // Checke erste Spalte
         ELSEIF (gGrid(1) = pTurn AND
                 gGrid(4) = pTurn AND
                 gGrid(7) = pTurn);
            lWinner = *On;

        // Checke zweite Spalte
        ELSEIF (gGrid(2) = pTurn AND
                gGrid(5) = pTurn AND
                gGrid(8) = pTurn);
            lWinner = *On;

        // Checke dritte Spalte
        ELSEIF (gGrid(3) = pTurn AND
                gGrid(6) = pTurn AND
                gGrid(9) = pTurn);
            lWinner = *On;

        // Checke erste Diagonale
        ELSEIF (gGrid(1) = pTurn AND
                gGrid(5) = pTurn AND
                gGrid(9) = pTurn);
            lWinner = *On;

        // Checke zweite Diagonale
        ELSEIF (gGrid(3) = pTurn AND
                gGrid(5) = pTurn AND
                gGrid(7) = pTurn);
            lWinner = *On;
        ENDIF;

        // Prüfen, ob ein Sie vorliegt
        If (lWinner = *On);
            // Sieger-Nachricht festlegen
            WINTEXT = pTurn + ' is the winner.';

            If (gTurn = X);
                totalWinX = totalWinX + 1;
            Else;
                totalWinO = totalWinO + 1;
            ENDIF;

            // Nachricht einblenen & Spielplan zurücksetzen
            EXFMT WIN;
            Board_Reset();
        ENDIF;
    END-PROC Board_CheckWinner;

    //<summary>
    // Prüfe auf Kein Sieg
    //</summary>
    DCL-PROC Board_CheckNoWin;

        Dcl-S lReset Ind;
        Dcl-S lIndex Int(3);

        lReset = *On;

        For lIndex = 1 to 9;
            If (gGrid(lIndex) = %Char(lIndex));
                lReset = *Off;
            ENDIF;
        ENDFOR;

        If (lReset);
               Board_Reset();
        ENDIF;
    END-PROC Board_CheckNoWin;

    // <summary>
    // Ermittelt den aktuellen Machinen-Namen
    // </summary>
    DCL-PROC GetMachineName;
        DCL-Pi *N Char(10)
        End-Pi;

         DCL-S machName Char(10) INZ('AI');

         EXEC SQL SELECT current server
                    into :machName FROM sysibm/sysdummy1;

         Return machName;

    END-PROC GetMachineName;
// #EndRegion Procedures
