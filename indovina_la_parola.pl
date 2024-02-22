/* Programma Prolog che implementa un gioco per indovinare una parola data una lista di parole tra due giocatori. */

 main :-
  write('---------------- GIOCATORE 1'), nl,
  first_player(ListWords),
  nl, write('--------------- GIOCATORE 2'), 
  nl, write('Indovina la parola:'), nl,
  second_player(ListWords).
  
  /*********************************************************************************/
  /********************************* PRIMO GIOCATORE *******************************/  
  /*********************************************************************************/
  /* Il predicato viene utilizzato per richiamare le funzionalità del giocatore 1. 
     Viene passato un solo argomento (ListWords), utilizzato per restituire la lista 
     delle parole che il secondo giocatore dovrà indovinare. */
  first_player(ListWords) :-
    repeat,
    (validate_first_input(N)),
    read_input_words(N, [], ListWords, 1). 

  /* Il predicato acquisisce e valida il numero di parole inserito (input >= 10).
     In caso di validazione errata si richiede un nuovo inserimento.  
     Viene passato un solo argomento (N), utilizzato per restituire il numero di 
     parole effettive che il primo giocatore vuole inserire. */
   validate_first_input(N) :-
    (
      nl, write('Inserisci un numero (>= 10):'), nl,  
      catch(read(N), _, fail), 
      (
        number(N) -> 
        (
          integer(N),
          N >= 10 -> 
            !
        ;
          fail
        )
      )
    ).
      
  /* Il predicato acquisisce l'input, validandolo tramite 'validate_second_input', 
     e in caso positivo lo aggiunge alla lista delle parole.
     I suoi argomenti sono:
     - N, che indica il numero di parole da inserire nella lista;
     - ListInit, l'insieme da comporre, nella quale vengono aggiunte le parole validate;
     - ListWords, l'insieme risultante delle parole;
     - Index, un indice utilizzato nella stampa a video, incrementato ad ogni input accettato. */
  read_input_words(0, ListInit, ListInit, _).
  read_input_words(N, ListInit, ListWords, Index) :-
    N > 0,
     (
        nl, format('Inserisci la parola ~w: ~n', [Index]),
        catch(read(Input), _, fail),
        validate_input_words(Input) ->
          (
            member(Input, ListInit) ->
              nl, write('Parola gia'' inserita.'), nl, 
              read_input_words(N, ListInit, ListWords, Index)
          ;              
              Index1 is Index + 1,
              N1 is N - 1,
              append(ListInit, [Input], UpdatedList),
              read_input_words(N1, UpdatedList, ListWords, Index1)
          )
     ;               
        (
            % Se la validazione fallisce, gestione dell'input
            nl, write('Inserimento non valido.'),
            nl, write('La parola deve contenere lettere minuscole dell''alfabeto.'), nl,
            read_input_words(N, ListInit, ListWords, Index)
        )
     ).
    
  /*********************************************************************************/
  /******************************* SECONDO GIOCATORE *******************************/
  /*********************************************************************************/
  /* Il predicato determina le mosse del secondo giocatore.
     Richiama i predicati per l'estrazione casuale di una parola dalla lista delle 
     parole, inizializza la maschera e avvia la "guessing procedure".
     Argomenti in input: lista delle parole (ListWords). */
  second_player(ListWords) :-
    random_word(ListWords, RandomWord),
    atom_length(RandomWord, RandomWordLength),
    init_mask_word(RandomWordLength, MaskWord),
    check_word(ListWords, RandomWord, MaskWord, RandomWordLength).

  /* Il predicato seleziona causalmente una parola per la "guessing procedure".
     Argomenti:
     - ListWords, lista delle parole dalla quale estrarre la parola casuale;
     - RandomWord, parola casuale estratta.
     L'uso di random consente di generare un indice casuale, 
     mentre nth0 di estrarre dalla lista la parola corrispondente all'indice. */
  random_word(ListWords, RandomWord) :-
    length(ListWords, ListLenght),  
    random(0, ListLenght, Index),       
    nth0(Index, ListWords, RandomWord).  
    
  /* Il predicato inizializza una maschera di asterischi, 
     per nascondere al secondo giocatore la parola da indovinare.
      Argomenti:
      - N, la lunghezza della parola da indovinare;
      - la maschera di asterischi, rappresentata da una lista.*/
  init_mask_word(0, []). 
  init_mask_word(N, ['*' | Resto]) :-
    N > 0,
    N1 is N - 1,
    init_mask_word(N1, Resto).
    
  /* Il predicato è utilizzato per la "guessed procedure".
     Stampa ogni volta la maschera aggiornata, verifica la disponibilità di tentativi
     rimanenti per indovinare la parola, e gestisce l'input dell'utente, richiamando
     i predicati 'try_again/1' (nel caso di tentativi terminati) 
     o 'handle_input/5' (per la gestione dell'input validato). 
     Nel caso in cui i tentativi siano terminati, rimuove la parola non indovinata 
     dalla lista delle parole, restituendo una lista aggiornata.
     Nel caso in cui la maschera non contenga più asterischi, si chiama il predicato
     'guessed_word/4' per la gestione della parola indovinata. 
     Argomenti:
     - ListWords, lista delle parole, passata per eliminare la parola se terminati i 
       tentativi o indovinata la parola;
     - RandomWord, parola randoma da indovinare;
     - MaskWord, maschera di asterischi da aggiornare;
     - Attempts, numero di tentativi a disposizione.*/
  check_word(ListWords, RandomWord, MaskWord, Attempts) :-   
    list_to_string(MaskWord, ListToString), 
    (
      Attempts =:= 0 ->    
        nl, write('Parola non indovinata, hai terminato i tentativi.'), nl,
        remove_guess_word(ListWords, RandomWord, NewLists),
        length(NewLists, Length),
        (
          Length > 0 ->
            try_again(NewLists)
        ;
            nl, write('Non ci sono piu'' parole da indovinare!'),
            true
          )        
    ;
        % Se ci sono ancora tentativi si procede con il controllo della maschera.
        (
          member('*', MaskWord) -> 
            handle_input(ListWords, RandomWord, MaskWord, Attempts, ListToString)        
        ;  
            guessed_word(RandomWord, ListToString, ListWords)
        )
    ).   

  /* Predicato ausiliario per gestire l'input dell'utente, se valido.
     Nel caso in cui l'input sia valido, viene verificata la lunghezza della parola. 
     Se la lunghezza dell'input è diversa da quella richiesta, il numero di tentativi viene decrementato.
     Argomenti:
     - ListWords, lista delle parole;
     - RandomWord, parola random;
     - MaskWord, maschera da aggiornare;
     - Attempts, numero di tentavi a disposizione,
     - ListToString, lista della maschera aggiornata, passata per la gestione dello status. */
  handle_input(ListWords, RandomWord, MaskWord, Attempts, ListToString) :-
    (
      status(Attempts, ListToString),
      catch(read(Input), _, fail),
      validate_input_words(Input) ->
        atom_chars(Input, ListInput),
        length(ListInput, InputLength),
        atom_chars(RandomWord, ListRandomWord),
        length(ListRandomWord, RandomWordLength),
          (

            InputLength =:= RandomWordLength ->  
              compare_words(ListInput, ListRandomWord, MaskWord, [], UpdateMaskWord),
              NewAttempts is Attempts - 1,
              check_word(ListWords, RandomWord, UpdateMaskWord, NewAttempts)
          ;
              nl, write('Inserimento non valido.'),
              nl, write('La parola inserita ha lunghezza diversa rispetto a quella da indovinare.'), nl,
              NewAttempts is Attempts - 1,
              check_word(ListWords, RandomWord, MaskWord, NewAttempts)  
          )
    ;
        nl, write('Inserimento non valido.'),
        nl, write('La parola deve contenere lettere minuscole dell''alfabeto.'), nl,
        handle_input(ListWords, RandomWord, MaskWord, Attempts, ListToString)
    ).


  /* Il predicato converte una lista di caratteri in una lista di stringhe.
     CASO BASE: restituisce la lista aggiornata se la lista di caratteri è vuota.
     CASO GENERALE: genera una lista di caratteri, utilizzando la ricorsione aggiungendo un carattere 
     alla volta, preso dalla lista passatagli. 
     La lista Update viene utilizzata come 'accumulatore', nella quale aggiungere caratteri,
     grazie all'utilizzo di 'append', reiterando fino a che la maschera che gli viene passata è vuota.
     Viene restituita la lista aggiornata "UpdateList".
     Argomenti:
     - MaskWord, maschera da stampare;
     - UpdateList, lista aggiornata.
     - Update, lista da aggiornare. */
  list_to_string(MaskWord, UpdateList) :-
    list_to_string(MaskWord, [], StringList),
    atom_chars(UpdateList, StringList).
  list_to_string([], Update, Update).
  list_to_string([Char|Tail], Update, UpdateList) :-
    append(Update, [Char], NewUpdate),
    list_to_string(Tail, NewUpdate, UpdateList).

  /* Il redicato serve per visualizzare lo stato del gioco.
     Argomenti:
     - Attempts, numero di tentativi a disposizione;
     - ListToString, maschera aggiornata trasformata in lista. */
  status(Attempts, ListToString) :-    
    write(ListToString), nl,
    atom_length(ListToString, LenghList),
    nl, format('Hai a disposizione ~w tentativi.', [Attempts]),
    nl, format('Inserisci una parola lunga ~w: ', [LenghList]).

  /* Il predicato mette a confronto ogni lettera della parola in input con quella da indovinare, 
     andando ad aggiornare in tal modo la maschera da mostrare all'utente.
     Durante questo confronto, se una lettera è corretta, viene inclusa nella nuova lista risultante. 
     Altrimenti, viene inclusa nella nuova lista la lettera corrispondente della maschera fornita.
     Argomenti:
     - Il primo input rappresenta la lista dei caratteri che formano la parola in input dell'utente;
     - Il secondo input rappresenta la lista dei caratteri che formano la parola random;
     - Il terzo input rappresenta la lista dei caratteri che formano la maschera attuale;
     - Update rappresenta la maschera di appoggio da aggiornare;
     - UpdateMask rappresenta la maschera risultante aggiornata. */
  compare_words([], [], [], Update, Update).
  compare_words([X | RestInput], [Y | RestRandomWord], [Mask | RestMask], Update, UpdateMask) :-
    (
      X \= Y ->        
        append(Update, [Mask], NewUpdate)
    ;
        append(Update, [X], NewUpdate)
    ), 
    compare_words(RestInput, RestRandomWord, RestMask, NewUpdate, UpdateMask).
    
 
  /* Il predicato controlla che venga indovinata la parola, rimuovendola dalla lista.
     Controlla inoltre se la lista è vuota terminando il programma, 
     o in caso alternativo chiama il predicato try_again. 
     Argomenti:
     - RandomWord, parola random da confrontare con la parola creata;
     - InputWord, che rappresenta la parola creata dalle varie lettere indovinate;
     - ListWords, lista delle parole, per rimuovere la parola. */
  guessed_word(RandomWord, InputWord, ListWords) :-
    (
      InputWord == RandomWord ->
        write(InputWord), nl,
        nl, write('Parola indovinata correttamente!'), nl,
        remove_guess_word(ListWords, RandomWord, NewLists),
        length(NewLists, Length),
        (
          Length > 0 ->
            try_again(NewLists)
        ;
            nl, write('Non ci sono piu'' parole da indovinare!'),
            true
          )      
    ).

  /* Predicato usato per rimuovere la parola indovinata dalla lista.
     Argomenti:
     - ListWords, lista delle parole dalla quale rimuovere la parola.
     - RandomWord, parola random da eliminare dalla lista;
     - NewListWords, lista aggiornata dopo la rimozione. */
  remove_guess_word(ListWords, RandomWord, NewListWords) :-
    select(RandomWord, ListWords, NewListWords).

  /* Predicato utilizzato per gestire la risposta dell'utente alla richiesta
     di indovinare una nuova parola nel caso in cui abbia indovinato la precedente.
     - Nel caso di risposta positiva viene richiamato il predicato utilizzato per 
       l'intera routine che parte dalla scelta della parola casuale in poi.
     - Nel caso di risposta negativa il programma termina con 'True'.
     - Nel caso di risposta non valida, viene riproposta la domanda. 
     L'unico argomento è ListWords, ovvero la lista delle parole aggiornata,
     che viene passata come argomento per fare in modo che ricominci il turno 
     del secondo giocatore in caso di risposta positiva. */
  try_again(ListWords) :-
    nl, write('Vuoi indovinare un''altra parola? (s/n)'), nl,
    read(Response),
    ( 
      Response == 's' -> 
        second_player(ListWords)
    ; 
      Response == 'n' ->
        nl, write('GAME OVER!'), nl,
        true
    ;
      write('Inserimento non valido. Riprova.'), nl,
      try_again(ListWords)
    ).
   
  /* Predicato utilizzato per validare l'input.
     L'input deve essere una lettera minuscola appartenente all'alfabeto.
     Viene controllato quindi che non sia un numero, che non sia composto da lettere maiuscole 
     e che appartenga alle lettere dell'alfabeto (e quindi non sia un simbolo o segno di punteggiatura). */
  validate_input_words(Input) :-
    (
      maplist(is_upper, Input) ->
        false
    ;
      number(Input) ->
        false
    ;
        atom_chars(Input, Chars),
        length(Chars, InputLength),
        (
          InputLength > 0 ->
            maplist(is_alpha_character, Chars)
        )
    ).

  /* Predicato utilizzato per verificare che ogni carattere della parola sia composta da 
     lettere minuscole dell'alfabeto, validando l'input in ingresso (Char). */
  is_alpha_character(Char) :-
    Char @>= 'a', Char @=< 'z'.

  /* Il predicato verifica la presenza di lettere maiuscole in ogni carattere 
     dell'input che gli viene passato (Char). */ 
  is_upper(Char) :-
    Char @>= 'A', Char @=< 'Z'.

  