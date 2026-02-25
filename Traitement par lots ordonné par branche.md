C'est un défi classique de haute performance. Si vous traitez **200 000 messages** un par un avec une transaction complète (Lecture MQ \+ Insertion Table 1 \+ Insertion Table 2 \+ Commit) pour chaque message, vous allez saturer la base de données à cause du coût des allers-retours réseau (*network roundtrips*) et de la gestion des verrous.

Pour traiter ce pic le plus vite possible tout en restant transactionnel, voici les **3 leviers** à activer dans votre IntegrationFlow :

### **1\. Le Batching (Traitement par lots) \- LE PLUS IMPORTANT**

Au lieu de faire 200 000 transactions, vous en faites, par exemple, 400 de 500 messages chacune.

Dans Spring Integration, vous pouvez utiliser un Aggregator pour regrouper les messages avant l'insertion en base.

**Attention :** Le batching complique le rollback. Si 1 message sur 500 échoue, tout le lot repart dans la queue MQ.

### **2\. Le Parallélisme (Concurrency)**

Vous devez augmenter le nombre de consommateurs pour qu'IBM MQ puisse "pousser" les messages sur plusieurs threads en même temps.

Java

.configureListenerContainer(c \-\> c

    .concurrentConsumers(10)      // 10 threads qui lisent en permanence

    .maxConcurrentConsumers(50)   // Peut monter à 50 si la queue déborde

    .sessionTransacted(true))

### **3\. Utilisation de JdbcBatchItemWriter ou executeBatch**

Au niveau de la base de données, n'utilisez pas repository.save() dans une boucle. Utilisez le mode **Batch** de JDBC qui envoie une seule commande SQL pour plusieurs lignes.

---

### **Exemple de Flow optimisé pour les pics de charge :**

Voici comment structurer votre code pour combiner **Parallélisme** et **Batching** :

Java

@Bean

public IntegrationFlow highSpeedMqFlow() {

    return IntegrationFlow.from(

        Jms.messageDrivenChannelAdapter(mqConnectionFactory)

            .destination("MA.QUEUE.PIC")

            .configureListenerContainer(c \-\> c

                .concurrentConsumers(20) // Beaucoup de threads pour vider la queue

                .sessionTransacted(true)))

        

        // 1\. On groupe les messages par 500 ou toutes les 2 secondes

        .aggregate(a \-\> a

            .correlationStrategy(m \-\> 1) // On groupe tout le monde ensemble

            .releaseStrategy(new MessageCountReleaseStrategy(500))

            .groupTimeout(2000)

            .sendPartialResultOnExpiry(true))

        

        // 2\. On insère le lot de 500 en une seule fois

        .handle(messages \-\> {

            List\<String\> batch \= (List\<String\>) messages.getPayload();

            saveInBatch(batch);

        })

        .get();

}

@Transactional

public void saveInBatch(List\<String\> payloads) {

    // Utiliser jdbcTemplate.batchUpdate pour les 2 tables

    // C'est 10x plus rapide que 500 .save() individuels

    String sql1 \= "INSERT INTO TABLE1 (col) VALUES (?)";

    jdbcTemplate.batchUpdate(sql1, payloads, 500, (ps, argument) \-\> ps.setString(1, argument));

    

    String sql2 \= "INSERT INTO TABLE2 (col) VALUES (?)";

    jdbcTemplate.batchUpdate(sql2, payloads, 500, (ps, argument) \-\> ps.setString(1, argument));

}

### **Les compromis à accepter pour la performance :**

1. **Risque de doublons au Rollback** : Si vous traitez 500 messages et que le 499ème fait planter la DB, les 500 messages seront remis dans MQ. Au prochain essai, vous ré-insérerez les 498 premiers.  
   * *Solution :* Vos tables doivent être **idempotentes** (utiliser un UPSERT ou ignorer les doublons sur la clé primaire).  
2. **Consommation Mémoire** : Charger 500 messages en mémoire par thread (si vous avez 20 threads) consomme de la RAM. Surveillez votre heap.  
3. **Tuning IBM MQ** : Assurez-vous que la propriété Prefetch (ou MaxMessagesPerTask) est augmentée côté client MQ pour que chaque thread récupère plusieurs messages d'un coup sans attendre.

**Mon conseil :** Commencez par augmenter le concurrentConsumers à 10 ou 20\. Si ce n'est pas assez rapide, passez à l'étape aggregate (batching). L'idempotence de la base de données est la clé de la très haute performance.

C'est un défi classique : comment concilier **haute performance (parallélisme)** et **ordre de traitement (séquentiel)**.

Si vous augmentez simplement le nombre de concurrentConsumers, vous perdrez l'ordre, car le message 2 pourrait être traité par le Thread B avant que le Thread A n'ait fini le message 1\.

Pour garantir l'ordre par **branche** (votre critère de classification) tout en traitant les branches en parallèle, voici la solution d'architecture recommandée avec Spring Integration :

### **La Solution : Le "Message Dispatcher" par Branche**

L'idée est d'avoir un seul point d'entrée qui lit la queue (pour garantir l'ordre de sortie de MQ) et qui distribue les messages dans des files internes (canaux) dédiées à chaque branche.

#### **1\. Architecture logique**

1. **Consumer Unique (Main Inbound) :** Lit IBM MQ de façon séquentielle (concurrentConsumers \= 1).  
2. **Header Enricher :** Extrait l'ID de la "Branche" du message.  
3. **Executor Channel (Le secret) :** Utilise un PartitionedDispatcher ou plus simplement un **Router** qui envoie vers des canaux typés.

#### **2\. Implémentation avec Spring Integration (DSL)**

Java

@Bean

public IntegrationFlow branchOrderedFlow() {

    return IntegrationFlow.from(

        Jms.messageDrivenChannelAdapter(mqConnectionFactory)

            .destination("MA.QUEUE.UNIQUE")

            .configureListenerContainer(c \-\> c

                .concurrentConsumers(1) // OBLIGATOIRE pour garder l'ordre initial de MQ

                .sessionTransacted(true)))

        

        // On détermine la branche (ex: via un header JMS ou le corps du message)

        .route(Message.class, m \-\> extractBranchId(m), 

            r \-\> r

                .resolutionRequired(false)

                .defaultOutputChannel("otherBranchChannel")

                // Chaque branche pointe vers un canal qui a SON PROPRE thread

                .subFlowMapping("BR\_PARIS", sf \-\> sf.channel(c \-\> c.executor(executorParis())).handle(myService))

                .subFlowMapping("BR\_LYON", sf \-\> sf.channel(c \-\> c.executor(executorLyon())).handle(myService))

        )

        .get();

}

@Bean

public Executor executorParis() {

    // Un pool de 1 seul thread par branche garantit l'ordre pour CETTE branche

    ThreadPoolTaskExecutor executor \= new ThreadPoolTaskExecutor();

    executor.setCorePoolSize(1);

    executor.setMaxPoolSize(1);

    return executor;

}

### **3\. Pourquoi c'est la meilleure solution pour 200 000 messages ?**

* **Ordre garanti par branche :** Comme chaque branche a son propre Executor avec **un seul thread**, le message N est forcément traité avant le N+1 pour la branche Paris.  
* **Performance globale :** Si vous avez 50 branches, vous avez 50 threads qui travaillent en parallèle. Votre débit global est 50x plus rapide qu'un traitement unitaire, tout en respectant l'ordre local.  
* **Fiabilité transactionnelle :** En cas d'erreur sur la branche "Paris", la transaction échoue, le message retourne dans IBM MQ.  
  * *Attention :* Si le message 1 de Paris échoue, le message 2 de Paris ne doit pas être traité. Avec un seul thread par branche, le blocage est naturel, ce qui préserve l'ordre.

### **4\. Alternative : Utiliser l'ID de corrélation (JMSXGroupID)**

Si vous pouvez modifier l'application qui envoie les messages sur IBM MQ, demandez-leur d'utiliser le header **JMSXGroupID** (positionné avec l'ID de la branche).

* **Avantage :** IBM MQ garantit que tous les messages ayant le même JMSXGroupID sont envoyés au **même consommateur**.  
* **Configuration Spring :** Vous pouvez alors augmenter concurrentConsumers à 10\. IBM MQ se chargera d'envoyer tous les messages de "Paris" au Thread 1 et tous ceux de "Lyon" au Thread 2\. C'est la solution la plus performante et la plus simple, mais elle dépend de l'émetteur du message.

### **Résumé de ma recommandation :**

1. **Si vous maîtrisez l'émetteur :** Utilisez les **Groupes de Messages JMS (JMSXGroupID)**. C'est géré nativement par IBM MQ et c'est le plus performant.  
2. **Si vous ne maîtrisez pas l'émetteur :** Utilisez le **Router** de Spring Integration avec des **Executor Channels** (1 thread max par canal de branche) pour simuler ce comportement.

Est-ce que vous connaissez le nombre approximatif de branches différentes ? Cela aidera à dimensionner les pools de threads.

C'est une excellente question qui touche à la différence entre le **débit (throughput)** et la **latence**.

En mode **Event-Driven**, IBM MQ "pousse" les messages dès qu'ils sont disponibles. Par défaut, Spring Integration les traite un par un pour garantir la sécurité transactionnelle. Mais si vous recevez 200 000 messages, vous ne voulez pas faire 200 000 allers-retours avec la base de données.

Voici les deux façons de "récupérer la liste" pour traiter en masse tout en restant en mode événementiel :

### **1\. La solution "Batch Natif" (Via le Container)**

Certains adaptateurs JMS modernes permettent de recevoir une liste de messages directement depuis la queue au lieu d'un seul. Pour cela, on configure le ConsumerBatchEnabled sur le container de Spring.

* **Avantage :** C'est très rapide car on vide le buffer de MQ d'un coup.  
* **Inconvénient :** Si un seul message du lot échoue, tout le lot est rejeté dans la queue.

Java

@Bean

public IntegrationFlow batchFlow() {

    return IntegrationFlow.from(

        Jms.messageDrivenChannelAdapter(mqConnectionFactory)

            .configureListenerContainer(c \-\> c

                .consumerBatchEnabled(true) // Active la réception par lots

                .batchSize(100)             // Récupère jusqu'à 100 messages d'un coup

                .transactionManager(jmsTransactionManager)

            )

    )

    .handle(message \-\> {

        // Ici, le payload est une List\<Message\>

        List\<String\> payloads \= (List\<String\>) message.getPayload();

        businessService.saveAll(payloads);

    })

    .get();

}

---

### **2\. La solution "Aggregator" (Le compromis idéal)**

Si vous voulez garder l'ordre par **branche** (comme discuté avant) mais insérer en base par lots pour la performance, vous utilisez un **Aggregator**.

Le flux devient :

1. **Réception unitaire** (pour respecter l'ordre et le dispatch par branche).  
2. **Regroupement** (Aggregator) : On attend d'avoir 500 messages de la branche "Paris" OU que 2 secondes se soient écoulées.  
3. **Traitement lourd** : Une seule insertion SQL pour les 500 messages.

Java

@Bean

public IntegrationFlow optimizedBranchFlow() {

    return IntegrationFlow.from(Jms.messageDrivenChannelAdapter(...))

        .route(m \-\> extractBranchId(m), r \-\> r

            .subFlowMapping("PARIS", sf \-\> sf

                // On regroupe par 500 uniquement pour CETTE branche

                .aggregate(a \-\> a

                    .releaseStrategy(new MessageCountReleaseStrategy(500))

                    .groupTimeout(2000)

                    .expireGroupsUponCompletion(true))

                .handle(payloads \-\> businessService.saveBatch(payloads))

            )

        )

        .get();

}

---

### **En résumé : Pourquoi vous ne recevez pas "tout" d'un coup ?**

Dans un système transactionnel strict :

* **MQ dit :** "Je te donne le message A, dis-moi quand c'est fini."  
* **Si vous voulez "la liste complète" :** Vous prenez un risque. Si vous videz 200 000 messages en mémoire et que votre application crash avant de commit en base, vous perdez 200 000 messages (ou vous créez un rollback gigantesque qui va geler votre base de données).

**Ma recommandation pour vos 200 000 messages :**

N'essayez pas de récupérer les 200 000 d'un coup. Utilisez l'**Option 2 (Aggregator)** avec des lots de **500 ou 1000**.

* C'est le "Sweet Spot" : assez grand pour que la base de données soit ultra-rapide (via batchUpdate), mais assez petit pour ne pas saturer la mémoire et limiter l'impact en cas de rollback.

**Voulez-vous que je vous aide à paramétrer le batchUpdate JDBC pour que vos insertions soient 10 à 20 fois plus rapides qu'avec un save() classique ?**

C'est un défi architectural précis : vous voulez de la **performance** (traitement par lots), de la **hauteur de charge** (200 000 messages) et une **garantie d'ordre strict par branche**.

Pour résoudre cela en mode Event-Driven avec Spring Integration, voici la solution la plus robuste : **Le Partitionnement par Branche avec Agrégation.**

### **L'Architecture proposée**

1. **Le Reader (Unique) :** Lit les messages un par un pour garantir l'ordre de sortie de MQ.  
2. **Le Router :** Envoie chaque message vers un canal dédié à sa branche.  
3. **L'Aggregator (Par branche) :** Attend d'avoir un lot (ex: 100 messages) **pour cette branche spécifique**.  
4. **Le Database Writer :** Effectue une insertion batch en base de données.

### **Le Code (Spring Integration Java DSL)**

Java

@Configuration  
public class BranchOrderedBatchConfig {

    @Autowired  
    private ConnectionFactory mqConnectionFactory;

    @Bean  
    public IntegrationFlow branchFlow() {  
        return IntegrationFlow.from(  
            Jms.messageDrivenChannelAdapter(mqConnectionFactory)  
                .destination("MA.QUEUE.ENTREE")  
                .configureListenerContainer(c \-\> c  
                    .concurrentConsumers(1) // 1 seul pour garantir l'ordre global en sortie de MQ  
                    .sessionTransacted(true)))  
                  
            // 1\. On extrait la branche du Body (ex: JSON)  
            .enrichHeaders(h \-\> h.headerFunction("branchId", m \-\> parseBranch(m.getPayload())))

            // 2\. On route vers un subflow par branche  
            .route(Message.class, m \-\> m.getHeaders().get("branchId"),   
                r \-\> r.defaultOutputChannel("nullChannel") // Si branche inconnue  
                     .subFlowMapping("PARIS", sf \-\> branchSubFlow("PARIS"))  
                     .subFlowMapping("LYON", sf \-\> branchSubFlow("LYON"))  
            )  
            .get();  
    }

    // 3\. Le sous-flux qui gère l'ordre et le batch pour UNE branche  
    private IntegrationFlow branchSubFlow(String branchName) {  
        return f \-\> f  
            // L'agrégateur va grouper les messages par branche  
            .aggregate(a \-\> a  
                .correlationStrategy(m \-\> m.getHeaders().get("branchId"))  
                .releaseStrategy(new MessageCountReleaseStrategy(100)) // Lot de 100  
                .groupTimeout(1000) // Ou toutes les secondes si moins de 100  
                .expireGroupsUponCompletion(true))  
              
            // 4\. Insertion batch en base  
            .handle(messages \-\> {  
                List\<String\> payloads \= (List\<String\>) messages.getPayload();  
                saveToDatabaseInBatch(payloads, branchName);  
            });  
    }

    @Transactional  
    public void saveToDatabaseInBatch(List\<String\> payloads, String branch) {  
        // Utiliser jdbcTemplate.batchUpdate pour insérer dans les 2 tables  
        // Cela garantit l'ordre des 100 messages à l'intérieur du batch  
        System.out.println("Sauvegarde batch de " \+ payloads.size() \+ " messages pour " \+ branch);  
    }  
      
    private String parseBranch(Object payload) {  
        // Votre logique pour extraire la branche du body  
        return "PARIS";   
    }  
}

### **Pourquoi cette solution répond à vos 3 besoins ?**

1. **Ordre par branche :** \* Puisque vous lisez MQ avec 1 seul thread (concurrentConsumers(1)), vous respectez l'ordre d'arrivée.  
   * L'agrégateur conserve l'ordre des messages qu'il reçoit à l'intérieur de sa liste (payload). Quand vous faites votre batchUpdate SQL, les messages sont insérés dans l'ordre exact de la liste.  
2. **Performance des pics (200 000 messages) :**  
   * Le goulot d'étranglement est souvent le réseau et les commits DB. En passant de l'insertion unitaire au **Batch (lot de 100\)**, vous divisez par 100 le nombre de commits et de requêtes réseau. Votre débit va exploser.  
3. **Aspect transactionnel :**  
   * Si l'insertion du lot de 100 échoue (ex: erreur DB), la transaction Spring échoue, et grâce au sessionTransacted(true), les 100 messages **restent dans la queue IBM MQ**. Ils seront re-tentés.

### **Une optimisation pour aller encore plus vite**

Si vous avez beaucoup de branches (ex: 50 agences), vous pouvez augmenter le parallélisme **après** la lecture de MQ en utilisant un ExecutorChannel pour chaque branche. Cela permettrait à la branche "PARIS" de ne pas attendre que le batch de "LYON" soit fini d'insérer en base.

**Est-ce que le nombre de branches est fixe ou dynamique dans votre cas ?** (Cela change la façon dont on configure le route).