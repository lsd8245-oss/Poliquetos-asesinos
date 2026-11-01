# Revisión independiente B1

Base d31d340. Implementadores independientes para FX/PNG y ambiente; auditor independiente verificó las cuatro capturas del usuario y los contratos de recursos. El revisor de render comprobó la fuente y el atlas por separado.

Cuatro hallazgos corregidos y revisados nuevamente:

1. La conversión de TTL a tiempo de animación omitía el último cuadro antes de eliminar el FX. Regresión roja conservada; ahora usa frames/fps y el renderer limita el índice al último cuadro. Los efectos se ajustan a su duración real (`age+ttl`), incluso bombas/escudo/pulsos.
2. Giro de misil: el cuerpo dibujado podía quedar fuera del AABB colisionable sin rotar. PNG centrado14×6 frente a core12×6; inclinación visual máxima0.12rad para cuerpos alargados, orientación izquierda/derecha preservada. El ángulo físico y trayectoria no se cambian. Halo verificado ≈1.31px horizontal/0.82px vertical. Los orbes cuadrados conservan su rotación.
3. Destellos de boca y recogida no respetaban Reducir destellos. Ahora baja su alfa, igual que golpe/escudo/bomba.
4. Pausa cambiaba la inclinación y borraba el fogonazo; el contador de reanudación envejecía FX. La presentación se actualiza solo cuando avanza total_time, y conserva pose en pausa/confirmación.

Revisión posterior: sin nuevos bloqueos de fuente; 297rectángulos del atlas2048×2048 sin solapes/salidas y con píxeles idénticos a los PNG individuales. Los cuatro segmentos PNG de criaturas solo oscilan ±1px; simulación/hitboxes permanecen intactas. El auditor mantiene explícita la incertidumbre de la banda central sobredimensionada en captura03: no se atribuye a un evento incompatible con los datos actuales.

La revisión de código no constituye aprobación visual. Esta entrega exige observar las grabaciones y capturas del ejecutable y queda pendiente de la aceptación del usuario.
