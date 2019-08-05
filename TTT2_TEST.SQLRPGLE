**free

// zuerst wird das 'Hauptmodul' ttt2 generiert: ACHTUNG OBJTYPE
//  <CODE>
// CRTSQLRPGI OBJ(PRSORGA1/TTT2_TEST) SRCFILE(PRSORGA1/QRPGLESRC)
// SRCMBR(TTT2_TEST) OBJTYPE(*MODULE) OPTION(*EVENTF) REPLACE(*YES)
// DBGVIEW(*SOURCE)
//  </CODE>

// dann wird das Programm ttt erstellt und das Service-Programm ttt_init eingebunden
//  <CODE>
// CRTPGM PGM(PRSORGA1/TTT2_TEST) BNDSRVPGM(TTT2_SRV) ACTGRP(*NEW)
//  </CODE>

CTL-OPT MAIN(main_pr);

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

DCL-PR Board_Reset Char(2) Dim(9);
  Grid Char(2) Dim(9);
END-PR;


DCL-PROC Main_pr;

  Test_Winner();


END-PROC Main_pr;

///
// Testet den Gewinner in den Standard-Situationen
///
DCL-PROC Test_Winner;

 // Definition f}r das Spielfeld
  DCL-S pGrid       Char(2) Dim(9);

  // Definition f}r den aktuellen Spieler
  DCL-S pX       Char(2);
  DCL-S pO       Char(2);

  pX = ' x';
  pO = ' o';

  // Spielplan zur}cksetzen
  pGrid = Board_Reset(pGrid);

  pGrid(1) = pX;
  pGrid(2) = pX;
  pGrid(3) = pX;

   DSPLY ('Spielplan :' + GridToString(pGrid));

  IF (Board_CheckWinner(pX:pGrid));
      DSPLY 'Test OK: Sieger ist x';
  ENDIF;

  IF (Board_CheckWinner(pO:pGrid));
       DSPLY 'Test nicht OK: Sieger ist x';
  ENDIF;


  // Spielplan zur}cksetzen
  pGrid = Board_Reset(pGrid);

  pGrid(1) = pX;
  pGrid(6) = pO;
  pGrid(4) = pX;
  pGrid(9) = pO;
  pGrid(7) = pX;

  DSPLY ('Spielplan :' + GridToString(pGrid));


  IF (Board_CheckWinner(pX:pGrid));
      DSPLY 'Test OK: Sieger ist x';
  ENDIF;

  IF (Board_CheckWinner(pO:pGrid));
       DSPLY 'Test nicht OK: Sieger ist x';
  ENDIF;

  // Spielplan zur}cksetzen
  pGrid = Board_Reset(pGrid);

  pGrid(9) = pX;
  pGrid(8) = pO;
  pGrid(1) = pX;
  pGrid(3) = pO;
  pGrid(5) = pX;

  DSPLY ('Spielplan :' + GridToString(pGrid));


  IF (Board_CheckWinner(pX:pGrid));
      DSPLY 'Test OK: Sieger ist x';
  ENDIF;

  IF (Board_CheckWinner(pO:pGrid));
       DSPLY 'Test nicht OK: Sieger ist x';
  ENDIF;


END-PROC Test_Winner;

///
// Wandelt das Spielgrid in einen String
///
DCL-PROC GridToString;

  DCL-PI GridToString varchar(30);
    pGrid     Char(2) Dim(9);
  END-PI;

  DCL-S index Int(3);
  DCL-S returnValue  varchar(30);

  FOR index = 1 TO 9;
      returnValue = returnValue + %char(pGrid(index));
      returnValue = returnValue + ';';
  ENDFOR;

   return returnValue;
END-PROC GridToString;
