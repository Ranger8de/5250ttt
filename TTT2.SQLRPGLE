**free
// Zuerst muss das Binderverzeichnis erstellt werde
// <code>
// CRTBNDDIR BNDDIR(PRSORGA1/TTTSRVPGM)
// </code>
// dann muss das SRV-Programm dem Binderverzeichnis hinzugef}ugt werden
// <code>
// ADDBNDDIRE BNDDIR(PRSORGA1/TTTSRVPGM) OBJ((PRSORGA1/TTT2_SRV *SRVPGM))
// </code>
// zuerst wird das 'Hauptmodul' ttt2 generiert: ACHTUNG OBJTYPE
//  <CODE>
// CRTSQLRPGI OBJ(PRSORGA1/TTT2) SRCFILE(PRSORGA1/QRPGLESRC)
// SRCMBR(TTT2) OBJTYPE(*MODULE) OPTION(*EVENTF) REPLACE(*YES)
// DBGVIEW(*SOURCE)
//  </CODE>

// dann wird das Programm ttt erstellt und das Service-Programm ttt_init eingebunden
//  <CODE>
// CRTPGM PGM(PRSORGA1/TTT2) BNDSRVPGM(TTT2_SRV) ACTGRP(*NEW)
//  </CODE>

// #Region Control-Options
    CTL-OPT MAIN(main_pr);        // Die Hauptprozedur wird mit main_pr festgelegt
    //CTL-OPT DFTACTGRP(*NO);       // es handelt sich um ein ILE Programm
    //CTL-OPT OPTION(*SRCSTMT);     // Die Zeilennummern werden im Format der Source zurückgegeben
    CTL-OPT DATFMT(*DMY);         // Datum wird im Tag-Monat-Jahr-Format angegeben
   // ctl-opt bnddir('TTTSRVPGM');    // Verweis auf das Binderverzeichnis
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
        Cmd char(250) const;
        Length packed(15:5) const ;
    END-PR;

///
// Title MyQCmdExc vereinfachung von QCMDEXC
///
 DCL-PR MyQCmdExc ind ;
  cmdString char(256);
 END-PR;


///
// Ermittelt die aktuelle Nummer des Jobs
///
DCL-PR GetJobNo Zoned(6) ;

END-PR;

///
// Erstellt eine DataQ mit angegebenen Parametern
///
DCL-PR CreateDataQ Ind;
    DatQLib              char(10);
    DatQName             char(10);
    MaxDataQLength       zoned(5);
    User                 char(10)      OPTIONS(*NOPASS);
END-PR;

///
// Title DropDataQ
// Description L¦scht die angegeben DataQ
///
DCL-PR DropDataQ Ind;
    DatQLib              char(10);
    DatQName             char(10);
END-PR;

///
// Title Board_CheckWinner
// Description Pr}ft, ob ein Soeg vorliegt
// $param Turn = der zu pr}fenden Spieler
// $param Grid = das zu }berpr}fende Spielfeld
///
DCL-PR Board_CheckWinner ind;
    Turn                 Char(2)        Const;
    Grid                 Char(2) Dim(9) Const;
END-PR;

///
//
///
DCL-PR CheckIfDataqExists ind;
   DatQLib           char(10);
   DatQName          char(10);
END-PR;

///
//  Setzt das Spielfeld auf die Ausgangswerte zur}ck
///
DCL-PR Board_Reset Char(2) Dim(9);
    Grid Char(2) Dim(9);
END-PR;

///
//
///
DCL-PR Game_Turn Char(2);
    Turn Char(2);
END-PR;

///
// Gibt das Zeichen f}r Spieler X zur}ck
///
DCL-PR Get_X Char(2);
END-PR;

///
// Gibt das Zeichen f}r Spieler O zur}ck
///
DCL-PR Get_O Char(2);
END-PR;

///
// Ermittelt einen Zufallszug f}r die Machine
///
DCL-PR SetAiMove Char(2) Dim(9);
    Grid Char(2) Dim(9);
    Player Char(2) const;
END-PR;

///
// Speichert den aktuellen Spielstand
///
DCL-PR SaveGameResult;
  ttt2 likeds(ttt2);
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

    DCL-S DatQLib     Char(10);
    DCL-S DatQName    Char(10);

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

    // TTT200 Spielergebnisse
    DCL-DS ttt2 EXT INZ(*EXTDFT) EXTNAME('TTT200');
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

      DCL-DS ttt20r likeds(ttt2);

        Init_Game();
        gGrid = Board_Reset(gGrid);
        Dow (gExit = *Off);
            RefreshScreen();


            // Wenn gegen die Machine gerspielt wird, und diese am Zug ist
            // gTurn entspricht dem Spieler der am Zug ist,
            // iam wird zu Spielbeginn festgelegt
            If (gTURN <> iam);
                IF (gAIT);
                    Text = 'wait for AI is moving...';
                 SetAiMove(gGrid:gTurn);
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
            WRITE MAIN;

            if (Board_CheckWinner(gTurn:gGrid));

                clear ttt20r ;
                ttt20r.TTGAME = 'TTT';
                ttt20r.TTPlr1 = namePlyrX;
                ttt20r.TTPlr2 = namePlyrO;

                If (gTurn = X);
                    totalWinX = totalWinX + 1;
                     ttt20r.TTPnt1 = 1;

                Else;
                    totalWinO = totalWinO + 1;
                    ttt20r.TTPnt2 = 1;
                ENDIF;

                SaveGameResult(ttt20r);
                 // Sieger-Nachricht festlegen
                WINTEXT = gTurn + ' is the winner.';

                // Nachricht einblenen & Spielplan zurücksetzen
                EXFMT WIN;
                Board_Reset(gGrid);
            ENDIF;

            Board_CheckNoWin();

            gTurn = Game_Turn(gTurn);         //Switch turn

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

        Board_GridUpdate();

    END-PROC RefreshScreen;

    ///
    // <summary>
    // Beendet das Spiel
    // </summary>
    ///
    DCL-PROC EndGame;
        // Kommunikations-Datenbereich entfernen
        DropDataQ(DatQLib:DatQName);

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
        X = Get_X();
        // ein O ist rot
        O = Get_O();

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
        iam = X;
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
                    CreateDataQ(DatQLib:DatQName:maxDataQLength);
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

                 IF (CheckIfDataqExists(DatQLib:DatQName));

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
            ENDSL;
        ENDDO;

    END-PROC SetGameModus;

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



    END-PROC Board_GridUpdate;

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
            pTurn         Char(2) Const;
            pAI           Ind     Const;
        END-PI;

        DCL-DS tempDs likeds(GameStructure) INZ;
        DCL-S  lExit      Ind;
        DCL-S  lValid     Ind;
        DCL-S  lIndex     Int(3);


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

            // Eingabefeld aufr{umen
            POS = ' ';

            // Sende GameStructure an Dataq, sofern kein AI-Gegner
            if (gAIT = *OFF);
                 tempDs.g_id = GameId;

                 For lIndex = 1 to 9;
                     tempDs.g_Board(lIndex) = gGrid(lIndex);
                 ENDFOR;
                 SendDataQ(DatQName:DatQLib:maxDataQLength:tempDs);
          ENDIF;
    END-PROC Board_Turn;

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
              gGrid = Board_Reset(gGrid);
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
