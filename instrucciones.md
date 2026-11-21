# Minijuegos MathForge

Cinco minijuegos en **Roblox** para niños de 8 a 10 años. La matemática va dentro de la mecánica: el niño juega a repartir, equilibrar o descubrir, y nunca ve la palabra "problema". Los porcentajes son el acierto nacional en la prueba Canguro Ecolier 2026 de cuarto grado (falta anotar la fuente de esos porcentajes para el pitch).

**Qué nos diferencia:** cada decisión de diseño sale de la investigación sobre cómo aprenden los niños (ver "Base en la investigación", al final), no solo de que el juego sea divertido.

| Juego | Id en el código | Habilidades (para la rueda de la web de papás) |
|---|---|---|
| El Mandadero | `mandadero` | memoria, geométrico (giros y recorridos) |
| La Balanza | `balanza` | deductivo |
| ¿Qué se esconde? | `escondido` | inductivo/abductivo, geométrico |
| El Colado | `colado` | inductivo |
| ¡El suelo es lava! | `lava` | deductivo, memoria |
| El Mensajero (extra) | `mensajero` | memoria, deductivo, geométrico |

Los ids son los mismos en `papas/servidor/modulos.ts` y en `roblox/src/shared/Modulos.luau`.

---

## 1. El Mandadero (memoria de trabajo)

Un motorizado oye un pedido, el pedido se tapa y tiene que entregarlo completo después de recorrer el barrio.

**Matemática dentro del juego:** el pedido es la información que hay que retener, y cobrar el vuelto es la operación que se hace mientras se recuerda. Si se le olvida algo, la entrega sale mal.

**Lo que entrena (y lo que no prometemos):** practicar memoria sola casi no mejora otras habilidades (Sala y Gobet, 2017). Por eso aquí la memoria está al servicio del razonamiento: sostener el pedido **mientras** se resuelve el recorrido y el vuelto, como piden los problemas de Canguro. El puntaje premia el recorrido y el vuelto, no solo recordar la lista.

**Basado en Canguro 2026**
- Recorrido que pasa por cada calle una sola vez, siguiendo flechas (preg. 12, 30 % de acierto).
- Giros a la derecha o izquierda del personaje (preg. 19, 28 %).

**Piso bajo:** 2 productos y 4 calles. **Techo alto:** 5 productos al revés, y el niño elige desde dónde arrancar.

### Instrucciones

**Objetivo:** entregar el pedido completo sin olvidar nada.

**Cómo se juega**
1. Mira el pedido de la clienta (de 2 a 5 productos).
2. El pedido se tapa.
3. Maneja la moto siguiendo las flechas. En algunos niveles tienes que pasar por cada calle una sola vez.
4. Al llegar, elige los productos en el orden en que te los pidieron.

**Niveles**
- 1: 2 productos y 4 calles.
- 2: 3 productos, y además cobrar el vuelto.
- 3: la clienta lo quiere al revés.
- 4: 5 productos, eliges desde dónde arrancar para pasar por todas las calles, con giros a la derecha o izquierda de la moto.

**Si se equivoca:** la clienta dice "¡Me faltó el tamal!" y el pedido se repite con un producto menos. Si falla dos veces seguidas el recorrido, se iluminan las próximas flechas.

---

## 2. La Balanza (deductivo, álgebra)

Las dos palmas del gesto 6-7 son los platos (el "6-7" queda como guiño escondido: el nombre del juego es "La Balanza", porque el meme cansa a muchos docentes y envejece rápido). El niño pone y quita objetos hasta que quedan parejas y así descubre cuánto pesa el objeto misterioso.

**Matemática dentro del juego:** el peso de la caja es la incógnita. Para que las palmas queden parejas, los dos lados tienen que pesar lo mismo. No hay ecuaciones escritas: la balanza muestra si la igualdad se cumple.

**Basado en Canguro 2026**
- "Dame 2 y quedamos iguales": pasar objetos de un plato al otro (preg. 18, 40 %).
- Monstruos con distintos ojos y patas como pesas, dos datos a la vez (preg. 14, 48 %).

**Piso bajo:** ¿qué lado pesa más? **Techo alto:** dos balanzas y dos objetos misteriosos.

### Instrucciones

**Objetivo:** dejar las dos palmas parejas y descubrir cuánto pesa la caja misteriosa.

**Cómo se juega**
1. Arrastra bloques a una palma o a la otra.
2. **Antes de soltar, toca hacia dónde crees que se va a inclinar.** Predecir obliga a pensar (y deja ver si entendió la igualdad).
3. La balanza se inclina hacia el lado que pesa más.
4. Cuando queda pareja suena "¡Six-Seven!" (el guiño).
5. Di cuánto pesa la caja.

**Niveles**
- 1: ¿qué lado pesa más?
- 2: una caja misteriosa.
- 3: "dame 2 y quedamos iguales", pasando objetos de una palma a la otra.
- 4: monstruos con distintos ojos y patas como pesas.
- 5: dos balanzas y dos misterios.
- Extra: modo globo, donde se suelta lastre para llegar a la meta. Si el total da 67, hay premio secreto.

**Si se equivoca:** la balanza se mueve de forma exagerada y chistosa. Si falla dos veces seguidas, se ilumina un bloque que ayuda a emparejar.

---

## 3. ¿Qué se esconde? (abductivo, geométrico)

Un animal tico armado con piezas de tangram está tapado. Entre menos bloques destape el niño antes de adivinar, más puntos gana. Después lo reconstruye.

**Matemática dentro del juego:** cada bloque destapado es una pista, y adivinar con menos bloques premia la mejor hipótesis. Armar el animal con el tangram es componer figuras.

**Basado en Canguro 2026**
- Cartas con la mitad de arriba tapada: deducir qué dígito es por los trazos (preg. 20, 17 %).
- Papeles apilados y cortados: ¿cuántos pedazos salen? (preg. 8, 19 %).
- Arranque fácil con el rompecabezas del animal (preg. 1, 83 %).

**Piso bajo:** el animal casi descubierto. **Techo alto:** un solo bloque abierto y cartas a medias.

### Instrucciones

**Objetivo:** adivinar el animal destapando la menor cantidad de bloques.

**Cómo se juega**
1. Toca un bloque para destaparlo.
2. Cuando creas saber qué animal es, elígelo.
3. Entre menos bloques destapes, más puntos ganas.
4. Después arma el animal con las piezas de tangram.

**Niveles**
- 1: animal grande, casi destapado.
- 2: tablero de 4×3 bloques.
- 3: tablero de 5×4 y menos opciones parecidas.

**Retos extra** (misma idea de "adivinar lo que no se ve", pero son otro juego; van aparte para no mezclar reglas):
- Cartas con la mitad de arriba tapada: adivina los dígitos y la operación.
- Papeles apilados: ¿cuántos pedazos salen después de cortar?

**Si se equivoca:** se destapa un bloque que da otra pista, **y cuenta como un bloque destapado** (si fuera gratis, adivinar al azar convendría más que pensar). Si falla dos veces seguidas, las opciones bajan de 3 a 2. Nunca se pierde la partida.

---

## 4. El Colado (inductivo)

Una fila de bailarines sigue un patrón de ropa y pasos. El niño encuentra al que se coló y predice cómo se verá un bailarín muy lejos en la fila.

**Matemática dentro del juego:** para encontrar al colado y vestir al bailarín 50 hay que descubrir la regla de la fila y usarla. Contar uno por uno no alcanza, porque la fila se va antes.

**Basado en Canguro 2026**
- "¿Cómo va vestido el bailarín 50?": ciclos largos (preg. 21, 9 %, la de menor acierto de toda la prueba).
- Código secreto: cada símbolo es un dígito y hay que descifrarlo (preg. 13, 27 %).

**Piso bajo:** patrón de 2 colores. **Techo alto:** patrón doble de ropa y pasos, con el bailarín 50.

### Instrucciones

**Objetivo:** encontrar al bailarín que rompe el patrón y adivinar cómo va vestido uno muy lejano.

**Cómo se juega**
1. Mira la fila bailar.
2. Toca al que se coló.
3. **Elige la regla** entre 3 frases ("se repite cada 3", "cada 2 cambia de paso", …). Explicar el porqué fija lo aprendido.
4. La fila se aleja y aparece el bailarín número 50. Elige su ropa.

**Ejemplo resuelto que se retira:** la primera vez que sale el bailarín lejano, el juego muestra el bailarín 10 agrupando la fila por ciclos ("cada grupo de 3 es igual; 10 = 3 + 3 + 3 + 1"). La segunda vez muestra solo el primer grupo. Desde la tercera, el niño lo hace solo.

**Niveles**
- 1: patrón de 2 colores.
- 2: patrón de 3 colores.
- 3: ropa y paso de baile a la vez.
- 4: el bailarín número 50.
- 5: código secreto, donde cada símbolo es un dígito.

**Si se equivoca:** la fila baila más lento y brilla cada vez que el patrón vuelve a empezar. Si falla dos veces seguidas, se agrupan los bailarines por ciclo.

---

## 5. ¡El suelo es lava! (deductivo, memoria de trabajo) · jugable

El niño tiene que cruzar un piso de baldosas. Con un palo tantea si cada baldosa es piso o lava, pero cada tanteo cuesta. La regla del nivel le deja deducir dónde es seguro sin tantear todo. Si se quema, su camino se borra pero el piso sigue igual, así que tiene que recordar por dónde iba.

**Matemática dentro del juego:** la regla "una lava por fila y por columna" es lo que permite cruzar sin tantear todo. Cada lava que se encuentra vuelve seguras otras baldosas.

**Basado en Canguro 2026**
- Regla "una sola lava por fila y por columna", igual que los canguros de la preg. 7 (43 %) y la cuadrícula 2-0-2-6 de la preg. 17 (29 %).
- Techo alto: baldosas con un número que dice cuánta lava hay a su lado, como los dulces vecinos de la preg. 24 (8 %).

**Piso bajo:** 3×3. **Techo alto:** 5×5 con números.

### Instrucciones

**Objetivo:** cruzar al otro lado sin quemarse y con pocos tanteos.

**Cómo se juega**
1. **Tantear:** toca cualquier baldosa (o hazle clic) y el palo te dice si es piso o lava. Cada tanteo cuenta.
2. **Caminar:** muévete con el joystick o las teclas; no se puede saltar. Las baldosas vecinas a donde estás brillan.
3. Regla: en cada fila y en cada columna hay exactamente una lava.
4. Si encuentras una lava, el resto de su fila y de su columna es seguro.
5. Llegar a la fila de arriba es ganar.

**Niveles**
- 1: piso de 3×3.
- 2: piso de 4×4.
- 3: piso de 5×5. Cada baldosa de piso muestra cuántas lavas tiene a su lado.

**Si se equivoca**
- Si pisa lava, el camino recorrido se borra y vuelve al inicio. El piso no cambia y la lava donde se quemó queda marcada, para que aprenda del error.
- Si intenta pisar una lava que ya conoce, el juego le avisa y no lo quema.
- Después de 2 quemadas en el mismo piso, se marcan con ✓ las baldosas que ya se sabe que son seguras.
- Si se quema más de 3 veces, el piso cambia por uno nuevo y se regala una lava descubierta para arrancar con ventaja.
- Todos los pisos tienen al menos un camino seguro.

**¿Por qué es segura?** De vez en cuando, al pisar una baldosa sin tantearla, el juego pregunta por qué es segura y da 3 razones para elegir ("ya hay lava en esa fila", "ya hay lava en esa columna", "adiviné"). No resta puntos: sirve para que el niño ponga en palabras la regla.

**Puntaje:** de 1 a 3 estrellas según los tanteos. Cada quemada cuenta como dos tanteos.

**A revisar con niños:** que borrar el camino al quemarse no frustre. Si frustra, se deja el camino y solo se vuelve al inicio.

---

## Reglas para los 5 juegos

- **La dificultad se ajusta sola:** 2 aciertos seguidos suben un escalón; 2 fallos seguidos dan una ayuda y, si sigue fallando, bajan un escalón. La meta es que el niño acierte la mayoría de las veces sin que le resulte fácil (cerca de 85 %, Wilson et al. 2019, usado como guía).
- **Volver en días distintos:** el juego invita a jugar un rato cada día en vez de todo de una vez (la práctica espaciada es de lo más sólido, Dunlosky et al. 2013). La rueda de la semana de la web de papás lo refuerza: se cierra con 6 retos de cada habilidad repartidos en la semana.
- **Ruta mezclada:** cuando ya jugó los 5, aparece una ruta con un reto de cada juego mezclados. Tiene que reconocer qué regla usar en cada uno (práctica intercalada).
- **La retroalimentación habla de la tarea, no del niño:** "¡Me faltó el tamal!", "esa fila ya tiene lava", nunca "¡qué inteligente!" ni un sonido de error a secas (Hattie y Timperley, 2007).
- **Sin dinero dentro del juego:** el juego da sellos (uno por juego terminado). Las recargas las maneja el papá desde su web, por esfuerzo (rueda cerrada), no por resultados (Fryer, 2011).
- **Cada reto se reporta** a la web de papás: habilidad, aciertos, intentos, pistas y segundos (`roblox/src/server/Reporte.luau`).

---

## Cómo cumple la rúbrica

| Criterio | Peso | Cómo lo cumplimos |
|---|---|---|
| Alineación con habilidades cognitivas | P1 · 40 % | Cada juego entrena una habilidad del reto: memoria de trabajo, inductivo/abductivo, deductivo y geométrico. Cada uno está basado en las preguntas de Canguro 2026 con menos acierto nacional. |
| Matemática intrínseca | P1 | La matemática es la regla del juego: equilibrar, recordar el pedido, la regla de fila y columna, el patrón de la fila. No hay preguntas tipo examen. |
| Piso bajo y techo alto | P1 | Cada juego tiene de 3 a 5 niveles. En la lava se puede probar: del 3×3 al 5×5 con números. |
| Andamiaje y gestión del error | P1 | Todos los juegos detectan 2 fallos seguidos y dan una ayuda concreta. Nunca se pierde la partida. |
| Funcionalidad del prototipo | P2 · 30 % | En Roblox: la lava funciona completa en 3 niveles, con la lógica probada aparte. Los otros juegos, según avance el fin de semana (concepto o jugables). Los reportes llegan a la web de papás. |
| Usabilidad e interfaz intuitiva | P2 | Las baldosas que se pueden pisar brillan, el botón a usar parpadea al inicio, la meta está marcada arriba y los mensajes son de una línea. |
| Diseño gráfico y UX | P2 | Colores fijos por estado, botones táctiles grandes, y funciona en celular y tablet (donde más se juega Roblox). La web de papás tiene identidad propia: la rueda de carreta. |
| Propuesta de valor e innovación (tecnología e IA) | P3 · 30 % | Juegos cortos basados en datos reales de Canguro Costa Rica y en la investigación sobre aprendizaje. Los papás ven el avance por habilidad y premian el esfuerzo. A futuro, la IA elige la pista según el error que se repite y genera niveles nuevos. |
| Claridad de alcances y limitaciones | P3 | Ver "Alcances y limitaciones". |
| Visión de trabajo futuro y escalabilidad | P3 | Ver "Hoja de ruta y escalabilidad". |

---

## Propuesta de valor

- Ataca las preguntas donde menos aciertan los niños de Costa Rica (9 % a 48 %).
- Partidas de 3 a 5 minutos que se pueden usar en clase o en la casa.
- **IA:** analiza el error que se repite (por ejemplo, siempre olvida el último producto) y elige la pista que corresponde. También genera niveles nuevos con la misma regla matemática, para que el contenido no se acabe.
- Reporte para el docente: qué habilidad necesita refuerzo cada niño.
- **Web para la familia:** la rueda de la semana muestra la práctica por habilidad. El papá puede poner una recarga de Roblox que se gana practicando (esfuerzo), no sacando buenas notas.

## Alcances y limitaciones

- **Funciona hoy:** ¡El suelo es lava! en Roblox con 3 niveles, ayudas y puntaje; la web de papás con rueda semanal, recargas y modo demostración.
- **Concepto o parcial:** Mandadero, Balanza, ¿Qué se esconde? y Colado (según lo que alcance el fin de semana).
- **Todavía no tiene:** la IA de pistas (en el prototipo las ayudas siguen reglas fijas), el cobro real de las recargas (se simula) ni el reporte docente.
- **Falta validar** con niños reales que el juego mejora el desempeño en Canguro.

## Hoja de ruta y escalabilidad

1. **Mes 1:** terminar la Balanza y el Mandadero, y probar con un grupo de cuarto grado.
2. **Meses 2 y 3:** conectar la IA de pistas y el reporte docente, y hacer una prueba antes y después con preguntas tipo Canguro.
3. **Meses 4 a 6:** piloto en escuelas con la Asociación Canguro Matemático y la Escuela de Matemática del TEC.
4. **Escala:** para familias, plan Gratis (1 hijo) y plan Familia por suscripción mensual (ejemplo: $4,99; hasta 5 hijos y recargas por esfuerzo); para escuelas, licencia por escuela. Los niveles se agregan como datos, así que se pueden crear nuevos sin programar.

---

## Base en la investigación

| Técnica | Qué dice | Dónde está en los juegos |
|---|---|---|
| Matemática intrínseca | La matemática dentro de la mecánica enseña más y se retiene mejor que la matemática como premio aparte (Habgood y Ainsworth, 2011; las réplicas son mixtas). | Los 5 juegos: equilibrar, recorrer, deducir la lava. |
| Práctica espaciada | De las técnicas más sólidas (Dunlosky et al., 2013). | Rueda semanal: un poco cada día. |
| Práctica intercalada | Mezclar tipos de problema obliga a elegir la estrategia (prometedora; Dunlosky et al., 2013). | Ruta mezclada. |
| Ejemplos resueltos que se retiran | Al principiante le sirve ver el primer caso resuelto y que la ayuda se vaya quitando (Renkl y Atkinson, 2003). | El Colado: bailarín 10; fantasma del primer paso. |
| Autoexplicación | Explicar el porqué fija lo aprendido. | Lava: "¿por qué es segura?"; Colado: elegir la regla. |
| Predicción | Predecir antes de ver el resultado obliga a pensar. | Balanza: ¿hacia dónde se inclina? |
| Dificultad justa | Cerca de 85 % de acierto como guía (Wilson et al., 2019; resultado teórico). | Escalera: 2 aciertos suben, 2 fallos ayudan o bajan. |
| Retroalimentación sobre la tarea | Decir qué faltó sirve más que juzgar a la persona (Hattie y Timperley, 2007). | "¡Me faltó el tamal!", "esa fila ya tiene lava". |
| Premiar el esfuerzo | Los premios por esfuerzo funcionaron; los premios por resultados, no (Fryer, 2011). Los premios tangibles y esperados pueden bajar la motivación propia (Deci, Koestner y Ryan, 1999; es un tema discutido). | Recarga por rueda cerrada, desde la web del papá; sin dinero dentro del juego. |
| Lo que NO prometemos | Entrenar la memoria sola casi no mejora otras habilidades (Sala y Gobet, 2017). | El Mandadero se presenta como razonar sosteniendo datos, no como "entrenar la memoria". |
