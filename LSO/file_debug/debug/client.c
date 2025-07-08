#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#define MAX_WORD_LENGTH 50
#define MAX_USERNAME_LENGTH 32


//tipi di messaggi
#define MSG_OK 'K'
#define MSG_ERR 'E'
#define MSG_REGISTRA_UTENTE 'R'                     //�ض��Ŀͻ����ź�����  ע����Ϣ
#define MSG_MATRICE 'M'
#define MSG_TEMPO_PARTITA 'T'
#define MSG_TEMPO_ATTESA 'A'
#define MSG_PAROLA 'W'
#define MSG_PUNTI_FINALI 'F'
#define MSG_PUNTI_PAROLA 'P'

//funzionalit�� aggiuntive    ���ӹ���
#define MSG_CANCELLA_UTENTE 'D'
#define MSG_LOGIN_UTENTE 'L'
#define MSG_POST_BACHECA 'H'
#define MSG_SHOW_BACHECA 'S'

int main(int argc, char *argv[]){
    if(argc != 3){                                  // ./paroliere_cl nome_server porta_server  (3 argomenti)
        printf("Usage: %s <server_address> <server_port>\n", argv[0]);
        return 1;
    }
    char *nome_server = argv[1];
    int porta_server = atoi(argv[2]);           // Converte una stringa in un numero intero. ǿ�ƽ��ַ���ת��Ϊ����

    //crea un socket
    int client = socket(AF_INET, SOCK_STREAM, 0);
	if (client == -1) {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(porta_server);
    server_addr.sin_addr.s_addr = inet_addr(nome_server);

    int conn=connect(client, (struct sockaddr*)&server_addr,sizeof(server_addr));
	if (conn < 0) {
        perror("connect failed");
        exit(EXIT_FAILURE);
    }

    printf("Connected to the server.\n");

	char comando[100];
    char username[11];      //carattere visibile + \0
    int registered = 0;

    //Entrare in una sessione interattiva
	while (1) {
        printf("[PROMPT PAROLIERE]--> ");
        fgets(comando, sizeof(comando), stdin);
        //getchar(); // ���������
        comando[strcspn(comando, "\n")] = '\0'; // ȥ�����з�

        if (strcmp(comando, "aiuto") == 0) {        //se command == "aiuto"
            printf("comando utilizzato:\n");
            printf("registra utente <username>\n");
            printf("matrice\n");
            printf("p <parola>\n");
            printf("fine\n");
        } else if (strncmp(comando, "registra utente ", 15) == 0) {

            char *token = strtok(comando + 15, " ");
            if (token != NULL) {
                strncpy(username, token, 10);
                username[10] = '\0';
            } else {
                printf("Errore: nome utente non valido.\n");
                continue;
            }

            // ���� MSG_REGISTRA_UTENTE ��Ϣ
            char msg_type = MSG_REGISTRA_UTENTE;
            write(client, &msg_type, 1);
            write(client, username, strlen(username) + 1);

            // ���շ�������Ӧ
            read(client, &msg_type, 1);
            if (msg_type == MSG_OK) {
                printf("Registrazione riuscita!\n");
                registered = 1;
            } else {
                printf("Registrazione fallita, il nome utente esiste gi��.\n");
            }
        } else if (strcmp(comando, "matrice") == 0) {
            // ���� MSG_MATRICE ��Ϣ
            char msg_type = MSG_MATRICE;
            write(client, &msg_type, 1);

            // ���շ�������Ӧ
            read(client, &msg_type, 1);
            if (msg_type == MSG_MATRICE) {
                char matrice[4][4];
                read(client, matrice, sizeof(matrice));
                printf("matrice:\n");
                for (int i = 0; i < 4; i++) {
                    for (int j = 0; j < 4; j++) {
                        if (matrice[i][j] == 'q') {
                            printf("qu ");
                        } else {
                            printf("%c  ", matrice[i][j]);
                        }
                    }
                     printf("\n");
                }

                read(client, &msg_type, 1);
                if (msg_type == MSG_TEMPO_PARTITA) {
                    int time_remaining;
                    read(client, &time_remaining, sizeof(int));
                    printf("tempo restos: %d secondi\n", time_remaining);
                } else {
                    int time_remaining;
                    read(client, &time_remaining, sizeof(int));
                    printf("����һ�ֿ�ʼ���� %d secondi\n", time_remaining);
                }
            } else {
                printf("Errore: Impossibile ottenere informazioni sulla matrice.����\n");
            }
        } else if (strncmp(comando, "p ", 2) == 0) {
            if (!registered) {
                printf("Errore: non sei registrato.\n");
                continue;
            }

            char *word = comando + 2;
            if (strlen(word) < 4) {
                printf("Errore: la parola �� troppo corta (meno di 4 caratteri).\n");
                continue;
            }

            // ���� MSG_PAROLA ��Ϣ
            char msg_type = MSG_PAROLA;
            write(client, &msg_type, 1);
            write(client, word, strlen(word) + 1);

            // ���շ�������Ӧ
            read(client, &msg_type, 1);
            if (msg_type == MSG_PUNTI_PAROLA) {
                int points;
                read(client, &points, sizeof(int));
                printf("palore %s puntegi: %d\n", word, points);        //����
            } else {
                printf("Errore: palore %s nonvalida.\n", word);     //���󵥴�
            }
        } else if (strcmp(comando, "fine") == 0) {
            if (registered) {
                // ���� MSG_CANCELLA_UTENTE ��Ϣ
                char msg_type = MSG_CANCELLA_UTENTE;
                write(client, &msg_type, 1);
                write(client, username, strlen(username) + 1);

                // ���շ�������Ӧ
                read(client, &msg_type, 1);
                if (msg_type == MSG_OK) {
                    printf("Utente %s cancellato con successo.\n", username);
                } else {
                    printf("Errore: impossibile cancellare l'utente %s.\n", username);
                }
            }
            break;
        } else {
            printf("Errore: comando non connosciuto '%s'.\n", comando);     //��Ч����
        }
    }

    close(client);
    return 0;
}