# Cipher-solver
Encrypt and decrypt text using vigenere ciphers. Written in MIPS assembly language. Run I/O console to encrypt and decrypt text using a simple ciphers. 

# Description
## Encryption:
Text is shifted using the input key (string). For instance, when key is 'C' (corresponds to 3), it would change A to D. At the end of the alphabet, wrap back the the beginning.
- Assume all text is ASCII, work only with capital letters. 
- Key will be wirtten using letters where A correponds to a shift of 0, B to 1, C to 2, so on. 
- Repeat the key in encryption over and over again, leave the text unchanged where there is space or punctuation. 

Ex: ”LET’S GO TO THE CAT MUSEUM!” with key ”AB” will becomes ”LFT’S GP UO TIE CBT MVSFUN!”, that is, letters in even positions starting at position zero are not shifted, while letters in odd positions are shifted by 1.

## Decryption: 
Look at letter frequences and compute the frequencies of letters to try to identify the key. 
- Input an assumed length of the key and what letter you believe to be most probably (or frequent)
For the string ”UIF RVJDL CSPXO GPY KVNQT PWFS UIF MBAZ EPH”, because the letter P is the most common, this is assumed to map to the letter O, so we guess that the key is B so as to shift all the letters by one position.

# Getting Started

## Installing
Software: MARS, download here: https://courses.missouristate.edu/KenVollmar/MARS/download.htm

## Executing program
1. Open a terminal
2. Go to folder where MARS is located (cd PATH_TO_DIRECTORY)
4. Open MARS by java -jar pMRAS.jar
5. Download cipher.asm and .txt files and place in the same folder as MARS
6. Open cipher.asm inside MARS, hit run

```
Commands (read, print, encrypt, decrypt, write, guess, quit): 
```
When program is ran, a simple command menu will pop up on I/O console to let you read a text file into a buffer, print the text in the buffer, encrypt the buffer, decrypt the buffer, write the buffer to a file, guess an encryption key, and quit. 
enter r, p, e, d, w, g, q for the corresponding command. 

## Example: 
```
Commands (read, print, encrypt, decrypt, write, guess, quit):r
Enter file name:plain0.txt
THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG.
Commands (read, print, encrypt, decrypt, write, guess, quit):e
Enter key (upper case letters only):B
UIF RVJDL CSPXO GPY KVNQT PWFS UIF MBAZ EPH.
Commands (read, print, encrypt, decrypt, write, guess, quit):w
Enter file name:cipher0.txt
Commands (read, print, encrypt, decrypt, write, guess, quit):g
Enter a nubmer (the key length) for guessing:1
Enter guess of most common letter:O
B
Commands (read, print, encrypt, decrypt, write, guess, quit):p
UIF RVJDL CSPXO GPY KVNQT PWFS UIF MBAZ EPH.
Commands (read, print, encrypt, decrypt, write, guess, quit):d
Enter key (upper case letters only):B
THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG.
Commands (read, print, encrypt, decrypt, write, guess, quit):q
```

# testing
You can use the attached .txt files to test the program
