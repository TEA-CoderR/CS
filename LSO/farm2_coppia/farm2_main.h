/***********************************************************************
*** progetto LSO farm2
*** 
*** 
*** 
*** @author Yang Juhong
*** @date 01/05/2024
***********************************************************************/
#ifndef FARM2_MAIN_H_
#define FARM2_MAIN_H_

#ifndef SOCKETNAME
#define SOCKETNAME "./farm2.sck"
#endif

/**
 * unlink SOCKETNAME.
 */
static void cleansock();

/** 
 *  inizialliza sockaddr
 * 
 * @param sa socket address
 */
static void inizialliza(struct sockaddr_un *sa);

/** 
 *  inizialliza sigset e maschera i segnali da gestire, ignora SIGPIPE
 * 
 * @param mask sigset agli signali da mascherare
 * @param oldmask sigset vecchio
 * @param s puntatore alla una struttura di sigaction
 */
static void mascheraIgnoraSig(sigset_t *mask, sigset_t *oldmask, struct sigaction *s);

#endif