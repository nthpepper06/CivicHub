package com.civichub.common;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class CsvUtilsTest {

    @Test
    void textShouldEscapePlainCommaQuoteAndNewlineValues() {
        assertThat(CsvUtils.escapeText("plain text")).isEqualTo("plain text");
        assertThat(CsvUtils.escapeText("hello, world")).isEqualTo("\"hello, world\"");
        assertThat(CsvUtils.escapeText("hello \"world\"")).isEqualTo("\"hello \"\"world\"\"\"");
        assertThat(CsvUtils.escapeText("hello\nworld")).isEqualTo("\"hello\nworld\"");
    }

    @Test
    void textShouldNeutralizeFormulaPrefixes() {
        assertThat(CsvUtils.escapeText("=SUM(A1:A2)")).isEqualTo("'=SUM(A1:A2)");
        assertThat(CsvUtils.escapeText("+CMD")).isEqualTo("'+CMD");
        assertThat(CsvUtils.escapeText("-2+3")).isEqualTo("'-2+3");
        assertThat(CsvUtils.escapeText("@SUM(A1:A2)")).isEqualTo("'@SUM(A1:A2)");
    }

    @Test
    void textShouldNeutralizeFormulaPrefixesAfterWhitespace() {
        assertThat(CsvUtils.escapeText(" =SUM(A1:A2)")).isEqualTo("' =SUM(A1:A2)");
        assertThat(CsvUtils.escapeText("\t=SUM(A1:A2)")).isEqualTo("'\t=SUM(A1:A2)");
    }

    @Test
    void trustedValuesShouldNotConvertBackendControlledNumericOrDateValues() {
        assertThat(CsvUtils.escapeTrustedValue(-2)).isEqualTo("-2");
        assertThat(CsvUtils.escapeTrustedValue("2026-07-22T23:59:59")).isEqualTo("2026-07-22T23:59:59");
    }

    @Test
    void textShouldKeepVietnameseContent() {
        assertThat(CsvUtils.escapeText("Bảo trì đường Nguyễn Huệ")).isEqualTo("Bảo trì đường Nguyễn Huệ");
    }
}
