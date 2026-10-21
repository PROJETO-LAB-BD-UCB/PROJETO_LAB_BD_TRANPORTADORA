from pathlib import Path
import ast
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ProjectStructureTests(unittest.TestCase):
    def test_python_files_parse(self):
        for source in (ROOT / "app.py", ROOT / "database.py", ROOT / "security.py"):
            with self.subTest(file=source.name):
                ast.parse(source.read_text(encoding="utf-8"), filename=str(source))

    def test_required_pages_and_crud_actions_are_present(self):
        source = (ROOT / "app.py").read_text(encoding="utf-8")
        for feature in (
            "page_advanced_queries", "page_services", "page_security_tests",
            "edit_selected_client", "delete_selected_client", "edit_selected_order",
            "delete_selected_order", "edit_selected_incident", "delete_selected_incident",
            "_run_rollback_demo", "_open_login_dialog",
        ):
            with self.subTest(feature=feature):
                self.assertIn(f"def {feature}", source)

    def test_security_audit_and_performance_sql_exist(self):
        security = (ROOT / "sql" / "04_etapa2_seguranca_auditoria.sql").read_text(encoding="utf-8")
        performance = (ROOT / "sql" / "05_desempenho_transacoes.sql").read_text(encoding="utf-8")
        for expected in ("usuario_aplicacao", "vw_relatorio_operacional", "auditoria_alteracao", "nexo_consulta", "nexo_operador", "nexo_admin", "REVOKE", "trg_auditoria_encomenda_upd"):
            with self.subTest(expected=expected):
                self.assertIn(expected, security)
        self.assertIn("EXPLAIN", performance)
        self.assertIn("@@transaction_isolation", performance)
        self.assertIn("vw_rastreamento_publico", security)
        self.assertNotIn("GRANT SELECT ON db_transportadora.vw_relatorio_operacional TO 'nexo_consulta'@'%';", security)
        app_source = (ROOT / "app.py").read_text(encoding="utf-8")
        self.assertIn("vw_historico_rastreamento_publico", app_source)
        self.assertIn("WHERE UPPER(TRIM(e.codigo_rastreio)) = UPPER(%s)", app_source)
        self.assertIn("reached_duplicate_statement", app_source)
        self.assertIn("errno == 1062", app_source)
        verification = (ROOT / "sql" / "06_verificacao_etapa2.sql").read_text(encoding="utf-8")
        self.assertIn("information_schema.triggers", verification)
        self.assertIn("historico_status_encomenda", verification)


if __name__ == "__main__":
    unittest.main()
