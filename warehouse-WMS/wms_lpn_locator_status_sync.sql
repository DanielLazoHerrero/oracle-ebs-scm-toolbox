-- ========================================================================
-- PACKAGE/PROCEDURE: xx_sync_lpn_locator_status_prc
-- OBJETIVO: Fuerza la sincronización del estado del material (Onhand Status) 
--           de un contenedor LPN para que coincida obligatoriamente con el 
--           estado maestro de la ubicación física (Locator) en la que reside.
-- ========================================================================

CREATE OR REPLACE PROCEDURE xx_sync_lpn_locator_status_prc (
    p_organization_id IN NUMBER
) IS
    -- Declaraciones comunes de API E-Business Suite
    l_api_version      NUMBER      := 1.0; 
    l_init_msg_list    VARCHAR2(2) := FND_API.G_TRUE; 
    l_commit           VARCHAR2(2) := FND_API.G_FALSE; 
    x_return_status    VARCHAR2(2);
    x_msg_count        NUMBER      := 0;
    x_msg_data         VARCHAR2(255);
    
    -- Declaraciones específicas para la API de Estados de Material
    l_object_type      VARCHAR2(20); 
    l_status_rec       INV_MATERIAL_STATUS_PUB.mtl_status_update_rec_type;   
    
    -- Cursor de registros a corregir: Identifica LPNs cuyo estado de Onhand 
    -- difiere del estado asignado a su ubicación física.
    CURSOR c_fix IS
        SELECT wlpn.license_plate_number nro_lpn,
               wlpn.lpn_id, 
               moqd.inventory_item_id, 
               moqd.lot_number, 
               moqd.locator_id, 
               wlpn.subinventory_code subalmacen, 
               moqd.status_id status_id_onhand,
               ubi.status_id status_id_ubi
        FROM wms_license_plate_numbers wlpn, 
             mtl_onhand_quantities_detail moqd, 
             mtl_item_locations ubi
        WHERE wlpn.lpn_id = moqd.lpn_id(+) 
          AND wlpn.organization_id = p_organization_id
          AND moqd.status_id != ubi.status_id
          AND wlpn.locator_id = ubi.inventory_location_id
          AND moqd.locator_id = ubi.inventory_location_id;

BEGIN
    -- NOTA: Se asume que el contexto FND_GLOBAL.APPS_INITIALIZE 
    -- se establece en el envoltorio concurrente previo a invocar este procedimiento.

    -- Inicialización de variables constantes de actualización
    l_object_type                 := 'H'; -- 'O'=Lot, 'S'=Serial, 'Z'=Subinventory, 'L'=Locator, 'H'=Onhand
    l_status_rec.organization_id  := p_organization_id;
    l_status_rec.update_reason_id := 141; -- Reason ID mapeado a corrección administrativa (Ajustar según instancia)
    l_status_rec.update_method    := 2;

    FOR r_fix IN c_fix LOOP

        -- Mapeo de la transacción para el LPN iterado
        l_status_rec.inventory_item_id := r_fix.inventory_item_id;
        l_status_rec.lot_number        := r_fix.lot_number;
        l_status_rec.locator_id        := r_fix.locator_id;
        l_status_rec.status_id         := r_fix.status_id_ubi;  -- Forzamos la herencia del estado de la ubicación
        l_status_rec.lpn_id            := r_fix.lpn_id;

        -- Llamada a la API nativa de actualización de estado
        INV_MATERIAL_STATUS_PUB.update_status (
             p_api_version_number => l_api_version
           , p_init_msg_lst       => l_init_msg_list       
           , p_commit             => l_commit             
           , x_return_status      => x_return_status      
           , x_msg_count          => x_msg_count          
           , x_msg_data           => x_msg_data           
           , p_object_type        => l_object_type        
           , p_status_rec         => l_status_rec         
        );
        
        -- Volcado de log de ejecución estructurado
        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            DBMS_OUTPUT.PUT_LINE('ERROR - Sincronización fallida LPN: ' || r_fix.nro_lpn);
            FOR i IN 1..x_msg_count LOOP
                DBMS_OUTPUT.PUT_LINE(FND_MSG_PUB.get(p_msg_index => i, p_encoded => FND_API.G_FALSE));
            END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE('ÉXITO - LPN: ' || r_fix.nro_lpn || ' actualizado al Estado de Ubicación ID: ' || r_fix.status_id_ubi);
        END IF;
    
    END LOOP;
    
    -- Confirmación del bloque transaccional
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('EXCEPCIÓN CRÍTICA EN xx_sync_lpn_locator_status_prc: ' || SQLERRM);
END xx_sync_lpn_locator_status_prc;
/