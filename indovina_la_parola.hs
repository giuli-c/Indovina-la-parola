{- Programma Haskell che implementa un gioco per indovinare una parola
   data una lista di parole tra due giocatori. -}

import Text.Read (readMaybe)        -- necessario per verificare se è stato inserito un numero
import Data.List (nub)              -- necessario per rimuovere i duplicati dalla lista 
import Data.Char (isLower,isLetter) -- necessario per stabilire se la lettera inserita è minuscola
                                    -- e se il secondo giocatore ha inserito un carattere
import System.Random(randomRIO)     -- necessario per estrarre l'indice casuale 
                                    -- nell'intervallo della lista di parole

main :: IO ()
main = do
    putStrLn "---------------- GIOCATORE 1"
    listWords <- first_player 
    putStrLn " ---------------- GIOCATORE 2"
    second_player listWords

{- La funzione first_player acquisisce il numero di parole -}
first_player :: IO [String]
first_player = do
  n <- validate_first_input
  listWords <- read_input_words n []
  return listWords

{- La funzione second_player ha come argomento la lista di parole:
   - Estrae dalla lista delle parole una parola randomica 
   - La parola estratta viene tramutata in asterischi 
   - Viene richiesto se si vuole indovinare un'altra parola -}
second_player :: [String] -> IO ()
second_player listWord = do
    randomStr <- random_word listWord
    maskWord <- init_mask_word randomStr 
    let randomWordLength = length randomStr
    check_word randomStr maskWord randomWordLength
    let newList = remove_guess_word randomStr listWord 
    continue <- try_again newList
    result newList continue 

{- La funzione result ha come primo argomento la lista di parole e
   come secondo argomento la scelta s/n del secondo giocatore.
   Viene verificato se la lista è vuota e in tal caso il gioco termina
   se la lista non è vuota e il giocatore vuole proseguire il gioco continua 
   se la lista non è vuota e il giocatore NON vuole proseguire il gioco termina -}   
result :: [String] -> Bool -> IO ()
result newList continue
  | is_list_empty newList = putStrLn "Non ci sono più parole da indovinare!"
  | continue              = do
                            second_player newList
  | otherwise             = putStrLn "GAME OVER!"

{- La funzione is_list_empty ha come argomento la lista di parole
   e verifica se la lista è vuota -}
is_list_empty :: [a] -> Bool
is_list_empty [] = True
is_list_empty _  = False

{- La funzione remove_guess_word rimuove la parola dalla lista delle parole 
   primo argomento: parola estratta
   secondo argomento: lista di parole -}
remove_guess_word :: Eq a => a -> [a] -> [a]
remove_guess_word x ys = filter (/= x) ys

{- La funzione try_again chiede se si vuole indovinare un'altra parola
   Nel caso in cui la lista delle parole risulti vuota non viene richiesto
   il messaggio -}
try_again :: [String] -> IO Bool
try_again str = do

  if is_list_empty str 
    then return False 
  else 
    do
    putStrLn "Vuoi indovinare un'altra parola? (s/n)"
    answer <- getLine
    case answer of
      ['s'] -> return True
      ['n'] -> return False
      _ -> do
        try_again str
    
{- La funzione validate_first_input chede di inserire il numero di parole
   e verifica se è stato inserito un numero intero -}
validate_first_input :: IO Int
validate_first_input = do
    putStrLn "Inserisci un numero (>= 10):"
    n <- getLine

    case readMaybe n of
        Just np -> validate_n np
        Nothing -> do
            validate_first_input

{- La funzione validate_n ha come parametro il numero di parole 
   e se il numero è < 10 chiede il suo reinserimento -}
validate_n :: Int -> IO Int
validate_n n
    | n >= 10    = return n
    | otherwise  = do
        validate_first_input
        
{- La funzione read_input_words permette l'inserimento delle parole nella lista 
   e verifica se la la parola è già presente nella lista: 
   - primo argomento: numero di parole da inserire nella lista 
   - secondo argomento: lista di parole -}
read_input_words :: Int -> [String] -> IO [String]
read_input_words 0 listWords = return listWords
read_input_words n listWords = do
    putStrLn $ "Inserisci la parola " ++ show (length listWords + 1) ++ ":"
    input <- validate_second_input
    newList <- remove_dup_ins input listWords
    read_input_words (n - 1) newList

{- La funzione remove_dup_ins rende in ingresso una stringa 
   e una lista e controlla se è gia presente
   chiedendo l'eventuale reinserimento: 
   - primo argomento: parola inserita 
   - secondo argomento: lista di parole -}
remove_dup_ins :: String -> [String] -> IO [String]
remove_dup_ins str strList 
    | str `elem` nub strList = do
        putStrLn "Parola già inserita."
        newStr <- validate_second_input
        remove_dup_ins newStr strList
    | otherwise = return (strList ++ [str])

{- La funzione validate_second_input ha come argomento la parola
   se la parola ha lunghezza inferiore a 2 oppure 
   non contiene lettere minuscole dell'alfabeto 
   viene richiesto il reinserimento -}
validate_second_input :: IO String
validate_second_input = do
    input <- getLine
    case () of
        _ | length input >= 1 && is_StringBetween_AZ input && 
                   all isLower input -> return input
        _ -> do
            putStrLn "Inserimento non valido."
            putStrLn "La parola deve contenere lettere minuscole dell'alfabeto."
            validate_second_input

{- La funzione random_word ha come parametro la lista di parole 
   ed estrae un indice nell'intervallo della lista -}
random_word :: [String] -> IO String
random_word strings = do
  let lastIndex = length strings - 1
  randomIndex <- randomRIO(0, lastIndex)
  return (strings !! randomIndex)

{- La funzione init_mask_word genera asterischi pari al numero della parola estratta
   ha come parametro la parola da indovinare -}
init_mask_word :: String -> IO String
init_mask_word inputString = return (replicate (length inputString) '*')

{- La funzione check_word controlla se la parola inserita trova corrispondenze
   con la parola da indovinare
   - primo argomento: parola estratta dalla lista delle parole
   - secondo argomento: maschera costituita da asterischi
   - terzo argomento: tentativi
  Si procede in maniera ricorsiva come segue:
  Se ho terminato i tentativi la parola non è stata indovinata.
  Se la maschera aggiornata corrisponde con la parola estratta la parola è stata indovinata.
  Altrimenti viene validato l'input e se la lunghezza della parola inserita coincide con 
  la lunghezza della parola da indovinare viene aggiornata la maschera decrementando 
  il numero di tentativi.
  Se l'input non è valido viene richiesto l'inserimento decrementando il numero di tentativi -}
check_word :: String -> String -> Int -> IO ()
check_word randomWord maskWord attempts
  | attempts == 0 = putStrLn "Parola non indovinata, hai terminato i tentativi."
  | randomWord == maskWord = putStrLn "Parola indovinata correttamente!"
  | otherwise = do
      status maskWord attempts

      inputWord <- validate_second_input
      if length inputWord /= length randomWord
         then do
            putStrLn "Inserimento non valido."
            putStrLn "La parola inserita ha lunghezza diversa rispetto a quella da indovinare"
            check_word randomWord maskWord (attempts - 1)
         else do
            let nuovaMaskWord = compare_words randomWord maskWord inputWord
            check_word randomWord nuovaMaskWord (attempts - 1)

{- La funzione compare_words aggiorna la maschera in base alla parola da indovinare
   e restituisce la maschera aggiornata.
   primo argomento: parola da indovinare
   secondo argomento: la maschera 
   terzo argomento: la nuova maschera aggiornata -}
compare_words :: String -> String -> String -> String
compare_words [] _ _ = ""
compare_words (p : parola) (m : maskWord) (p2 : parola2)
  | m == '*' && p2 == p = p : compare_words parola maskWord parola2
  | otherwise = m : compare_words parola maskWord parola2

{- La funzione status stampa il numero di tentativi a disposizione e la maschera:
   primo argomento: maschera 
   secondo argomento: numero di tentativi -}
status :: String -> Int -> IO ()
status p t = do 
    let lengthWord = length p
    putStrLn $ "Hai a disposizione " ++ show t ++ " tentativi"
    putStrLn $ "Inserisci una parola lunga " ++ show lengthWord ++ ": "
    putStrLn p   

{- La funzione is_StringBetween_AZ controlla se la stringa contiene 
   lettere minuscole -}
is_StringBetween_AZ :: String -> Bool
is_StringBetween_AZ str = all (\c -> c >= 'a' && c <= 'z') str
