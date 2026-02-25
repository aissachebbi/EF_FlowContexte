package com.bnpparibas.frmk.easyflow.si.mq2db.config;

import com.bnpparibas.frmk.easyflow.si.mq2db.dao.*;
import com.bnpparibas.frmk.easyflow.si.mq2db.util.schema.SiSchema;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.integration.jdbc.store.JdbcMessageStore;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;

import java.lang.reflect.Field;
import java.util.Map;

@Configuration
public class Mq2DbJdbcInfraConfig {

    private static final Logger LOGGER = LoggerFactory.getLogger(Mq2DbJdbcInfraConfig.class);

    @Bean
    public CbMsgDao cbMsgDao(NamedParameterJdbcTemplate mq2dbNamedJdbcTemplate) {
        return new CbMsgDao(mq2dbNamedJdbcTemplate);
    }

    @Bean
    public CbFileDao cbFileDao(JdbcTemplate mq2dbJdbcTemplate) {
        return new CbFileDao(mq2dbJdbcTemplate);
    }

    @Bean
    public BusinessTableDao businessTableDao(NamedParameterJdbcTemplate mq2dbNamedJdbcTemplate) {
        return new BusinessTableDao(mq2dbNamedJdbcTemplate);
    }

    @Bean
    public AqMockDao aqMockDao(JdbcTemplate mq2dbJdbcTemplate) {
        return new AqMockDao(mq2dbJdbcTemplate);
    }

    @Bean
    public CbMsgClaimDao cbMsgClaimDao(NamedParameterJdbcTemplate mq2dbNamedJdbcTemplate) {
        return new CbMsgClaimDao(mq2dbNamedJdbcTemplate);
    }

    @Bean
    public org.springframework.transaction.support.TransactionTemplate mq2dbTxTemplate(org.springframework.transaction.PlatformTransactionManager transactionManager) {
        return new org.springframework.transaction.support.TransactionTemplate(transactionManager);
    }

    /**
     * Configuration du magasin de messages persistant (Spring Integration).
     * <p><b>Index critique :</b> <code>I_EF_INT_G2M_GK_REG</code> sur <code>EF_INT_GROUP_TO_MESSAGE</code> (GROUP_KEY, REGION).
     * Cet index est vital pour éviter les contentions et les ORA-00060 lors de l'ajout/récupération 
     * des messages dans l'agrégateur en environnement distribué.</p>
     */
    @Bean
    public JdbcMessageStore jdbcMessageStore(javax.sql.DataSource dataSource,
                                                                                         @Value("${acetp.easyflows.componentname:EasyFlows}") String componentName) {
        JdbcMessageStore store = new JdbcMessageStore(dataSource);
        store.setTablePrefix(SiSchema.MSG_STORE_TABLE_PREFIX);
        store.setRegion(componentName);
        return store;
    }

    /**
     * BeanPostProcessor pour injecter l'optimisation Oracle Actif-Actif dans le JdbcMessageStore.
     * Cette approche garantit que l'optimisation est appliquée après l'initialisation complète du bean.
     */
    @Bean
    public static BeanPostProcessor jdbcMessageStoreOptimizationPostProcessor() {
        return new BeanPostProcessor() {
            @Override
            public Object postProcessAfterInitialization(Object bean, String beanName) {
                if (bean instanceof JdbcMessageStore) {
                    optimizeJdbcMessageStore((JdbcMessageStore) bean);
                }
                return bean;
            }

            private void optimizeJdbcMessageStore(JdbcMessageStore store) {
                try {
                    LOGGER.info("Applying Oracle Active-Active optimization to JdbcMessageStore...");

                    Field queryCacheField = JdbcMessageStore.class.getDeclaredField("queryCache");
                    queryCacheField.setAccessible(true);
                    Map queryCache = (Map) queryCacheField.get(store);

                    // Accès à l'énumération Query (privée dans JdbcMessageStore)
                    Class<?> queryEnumClass = Class.forName("org.springframework.integration.jdbc.store.JdbcMessageStore$Query");
                    Object createGroupQuery = Enum.valueOf((Class<Enum>) queryEnumClass, "CREATE_MESSAGE_GROUP");

                    String tablePrefix = SiSchema.MSG_STORE_TABLE_PREFIX;
                    String tableName = tablePrefix + "MESSAGE_GROUP";
                    String pkName = tableName + "_PK";

                    // SQL avec hint Oracle pour ignorer les doublons sur PK sans lever d'exception
                    String insertSql = "INSERT /*+ IGNORE_ROW_ON_DUPKEY_INDEX(" + tableName + ", " + pkName + ") */ " +
                            "INTO " + tableName + "(GROUP_KEY, REGION, COMPLETE, LAST_RELEASED_SEQUENCE, CREATED_DATE, UPDATED_DATE) " +
                            "VALUES (?, ?, 0, 0, ?, ?)";

                    queryCache.put(createGroupQuery, insertSql);
                    LOGGER.info("Successfully injected Oracle hint 'IGNORE_ROW_ON_DUPKEY_INDEX' for table {} and index {}", tableName, pkName);
                } catch (Exception e) {
                    LOGGER.error("CRITICAL: Failed to inject Oracle optimization into JdbcMessageStore. " +
                            "The system will fall back to default SQL which may cause ORA-00001 warnings in Actif-Actif mode. " +
                            "Error: {}", e.getMessage(), e);
                }
            }
        };
    }

    @Bean
    public org.springframework.integration.jdbc.lock.JdbcLockRegistry jdbcLockRegistry(org.springframework.integration.jdbc.lock.LockRepository lockRepository) {
        return new org.springframework.integration.jdbc.lock.JdbcLockRegistry(lockRepository);
    }

    /**
     * BeanPostProcessor pour injecter l'optimisation Oracle dans le DefaultLockRepository.
     * Le schéma Oracle définit EXPIRED_AFTER comme NOT NULL, mais certaines versions de 
     * DefaultLockRepository ne l'incluent pas dans l'INSERT, causant des ORA-01400.
     */
    @Bean
    public static BeanPostProcessor lockRepositoryOptimizationPostProcessor() {
        return new BeanPostProcessor() {
            @Override
            public Object postProcessAfterInitialization(Object bean, String beanName) {
                if (bean instanceof org.springframework.integration.jdbc.lock.DefaultLockRepository) {
                    fixLockRepositoryInsert((org.springframework.integration.jdbc.lock.DefaultLockRepository) bean);
                }
                return bean;
            }

            private void fixLockRepositoryInsert(org.springframework.integration.jdbc.lock.DefaultLockRepository repo) {
                try {
                    Field queryCacheField = org.springframework.integration.jdbc.lock.DefaultLockRepository.class.getDeclaredField("queryCache");
                    queryCacheField.setAccessible(true);
                    Map queryCache = (Map) queryCacheField.get(repo);

                    Field ttlField = org.springframework.integration.jdbc.lock.DefaultLockRepository.class.getDeclaredField("timeToLive");
                    ttlField.setAccessible(true);
                    long ttlMs = (long) ttlField.get(repo);

                    Class<?> queryEnumClass = Class.forName("org.springframework.integration.jdbc.lock.DefaultLockRepository$Query");
                    Object insertQuery = Enum.valueOf((Class<Enum>) queryEnumClass, "INSERT_LOCK");

                    String prefix = SiSchema.LOCK_TABLE_PREFIX;
                    // On recalcule le SQL d'insertion pour inclure EXPIRED_AFTER (calculé comme CREATED_DATE + TTL)
                    // Note: DefaultLockRepository utilise des paramètres positionnels (?) dans son JdbcTemplate interne.
                    // L'ordre standard est: REGION, LOCK_KEY, CLIENT_ID, CREATED_DATE
                    String table = prefix + "LOCK";
                    
                    // La solution la plus robuste sans changer le code de Spring Integration est d'utiliser 
                    // une expression SQL pour le 5ème paramètre basée sur le 4ème (CREATED_DATE).
                    
                    String oracleFixedInsertSql = "INSERT INTO " + table + " (REGION, LOCK_KEY, CLIENT_ID, CREATED_DATE, EXPIRED_AFTER) " +
                            "VALUES (?, ?, ?, ?, ? + numtodsinterval(" + (ttlMs/1000.0) + ", 'SECOND'))";

                    queryCache.put(insertQuery, oracleFixedInsertSql);
                    LOGGER.info("Successfully patched JdbcLockRepository INSERT query with EXPIRED_AFTER support for Oracle (TTL: {}ms).", ttlMs);
                } catch (Exception e) {
                    LOGGER.error("Failed to patch JdbcLockRepository. Lock acquisition might fail if schema has NOT NULL constraint on EXPIRED_AFTER. Error: {}", e.getMessage());
                }
            }
        };
    }

    /**
     * Répertoire des verrous JDBC (Shared Lock).
     * <p><b>Index critique :</b> <code>I_EF_LOCK_REG_DATE</code> sur <code>EF_SHARED_LOCK</code> (REGION, CREATED_DATE).
     * Accélère les opérations du registre de verrous et permet au Reaper de purger les verrous 
     * expirés sans impacter les performances globales.</p>
     */
    @Bean
    public org.springframework.integration.jdbc.lock.DefaultLockRepository lockRepository(javax.sql.DataSource dataSource,
                                                                                          @Value("${acetp.easyflows.componentname:EasyFlows}") String componentName,
                                                                                          @Value("${mq2db.lockreaper.ttlSeconds:330}") int ttlSeconds) {
        org.springframework.integration.jdbc.lock.DefaultLockRepository repo = new org.springframework.integration.jdbc.lock.DefaultLockRepository(dataSource);
        repo.setPrefix(SiSchema.LOCK_TABLE_PREFIX);
        repo.setRegion(componentName);
        // TTL des verrous en millisecondes (par défaut 5.5 minutes)
        int ttlMs = (int) java.util.concurrent.TimeUnit.SECONDS.toMillis(ttlSeconds);
        repo.setTimeToLive(ttlMs);
        return repo;
    }
    @Bean
    public OracleAqDao oracleAqDao(JdbcTemplate mq2dbJdbcTemplate,
                                   @Value("${mq2db.aq.queueName:MTM_IN}") String queueName) {
        return new OracleAqDao(mq2dbJdbcTemplate, queueName);
    }
}
