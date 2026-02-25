-- =============================================================================
-- TEST DU MODE DRAINAGE (MQ2DB DRAIN MODE TEST)
-- =============================================================================
-- Ce script démontre comment activer le mode drainage pour forcer la libération
-- immédiate d'un lot d'un flux spécifique (ex: MTMIN) pour une branche (ex: FRPP).
-- =============================================================================

-- 1. PRÉPARATION DES DONNÉES DE TEST (Flux MTMIN, Branche FRPP/ID=31)
-- On insère quelques messages 'NEW' pour s'assurer qu'il y a du stock.
DECLARE
    v_cb_id NUMBER;
    v_file_id NUMBER;
BEGIN
    SELECT ACETP.SEQ_CB_FILE.NEXTVAL INTO v_file_id FROM DUAL;
    
    -- Insertion d'un fichier fictif
    INSERT INTO ACETP.CB_FILE (CB_FILE_ID, CB_FILE_TYPE_DB_ID, DIRECTION, EXPECTED_MSG, CREATION_DATE, VERSION_NUM, BRANCH_DB_ID, FILE_NAME, STATUS_TYPE, SEQ_NUMBER)
    VALUES (v_file_id, 1, 'IN', 10, SYSDATE, 1, 31, 'TEST_DRAIN_FILE_'||v_file_id, 'NEW', '001');

    FOR i IN 1..5 LOOP
        SELECT ACETP.SEQ_CB_MSG_DB_ID.NEXTVAL INTO v_cb_id FROM DUAL;
        
        -- Message technique
        INSERT INTO ACETP.CB_MSG (CB_MSG_DB_ID, CB_FILE_DB_ID, CREATION_DATE, VERSION_NUM, BRANCH_DB_ID, DIRECTION, TECHNICAL_TYPE, STATUS_TYPE, EZF_PROC_STATUS, EZF_TRY_COUNT, BIZ_MSG_IDR)
        VALUES (v_cb_id, v_file_id, SYSDATE, 1, 31, 'IN', 'MT', 'NEW', 'NEW', 0, 'MSG_DRAIN_'||v_cb_id);
        
        -- Message métier (obligatoire pour le claim)
        INSERT INTO ACETP.CL_BUSINESS_MTM_IN (FILE_ID, MSG_ID, CB_MSG_DB_ID, CREATION_DATE)
        VALUES (v_file_id, i, v_cb_id, SYSDATE);
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('5 messages de test insérés pour MTMIN / FRPP (Branch ID 31)');
END;
/

-- Mode DRAIN activé pour MTMIN / FRPP.
INSERT INTO ACETP.EF_DRAIN_STATE (FLOW_NAME, BRANCH_CODE)
VALUES ('MTMIN', 'FRPP');
COMMIT;

-- 3. VÉRIFICATION DE L'ÉTAT
-- Requête pour voir si le mode drain est bien enregistré :
SELECT * FROM ACETP.EF_DRAIN_STATE WHERE FLOW_NAME = 'MTMIN';

-- Requête pour surveiller le passage des messages en 'DONE' :
-- SELECT EZF_PROC_STATUS, COUNT(*) FROM ACETP.CB_MSG WHERE BRANCH_DB_ID = 31 GROUP BY EZF_PROC_STATUS;

-- 4. OBSERVATION (Côté Application)
-- Dans les logs (niveau INFO/DEBUG), vous devriez voir :
-- [DEBUG] Poller détecte le mode DRAIN pour MTMIN/FRPP
-- [INFO] Aggregator released batch: flow=MTMIN, cause=DRAIN_COMPLETE
-- [DEBUG] DrainCoordinator.clearDrainRequired('MTMIN', 'FRPP') appelé.

-- 5. VÉRIFICATION FINALE (Après passage du poller)
-- Une fois le lot libéré par le mode DRAIN, la ligne dans EF_DRAIN_STATE doit disparaître automatiquement.
-- SELECT * FROM ACETP.EF_DRAIN_STATE WHERE FLOW_NAME = 'MTMIN';
