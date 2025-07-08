#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <arpa/inet.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <time.h>
#include <signal.h>             //per uttillizare alarm()

//#include <sys/types.h>
//#include <ctype.h>

#define N 100

//cerca un parole
#define ALPHABET_SIZE 26
#define MAX_WORD_LENGTH 50
#define MAX_NUM_CLIENTS 32                      // il massimo di pthread  ����߳���
int clients[MAX_NUM_CLIENTS];
int num_clients = 0; 

#define MAX_USERNAME_LENGTH 32                  

//tipi di messaggi
#define MSG_OK "K"
#define MSG_ERR "E"
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



char matrice[4][4];
void genera_matrice() {                         //prima funzione
    static int seed = 0;
    if (seed == 0) {    
        seed = time(NULL);
        srand(seed);
    }

    char letters[] = "abcdefghijklmnopqrstuvwxyz";
    int len = strlen(letters);

    for(int i = 0; i < 4; i++) {
        for(int j = 0; j < 4; j++) {
            matrice[i][j] = letters[rand()%len];
        }  
    }
}

//cerca
typedef struct TrieNode {
    struct TrieNode* children[ALPHABET_SIZE];
    int isEndOfWord;
} TrieNode;

TrieNode* createNode() {
    TrieNode* newNode = (TrieNode*)malloc(sizeof(TrieNode));
    newNode->isEndOfWord = 0;
    for (int i = 0; i < ALPHABET_SIZE; i++) {
        newNode->children[i] = NULL;
    }
    return newNode;
}
void insert(TrieNode* root, char* word) {
    TrieNode* node = root;
    for (int i = 0; word[i]; i++) {
        int index = word[i] - 'a';
        if (!node->children[index]) {
            node->children[index] = createNode();
        }
        node = node->children[index];
    }
    node->isEndOfWord = 1;
}
int search(TrieNode* root, char* word) {
    TrieNode* node = root;
    for (int i = 0; word[i]; i++) {
        int index = word[i] - 'a';
        if (!node->children[index]) {
            return 0;
        }
        node = node->children[index];
    }
    return (node != NULL && node->isEndOfWord);
}

TrieNode* dictionary_root;
void load_dictionary() {
    dictionary_root = createNode();
    FILE* file = fopen("dictionary_ita.txt", "r");
    if (file == NULL) {
        printf("non pu�� open dictionary_ita.txt\n");
        return;
    }

    char word[MAX_WORD_LENGTH];
    while (fscanf(file, "%s", word) != EOF) {
        insert(dictionary_root, word);
    }
    fclose(file);
}
int is_word_valid(char* word) {
    return search(dictionary_root, word);
}

typedef struct {                            //Informazioni sui partecipanti ��������Ϣ
    char username[MAX_USERNAME_LENGTH + 1];
    int score;
    int registrato; // posizione della bandiera �����ı�־λ
} Player;
Player players[MAX_NUM_CLIENTS];        //������һ����Ϊ players �����飬���ڴ洢��ҵ������Ϣ  ���Խ��������ĳ��������
int num_players = 0;                    //������һ���������� num_players �������ʼ��Ϊ 0�������ڸ��ٵ�ǰ�����ӵ����������
pthread_mutex_t players_mutex = PTHREAD_MUTEX_INITIALIZER;      //������������ڱ����� players ����� num_players �����Ĳ������ʣ���ֹ����߳�ͬʱ�޸����ǵ������ݲ�һ�¡�


typedef struct {
    char username[MAX_USERNAME_LENGTH + 1];
    char message[256];
} BoardMessage;                         //�û�������Ϣ�ı�

BoardMessage board_messages[MAX_NUM_CLIENTS];       //������һ����Ϊ board_messages �����飬���ڴ洢ÿ������ڹ�����ϵ���Ϣ��
int num_board_messages = 0;                         //���ٵ�ǰ���������Ϣ��������  ��Ų�����8
pthread_mutex_t board_mutex = PTHREAD_MUTEX_INITIALIZER;            //������������ڱ����� board_messages ����� num_board_messages �����Ĳ������ʣ�ȷ������߳��ڲ����������Ϣʱ���������ͻ��




//int game_duration_minutes;
//int disconnect_timeout_minutes;



static void* myfun(void* arg) {                  // il thread inizia  l'esecuzione con myfun(arg) 
    int client_socket = *(int*)arg;              //�����Ǻʹ����߳��е�client_socket��һ���� Questo valore intero rappresenta il descrittore del socket del client, utilizzato per comunicare con il client.
    char message_type;
    char buffer[MAX_WORD_LENGTH];

    while (read(client_socket, &message_type, 1) > 0) {
        if (message_type == MSG_REGISTRA_UTENTE) {

             // ע���û�
            read(client_socket, buffer, MAX_USERNAME_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; //ȥ���ַ���ĩβ�Ļ��з� \n

            pthread_mutex_lock(&players_mutex);

            // ����Ƿ��Ѿ�����ͬ���Ƶ��û�
            int found = 0;
            for (int i = 0; i < num_players; i++) {
                if (strcmp(players[i].username, buffer) == 0) {
                    found = 1;
                    break;
                }
            }

            if (!found && num_players < MAX_NUM_CLIENTS) {
                strcpy(players[num_players].username, buffer);
                players[num_players].score = 0;
                players[num_players].registrato = 1; // ����ע���־λ
                num_players++;
                write(client_socket, &MSG_OK, 1);
            } else {
                write(client_socket, &MSG_ERR, 1); // ���� MSG_ERR ��Ϣ
            }

            pthread_mutex_unlock(&players_mutex);
        } else if (message_type == MSG_PAROLA) {            //score
            // �������ύ
            read(client_socket, buffer, MAX_WORD_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; // Remove newline character

            if (is_word_valid(buffer)) {
                // parole valida   ������Ч
                int word_length = strlen(buffer);
                if (word_length == 2 && buffer[0] == 'q' && buffer[1] == 'u') {
                    word_length = 1; // 'qu' ���� 1 ����ĸ
                }

                pthread_mutex_lock(&players_mutex);
                // �ҵ��ύ���ʵ����,��������÷�
                for (int i = 0; i < num_players; i++) {
                    if (players[i].registrato) {
                        players[i].score += word_length;
                        char msg_type = MSG_PUNTI_PAROLA;
                        write(client_socket, &msg_type, 1);
                        write(client_socket, &word_length, sizeof(int));
                        break;
                    }
                }
                pthread_mutex_unlock(&players_mutex);
            } else {
                // ������Ч
                write(client_socket, &MSG_ERR, 1);
            }
            
        } else if (message_type == MSG_CANCELLA_UTENTE) {
            // ע���û�
            read(client_socket, buffer, MAX_USERNAME_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; // ȥ�����з�

            pthread_mutex_lock(&players_mutex);
            int found = -1; // ��ʼ�� found Ϊ -1
            for(int i = 0; i < num_players; i++) {
                if (strcmp(players[i].username, buffer) == 0) {
                    found = i; // �ҵ��û���ʱ,��¼���� players �����е�����
                    break; // �ҵ�ƥ����û�����,�˳�ѭ��
                }
            }
            if (found >= 0) {
                // ���ҵ����û��� players �������Ƴ�
                for (int i = found; i < num_players - 1; i++) {
                    players[i] = players[i + 1];
                }
                num_players--;
                write(client_socket, &MSG_OK, strlen(MSG_OK)); // ���ͳɹ���Ϣ
            } else {
                write(client_socket, &MSG_ERR, strlen(MSG_ERR)); // ���ʹ�����Ϣ
            }
            pthread_mutex_unlock(&players_mutex);
        }else if (message_type == MSG_LOGIN_UTENTE) {
            // �û���¼
            read(client_socket, buffer, MAX_USERNAME_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; // ȥ�����з�

            pthread_mutex_lock(&players_mutex);
            int found = 0;
            for (int i = 0; i < num_players; i++) {
                if (strcmp(players[i].username, buffer) == 0) {
                    found = 1;
                    break;
                }
            }
            if (found) {
                write(client_socket, &MSG_OK, strlen(MSG_OK));
            } else {
                write(client_socket, &MSG_ERR, strlen(MSG_ERR));
            }
            pthread_mutex_unlock(&players_mutex);
        } else if (message_type == MSG_MATRICE) {
            // ���͵�ǰ�ľ�����Ϣ
            char msg_type = MSG_MATRICE;
            write(client_socket, &msg_type, sizeof(msg_type));

            // ��������Ϣ���͸��ͻ���
            genera_matrice();
            write(client_socket, matrice, sizeof(matrice));

            // ������Ϸʣ��ʱ��
            msg_type = MSG_TEMPO_PARTITA;
            write(client_socket, &msg_type, 1);
            int time_remaining = 180; // ������Ϸʱ��Ϊ 180 ��
            write(client_socket, &time_remaining, sizeof(int));
        }else if (message_type == MSG_POST_BACHECA) {
            // ������Ϣ����Ϣ��
             read(client_socket, buffer, MAX_USERNAME_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; // ȥ�����з�

            read(client_socket, board_messages[num_board_messages].message, 256);
            board_messages[num_board_messages].message[strcspn(board_messages[num_board_messages].message, "\n")] = '\0'; // ȥ�����з�
            strcpy(board_messages[num_board_messages].username, buffer);
            num_board_messages++;
            write(client_socket, &MSG_OK, strlen(MSG_OK));
        } else if (message_type == MSG_SHOW_BACHECA) {
            // ��ʾ��Ϣ������
            pthread_mutex_lock(&board_mutex);
            for (int i = 0; i < num_board_messages; i++) {
                char message[512];
                sprintf(message, "%s: %s\n", board_messages[i].username, board_messages[i].message);
                write(client_socket, message, strlen(message));
            }
            pthread_mutex_unlock(&board_mutex);
        } else {
            // ������Ϣ���͵Ĵ���
        }
    }

    close(client_socket);
    pthread_exit(NULL);
}

// Funzione per aggiornare il punteggio di un giocatore
void update_player_score(char* username, int score_increment) {
    pthread_mutex_lock(&players_mutex);
    for (int i = 0; i < num_players; i++) {
        if (strcmp(players[i].username, username) == 0) {
            players[i].score += score_increment;
            break;
        }
    }
    pthread_mutex_unlock(&players_mutex);
}

int comparePlayers(const void* a, const void* b) {
    const Player* playerA = (const Player*)a;
    const Player* playerB = (const Player*)b;
    return playerB->score - playerA->score;  // ��������
}
// Nuova funzione per determinare il vincitore
void* score_handler(void* arg) {
    // ����ҵ÷ֶ����ж�ȡ�÷�,����������ȷ����ʤ��
    // �����пͻ��˷������ս��
    while (1) {
        // Leggi i punteggi di tutti i giocatori
        pthread_mutex_lock(&players_mutex);
        Player sorted_players[MAX_NUM_CLIENTS];
        memcpy(sorted_players, players, sizeof(players));
        pthread_mutex_unlock(&players_mutex);

        // Ordina i giocatori in ordine decrescente di punteggio
        qsort(sorted_players, num_players, sizeof(Player), comparePlayers);
        // Determina il vincitore
        int winner_index = 0;
        int winner_score = sorted_players[0].score;
        char winner_name[MAX_USERNAME_LENGTH + 1];
        strcpy(winner_name, sorted_players[0].username);

        // Invia i risultati finali a tutti i client connessi
        char msg_type = MSG_PUNTI_FINALI;
        for (int i = 0; i < num_players; i++) {
            write(clients[i], &msg_type, 1);
            write(clients[i], &sorted_players[i].score, sizeof(int));
            write(clients[i], sorted_players[i].username, MAX_USERNAME_LENGTH + 1);
        }

        // Attendi un po' prima di rieseguire il controllo dei punteggi
        sleep(10); // Puoi regolare questo valore in base alle esigenze del tuo gioco
    }
    pthread_exit(NULL);
}



int main(int argc, char* argv[]){
    if (argc < 3 || argc > 9) {
        printf("Inserire: %s <nome_server> <porta_server> [--matrici <data_filename>] [--durata <durata_in_minuti>] [--seed <rnd_seed>] [--diz <dizionario>]\n", argv[0]);
        return 1;
    }
    char *nome_server = argv[1];
    int porta_server = atoi(argv[2]);
    char *data_filename = NULL;
    int durata_partita = 3;
    int rnd_seed = time(NULL);
    char *dizionario = NULL;
    for (int i = 3; i < argc; i++) {
        if (strcmp(argv[i], "--matrici") == 0 && i + 1 < argc) {
            data_filename = argv[++i];
        } else if (strcmp(argv[i], "--durata") == 0 && i + 1 < argc) {
            durata_partita = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--seed") == 0 && i + 1 < argc) {
            rnd_seed = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--diz") == 0 && i + 1 < argc) {
            dizionario = argv[++i];
        } else {
            printf("Opzione sconosciuta: %s\n", argv[i]);
            return 1;
        }
    }

    //socket
    int server = socket(AF_INET, SOCK_STREAM, 0);
    if(server < 0){
        printf("socket error:%s\n",strerror(errno));
        exit(-1);
    }
    char buf[N];

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(porta_server);
    server_addr.sin_addr.s_addr = inet_addr(nome_server); 

    bind(server, (struct sockaddr*)&server_addr, sizeof(server_addr));
    listen(server, MAX_NUM_CLIENTS);
    printf("Server started, listening on %s:%d\n", nome_server, porta_server);

    //genera una matrice
    genera_matrice();
    load_dictionary();

    while(1){
        struct sockaddr_in client_addr;
        socklen_t client_addr_len = sizeof(client_addr);
        int client_socket = accept(server,(struct sockaddr*)&client_addr,&client_addr_len);
        if(client_socket < 0){
            printf("accept error:%s\n",strerror(errno));
            continue;
        }
        if (client_socket != -1) {
            clients[num_clients++] = client_socket;
        }

        pthread_t tid;
        if(pthread_create(&tid, NULL,myfun,(void*)&client_socket) != 0 ){
            printf("pthread_create:%s\n",strerror(errno));
            close(client_socket);
        }else{
            pthread_detach(tid);
        }

        // �����÷ִ����߳�
        pthread_t score_tid;
        static int score_thread_created = 0;  // Utilizzare variabili static per garantire che i thread di elaborazione dei punteggi siano creati una sola volta.
        if (pthread_create(&score_tid, NULL, score_handler, NULL) != 0) {
            printf("pthread_create:%s\n", strerror(errno));
            close(score_tid);
        }else{
            pthread_detach(score_tid);
            score_thread_created = 1;
        }
    }
    close(server);
    return 0;


    
}