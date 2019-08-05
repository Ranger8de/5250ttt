**free
// SQLRPGLE Service-Programme werden mit CRTSQLRPGI erstellt, z.B.:
 //  <CODE>
 // CRTSQLRPGI OBJ(PRSORGA1/ttt2_SRV) SRCFILE(PRSORGA1/QRPGLESRC)
 // SRCMBR(ttt2_SRV) OBJTYPE(*MODULE) OPTION(*EVENTF) REPLACE(*YES)
 // DBGVIEW(*SOURCE)
 //  </CODE>
 //
 // und m}ssen hinterher via CRTSRVPGM umgewandelt werden, z.B.:
 //  <CODE>
 //  CRTSRVPGM SRVPGM(prsorga1/ttt2_SRV) export(*all)
 //  </CODE>

 // Service-Programme haben IMMER nomain||
CTL-OPT NOMAIN;

DCL-PR QCMDEXC extpgm;
   Cmd char(250) options(*varsize) const;
   Length packed(15:5) const ;
END-PR;

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

///
// Title
// MyQCmdExc
// Description
// Ruft das QCMDEXC mit den richtigen Parametern auf
// $return
// <code>true</code> oder <code>false</code>
// je nachdem, ob der Aufruf erfolgreich war
///
DCL-PROC MyQCmdExc EXPORT;

   DCL-Pi *N ind ;
      cmdString char(256);
   END-PI;

   Monitor;
      callp QCMDEXC(%trim(cmdString):%len(%trim(cmdString)));
      return *On;
   On-ERROR;
      return *OFF;
   EndMon;

END-PROC MyQCmdExc;


///
// Title
// GetJobNo
// Description
// Ermittelt die aktuelle JobNummer (ben¦tigt die DS PSDS)
// @return
// Gibt die Nummer des aktuellen Jobs zurück
///
DCL-PROC GetJobNo EXPORT;

   DCL-Pi *N Zoned(6)

   END-PI;

   DCL-S JobNo Zoned(6) INZ(0);

   JobNo = pgm_stat.JobNo;

   Return JobNo;

END-PROC GetJobNo;



///
// <summary>
// Erstellt einen Datenbereich, indem ein zweiter Spieler spielen kann
// </summary>
// <returns>true oder false, ob die DTAQ erstellt werden konnte</returns>
///
DCL-PROC CreateDataQ EXPORT;

    DCL-PI *N Ind;
        DatQLib              char(10);
        DatQName             char(10);
        MaxDataQLength       zoned(5);
        User                 char(10)      OPTIONS(*NOPASS);
    END-PI;


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
DCL-PROC DropDataQ EXPORT;
    DCL-PI *N Ind;
       DatQLib              char(10);
       DatQName             char(10);
    END-PI;

    dcl-s cmdString char(256);

    cmdString = 'DLTDTAQ DTAQ('+ %trim(DatQLib) +'/'+ %trim(DatQName) + ')' ;

    Monitor;
       callp MyQCmdExc(cmdString);
       return *On;
    On-ERROR;
        return *OFF;
    EndMon;

END-PROC DropDataQ;

/// <summary>
// Ermittle Gewinner
/// </summary>
DCL-PROC Board_CheckWinner EXPORT;
 // bekommt den aktuellen Spieler und das Spielfeld
  DCL-PI *N ind;
    Turn Char(2) Const;
    Grid Char(2) Dim(9) Const;
  END-PI;

  // definiert ob der aktueller Spieler drei Elemente in einer Reihe hält
  Dcl-S lWinner Ind Inz(*Off);

  // Checke erste Reihe
  If (Grid(1) = Turn AND
      Grid(2) = Turn AND
      Grid(3) = Turn);
    lWinner = *On;

  // checke zweite Reihe
  ELSEIF (Grid(4) = Turn AND
          Grid(5) = Turn AND
          Grid(6) = Turn);
    lWinner = *On;

  // Checke dritte Reihe
  ELSEIF (Grid(7) = Turn AND
          Grid(8) = Turn AND
          Grid(9) = Turn);
    lWinner = *On;

  // Checke erste Spalte
  ELSEIF (Grid(1) = Turn AND
          Grid(4) = Turn AND
          Grid(7) = Turn);
    lWinner = *On;

  // Checke zweite Spalte
  ELSEIF (Grid(2) = Turn AND
          Grid(5) = Turn AND
          Grid(8) = Turn);
    lWinner = *On;

  // Checke dritte Spalte
  ELSEIF (Grid(3) = Turn AND
          Grid(6) = Turn AND
          Grid(9) = Turn);
    lWinner = *On;

  // Checke erste Diagonale
  ELSEIF (Grid(1) = Turn AND
          Grid(5) = Turn AND
          Grid(9) = Turn);
    lWinner = *On;

  // Checke zweite Diagonale
  ELSEIF (Grid(3) = Turn AND
          Grid(5) = Turn AND
          Grid(7) = Turn);
    lWinner = *On;
  ENDIF;

  return lWinner;

END-PROC Board_CheckWinner;

///
// <summary>
// Brett neu aufbauen
// </summary>
///
DCL-PROC Board_Reset EXPORT;

  DCL-PI *N Char(2) Dim(9);
    Grid Char(2) Dim(9);
  END-PI;

  Grid(1) = '1';
  Grid(2) = '2';
  Grid(3) = '3';
  Grid(4) = '4';
  Grid(5) = '5';
  Grid(6) = '6';
  Grid(7) = '7';
  Grid(8) = '8';
  Grid(9) = '9';

  Return Grid;

END-PROC Board_Reset;

///
//
///
Dcl-Proc Game_Turn EXPORT; //Current turn
    Dcl-Pi Game_Turn Char(2);
       Turn Char(2);
    END-PI;

    // Wenn der aktuelle Spieler X ist, wird O gesetzt
    If (Turn = Get_X());
        Turn = Get_O();
    Else;
        Turn = Get_X();
    ENDIF;

    Return Turn;

END-PROC Game_Turn;

///
// gibt die Parameter f}r Spieler X zur}ck
///
Dcl-Proc Get_X EXPORT; //Current turn
    DCL-PI Get_X Char(2);
    END-PI;

    Return  x'3A' + 'X';

END-PROC Get_X;

///
// gibt die Parameter f}r Spieler O zur}ck
///
Dcl-Proc Get_O EXPORT; //Current turn
    DCL-PI Get_O Char(2);
    END-PI;

    Return  x'28' + 'O';

END-PROC Get_O;

///
//  Pr}ft, ob die DataQ in der Bibliothek vorhanden ist
///
DCL-PROC CheckIfDataqExists EXPORT;
    DCL-PI CheckIfDataqExists ind;
       DatQLib              char(10);
       DatQName             char(10);
    END-PI;

    dcl-s cmdString char(256);

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
// Ermittelt einen Zufallszug f}r die Machine
///
DCL-PROC SetAiMove EXPORT;

  DCL-PI SetAiMove Char(2) Dim(9);
    Grid Char(2) Dim(9);
    Player Char(2) const;
  END-PI;

  DCL-S lIndex Int(3);
  DCL-S GetEmptyField Ind Inz(*ON);

  // Planlos über das Feld latschen und das nächste freie ermitteln
  DOW (GetEmptyField);
    EXEC SQL SELECT int(CEILING(RAND()* 9))
                    into :lIndex FROM sysibm/sysdummy1;

    // Ist das Feld leer, übernehmen wir es
    if (Grid(lIndex) = %char(lIndex));
        Grid(lIndex) = Player;

       GetEmptyField = *OFF;
    EndIf;

  ENDDO;

  RETURN Grid;

END-PROC SetAiMove;

///
//
///
DCL-PROC SaveGameResult EXPORT;

  DCL-PI SaveGameResult;
      i_ttt2      likeds(ttt2);
  END-PI;

  Exec Sql INSERT INTO TTT200 (
     TTGAME
     , TTPLR1
     , TTPNT1
     , TTPLR2
     , TTPNT2
     , TTTIME
    )

    Values (
     :i_ttt2.TTGAME
     , :i_ttt2.TTPLR1
     , :i_ttt2.TTPNT1
     , :i_ttt2.TTPLR2
     , :i_ttt2.TTPNT2
     , current timestamp
   )
  WITH NC;

END-PROC SaveGameResult;


