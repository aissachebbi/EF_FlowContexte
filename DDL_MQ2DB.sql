-- =====================================================================
-- TABLE: CALENDAR
-- =====================================================================
create table ACETP.CALENDAR
(
    CALENDAR_DB_ID       NUMBER(15)           not null
        constraint PK_CALENDAR
            primary key,
    LOGICAL_BUSINESS_DAY DATE,
    CREATION_DATE        DATE default SYSDATE not null,
    UPDATING_DATE        DATE,
    VERSION_NUM          NUMBER               not null,
    PRE_MATCHING_GRP     VARCHAR2(4)
)
/

comment on column ACETP.CALENDAR.CALENDAR_DB_ID is 'PK'
/

comment on column ACETP.CALENDAR.CREATION_DATE is 'Date of creation (of the row)'
/

comment on column ACETP.CALENDAR.UPDATING_DATE is 'Date of last update (of the row)'
/

comment on column ACETP.CALENDAR.VERSION_NUM is 'Row version number (for optimistic locking)'
/

-- =====================================================================
-- TABLE: BRANCH
-- =====================================================================
create table ACETP.BRANCH
(
    BRANCH_DB_ID         NUMBER(4)                 not null
        constraint PK_BRANCH
            primary key,
    CALENDAR_DB_ID       NUMBER(15)                not null,
    POSTAL_ADDR_DB_ID    NUMBER(10)                not null,
    NAME                 VARCHAR2(40)              not null,
    BIC                  VARCHAR2(11),
    TIME_ZONE            VARCHAR2(50),
    CCY                  VARCHAR2(3),
    BRANCH_OPEN          NUMBER(1) default 1       not null,
    CREATION_DATE        DATE      default sysdate not null,
    UPDATING_DATE        DATE,
    VERSION_NUM          NUMBER                    not null,
    CODE                 VARCHAR2(4)               not null,
    RISK_CALENDAR_DB_ID  NUMBER(15)                not null,
    NPK_CALENDAR_DB_ID   NUMBER(15),
    AGG_HOMOGENEOUS_MVTS NUMBER(1) default 0       not null
)
/

comment on table ACETP.BRANCH is 'Definition: This class contains basic information about a branch.'
/

comment on column ACETP.BRANCH.BRANCH_DB_ID is 'U>>>>>>PK'
/

comment on column ACETP.BRANCH.CREATION_DATE is 'Ub>>>>>Date of creation (of the row)'
/

comment on column ACETP.BRANCH.UPDATING_DATE is 'U>>>>>>Date of last update (of the row)'
/

comment on column ACETP.BRANCH.VERSION_NUM is 'U>>>>>>Row version number (for optimistic locking)'
/

-- Indexes for BRANCH
create unique index ACETP.INN_BRANCH
    on ACETP.BRANCH (CODE)
/

-- index technique
create unique index ACETP.PK_BRANCH
    on ACETP.BRANCH (BRANCH_DB_ID)
/

-- =====================================================================
-- TABLE: APPLICATION_PARAMETER
-- =====================================================================
create table ACETP.APPLICATION_PARAMETER
(
    VALUE                       VARCHAR2(2000),
    CREATION_DATE               DATE           default sysdate not null,
    UPDATING_DATE               DATE,
    VERSION_NUM                 NUMBER                         not null,
    BRANCH_DB_ID                NUMBER(4)
        constraint FK_APPLICAT_REF_BRANCH
            references ACETP.BRANCH,
    KEY                         VARCHAR2(80)                   not null,
    APPLICATION_PARAMETER_DB_ID NUMBER(15)                     not null
        constraint PK_APPLICATION_PARAMETER
            primary key,
    CB_REFERENCE                VARCHAR2(50)   default NULL,
    VALUE_TYPE                  VARCHAR2(20)   default NULL    not null,
    VALUE_EXEMPLE               VARCHAR2(2000) default NULL    not null,
    NARRATIVE                   VARCHAR2(1000) default NULL,
    BRANCH_OR_ID                NUMBER(4),
    CR_REFERENCE                VARCHAR2(50)
)
/

-- Indexes for APPLICATION_PARAMETER
create index ACETP.INN_APPLICATION_PARAMETER_KEY
    on ACETP.APPLICATION_PARAMETER (KEY)
/

create index ACETP.INN_FK_APPLICAT_REF_BRANCH
    on ACETP.APPLICATION_PARAMETER (BRANCH_DB_ID)
/

create unique index ACETP.IUN_APPLICATION_PARAMETER
    on ACETP.APPLICATION_PARAMETER (KEY, BRANCH_DB_ID)
/

-- index technique
create unique index ACETP.PK_APPLICATION_PARAMETER
    on ACETP.APPLICATION_PARAMETER (APPLICATION_PARAMETER_DB_ID)
/

-- =====================================================================
-- TABLE: CB_FILE_TYPE
-- =====================================================================
create table ACETP.CB_FILE_TYPE
(
    CB_FILE_TYPE_DB_ID        NUMBER(15)                not null
        constraint PK_CB_FILE_TYPE
            primary key,
    LOGICAL_FILE_TYPE         VARCHAR2(30)              not null,
    SENDER_APPLICATION        VARCHAR2(10),
    RECEIVER_APPLICATION      VARCHAR2(10),
    TECHNICAL_TYPE            VARCHAR2(2),
    CREATION_DATE             DATE      default SYSDATE not null,
    UPDATING_DATE             DATE,
    VERSION_NUM               NUMBER                    not null,
    RUNNING_STATUS_IND        NUMBER(1) default 1       not null,
    BRANCH_DB_ID              NUMBER(4)
        constraint FK_CB_FILE_REF_BRANCH
            references ACETP.BRANCH,
    ENTITY_DB_ID              NUMBER(4),
    DIRECTION                 VARCHAR2(3)               not null,
    PHYSICAL_FILE_TYPE        VARCHAR2(100)             not null,
    ONE_AT_A_TIME_IND         NUMBER(1) default 0       not null,
    MASS_PROCESSING_IND       NUMBER(1) default 0       not null,
    EF_LOGS_ONE_AT_A_TIME_IND NUMBER(1) default 0       not null,
    COB_CLOSABLE              NUMBER(1) default 1
)
/

comment on column ACETP.CB_FILE_TYPE.CB_FILE_TYPE_DB_ID is 'U>>>>>>PK'
/

comment on column ACETP.CB_FILE_TYPE.LOGICAL_FILE_TYPE is 'U>>>>>>'
/

comment on column ACETP.CB_FILE_TYPE.SENDER_APPLICATION is 'U>>>>>>'
/

comment on column ACETP.CB_FILE_TYPE.RECEIVER_APPLICATION is 'U>>>>>>'
/

comment on column ACETP.CB_FILE_TYPE.TECHNICAL_TYPE is 'U>>>>>>'
/

comment on column ACETP.CB_FILE_TYPE.CREATION_DATE is 'U>>>>>>Date of creation (of the row)'
/

comment on column ACETP.CB_FILE_TYPE.UPDATING_DATE is 'U>>>>>>Date of last update (of the row)'
/

comment on column ACETP.CB_FILE_TYPE.VERSION_NUM is 'U>>>>>>Row version number (for optimistic locking)'
/

comment on column ACETP.CB_FILE_TYPE.RUNNING_STATUS_IND is 'U>>>>>>'
/

comment on column ACETP.CB_FILE_TYPE.BRANCH_DB_ID is 'U>>>>>>-> BRANCH'
/

-- Indexes for CB_FILE_TYPE
create index ACETP.INN_CB_FILE_REF_DIRECTION_1
    on ACETP.CB_FILE_TYPE (DIRECTION)
/

create unique index ACETP.IUN_CB_FILE_TYPE_1
    on ACETP.CB_FILE_TYPE (PHYSICAL_FILE_TYPE)
/

create index ACETP.INN_FK_CB_FILE_REF_BRANCH
    on ACETP.CB_FILE_TYPE (BRANCH_DB_ID)
/

-- index technique
create unique index ACETP.PK_CB_FILE_TYPE
    on ACETP.CB_FILE_TYPE (CB_FILE_TYPE_DB_ID)
/

alter table ACETP.CB_FILE_TYPE
    add constraint AK_CB_FILE_TYPE_1
        unique (PHYSICAL_FILE_TYPE)
/

-- =====================================================================
-- TABLE: CB_FILE
-- =====================================================================
create table ACETP.CB_FILE
(
    CB_FILE_ID           NUMBER(15)                 not null
        constraint PK_CB_FILE
            primary key,
    CB_FILE_TYPE_DB_ID   NUMBER(15)                 not null
        constraint FK_CB_FILE_CB_FIL_CB_FILE
            references ACETP.CB_FILE_TYPE,
    FILE_SIZE            VARCHAR2(15),
    DIRECTION            VARCHAR2(6)                not null,
    ACCOUNT_ID           VARCHAR2(40),
    BP_ROLE_ID           VARCHAR2(30),
    BP_ROLE_TYPE         VARCHAR2(20),
    EVENT_TYPE           VARCHAR2(6),
    EXPECTED_MSG         NUMBER(15),
    CREATION_DATE        DATE       default sysdate not null,
    UPDATING_DATE        DATE,
    VERSION_NUM          NUMBER                     not null,
    LOGICAL_BUSINESS_DAY DATE,
    HSKP_STATUS          CHAR(2)    default 'N'     not null,
    HEADER_LINE_START    NUMBER(15) default -1,
    HEADER_LINE_END      NUMBER(15) default -1,
    TRAILER_LINE_START   NUMBER(15) default -1,
    TRAILER_LINE_END     NUMBER(15) default -1,
    BRANCH_DB_ID         NUMBER(4)                  not null,
    ERROR_OBJ            CLOB,
    FILE_NAME            VARCHAR2(200)              not null,
    STATUS_TYPE          VARCHAR2(5)                not null,
    SEQ_NUMBER           VARCHAR2(20)               not null
)
/

comment on column ACETP.CB_FILE.CB_FILE_ID is '>>DB'
/

comment on column ACETP.CB_FILE.CB_FILE_TYPE_DB_ID is '>>FK-> CB_FILE_TYPE'
/

comment on column ACETP.CB_FILE.CREATION_DATE is '>>@Date of creation (of the row)'
/

comment on column ACETP.CB_FILE.UPDATING_DATE is '>>@Date of last update (of the row)'
/

comment on column ACETP.CB_FILE.VERSION_NUM is '>>@Database version number (for optimistic locking)'
/

comment on column ACETP.CB_FILE.HSKP_STATUS is '>>@Housekeeping status (technical flag)'
/

-- Indexes for CB_FILE
create index ACETP.INN_FK_CB_FILE_CB_FIL_CB_FILE
    on ACETP.CB_FILE (CB_FILE_TYPE_DB_ID)
/

create unique index ACETP.INN_CB_FILE_1
    on ACETP.CB_FILE (FILE_NAME)
/

create index ACETP.INN_CB_FILE_2
    on ACETP.CB_FILE (CREATION_DATE, STATUS_TYPE)
/

create index ACETP.INN_CB_FILE_3
    on ACETP.CB_FILE (LOGICAL_BUSINESS_DAY, SEQ_NUMBER)
/

create index ACETP.INN_CB_FILE_HSKP
    on ACETP.CB_FILE (HSKP_STATUS, CB_FILE_ID)
/

create index ACETP.INN_CB_FILE_STATUS_TYPE
    on ACETP.CB_FILE (STATUS_TYPE)
/

create index ACETP.I_CB_FILE_CREATED_AT
    on ACETP.CB_FILE (CREATION_DATE)
/

-- index technique
create unique index ACETP.PK_CB_FILE
    on ACETP.CB_FILE (CB_FILE_ID)
/

-- =====================================================================
-- TABLE: EF_FLOW_DEFINITION
-- =====================================================================
create table ACETP.EF_FLOW_DEFINITION
(
    FLOW_NAME                 VARCHAR2(30)              not null
        constraint PK_FLOW_DEFINITION
            primary key,
    BUSINESS_TABLE_NAME       VARCHAR2(64)              not null,
    FILETYPE_PHYSICAL_PATTERN VARCHAR2(200)             not null,
    APP_PARAM_KEY_PREFIX      VARCHAR2(80)              not null,
    GROUPING_STRATEGY_BEAN    VARCHAR2(120)             not null,
    CLAIM_BATCH_SIZE          NUMBER    default 200     not null,
    CBMSG_ALLOWED_COLUMNS     VARCHAR2(1000),
    ENABLED                   NUMBER(1) default 1       not null,
    RELOAD_ENABLED            NUMBER(1) default 1       not null,
    VERSION_NUM               NUMBER    default 1       not null,
    CREATION_DATE             DATE      default sysdate not null,
    UPDATING_DATE             DATE,
    NARRATIVE                 VARCHAR2(1000),
    PRIORITY_RANK             NUMBER    default 10      not null
)
/

comment on column ACETP.EF_FLOW_DEFINITION.PRIORITY_RANK is 'Rang de priorité du flux (1=haute, plus élevé=basse)'
/

-- Indexes for EF_FLOW_DEFINITION
create index ACETP.I_FLOW_DEF_ENABLED
    on ACETP.EF_FLOW_DEFINITION (ENABLED, RELOAD_ENABLED)
/

-- =====================================================================
-- TABLE: AQ_MOCK_NOTIFICATION
-- =====================================================================
create table ACETP.AQ_MOCK_NOTIFICATION
(
    AQ_MOCK_ID    NUMBER(15)           not null
        constraint PK_AQ_MOCK_NOTIFICATION
            primary key,
    CREATION_DATE DATE default sysdate not null,
    FLOW_NAME     VARCHAR2(30)         not null,
    BRANCH_DB_ID  NUMBER(4)            not null,
    CB_FILE_DB_ID NUMBER(15)           not null,
    PAYLOAD       CLOB
)
/

-- Indexes for AQ_MOCK_NOTIFICATION
create index ACETP.I_AQ_MOCK_1
    on ACETP.AQ_MOCK_NOTIFICATION (CREATION_DATE)
/

create index ACETP.I_AQ_MOCK_FILE
    on ACETP.AQ_MOCK_NOTIFICATION (CB_FILE_DB_ID)
/

-- index technique
create unique index ACETP.PK_AQ_MOCK_NOTIFICATION
    on ACETP.AQ_MOCK_NOTIFICATION (AQ_MOCK_ID)
/

-- =====================================================================
-- TABLE: EF_INT_MESSAGE
-- =====================================================================
create table ACETP.EF_INT_MESSAGE
(
    MESSAGE_ID    VARCHAR2(36)  not null,
    REGION        VARCHAR2(100) not null,
    CREATED_DATE  TIMESTAMP(6)  not null,
    MESSAGE_BYTES BLOB,
    constraint EF_INT_MESSAGE_PK
        primary key (MESSAGE_ID, REGION)
)
/

-- Indexes for EF_INT_MESSAGE
create index ACETP.EF_INT_MESSAGE_IX1
    on ACETP.EF_INT_MESSAGE (CREATED_DATE)
/

-- =====================================================================
-- TABLE: EF_INT_GROUP_TO_MESSAGE
-- =====================================================================
create table ACETP.EF_INT_GROUP_TO_MESSAGE
(
    GROUP_KEY  VARCHAR2(100) not null,
    MESSAGE_ID VARCHAR2(36)  not null,
    REGION     VARCHAR2(100) not null,
    constraint EF_INT_GROUP_TO_MESSAGE_PK
        primary key (GROUP_KEY, MESSAGE_ID, REGION)
)
PARTITION BY HASH (GROUP_KEY)
PARTITIONS 16
/

-- Indexes for EF_INT_GROUP_TO_MESSAGE
create index ACETP.I_EF_INT_G2M_GK_REG
    on ACETP.EF_INT_GROUP_TO_MESSAGE (GROUP_KEY, REGION)
/

-- =====================================================================
-- TABLE: EF_INT_MESSAGE_GROUP
-- =====================================================================
create table ACETP.EF_INT_MESSAGE_GROUP
(
    GROUP_KEY              VARCHAR2(100) not null,
    REGION                 VARCHAR2(100) not null,
    CONDITION              VARCHAR2(255),
    COMPLETE               NUMBER(19),
    LAST_RELEASED_SEQUENCE NUMBER(19),
    CREATED_DATE           TIMESTAMP(6)  not null,
    UPDATED_DATE           TIMESTAMP(6) default NULL,
    constraint EF_INT_MESSAGE_GROUP_PK
        primary key (GROUP_KEY, REGION)
)
PARTITION BY HASH (GROUP_KEY)
PARTITIONS 16
/

-- =====================================================================
-- TABLE: EF_INT_CHANNEL_MESSAGE
-- =====================================================================
create table ACETP.EF_INT_CHANNEL_MESSAGE
(
    MESSAGE_ID       CHAR(36)      not null,
    GROUP_KEY        VARCHAR2(36)  not null,
    CREATED_DATE     NUMBER(19)    not null,
    MESSAGE_PRIORITY NUMBER(19),
    MESSAGE_SEQUENCE NUMBER(19)    not null,
    MESSAGE_BYTES    BLOB,
    REGION           VARCHAR2(100) not null,
    constraint EF_INT_CHANNEL_MESSAGE_PK
        primary key (REGION, GROUP_KEY, CREATED_DATE, MESSAGE_SEQUENCE)
)
/

-- Indexes for EF_INT_CHANNEL_MESSAGE
create index ACETP.EF_INT_CHANNEL_MSG_DELETE_IDX
    on ACETP.EF_INT_CHANNEL_MESSAGE (REGION, GROUP_KEY, MESSAGE_ID)
/

create unique index ACETP.EF_INT_CHANNEL_MSG_PRIORITY_IDX
    on ACETP.EF_INT_CHANNEL_MESSAGE (REGION, GROUP_KEY, MESSAGE_PRIORITY DESC, CREATED_DATE, MESSAGE_SEQUENCE)
/

-- =====================================================================
-- TABLE: EF_INT_METADATA_STORE
-- =====================================================================
create table ACETP.EF_INT_METADATA_STORE
(
    METADATA_KEY   VARCHAR2(255) not null,
    METADATA_VALUE VARCHAR2(4000),
    REGION         VARCHAR2(100) not null,
    constraint EF_INT_METADATA_STORE_PK
        primary key (METADATA_KEY, REGION)
)
/

-- =====================================================================
-- TABLE: EF_SHARED_LOCK
-- =====================================================================
create table ACETP.EF_SHARED_LOCK
(
    LOCK_KEY     VARCHAR2(100) not null,
    REGION       VARCHAR2(100) not null,
    CLIENT_ID    VARCHAR2(36),
    CREATED_DATE TIMESTAMP(6)  not null,
    EXPIRED_AFTER TIMESTAMP(6)  default NULL,
    constraint PK_EF_SHARED_LOCK
        primary key (LOCK_KEY, REGION)
)
/

-- Indexes for EF_SHARED_LOCK
create index ACETP.IX_EF_SHARED_LOCK_REGION
    on ACETP.EF_SHARED_LOCK (REGION)
/

create index ACETP.I_EF_LOCK_REG_DATE
    on ACETP.EF_SHARED_LOCK (REGION, CREATED_DATE)
/

create index ACETP.I_EF_LOCK_EXP
    on ACETP.EF_SHARED_LOCK (REGION, EXPIRED_AFTER)
/

-- =====================================================================
-- TABLE: CB_MSG
-- =====================================================================
create table ACETP.CB_MSG
(
    CB_MSG_DB_ID           NUMBER(15)                 not null
        constraint PK_CB_MSG
            primary key,
    CB_BIZ_EVT_DB_ID       NUMBER(15),
    CB_FILE_DB_ID          NUMBER(15),
    ACCOUNT_ID             VARCHAR2(40),
    DEVICE                 VARCHAR2(8),
    MSG_TYPE               VARCHAR2(20),
    MSG_FUNCTION           VARCHAR2(6),
    MSG_GROUP              VARCHAR2(6),
    MSG_FAMILY             VARCHAR2(32),
    MUR_IMR                VARCHAR2(40),
    ISIN                   VARCHAR2(12),
    SENDER_ADDR            VARCHAR2(30),
    RECEIVER_ADDR          VARCHAR2(100),
    EVENT_TYPE             VARCHAR2(9),
    EVENT_GROUP            VARCHAR2(6),
    TO_BE_SENT             NUMBER(1),
    CREATION_DATE          DATE       default SYSDATE not null,
    UPDATING_DATE          DATE,
    VERSION_NUM            NUMBER                     not null,
    ORIGINAL_MUR_IMR       VARCHAR2(40),
    MERGED_NBR             NUMBER,
    HSKP_STATUS            CHAR(2)    default 'NW'    not null,
    BRANCH_DB_ID           NUMBER(4)                  not null,
    ENTITY_DB_ID           NUMBER(4),
    SENDER_TIMESTAMP       VARCHAR2(20),
    GRP_USER_DB_ID         NUMBER(15),
    LINE_START             NUMBER(15) default -1      not null,
    LINE_END               NUMBER(15) default -1      not null,
    ERROR_OBJ              CLOB,
    MODIFIED_MESSAGE       CLOB,
    PHYSICAL_MESSAGE       CLOB,
    BIZ_TRACKING_ID        VARCHAR2(80),
    BP_ROLE_ID             VARCHAR2(30),
    BP_ROLE_TYPE           VARCHAR2(20),
    DIRECTION              VARCHAR2(6)                not null,
    SCHEDULE_ID            VARCHAR2(16),
    SENDER_REF             VARCHAR2(35),
    TECHNICAL_TYPE         VARCHAR2(2)                not null,
    STATUS_TYPE            VARCHAR2(6)                not null,
    RECEIVER_REF           VARCHAR2(30),
    TRACKING_ID            VARCHAR2(80),
    PERSISTENT_TRACKING_ID VARCHAR2(80),
    REPROCESS_TRACKING_ID  VARCHAR2(80),
    FUNCTIONAL_KEY         VARCHAR2(1000),
    CY_INX_ID              VARCHAR2(35),
    CURRENT_REPROCESS_NBR  NUMBER(11) default -1      not null,
    BIZ_MSG_IDR            VARCHAR2(40),
    PSET                   VARCHAR2(35),
    PSAFE                  VARCHAR2(35),
    BD_SECTOR_DB_ID        NUMBER(15),
    SP_DB_ID               NUMBER(15),
    SHINE                  VARCHAR2(8),
    EZF_PROC_STATUS        VARCHAR2(20)               not null
        constraint CK_CB_MSG_EZF_STATUS
            check (EZF_PROC_STATUS IN ('NEW', 'IN_PROGRESS', 'DONE', 'ERROR')),
    EZF_CLAIM_TOKEN        VARCHAR2(64),
    EZF_CLAIMED_BY         VARCHAR2(64),
    EZF_CLAIMED_AT         DATE,
    EZF_TRY_COUNT          NUMBER(10)                 not null,
    EZF_LAST_ERROR         VARCHAR2(2000),
    EZF_LOGICAL_FILE_NAME  VARCHAR2(200)
)
/

-- Indexes for CB_MSG
create index ACETP.I_CB_MSG_EZF_1
    on ACETP.CB_MSG (EZF_PROC_STATUS, BRANCH_DB_ID, CREATION_DATE, CB_MSG_DB_ID)
/

create index ACETP.I_CB_MSG_EZF_2
    on ACETP.CB_MSG (EZF_PROC_STATUS, EZF_CLAIMED_AT)
/

create index ACETP.I_CB_MSG_EZF_3
    on ACETP.CB_MSG (EZF_CLAIM_TOKEN)
/

create index ACETP.I_CB_MSG_EZF_FILEMODE
    on ACETP.CB_MSG (EZF_PROC_STATUS, BRANCH_DB_ID, EZF_LOGICAL_FILE_NAME, CB_MSG_DB_ID)
/

create index ACETP.I_CB_MSG_CB_FILE
    on ACETP.CB_MSG (CB_FILE_DB_ID)
/

-- index technique
create unique index ACETP.PK_CB_MSG
    on ACETP.CB_MSG (CB_MSG_DB_ID)
/

-- =====================================================================
-- TABLE: CL_BUSINESS_MTM_IN
-- =====================================================================
create table ACETP.CL_BUSINESS_MTM_IN
(
    FILE_ID                      NUMBER(15)                 not null,
    LINE_START                   NUMBER(15),
    LINE_END                     NUMBER(15),
    MSG_ID                       NUMBER(16)                 not null,
    FCT_MSG                      VARCHAR2(3),
    STATUS_PREVTRX               VARCHAR2(2),
    BANK_CODE                    VARCHAR2(5),
    ENTITY_CODE                  VARCHAR2(5),
    APP_CODE                     VARCHAR2(8),
    CLIENT_ID                    VARCHAR2(11),
    CASH_ACCOUNT                 VARCHAR2(11),
    REV_IRREVOCABLE              VARCHAR2(1),
    DIRECT_INVERSE               VARCHAR2(1),
    CURRENCY_CODE                VARCHAR2(3),
    CASH_AMOUNT                  VARCHAR2(15),
    CURRCODE_FORYWR              VARCHAR2(3),
    YWRCASH_AMOUNT               VARCHAR2(15),
    REF                          VARCHAR2(16),
    VALUE_DATE                   VARCHAR2(8),
    ACCOUNTING_DATE              VARCHAR2(8),
    HOUR                         VARCHAR2(6),
    BOECTDTCD                    VARCHAR2(1),
    PAYMENT_CHANNEL_GEODE        VARCHAR2(3),
    CODEFORMAT_SWIFTCOUNTERPARTY VARCHAR2(1),
    IDENTIFIER_COUNTERPARTY      VARCHAR2(35),
    OPERATION_NUM                VARCHAR2(16),
    MISCBRANCH_CODE              VARCHAR2(4),
    MISCSENDER_RECEIVER          VARCHAR2(19),
    ANSWER_TYPE                  VARCHAR2(2),
    RETURN_CODE                  VARCHAR2(15),
    FUNCTIONAL_KEY               VARCHAR2(1000),
    MSG_TYPE                     VARCHAR2(10),
    MSG_FAMILY                   VARCHAR2(20),
    ACCOUNT_ID                   VARCHAR2(8),
    MSG_REFERENCE                VARCHAR2(20),
    CREATION_DATE                DATE       default SYSDATE not null,
    RCA_DB_ID                    NUMBER(15) default 0       not null,
    REPLY_TO_Q                   VARCHAR2(50),
    REPLY_TO_QMGR                VARCHAR2(50),
    CODED_CH_SET_ID              VARCHAR2(50),
    ISIN_CODE                    VARCHAR2(12),
    CB_MSG_DB_ID                 NUMBER(15),
    CASH_SYSTEM_ORIGIN           VARCHAR2(4),
    MANAGEMENT_SECTOR            VARCHAR2(5),
    CASH_MESSAGE                 VARCHAR2(8),
    PAYMENT_CHANNEL              VARCHAR2(20),
    CREDITED_ACCOUNT             VARCHAR2(11),
    INTERNAL_REMITTER            VARCHAR2(7),
    constraint PK_CL_BUSINESS_MTM_IN
        primary key (FILE_ID, MSG_ID)
)
/

-- Indexes for CL_BUSINESS_MTM_IN
create index ACETP.INN_CL_BUSINESS_MTM_1
    on ACETP.CL_BUSINESS_MTM_IN (FILE_ID, MSG_ID, CB_MSG_DB_ID)
/

create index ACETP.I_BIZ_MTM_CB_MSG_ID
    on ACETP.CL_BUSINESS_MTM_IN (CB_MSG_DB_ID)
/

create index ACETP.I_BIZ_MTM_FILE_ID
    on ACETP.CL_BUSINESS_MTM_IN (FILE_ID)
/

-- index technique
create unique index ACETP.PK_CL_BUSINESS_MTM_IN
    on ACETP.CL_BUSINESS_MTM_IN (FILE_ID, MSG_ID)
/

-- =====================================================================
-- TABLE: EF_MQ2DB_AUDIT_EVENT
-- =====================================================================
create table ACETP.EF_MQ2DB_AUDIT_EVENT
(
    AUDIT_EVENT_ID NUMBER GENERATED BY DEFAULT AS IDENTITY
		constraint PK_MQ2DB_AUDIT_EVENT
			primary key,
    EVENT_TS       TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
    INSTANCE_ID    VARCHAR2(100)                                    not null,
    RUN_ID         VARCHAR2(64)                                     not null,
    SEVERITY       VARCHAR2(10)                                     not null
        constraint CK_MQ2DB_AUDIT_SEV
            check (SEVERITY IN ('INFO', 'WARN', 'ERROR')),
    EVENT_DOMAIN   VARCHAR2(30)                                     not null,
    EVENT_TYPE     VARCHAR2(60)                                     not null,
    FLOW_NAME      VARCHAR2(30),
    BRANCH_CODE    VARCHAR2(30),
    GROUP_KEY      VARCHAR2(200),
    CLAIM_TOKEN    VARCHAR2(128),
    CB_MSG_DB_ID   NUMBER,
    CB_FILE_DB_ID  NUMBER,
    MSG_COUNT      NUMBER,
    DRAIN_MODE     NUMBER(1),
    DRAIN_COMPLETE NUMBER(1),
    RELEASE_CAUSE  VARCHAR2(30),
    STATUS_FROM    VARCHAR2(20),
    STATUS_TO      VARCHAR2(20),
    DURATION_MS    NUMBER,
    ERROR_CODE     VARCHAR2(50),
    ERROR_MESSAGE  VARCHAR2(4000),
    DETAILS_JSON   CLOB
        constraint CK_AUDIT_DETAILS_JSON
            check (DETAILS_JSON IS JSON)
)
/

comment on table ACETP.EF_MQ2DB_AUDIT_EVENT is 'Table unique d audit MQ2DB pour le monitoring et l alerting'
/

comment on column ACETP.EF_MQ2DB_AUDIT_EVENT.EVENT_DOMAIN is 'Domaine fonctionnel: BATCH, REAPER, REGISTRY...'
/

comment on column ACETP.EF_MQ2DB_AUDIT_EVENT.EVENT_TYPE is 'Type précis de l événement (ex: BATCH_TX_COMMITTED)'
/

-- =============================================================================
-- EXEMPLES DE CONSULTATION DU JSON (Oracle 19c)
-- =============================================================================

-- 1. Affichage Formaté (Pretty Print)
-- SELECT
--     AUDIT_EVENT_ID,
--     FLOW_NAME,
--     CB_FILE_DB_ID,
--     JSON_SERIALIZE(DETAILS_JSON RETURNING CLOB PRETTY ORDERED) AS CLAIRE_DETAILS
-- FROM ACETP.EF_MQ2DB_AUDIT_EVENT au
-- WHERE AUDIT_EVENT_ID = 15913;

-- 2. Lecture directe par "Dot Notation" (Grâce à la contrainte IS JSON)
-- SELECT t.DETAILS_JSON.msgCount, t.DETAILS_JSON.cbFileDbId FROM ACETP.EF_MQ2DB_AUDIT_EVENT t;

-- 3. Recherche avec jointure (Exemple complet)
-- SELECT
--     AUDIT_EVENT_ID,
--     FLOW_NAME,
--     CB_FILE_DB_ID,
--     CF.FILE_NAME,
--     JSON_SERIALIZE(DETAILS_JSON RETURNING CLOB PRETTY ORDERED) AS CLAIRE_DETAILS
-- FROM ACETP.EF_MQ2DB_AUDIT_EVENT au
--          JOIN ACETP.CB_FILE CF ON au.CB_FILE_DB_ID = CF.CB_FILE_ID
-- WHERE AUDIT_EVENT_ID = 15913;

-- 4. Recherche par ID spécifique (Exemple simple)
-- SELECT
--     AUDIT_EVENT_ID,
--     -- PRETTY : pour l'indentation (format clair)
--     JSON_SERIALIZE(DETAILS_JSON PRETTY ORDERED) AS CLAIRE_DETAILS
-- FROM ACETP.EF_MQ2DB_AUDIT_EVENT where AUDIT_EVENT_ID > 2400 and AUDIT_EVENT_ID = 9483;

-- 5. Extraire la liste complète des IDs (cbMsgDbIds) sous forme de lignes SQL
-- SELECT jt.id
-- FROM ACETP.EF_MQ2DB_AUDIT_EVENT t,
--      JSON_TABLE(t.DETAILS_JSON, '$.cbMsgDbIds[*]'
--        COLUMNS (id NUMBER PATH '$')) jt
-- WHERE t.AUDIT_EVENT_ID = :id;

-- Indexes for EF_MQ2DB_AUDIT_EVENT
create index ACETP.IX_MQ2DB_AUDIT_TS
    on ACETP.EF_MQ2DB_AUDIT_EVENT (SYS_EXTRACT_UTC("EVENT_TS"))
/

create index ACETP.IX_MQ2DB_AUDIT_FLOW
    on ACETP.EF_MQ2DB_AUDIT_EVENT (FLOW_NAME, SYS_EXTRACT_UTC("EVENT_TS"))
/

create index ACETP.IX_MQ2DB_AUDIT_BRANCH
    on ACETP.EF_MQ2DB_AUDIT_EVENT (BRANCH_CODE, SYS_EXTRACT_UTC("EVENT_TS"))
/

create index ACETP.IX_MQ2DB_AUDIT_DOMAIN
    on ACETP.EF_MQ2DB_AUDIT_EVENT (EVENT_DOMAIN, EVENT_TYPE, SYS_EXTRACT_UTC("EVENT_TS"))
/

-- index technique
create unique index ACETP.PK_MQ2DB_AUDIT_EVENT
    on ACETP.EF_MQ2DB_AUDIT_EVENT (AUDIT_EVENT_ID)
/

-- create search index ACETP.IDX_AUDIT_JSON
--    on ACETP.EF_MQ2DB_AUDIT_EVENT (DETAILS_JSON)
--    for json
-- /

-- =====================================================================
-- TABLE: EF_DRAIN_STATE
-- =====================================================================
create table ACETP.EF_DRAIN_STATE
(
    FLOW_NAME   VARCHAR2(100) not null,
    BRANCH_CODE VARCHAR2(20)  not null,
    primary key (FLOW_NAME, BRANCH_CODE)
        using index (create unique index ACETP.PK_EF_DRAIN_STATE on ACETP.EF_DRAIN_STATE (FLOW_NAME, BRANCH_CODE))
)
/

comment on table ACETP.EF_DRAIN_STATE is 'Stockage centralisé de l''état de drainage pour le cluster MQ2DB'
/

comment on column ACETP.EF_DRAIN_STATE.FLOW_NAME is 'Nom technique du flux'
/

comment on column ACETP.EF_DRAIN_STATE.BRANCH_CODE is 'Code de la branche (agence)'
/

create sequence ACETP.SEQ_AQ_MOCK_NOTIFICATION
    nocache
/

create sequence ACETP.EF_INT_MESSAGE_SEQ
    nocache
/

create sequence ACETP.BDOMO_GRM_TRD_CB_MSGS_DB_ID
    nocache
/

create sequence ACETP.BDOMO_GRM_TRD_CB_MSGS_DB_ID_TEST
    nocache
/

create sequence ACETP.SEQ_CL_BUSINESS_FILE_ID
    nocache
/

create sequence ACETP.ISEQ$$_72859
/

create sequence ACETP.SEQ_CB_FILE
    nocache
/

create sequence ACETP.SEQ_CB_MSG_DB_ID
    nocache
/



BEGIN
    -- 1. Création de la table de stockage (préfixée TQ_ pour Table Queue)
    -- Le type 'SYS.AQ$_JMS_TEXT_MESSAGE' est utilisé pour supporter les messages JMS standard.
    DBMS_AQADM.CREATE_QUEUE_TABLE (
            queue_table        => 'ACETP.TQ_MTM_IN',
            queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE'
    );

    -- 2. Création de la file d'attente nommée MTM_IN
    DBMS_AQADM.CREATE_QUEUE (
            queue_name  => 'ACETP.MTM_IN',
            queue_table => 'ACETP.TQ_MTM_IN'
    );

    -- 3. Activation de la file (Démarrage)
    DBMS_AQADM.START_QUEUE (
            queue_name => 'ACETP.MTM_IN'
    );
END;
/

-- =============================================================================
-- SCRIPTS UTILES (ADMIN & VALIDATION)
-- =============================================================================

-- 1. Changer le schéma par défaut
-- ALTER SESSION SET current_schema = ACETP;

-- 2. Purge rapide des données (Attention : irréversible)
-- 1. Tables Métier
TRUNCATE TABLE ACETP.CL_BUSINESS_MTM_IN REUSE STORAGE;
TRUNCATE TABLE ACETP.CB_MSG REUSE STORAGE;
TRUNCATE TABLE ACETP.CB_FILE REUSE STORAGE;
TRUNCATE TABLE ACETP.EF_MQ2DB_AUDIT_EVENT REUSE STORAGE;

-- 2. Tables de Drainage (Optionnel, si vous voulez reset les COB)
-- TRUNCATE TABLE ACETP.EF_DRAIN_STATE;

-- 3. TOUTES les tables techniques Spring Integration (CRITIQUE)
TRUNCATE TABLE EF_INT_MESSAGE;
TRUNCATE TABLE EF_INT_MESSAGE_GROUP;
TRUNCATE TABLE EF_INT_GROUP_TO_MESSAGE; -- 👈 Table oubliée dans votre script
TRUNCATE TABLE EF_SHARED_LOCK;
commit;

-- 3. Mise à jour manuelle des paramètres applicatifs
-- UPDATE ACETP.APPLICATION_PARAMETER
-- SET VALUE = '*,fileMode:true,messages:500,time:2min',
--     VERSION_NUM = VERSION_NUM + 1,
--     UPDATING_DATE = SYSTIMESTAMP
-- WHERE KEY = 'EZF_MQ2FILE_FLUSH_MTMIN_DEFAULT';
-- COMMIT;

-- 4. Audit rapide des messages en attente
-- SELECT count(*) FROM ACETP.CB_MSG WHERE EZF_PROC_STATUS = 'NEW';

-- 5. Vérification des index de Spring Integration
-- SELECT i.index_name, c.column_name, c.column_position
-- FROM user_indexes i
--          JOIN user_ind_columns c ON i.index_name = c.index_name
-- WHERE i.table_name = 'EF_INT_MESSAGE'
--   AND c.column_name IN ('GROUP_KEY','REGION','CREATED_DATE')
-- ORDER BY i.index_name, c.column_position;

-- 6. Configuration de l'affichage DBMS_METADATA pour les index
-- BEGIN
--     DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
--     DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
--     DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
-- END;
-- /


--Voici la requête pour obtenir uniquement la valeur globale du **Work Time**
--(l'écart entre la toute première et la toute dernière insertion dans la table `ACETP.CB_FILE`) au format `HH:MI:SS';

SELECT
    TO_CHAR(TRUNC(SYSDATE) + (MAX(CREATION_DATE) - MIN(CREATION_DATE)), 'HH24:MI:SS') AS WORK_TIME
FROM
    ACETP.CB_FILE ;


select count(*) from ACETP.CB_MSG where CB_MSG.EZF_PROC_STATUS = 'DONE';


SELECT
    TO_CHAR(TRUNC(SYSDATE) + (MAX(CREATION_DATE) - MIN(CREATION_DATE)), 'HH24:MI:SS') AS WORK_TIME
FROM
    ACETP.CB_FILE
WHERE
    CB_FILE_ID BETWEEN 100 AND 200; -- Remplacez 100 et 200 par vos identifiants

--### Détails :
--*   **`MAX(CREATION_DATE) - MIN(CREATION_DATE)`** : Calcule l'écart total en jours.
--*   **`TO_CHAR(..., 'HH24:MI:SS')`** : Formate cet écart en heures, minutes et secondes.
--*   **`WORK_TIME`** : Le nom de la colonne unique retournée.

