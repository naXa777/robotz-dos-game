program RoboGame;

uses Graph, Crt, DOS;
const FacWidth = 11; FacHeigth = 18; { ширина и высота поля }
      ShansO = 500; ShansP = 12; ShansNewP = 22; { базовые шансы генерации ям и роботов }
      MaxWait = 5; Hearts = 3; { максимальное количество пропусков хода и количество жизней }
var  FieldOfWar: array [ 1..FacHeigth, 1..FacWidth ] of SmallInt;
        { Игровое поле: 0 - яма, 1 - ничего, 2 - робот }
     PlayerX, PlayerY, ExitX, ExitY, { координаты игрока и выхода }
     Armor, Level, Lives { текущие значения боеприпасов, уровня и жизней }: SmallInt;
     Pts: Integer; { очки }
     GameOver, { нужно ли закончить игру? }
     Loaded, { TRUE, если только что была загружено сохранение }
     Legend { показывается ли красивая подсказка с расшифровкой символов }: Boolean;
     countSMS, countWait: Byte; { счётчики СМС и пропусков хода }
     Win: ShortInt; { 1 - выиграл, можно идти на следующий уровень,
                     -1 - проиграл. В начале игры Win = 0 }

function IntToStr( I: Integer ): String;
        { Преобразовывает значение типа Integer в строку }
Var S : String [ 11 ];
Begin
        Str( I, S );
        IntToStr := S
End;

procedure Boom( i, j: SmallInt );
	{ Анимация небольшого взрыва в клетке [ i, j ] }
Var x, y: Integer;
Begin
        x := 100 + j * 10 - 6;
        y := 100 + i * 10 - 6;
        SetColor( yellow );
        SetFillStyle( 1, red );
        FillEllipse( x, y, 2, 2 );
        Delay( 10 );
        FillEllipse( x, y, 4, 4 );
        Delay( 10 );
        SetFillStyle( 1, black );
        FillEllipse( x, y, 4, 4 );
        SetFillStyle( 1, red );
        FillEllipse( x, y, 2, 2 );
        Delay( 10 );
        SetFillStyle( 1, black );
        FillEllipse( x, y, 5, 5 );
        SetColor( White );
        OutTextXY( x - 4, y - 4, '.' );
        Delay( 10 )
End;

procedure Load;
	{ Загружает сохранёнку }
Var  F: Text; S: String;
Begin
        Assign( F, 'C:\Documents and Settings\save.sss' );
        Reset( F );

        ReadLn( F, Level );
        ReadLn( F, Lives );
        ReadLn( F, Pts );
        ReadLn( F, countSMS );

        Close( F );
        Loaded := TRUE
End;

procedure Save;
	{ Сохраняет игру }
Var  F: Text;
Begin
        Assign( F, 'C:\Documents and Settings\save.sss' );
        Rewrite( F );
        Append( F );

        WriteLn( F, Level );
        WriteLn( F, Lives );
        WriteLn( F, Pts );
        WriteLn( F, countSMS );

        Close( F )
End;

procedure Redraw;
        { Обновляет картинку на экране }
Var  i, j, X, Y: Integer;
Begin
        SetFillStyle( 1, black );
        Bar( 80, 0, FacWidth * 10 + 330, 100 + FacHeigth * 10 );
        SetColor( Red );
        for i := 1 to Lives do
        begin
                OutTextXY( 90 + i * 10, 70, chr( 3 ) );
                PutPixel( 91 + i * 10, 71, White )
        end;
        SetColor( White );
        OutTextXY( 100, 40, 'ypoBeHb: ' + IntToStr( Level ) );
        if Armor < 2 then
                SetColor( Red );
        OutTextXY( 100, 50, '6oenpunacbI: ' + IntToStr( Armor ) );
        SetColor( White );
        OutTextXY( 100, 60, 'o4Ku: ' + IntToStr( Pts ) );
        X := 100; Y := 100;
        for i := 1 to FacHeigth do
        begin
                for j := 1 to FacWidth do
                begin
                        if ( PlayerX = j ) and ( PlayerY = i ) then
                        begin
                                SetColor( Yellow );
                                OutTextXY( X, Y, chr( 12 ) );
                                SetColor( White )
                        end
                        else if FieldOfWar[ i, j ] = 2 then
                        begin
                                SetColor( Red );
                                OutTextXY( X, Y, 'P' );
                                SetColor( White )
                        end
                        else if ( ExitX = j ) and ( ExitY = i ) then
                        begin
                                SetColor( Green );
                                OutTextXY( X, Y, '+' );
                                SetColor( White )
                        end
                        else if FieldOfWar[ i, j ] = 0 then
                                OutTextXY( X, Y, 'O' )
                        else
                                OutTextXY( X, Y, '.' );

                        inc( X, 10 )
                end;
                inc( Y, 10 );
                X := 100
        end
End;

procedure MoveRobots;
	{ двигает роботов и проверяет их столкновения }
Var i, j, BBepx, BHu3, BLeBo, BnpaBo, count: SmallInt;
    MoveBuff: array [ 1..FacHeigth * FacWidth - 2, 1..2 ] of SmallInt;
    { В этом массиве хранятся новые координаты всех роботов }
Begin
        count := 1; { счётчик роботов }
        for i := 1 to FacHeigth do
                for j := 1 to FacWidth do
                begin
                        if FieldOfWar[ i, j ] = 2 then { стирает роботов }
                        begin
                        	{ Если раскрыть закомментированые команды, то прямо во время игры можно проследить за передвижением роботов }
                                { WriteLn( 'Отчёт робота №', count, '.', #13,'Координаты: i=', i, ', j=', j, ';' ); }
                                BBepx := i - PlayerY;
                                BHu3 := -BBepx;
                                BLeBo := j - PlayerX;
                                BnpaBo := -BLeBo;
                                { WriteLn( 'Расстояние до цели: Вправо=', BnpaBo, ', Вниз=', BHu3, ';' ); }
                                FieldOfWar[ i, j ] := 3;

                                if ( BHu3 = 0 ) and ( BnpaBo = 0 ) then
                                begin
                                        { WriteLn( 'Принято решение стоять на месте;' ); }
                                        MoveBuff[ count, 1 ] := i;
                                        MoveBuff[ count, 2 ] := j
                                end
                                else if ( BHu3 >= BLeBo ) and ( BHu3 >= BnpaBo ) then
                                begin
                                        { WriteLn( 'Принято решение идти вниз;' ); }
                                        MoveBuff[ count, 1 ] := i + 1; { вниз }
                                        MoveBuff[ count, 2 ] := j
                                end
                                else if ( BnpaBo >= BBepx ) and ( BnpaBo >= BHu3 ) then
                                begin
                                        { WriteLn( 'Принято решение идти вправо;' ); }
                                        MoveBuff[ count, 1 ] := i;
                                        MoveBuff[ count, 2 ] := j + 1 { вправо }
                                end
                                else if ( BBepx >= BLeBo ) and ( BBepx >= BnpaBo ) then
                                begin
                                        { WriteLn( 'Принято решение идти вверх;' ); }
                                        MoveBuff[ count, 1 ] := i - 1; { вверх }
                                        MoveBuff[ count, 2 ] := j
                                end
                                else if ( BLeBo >= BBepx ) and ( BLeBo >= BHu3 ) then
                                begin
                                        { WriteLn( 'Принято решение идти влево;' ); }
                                        MoveBuff[ count, 1 ] := i;
                                        MoveBuff[ count, 2 ] := j - 1 { влево }
                                end;
                                inc( count );
                                { WriteLn( '***КОНЕЦ ОТЧЁТА***' );
                                  ReadLn }
                        end
                end;
        for i := 1 to count - 1 do { рисует роботов в новом месте }
                if ( FieldOfWar[ MoveBuff[ i, 1 ], MoveBuff[ i, 2 ] ] = 2 ) and not ( ( PlayerX = MoveBuff[ i, 2 ] ) and ( PlayerY = MoveBuff[ i, 1 ] ) ) then
                begin
                        FieldOfWar[ MoveBuff[ i, 1 ], MoveBuff[ i, 2 ] ] := 3;
                        Boom( MoveBuff[ i, 1 ], MoveBuff[ i, 2 ] );
                        inc( Pts, 10 ) { +5 очков за каждого столкнувшегося робота }
                end
                else if FieldOfWar[ MoveBuff[ i, 1 ], MoveBuff[ i, 2 ] ] <> 0 then
                        FieldOfWar[ MoveBuff[ i, 1 ], MoveBuff[ i, 2 ] ] := 2
                else if FieldOfWar[ MoveBuff[ i, 1 ], MoveBuff[ i, 2 ] ] = 0 then
                        inc( Pts ) { +1 очко за каждого упавшего в яму робота }
End;

procedure AddRobotz;
	{ добавляет роботов в 4 углах }
Begin
        FieldOfWar[ 1, 1 ] := 2;
        FieldOfWar[ 1, FacWidth ] := 2;
        FieldOfWar[ FacHeigth, 1 ] := 2;
        FieldOfWar[ FacHeigth, FacWidth ] := 2
End;

procedure ShowMsgXY( x0, y0: Integer; Text: String; TxtColor: SmallInt );
	{ выводит на экран сообщение в рамочке, типа "Вы достигли двери!" }
Begin
        SetFillStyle( 1, white );
        Bar( x0 - 4, y0 - 1, x0 + Length( Text ) * 8 + 3, y0 + 9 );
        SetColor( TxtColor );
        OutTextXY( x0, y0, Text )
End;

procedure DestroyRobotz;
	{ взрывает всех роботов вокруг игрока; предусмотрены все случаи }
Var i, j, DeadRob: Integer;
Begin
        if Armor > 0 then
        begin
                DeadRob := 0;
                if PlayerX = 1 then
                        if PlayerY = 1 then
                        begin
                                for i := 1 to 2 do
                                        for j := 1 to 2 do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                        else if PlayerY = FacHeigth then
                        begin
                                for i := FacHeigth - 1 to FacHeigth do
                                        for j := 1 to 2 do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                        else
                        begin
                                for i := PlayerY - 1 to PlayerY + 1 do
                                        for j := PlayerX to PlayerX + 1 do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                else if PlayerX = FacWidth then
                        if PlayerY = 1 then
                        begin
                                for i := 1 to 2 do
                                        for j := FacWidth - 1 to FacWidth do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                        else if PlayerY = FacHeigth then
                        begin
                                for i := FacHeigth - 1 to FacHeigth do
                                        for j := FacWidth - 1 to FacWidth do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                        else
                        begin
                                for i := PlayerY - 1 to PlayerY + 1 do
                                        for j := PlayerX - 1 to PlayerX do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                else
                begin
                        if PlayerY = 1 then
                        begin
                                for i := 1 to 2 do
                                        for j := PlayerX - 1 to PlayerX + 1 do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                        else if PlayerY = FacHeigth then
                        begin
                                for i := FacHeigth - 1 to FacHeigth do
                                        for j := PlayerX - 1 to PlayerX + 1 do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                        else
                        begin
                                for i := PlayerY - 1 to PlayerY + 1 do
                                        for j := PlayerX - 1 to PlayerX + 1 do
                                                if FieldOfWar[ i, j ] = 2 then
                                                begin
                                                        inc( DeadRob );
                                                        dec( FieldOfWar[ i, j ] );
                                                        Boom( i, j )
                                                end
                        end
                end;
                dec( Armor );
                if DeadRob = 0 then
                begin
                        ShowMsgXY( 100, 100, 'BbI He y6u/\u Hu ogHoro po6oTa.', red );
                        ShowMsgXY( 100, 110, 'He/\b3R TaK 6e3gyMHo pacxogoBaTb 3apRgbI!', red );
                        Delay( 1000 )
                end
                else
                        ShowMsgXY( 100, 100, 'BbI y6u/\u ' + IntToStr( DeadRob ) + ' po6oToB!', green );
                inc( Pts, DeadRob * 5 );
                Delay( 500 )
        end
        else
        begin
                ShowMsgXY( 100, 100, 'ync! y Bac 3aKoH4u/\ucb 3apRgbI!', red );
                Delay( 2000 )
        end
End;

procedure HideLegend;
	{ эффектное появление легенды }
Var i: Byte;
Begin
	GoToXY( 1, 1 );
        for i := 1 to 8 do
        begin
                Delay( 50 );
                DelLine
        end
End;

procedure BlokDGI;
	{ выполняет повторяющиеся в след. процедуре действия }
Begin
	Delay( 50 );
        GoToXY( 1, 1 );
        InsLine
End;

procedure ShowLegend;
	{ анимирует легенду }
Begin
	TextColor( white );
        WriteLn( '"i" - показать/спрятать эту красивую подсказку.' );
        BlokDGI;
        InsLine;
        TextColor( green );
        WriteLn( '"+" - парадный выход; сюда нужно дойти.' );
        BlokDGI;
        TextColor( white );
        WriteLn( '"." - свободное место; сюда можно идти.' );
        BlokDGI;
        TextColor( yellow );
        WriteLn( '"' + #12 + '" - главный герой; берегите его!' );
        BlokDGI;
        TextColor( white );
        WriteLn( '"O" - глубокая яма; смотрите под ноги!' );
        BlokDGI;
        TextColor( red );
        WriteLn( '"P" - злобный робот; опасайтесь роботов!' );
        BlokDGI;
        TextColor( yellow );
        WriteLn( 'ЛЕГЕНДА:' );
        GoToXY( 1, 9 );
End;

procedure EndGame;
	{ заканчивает уровень }
Begin
        Delay( 300 );
        HideLegend;
        ClearDevice;
        if Win = 1 then
        begin
                if Level < 20 then
                        inc( Level );
                ShowMsgXY( 100, 100, 'BbI gocTur/\u BbIxoga!', green );
                inc( Pts, 50 + Armor * 20 )
        end
        else if ( Win = -1 ) and ( FieldOfWar[ PlayerY, PlayerX ] = 2 ) then
        begin
                ShowMsgXY( 100, 100, 'Bac y6u/\ oguH u3 po6oToB.', red );
                dec( Pts, 150 );
                if Pts < 0 then Pts := 0;
                dec( Lives )
        end
        else
        begin
                ShowMsgXY( 100, 100, 'BbI yna/\u B RMy.', red );
                dec( Pts, 150 );
                if Pts < 0 then Pts := 0;
                dec( Lives )
        end;
        Delay( 2500 )
End;

procedure Proverit;
Var x, y: SmallInt;
Begin
        for x := PlayerX - 1 to PlayerX do
                for y := PlayerY - 1 to PlayerY + 1 do
                        if FieldOfWar[ y, x ] = 2 then
                                dec( FieldOfWar[ y, x ] );
        if Level = 1 then
                for x := 1 to FacWidth do
                        FieldOfWar[ ExitY, x ] := 1;
        FieldOfWar[ 1, 1 ] := 2;
        FieldOfWar[ 1, FacWidth ] := 2;
        FieldOfWar[ FacHeigth, 1 ] := 2;
        FieldOfWar[ FacHeigth, FacWidth ] := 2;

        FieldOfWar[ PlayerY, PlayerX - 1 ] := 1;
        FieldOfWar[ ExitY, ExitX + 1 ] := 1;
End;

procedure History;
	{ ролик в начале игры, рассказывает предысторию }
Var  x, y, i, speed: Integer;
Const n = 10;
Begin
        y := 1024; x := GetMaxX DIV 2 - 60; speed := 500;
        SetFillStyle( 1, Black ); SetColor( Yellow );
        for i := 0 to 120 do
        begin
                if KeyPressed then
                        speed := 0
                else
                begin
                OutTextXY( x, y - 512, '2387 rog...' );
                if y - 512 + n < 512 then
                        OutTextXY( x, y - 512 + n, 'KocMu4ecKaR юKcneguTcuR gocTuraeT n/\aHeTbI X.' );
                if y - 512 + n * 2 < 512 then
                        OutTextXY( x, y - 512 + n * 2, 'OguH u3 y4acTHuKoB юKcneguTcuu npoHuKaeT B orpoMHbIБ 3a/\ pa3pyweHHoro 3gaHuR.' );
                if y  - 512 + n * 3 < 512 then
                        OutTextXY( x, y - 512 + n * 3, '3eM/\R u3pbITa MHoro4uc/\eHHbIMu pacc4e/\uHaMu, oTKpbIBaБyc4uMu 6e3goHHbIe nponacTu.' );
                if y - 512 + n * 4 < 512 then
                        OutTextXY( x, y - 512 + n * 4, 'Hu ogHoБ wuBoБ gywu, Ho MecTHbIe wuTe/\u gocTur/\u BbIcoKoro TexHu4ecKoro ypoBHR.' );
                if y - 512 + n * 5 < 512 then
                        OutTextXY( x, y - 512 + n * 5, 'OHu nocTpou/\u aBToMaTu4ecKue 3aBogbI, npou3BogRwue gBuwyc4uxcR po6oToB.' );
                if y - 512 + n * 6 < 512 then
                        OutTextXY( x, y - 512 + n * 6, '3aBogbI ec4Й pa6oTaБyT caMu no ce6e, Ho c nepe6oRMu.' );
                if y - 512 + n * 7 < 512 then
                        OutTextXY( x, y - 512 + n * 7, 'noRB/\eHue po6oToB c/\y4auHo, ga u He pa6oTaБyT 6o/\bwe ETu po6oTbI TaK, KaK Korga-To...' );
                if y - 512 + n * 8 < 512 then
                        OutTextXY( x, y - 512 + n * 8, 'OHu npogo/\waБyT cTpeMuTe/\bHo HanagaTb Ha npuwe/\bTceB, Ho KaK c/\enbIe.' );
                if y - 512 + n * 9 < 512 then
                        OutTextXY( x, y - 512 + n * 9, 'Ec/\u u36paHHbIБ uMu nyTb npuBoguT ux K pacc4e/\uHe,' );
                if y - 512 + n * 10 < 512 then
                        OutTextXY( x, y - 512 + n * 10, 'oHu oKa3bIBaБyTca He B cocToRHuu u36ewaTb eЙ u npoBa/\uBaБyTca B gbIpy.' );
                Bar( x - 1, 512, 2048, 532 );
                dec( y );
                Delay( speed );
                ClearDevice
                end
        end
End;

procedure SpellSent( Input: String; Prom, Pause: Integer );
Var i: Byte; d: Boolean;
Begin
        d := FALSE;
        for i := 1 to Length( Input ) do
        begin
                if KeyPressed then
                begin
                        Prom := 1;
                        Pause := 1;
                        d := TRUE
                end;
                Write( Input[ i ] );
                if i MOD 80 = 0 then WriteLn;
                if ( Input[ i ] = '.' ) or ( Input[ i ] = '?' ) or ( Input[ i ] = '!' ) then
                        Delay( Pause )
                else
                        Delay( Prom )
        end;
        if d then
        begin
                ReadLn;
                DelLine
        end
End;

procedure SendSMS( Sender, Theme, MessTxt: String );
Var  i: Byte; Hour, Min, Sec, Hund: Word; { часы, минуты, секунды и сотые доли секунды  }
Begin
        ClrScr;
        TextColor( yellow + blink );
        WriteLn( '         Notebook        ' );
        TextColor( green );
        WriteLn( 'Сообщение ', countSMS, '.' );
        inc( countSMS );
        WriteLn( 'От: ', Sender, '.' );
        WriteLn( 'Тема: ', Theme, '.' );
        GetTime( Hour, Min, Sec, Hund );
        WriteLn( Level DIV 5 + 1, '/06/87 ', Hour, ':', Min );
        Write( ' ' );
        for i := 1 to Length( MessTxt ) do
        begin
                Write( MessTxt[ i ] );
                if ( i + 1 ) MOD 80 = 0 then WriteLn
        end;
        { SpellSent( ' ' + MessTxt, 1, 1 ); }
        WriteLn;
        WriteLn( 'i Сообщение сохранено в директории Входящие.' );
        ReadLn
End;

procedure ReadyNote;
Var  Hour, Min, Sec, Hund: Word; { часы, минуты, секунды и сотые доли секунды  }
Begin
        ClrScr;
        TextColor( yellow + blink );
        WriteLn( '         Notebook        ' );
        TextColor( green );
        WriteLn( 'Заметка ', Level, '.' );
        GetTime( Hour, Min, Sec, Hund );
        if Min > 9 then
                WriteLn( Level DIV 5 + 21, '/06/87 ', Hour, ':', Min )
        else
                WriteLn( Level DIV 5 + 21, '/06/87 ', Hour, ':0', Min )
End;

procedure GoUp;
Begin
        dec( PlayerY );
        countWait := 0
End;

procedure GoDown;
Begin
        inc( PlayerY );
        countWait := 0
End;

procedure GoLeft;
Begin
        dec( PlayerX );
        countWait := 0
End;

procedure GoRight;
Begin
        inc( PlayerX );
        countWait := 0
End;

procedure StayHere;
Begin
        inc( countWait );
        if countWait = MaxWait then
        begin
                ReadyNote;
                SpellSent( ' Я оказался в западне. Роботам до меня не добраться, но и долго сидеть здесь я тоже не смогу. Через какое-то время у меня закончится еда, и тогда мне конец.', 100, 200 );
                GameOver := TRUE
        end
End;

procedure PlayGame;
Var  Code: Char;
Label ReadPoint;
Begin
        repeat
ReadPoint:      Code := ReadKey;
                if ( ( Code = 'H' ) or ( Code = 'w' ) ) and ( PlayerY > 1 ) then
                        GoUp
                else if ( ( Code = 'P' ) or ( Code = 's' ) ) and ( PlayerY < FacHeigth ) then
                        GoDown
                else if ( ( Code = 'K' ) or ( Code = 'a' ) ) and ( PlayerX > 1 ) then
                        GoLeft
                else if ( ( Code = 'M' ) or ( Code = 'd' ) ) and ( PlayerX < FacWidth ) then
                        GoRight
                else if Code = #13 then
                        DestroyRobotz
                else if Code = ' ' then
                        StayHere
                else if ( Code = 'q' ) or ( Code = 'й' ) then
                        GameOver := TRUE
                else if ( Code = 'i' ) or ( Code = 'ш' ) then
                begin
                        if Legend then
                        begin
                                Legend := FALSE;
                                HideLegend
                        end
                        else
                        begin
                                Legend := TRUE;
                                ShowLegend
                        end;
                        GoTo ReadPoint
                end
                else if ( Code = 'l' ) or ( Code = 'д' ) then
                begin
                        Load;
                        GameOver := TRUE
                end
                else
                        GoTo ReadPoint;

                MoveRobots;
                if Random( 1000 ) < ShansNewP * Level then AddRobotz;
                Redraw;

                if ( ExitX = PlayerX ) and ( ExitY = PlayerY ) then
                begin
                        ShowMsgXY( 100, 100, 'BbI BbIurpa/\u!', green );
                        Win := 1;
                        EndGame;
                        GameOver := TRUE
                end
                else if ( FieldOfWar[ PlayerY, PlayerX ] = 0 ) or ( FieldOfWar[ PlayerY, PlayerX ] = 2 ) then
                begin
                        ShowMsgXY( 100, 100, 'R.I.P.', red );
                        Boom( PlayerY, PlayerX );
                        Win := -1;
                        EndGame;
                        GameOver := TRUE
                end
        until GameOver;
End;

procedure Start;
Var i, j, n: Integer;
Label Beginnings;
Begin
Beginnings:
        ClearDevice; ClrScr;

        if Legend then ShowLegend;

        Randomize;
        for i := 1 to FacHeigth do
                for j := 1 to FacWidth do
                begin
                        n := Random( 1000 );
                        if n < ShansO DIV Level then
                                FieldOfWar[ i, j ] := 0
                        else if n < ShansP * Level + ShansO DIV Level then
                                FieldOfWar[ i, j ] := 2
                        else
                                FieldOfWar[ i, j ] := 1
                end;

        PlayerX := FacWidth; PlayerY := FacHeigth DIV 2;
        ExitX := 1; ExitY := FacHeigth DIV 2;
        Armor := 5;
        if Level = 12 then
                inc( Armor );
        Win := 0;
        GameOver := FALSE;

        FieldOfWar[ PlayerY, PlayerX ] := 3;
        FieldOfWar[ ExitY, ExitX ] := 3;
        Proverit;

        Redraw;

        PlayGame;
        if Loaded then
        begin
                Loaded := FALSE;
                GoTo Beginnings
        end
End;

procedure ShowTextFirst;
Begin
        TextColor( green );
        if ( Win = -1 ) and ( Lives = 1 ) then
        begin
                ClrScr;
                TextColor( red );
                WriteLn( 'Вы погибли...' );
                ReadLn;
                SendSMS( 'Неизвестно', 'Осторожнее..', 'Ты играешь со смертью.' )
        end
        else if ( Win = -1 ) and ( Lives = 2 ) then
        begin
                TextColor( red );
                WriteLn( 'Вы погибли.' );
                ReadLn;
                SendSMS( 'Создатель игры', 'Вы мертвы', 'Это игра и у Вас есть возможность начать заново. В реальной жизни у Вас такой возмлжности не будет.' )
        end
        else if ( Win = 0 ) and ( Level = 1 ) then
        begin
                SendSMS( 'Создатель игры', 'Приветствие', 'Приветствую Вас в игре RobotZ! Сейчас я объясню Вам основную концепцию игры. Ваша цель - дойти до выхода на противоположном конце поля и не попасться роботам. Нажмите клавишу ЕНТЕР.' );
                ClrScr;
                TextColor( yellow + blink );
                WriteLn( ' УПРАВЛЕНИЕ:' );
                TextColor( yellow );
                SpellSent( ' Клавиши ВЛЕВО, ВВЕРХ, ВПРАВО и ВНИЗ перемещают героя в соответствующем направлении;', 1, 1 );
                WriteLn;
                WriteLn( ' ПРОБЕЛ - пропустить ход, герой стоит на месте;' );
                WriteLn( '"q" - сохранить и выйти из игры.' );
                WriteLn;
                SpellSent( ' Сейчас Вы увидите заметку, которую написал главный герой игры. Внимательно её прочитайте. С этого момента начинается Ваша игра.', 0, 0 );
                WriteLn;
                WriteLn( ' Когда будете готовы, нажмите ЕНТЕР.' );
                ReadLn;
                ReadyNote;
                SpellSent( ' Я вошёл в разрушенное здание. Дверь за мной автоматически закрылась. Кажется, это помещение - цех по производству роботов.', 100, 200 );
                WriteLn;
                SpellSent( ' Справа и слева от меня автоматические конвейеры. Единственный выход - на другом краю.', 100, 300 )
        end
        else if ( Win = 1 ) and ( Level = 2 ) then
        begin
                SendSMS( 'Создатель игры', 'Мои поздравления', 'У Вас получилось! Согласитесь, это было не так уж и сложно. Посмотрим, как Вы справитесь со следующим уровнем.' );
                ReadyNote;
                SpellSent( ' К счастью, у меня есть несколько дезинтегрирующих зарядов. Но мне нужно их экономить. Ещё не известно, что меня ждёт, когда я приближусь к выходу...', 100, 500 );
                ReadLn;
                ClrScr;
                TextColor( yellow + blink );
                WriteLn( ' УПРАВЛЕНИЕ:' );
                TextColor( yellow );
                WriteLn( ' Если Вас окружили роботы, нажмите ЕНТЕР, чтобы уничтожить их.' );
                WriteLn( 'Зарядов ограниченное количество, поэтому не используйте их без необходимости.' );
                ReadLn;
                SendSMS( 'Создатель игры', 'Вы готовы',  'На этом Ваше обучение закончено. Теперь Вы сами по себе. Желаю приятного времяпрепровождения.' )
        end
        else if ( Win = 1 ) and ( Level = 3 ) then
                SpellSent( ' Похоже у роботов повреждено визуальное восприятие и они ничего не видят. Поэтому они и падают в ямы, как слепые котята. Что ж, мне это только на руку.', 100, 0 )
        else if ( Win = 1 ) and ( Level = 4 ) then
                SpellSent( ' Очень хочется узнать, что в тех ямах. Но их не то, что исследовать, в них даже заглядывать страшно. По крайней мере, ни один из роботов, которые туда свалились, больше не появлялся.', 100, 200 )
        else if ( Win = 1 ) and ( Level = 5 ) then
                SpellSent( ' Что же произошло с этим заводом? С этой планетой? Почему здесь пропала жизнь? Я должен в этом разобраться.', 100, 500 )
        else if ( Win = 1 ) and ( Level = 6 ) then
                SpellSent( ' Судя по огромному количеству провалов в земле, можно предположить, что на планету Х упал огромный метеорит. Но почему исчезла и не смогла защититься от какого-то метеорита такая развитая цивилизация?', 100, 500 )
        else if ( Win = 1 ) and ( Level = 7 ) then
                SpellSent( ' Вокруг одни роботы! Нужно найти кого-нибудь живого и узнать, что здесь произошло.', 100, 200 )
        else if ( Win = 1 ) and ( Level = 8 ) then
                SpellSent( ' За этой дверью ещё одна, а за ней ещё и ещё... И так до бесконечности. Когда же я отсюда выберусь?', 100, 300 )
        else if ( Win = 1 ) and ( Level = 9 ) then
                SpellSent( ' Эти роботы настроены враждебно. Наверное их целью было защищать. А почему, собственно, "было"? Они и сейчас защищают. Защищают ЧТО-ТО. Но ЧТО?', 100, 400 )
        else if ( Win = 1 ) and ( Level = 10 ) then
                SpellSent( ' У меня куча вопросов и ни одного ответа. Ничего не понимаю.', 100, 200 )
        else if ( Win = 1 ) and ( Level = 11 ) then
                SpellSent( ' У нас, на Земле, каждый завод нуждается в генераторе тока. Если разобраться, как работает этот инопланетный завод, то я смогу приостановить производство злобных роботов.', 100, 200 )
        else if ( Win = 1 ) and ( Level = 12 ) then
        begin
                SpellSent( ' Я проклинаю тот день, когда вошёл на территорию этого завода. Но сегодня мне крупно повезло - я нашёл сломанный билитарионный ретранслятор! Из него я смогу собрать ещё один дезинтегрирующий заряд.', 100, 1000 );
                WriteLn;
                SpellSent( 'Возможно, он спасёт мне жизнь.', 100, 0 )
        end
        else if ( Win = 1 ) and ( Level = 13 ) then
                SpellSent( ' Я совсем уже потерял надежду найти кого-нибудь живого.', 100, 0 )
        else if ( Win = 1 ) and ( Level = 14 ) then
                SpellSent( ' У меня нет времени на раздумья. Если я замешкаюсь хоть на секунду, эти жестяные монстры окружат меня и...', 90, 200 )
        else if ( Win = 1 ) and ( Level = 15 ) then
                SpellSent( ' Меня утешает только одна мысль: когда я отсюда выберусь - меня назовут Героем. Когда я отсюда выберусь....', 100, 200 )
        else if ( Win = 1 ) and ( Level = 16 ) then
                SpellSent( ' Как же я устал! Кажется я не спал уже трое суток. Глаза силпаются.', 200, 400 )
        else if ( Win = 1 ) and ( Level = 17 ) then
                SpellSent( ' Чувствую, я уже близок к разгадке. Нужно продолжать идти вперёд.', 100, 1000 )
        else if ( Win = 1 ) and ( Level = 18 ) then
                SpellSent( ' А может роботы захватили власть над этой планетой и уничтожили на ней жизнь... Нет... Этого не может быть... Они же глупые машины!', 100, 500 );
        ReadLn
End;

procedure Introduction;
Begin
        if ( Lives > 0 ) and ( Win = 1 ) and not ( Level = 2 ) then
        begin
                ReadyNote;
                ShowTextFirst;
                Start
        end
        else if ( Lives > 0 ) and ( Win = -1 ) then
        begin
                ShowTextFirst;
                TextColor( white + blink );
                WriteLn( 'Текущий уровень: ', Level );
                TextColor( Default );
                Start
        end
        else if Level = 2 then
        begin
                ShowTextFirst;
                Start
        end
End;

procedure NewGame;
Var  GDriver, GMode: Integer;
Label Rep;
Begin
        Level := 1; Lives := Hearts; Pts := 0;
        countSMS := 1; Legend := TRUE;
        Loaded := FALSE;
        GDriver := Detect;
        InitGraph( GDriver, GMode, '' );
        if GraphResult <> grOk then Halt( 1 );

        History;
        ShowTextFirst;
        Start;
Rep:
        if GameOver and ( Lives > 0 ) and not ( Win = 0 ) then
        begin
                Introduction;
                GoTo Rep
        end
        else if Win = -1 then
        begin
                SetTextStyle( SansSerifFont, HorizDir, 4 );
                OutTextXY( 100, 200, 'GAME OVER!' );
                TextColor( Red );
                WriteLn( 'У Вас закончились жизни. Радуйтесь, что это только игра, и Вы всё ещё живы...' );
                Delay( 1000 );
                WriteLn( 'Ха!!! Ха!! Ха!' );
                Delay( 1000 );
                WriteLn( 'Нажмите ENTER...' );
                ReadLn
        end
        else if ( Win = 0 ) and ( countWait < MaxWait ) then
        begin
                ClrScr;
                TextColor( yellow + blink );
                WriteLn( '         NoteBook        ' );
                TextColor( white );
                Write( 'Идёт сохранение... ' );
                Save;
                TextColor( Green );
                WriteLn( 'Ok!' );
                TextColor( yellow );
                WriteLn( 'Используйте клавишу "L" во время следующей игры, чтобы загрузить это сохранение.' );
                ReadLn
        end
        else if Win = 0 then
        begin
                ClrScr;
                TextColor( white );
                Write( ' Думаю, будет честно, если я предложу Вам начать уровень заново?' );
                ReadLn;
                GameOver := TRUE;
                Win := 1;
                GoTo Rep
        end;
        ClearDevice;
        CloseGraph
End;

BEGIN
        NewGame
END.
