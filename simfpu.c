#include <stdio.h>
#include <zconf.h>
#include <stdlib.h>

char znak1;
char wyk1[11];
char man1[52];

char znak2;
char wyk2[11];
char man2[52];


char num1[66];
char num2[66];


void loadTwoNumbers() {
    //Pierwsza liczba
    printf("\nPodaj znak specjalny pierwszej liczby: ");
    scanf("%s", &znak1);

    printf("\nPodaj wykładnik pierwszej liczby. W razie konieczności, zostanie wypełniony zerami do prawej strony: ");
    scanf("%s", wyk1);

    printf("\nPodaj mantysę pierwszej liczby. W razie konieczności, zostanie wypełniona zerami do prawej strony: ");
    scanf("%s", man1);

    //Druga liczba
    printf("\nPodaj znak specjalny drugiej liczby: ");
    scanf("%s", &znak2);

    printf("\nPodaj wykładnik drugiej liczby. W razie konieczności, zostanie wypełniony zerami do prawej strony: ");
    scanf("%s", wyk2);

    printf("\nPodaj mantysę drugiej liczby. W razie konieczności, zostanie wypełniona zerami do prawej strony: ");
    scanf("%s", man2);



    //---- LICZBA 1 -----
    //Znak specjalny LICZBY 1
    num1[0] = znak1;

    //Wykładnik LICZBY 1
    for (int i = 0; i < 11; i++) {
        if (!wyk1[i]) {
            wyk1[i] = '0';
        }
    }

    for (int i = 0, j = 1; i < 11; i++, j++) {
        num1[j] = wyk1[i];
    }


    //Mantysa LICZBY 1
    for (int i = 0; i < 52; i++) {
        if (!man1[i]) {
            man1[i] = '0';
        }
    }

    for (int i = 0, j = 12; i < 52; i++, j++) {
        num1[j] = man1[i];
    }




    //---- LICZBA 2 -----
    //Znak specjalny LICZBY 2
    num2[0] = znak2;

    //Wykładnik LICZBY 2
    for (int i = 0; i < 11; i++) {
        if (!wyk2[i]) {
            wyk2[i] = '0';
        }
    }

    for (int i = 0, j = 1; i < 11; i++, j++) {
        num2[j] = wyk2[i];
    }

    //Mantysa LICZBY 2
    for (int i = 0; i < 52; i++) {
        if (!man2[i]) {
            man2[i] = '0';
        }
    }

    for (int i = 0, j = 12; i < 52; i++, j++) {
        num2[j] = man2[i];
    }

    num1[64] = '\n';
    num2[64] = '\n';

    num1[65] = '\0';
    num2[65] = '\0';

    printf("\nPierwsza liczba: \n");
    printf("%s\n", num1);

    printf("\nDruga liczba: \n");
    printf("%s\n", num2);

    return;
}


int main(void) {
    int option = 0;


    //loadTwoNumbers();

    do {

        printf("Wybierz opcję:\n");
        printf("\t Wczytaj liczby (1)\n");
        printf("\t Dodawanie (2)\n");
        printf("\t Odejmowanie (3)\n");
        printf("\t Mnożenie (4)\n");
        printf("\t Dzielenie (5)\n");
        printf("\t Odwrotność (6)\n");
        printf("\t Wyjście z programu (0)\n");

        FILE *plik1;
        FILE *plik2;

        scanf("%d", &option);
        if(option > 0 && option < 7) {
            switch(option) {
                //TODO: sprawdzenie poprawności otwierania plików
                    //TODO: zamiast fputs --> fprintf(plik1, "%s", num1);
                case 1:
                    loadTwoNumbers();
                    break;
                case 2:
                    //przesłanie zawartości num1 i num2 do plików w katalogu 'add'
                    plik1 = fopen("./add/fpu1.txt", "w");
                    plik2 = fopen("./add/fpu2.txt", "w");

                    fputs(num1, plik1);
                    fputs(num2, plik2);

                    fclose(plik1);
                    fclose(plik2);

                    //uruchomienie funkcji add
                    system("cd add; ./asmfile");
                    break;
                case 3:
                    plik1 = fopen("./subtraction/fpu1.txt", "w");
                    plik2 = fopen("./subtraction/fpu2.txt", "w");

                    fputs(num1, plik1);
                    fputs(num2, plik2);

                    fclose(plik1);
                    fclose(plik2);

                    //uruchomienie funkcji sub
                    system("cd subtraction; ./asmfile");
                    break;

                case 4:
                    plik1 = fopen("./multiplication/fpu1.txt", "w");
                    plik2 = fopen("./multiplication/fpu2.txt", "w");

                    fputs(num1, plik1);
                    fputs(num2, plik2);

                    fclose(plik1);
                    fclose(plik2);

                    //uruchomienie funkcji mul
                    system("cd multiplication; ./asmfile");
                    break;

                case 5:
                    plik1 = fopen("./div/fpu1.txt", "w");
                    plik2 = fopen("./div/fpu2.txt", "w");

                    fputs(num1, plik1);
                    fputs(num2, plik2);

                    fclose(plik1);
                    fclose(plik2);

                    //uruchomienie funkcji div
                    system("cd div; ./asmfile");
                    break;

                case 6:
                    plik1 = fopen("./div/fpu1.txt", "w");
		    fputs(num1, plik1);
		    fclose(plik1);

		    system("cd reverse; ./asmfile");
                    break;
                default:
                    break;




            }


        }

    } while (option != 0);

    getchar();
}
