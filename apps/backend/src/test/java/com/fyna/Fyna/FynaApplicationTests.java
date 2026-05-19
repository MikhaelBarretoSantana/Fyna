package com.fyna.Fyna;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * Smoke test do contexto Spring. Usa o profile {@code test}, que aponta para
 * um Postgres efêmero via Testcontainers (requer Docker disponível na máquina
 * de build). Sem o profile, o teste tentaria conectar no banco de dev e
 * dependeria da infraestrutura local — fonte recorrente de falsos negativos.
 */
@SpringBootTest
@ActiveProfiles("test")
class FynaApplicationTests {

	@Test
	void contextLoads() {
	}

}
