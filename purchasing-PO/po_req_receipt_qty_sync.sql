-- ========================================================================
-- SCRIPT: po_req_receipt_qty_sync.sql
-- OBJETIVO: Ajusta las cantidades de las líneas de requisición y distribución
--           cuando una discrepancia bloquea la recepción de una solicitud interna.
-- ========================================================================

-- PROBLEMA --
-- Se intenta recepcionar una solicitud interna y el sistema no lo permite.
-- El problema se origina por haber modificado las cantidades en el pedido original,
-- haciendo que estas no coincidan con las cantidades pendientes de la recepción.
-- SOLUCION --
-- Este datafix actualiza la requisición para que coincida con las líneas de origen,
-- permitiendo liberar el bloqueo en la interfaz de transacciones.

-- ========================================================================
-- PASO PREVIO: IDENTIFICAR EL ID DEL ENVÍO (SHIPMENT_HEADER_ID)
-- ========================================================================
-- 1. Navegación UI: Inventory Super User --> Transacciones --> Recepción --> Consultar Transacciones de Recepción
-- 2. Consultar por la organización destino y el número de recepción en conflicto.
-- 3. Navegación UI: Diagnósticos --> Examinar --> Bloque: system, Campo: last_query
-- 4. Extraer del final de la consulta (cláusula WHERE) el valor de 'shipment_header_id'.
-- Opcional (Vía SQL): Ejecutar el siguiente bloque sustituyendo &NUMERO_RECEPCION.

SELECT shipment_header_id, receipt_num
FROM rcv_shipment_headers
WHERE receipt_num = '&NUMERO_RECEPCION';

-- ========================================================================
-- DATAFIX - PASO 1 (Limpieza UI)
-- ========================================================================
-- Navegación UI: Inventory Super User > Transacciones > Recepción > Resumen Estado Transacciones
-- Buscar el número de recepción/albarán y ELIMINAR la transacción que se encuentra en estado ERROR.

-- ========================================================================
-- DATAFIX - PASO 2 (Ajuste de Líneas de Requisición)
-- ========================================================================
UPDATE po_requisition_lines_all prl
SET quantity = (
        SELECT SUM(ordered_quantity)
        FROM oe_order_lines_all
        WHERE source_document_line_id = prl.requisition_line_id
          AND source_document_type_id = 10
    ),
    cancel_flag = NULL,
    quantity_cancelled = NULL,
    cancel_date = NULL,
    cancel_reason = NULL
WHERE requisition_line_id IN (
    SELECT requisition_line_id 
    FROM rcv_shipment_lines 
    WHERE shipment_header_id = &SHIPMENT_HEADER_ID -- Introducir ID recuperado en el paso previo
);

-- ========================================================================
-- DATAFIX - PASO 3 (Ajuste de Distribuciones)
-- ========================================================================
UPDATE po_req_distributions_all prd
SET req_line_quantity = (
        SELECT quantity
        FROM po_requisition_lines_all
        WHERE requisition_line_id = prd.requisition_line_id
    )
WHERE requisition_line_id IN (
    SELECT requisition_line_id 
    FROM rcv_shipment_lines 
    WHERE shipment_header_id = &SHIPMENT_HEADER_ID -- Introducir ID recuperado en el paso previo
);

COMMIT;

-- ========================================================================
-- COMPROBACIÓN POST-DATAFIX
-- ========================================================================
-- 1. Navegación UI: Purchasing Super User --> Buscar por número de recepción --> Copiar número de envío.
-- 2. Navegación UI: Recepciones --> Buscar por albarán --> Marcar el check y procesar (Guardar).
-- Resultado esperado: Deberían procesarse correctamente. Comprobar que no han vuelto a la pantalla de Resumen de estado de transacciones.