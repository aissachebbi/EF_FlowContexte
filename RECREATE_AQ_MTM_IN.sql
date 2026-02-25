BEGIN
    -- 1. Arrêt de la file d'attente (nécessaire avant suppression)
    BEGIN
        DBMS_AQADM.STOP_QUEUE(queue_name => 'ACETP.MTM_IN');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Queue MTM_IN already stopped or not found.');
    END;

    -- 2. Suppression de la file d'attente
    BEGIN
        DBMS_AQADM.DROP_QUEUE(queue_name => 'ACETP.MTM_IN');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Queue MTM_IN not found.');
    END;

    -- 3. Suppression de la table de file d'attente (et ses objets associés)
    BEGIN
        DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => 'ACETP.TQ_MTM_IN');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Queue Table TQ_MTM_IN not found.');
    END;

    -- 4. Re-création Propre : Table de stockage
    -- Utilisation de SYS.AQ$_JMS_TEXT_MESSAGE pour la compatibilité Java/JMS
    DBMS_AQADM.CREATE_QUEUE_TABLE (
            queue_table        => 'ACETP.TQ_MTM_IN',
            queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE'
    );

    -- 5. Re-création Propre : File d'attente
    DBMS_AQADM.CREATE_QUEUE (
            queue_name  => 'ACETP.MTM_IN',
            queue_table => 'ACETP.TQ_MTM_IN'
    );

    -- 6. Démarrage de la file
    DBMS_AQADM.START_QUEUE (
            queue_name => 'ACETP.MTM_IN'
    );
END;
/
commit;