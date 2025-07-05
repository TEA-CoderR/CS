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
#define MAX_NUM_CLIENTS 32                      // il massimo di pthread  最大线程数
int clients[MAX_NUM_CLIENTS];
int num_clients = 0; 

#define MAX_USERNAME_LENGTH 32                  

//tipi di messaggi
#define MSG_OK "K"
#define MSG_ERR "E"
#define MSG_REGISTRA_UTENTE 'R'                     //特定的客户端信号类型  注册消息
#define MSG_MATRICE 'M'
#define MSG_TEMPO_PARTITA 'T'
#define MSG_TEMPO_ATTESA 'A'
#define MSG_PAROLA 'W'
#define MSG_PUNTI_FINALI 'F'
#define MSG_PUNTI_PAROLA 'P'

//funzionalità aggiuntive    附加功能
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
        printf("non può open dictionary_ita.txt\n");
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

typedef struct {                            //Informazioni sui partecipanti 参与者信息
    char username[MAX_USERNAME_LENGTH + 1];
    int score;
    int registrato; // posizione della bandiera 新增的标志位
} Player;
Player players[MAX_NUM_CLIENTS];        //声明了一个名为 players 的数组，用于存储玩家的相关信息  可以将变量名改成意大利语
int num_players = 0;                    //声明了一个整数变量 num_players 并将其初始化为 0。它用于跟踪当前已连接的玩家数量。
pthread_mutex_t players_mutex = PTHREAD_MUTEX_INITIALIZER;      //这个互斥锁用于保护对 players 数组和 num_players 变量的并发访问，防止多个线程同时修改它们导致数据不一致。


typedef struct {
    char username[MAX_USERNAME_LENGTH + 1];
    char message[256];
} BoardMessage;                         //用户名和消息文本

BoardMessage board_messages[MAX_NUM_CLIENTS];       //声明了一个名为 board_messages 的数组，用于存储每个玩家在公告板上的消息。
int num_board_messages = 0;                         //跟踪当前公告板上消息的数量。  大概不超过8
pthread_mutex_t board_mutex = PTHREAD_MUTEX_INITIALIZER;            //这个互斥锁用于保护对 board_messages 数组和 num_board_messages 变量的并发访问，确保多个线程在操作公告板消息时不会产生冲突。




//int game_duration_minutes;
//int disconnect_timeout_minutes;



static void* myfun(void* arg) {                  // il thread inizia  l'esecuzione con myfun(arg) 
    int client_socket = *(int*)arg;              //本质是和创建线程中的client_socket是一个！ Questo valore intero rappresenta il descrittore del socket del client, utilizzato per comunicare con il client.
    char message_type;
    char buffer[MAX_WORD_LENGTH];

    while (read(client_socket, &message_type, 1) > 0) {
        if (message_type == MSG_REGISTRA_UTENTE) {

             // 注册用户
            read(client_socket, buffer, MAX_USERNAME_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; //去除字符串末尾的换行符 \n

            pthread_mutex_lock(&players_mutex);

            // 检查是否已经有相同名称的用户
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
                players[num_players].registrato = 1; // 设置注册标志位
                num_players++;
                write(client_socket, &MSG_OK, 1);
            } else {
                write(client_socket, &MSG_ERR, 1); // 返回 MSG_ERR 消息
            }

            pthread_mutex_unlock(&players_mutex);
        } else if (message_type == MSG_PAROLA) {            //score
            // 处理单词提交
            read(client_socket, buffer, MAX_WORD_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; // Remove newline character

            if (is_word_valid(buffer)) {
                // parole valida   单词有效
                int word_length = strlen(buffer);
                if (word_length == 2 && buffer[0] == 'q' && buffer[1] == 'u') {
                    word_length = 1; // 'qu' 算作 1 个字母
                }

                pthread_mutex_lock(&players_mutex);
                // 找到提交单词的玩家,并增加其得分
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
                // 单词无效
                write(client_socket, &MSG_ERR, 1);
            }
            
        } else if (message_type == MSG_CANCELLA_UTENTE) {
            // 注销用户
            read(client_socket, buffer, MAX_USERNAME_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; // 去除换行符

            pthread_mutex_lock(&players_mutex);
            int found = -1; // 初始化 found 为 -1
            for(int i = 0; i < num_players; i++) {
                if (strcmp(players[i].username, buffer) == 0) {
                    found = i; // 找到用户名时,记录其在 players 数组中的索引
                    break; // 找到匹配的用户名后,退出循环
                }
            }
            if (found >= 0) {
                // 将找到的用户从 players 数组中移除
                for (int i = found; i < num_players - 1; i++) {
                    players[i] = players[i + 1];
                }
                num_players--;
                write(client_socket, &MSG_OK, strlen(MSG_OK)); // 发送成功消息
            } else {
                write(client_socket, &MSG_ERR, strlen(MSG_ERR)); // 发送错误消息
            }
            pthread_mutex_unlock(&players_mutex);
        }else if (message_type == MSG_LOGIN_UTENTE) {
            // 用户登录
            read(client_socket, buffer, MAX_USERNAME_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; // 去除换行符

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
            // 发送当前的矩阵信息
            char msg_type = MSG_MATRICE;
            write(client_socket, &msg_type, sizeof(msg_type));

            // 将矩阵信息发送给客户端
            genera_matrice();
            write(client_socket, matrice, sizeof(matrice));

            // 发送游戏剩余时间
            msg_type = MSG_TEMPO_PARTITA;
            write(client_socket, &msg_type, 1);
            int time_remaining = 180; // 假设游戏时间为 180 秒
            write(client_socket, &time_remaining, sizeof(int));
        }else if (message_type == MSG_POST_BACHECA) {
            // 发布消息到消息板
             read(client_socket, buffer, MAX_USERNAME_LENGTH);
            buffer[strcspn(buffer, "\n")] = '\0'; // 去除换行符

            read(client_socket, board_messages[num_board_messages].message, 256);
            board_messages[num_board_messages].message[strcspn(board_messages[num_board_messages].message, "\n")] = '\0'; // 去除换行符
            strcpy(board_messages[num_board_messages].username, buffer);
            num_board_messages++;
            write(client_socket, &MSG_OK, strlen(MSG_OK));
        } else if (message_type == MSG_SHOW_BACHECA) {
            // 显示消息板内容
            pthread_mutex_lock(&board_mutex);
            for (int i = 0; i < num_board_messages; i++) {
                char message[512];
                sprintf(message, "%s: %s\n", board_messages[i].username, board_messages[i].message);
                write(client_socket, message, strlen(message));
            }
            pthread_mutex_unlock(&board_mutex);
        } else {
            // 其他消息类型的处理
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
    return playerB->score - playerA->score;  // 降序排序
}
// Nuova funzione per determinare il vincitore
void* score_handler(void* arg) {
    // 从玩家得分队列中读取得分,计算排名并确定获胜者
    // 向所有客户端发送最终结果
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

        // 创建得分处理线程
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