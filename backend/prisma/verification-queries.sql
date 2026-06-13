-- =============================================================================
-- Consultas de verificación para PGAdmin
-- Base de datos: LTIdb | Tablas en snake_case
-- =============================================================================
-- Ejecutar cada bloque por separado en la consola SQL de PGAdmin.
-- Los datos de prueba se insertan con: npx prisma db seed
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CONSULTA A: Posiciones abiertas con empresa y número de candidatos aplicados
-- -----------------------------------------------------------------------------
-- Devuelve todas las vacantes con status OPEN, el nombre de la empresa
-- y cuántas applications tiene cada posición.

SELECT
    p.id                                        AS position_id,
    p.title                                     AS position_title,
    c.name                                      AS company_name,
    COUNT(a.id)                                 AS total_candidates
FROM positions p
INNER JOIN companies c
    ON c.id = p.company_id
LEFT JOIN applications a
    ON a.position_id = p.id
WHERE p.status = 'OPEN'
GROUP BY
    p.id,
    p.title,
    c.name
ORDER BY
    p.title;


-- -----------------------------------------------------------------------------
-- CONSULTA B: Flujo detallado de un candidato específico
-- -----------------------------------------------------------------------------
-- Muestra el nombre completo, la posición, el paso de entrevista actual,
-- la fecha de la cita y las notas del entrevistador.
--
-- "Paso actual" = la entrevista más reciente con resultado PENDING,
-- o la última entrevista registrada si no hay ninguna pendiente.
--
-- Cambia el email en el WHERE para consultar otro candidato.

WITH candidate_application AS (
    SELECT
        cand.id             AS candidate_id,
        cand.first_name,
        cand.last_name,
        cand.email,
        app.id              AS application_id,
        app.status          AS application_status,
        pos.title           AS position_title
    FROM candidates cand
    INNER JOIN applications app
        ON app.candidate_id = cand.id
    INNER JOIN positions pos
        ON pos.id = app.position_id
    WHERE cand.email = 'laura.martinez@seed.dev'   -- ← candidato del seed
),
current_interview AS (
    SELECT DISTINCT ON (ca.application_id)
        ca.candidate_id,
        ca.first_name,
        ca.last_name,
        ca.email,
        ca.position_title,
        ca.application_status,
        istep.name          AS current_step,
        istep.order_index   AS step_order,
        i.interview_date,
        i.result            AS interview_result,
        i.notes             AS interviewer_notes,
        emp.name            AS interviewer_name
    FROM candidate_application ca
    INNER JOIN interviews i
        ON i.application_id = ca.application_id
    INNER JOIN interview_steps istep
        ON istep.id = i.interview_step_id
    INNER JOIN employees emp
        ON emp.id = i.employee_id
    ORDER BY
        ca.application_id,
        -- Prioriza entrevistas pendientes (paso actual); si no, la más reciente
        CASE WHEN i.result = 'PENDING' THEN 0 ELSE 1 END,
        i.interview_date DESC
)
SELECT
    first_name || ' ' || last_name          AS full_name,
    email,
    position_title,
    application_status,
    current_step                            AS current_interview_step,
    step_order,
    interview_date,
    interview_result,
    interviewer_name,
    interviewer_notes
FROM current_interview;


-- -----------------------------------------------------------------------------
-- CONSULTA B (alternativa): Historial completo de entrevistas del candidato
-- -----------------------------------------------------------------------------
-- Útil para ver todo el recorrido, no solo el paso actual.

SELECT
    cand.first_name || ' ' || cand.last_name  AS full_name,
    pos.title                                 AS position_title,
    istep.name                                AS interview_step,
    istep.order_index                         AS step_order,
    i.interview_date,
    i.result,
    i.score,
    emp.name                                  AS interviewer,
    i.notes                                   AS interviewer_notes
FROM candidates cand
INNER JOIN applications app
    ON app.candidate_id = cand.id
INNER JOIN positions pos
    ON pos.id = app.position_id
INNER JOIN interviews i
    ON i.application_id = app.id
INNER JOIN interview_steps istep
    ON istep.id = i.interview_step_id
INNER JOIN employees emp
    ON emp.id = i.employee_id
WHERE cand.email = 'laura.martinez@seed.dev'
ORDER BY
    istep.order_index,
    i.interview_date;
