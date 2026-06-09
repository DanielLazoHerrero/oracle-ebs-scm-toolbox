# 🛠️ Oracle EBS SCM & Logistics Toolbox

¡Bienvenido a mi biblioteca personal de utilidades de ingeniería de software para **Oracle E-Business Suite (R12.2.7)**! Este repositorio centraliza scripts de diagnóstico, scripts de soporte avanzados y datafixes críticos diseñados para optimizar el mantenimiento y resolver incidencias transaccionales complejas en entornos de producción.

Toda la lógica incluida ha sido abstrayendo configuraciones propietarias y estructurada bajo estándares profesionales de desarrollo PL/SQL empresarial.

---

## 📂 Estructura de la Caja de Herramientas

El repositorio se organiza modularmente emulando la arquitectura del ERP:

### 📦 1. Módulo de Compras y Abastecimiento (`purchasing-PO`)
Contiene scripts orientados a la conciliación de flujos de procura, requisiciones e interfaces de entrada.
* **`po_req_receipt_qty_sync.sql`**: Datafix crítico para solventar el bloqueo de recepciones en solicitudes internas debido a discrepancias forzadas por modificaciones de cantidad en pedidos de origen. Incluye guía de trazabilidad UI.

### 🏬 2. Módulo de Gestión de Almacenes (`warehouse-WMS`)
Utilidades enfocadas en la precisión del inventario, gestión de contenedores (LPN), tareas bulk y estados materiales.
* **`wms_lpn_locator_status_sync.pls`**: Procedimiento PL/SQL que invoca la API estándar `INV_MATERIAL_STATUS_PUB` para forzar la sincronización masiva y consistencia entre el estado de stock de los LPNs y sus ubicaciones físicas (*Locators*).

---

## ⚙️ Especificaciones del Entorno de Validación
Para garantizar la compatibilidad, los objetos se han testeado y ejecutado bajo la siguiente arquitectura core:
* **ERP:** Oracle Applications E-Business Suite R12.2.7
* **Database RDBMS:** Oracle Database 12c Enterprise Edition (12.1.0.2.0)
* **Esquema de Ejecución:** `APPS`

---

## ⚠️ Buenas Prácticas y Descargo de Responsabilidad
* **Entornos de Ejecución:** Estos scripts interactúan con núcleos transaccionales críticos. Se recomienda encarecidamente probar su comportamiento en instancias de desarrollo (`TEST` / `DEV`) antes de cualquier aplicación en producción.
* **Transaccionalidad:** Los datafixes incluyen bloques explícitos de control de transacciones (`COMMIT` / `ROLLBACK`). Revise los pasos interactivos antes de confirmar los cambios en la base de datos.