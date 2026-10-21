"""Interface desktop para gestão de transportadora, rastreamento e entregas.

A interface usa Tkinter (incluído no Python para Windows) e mysql-connector-python.
Ela conecta diretamente ao servidor MySQL; o MySQL Workbench é usado para administrar
esse servidor e executar os scripts SQL do projeto.
"""
from __future__ import annotations

import re
import tkinter as tk
from decimal import Decimal, InvalidOperation
from pathlib import Path
from datetime import date, datetime
from tkinter import messagebox, ttk
from typing import Any

from database import Database

# Paleta visual
NAVY = "#14213D"
NAVY_2 = "#1D3158"
ORANGE = "#F59E0B"
BG = "#F3F6FB"
WHITE = "#FFFFFF"
TEXT = "#1F2937"
MUTED = "#64748B"
BORDER = "#DCE3EF"
GREEN = "#16805D"
RED = "#C2413B"

STATUS_ENCOMENDA = (
    "REGISTRADA", "COLETADA", "EM_TRIAGEM", "EM_TRANSITO",
    "SAIU_PARA_ENTREGA", "ENTREGUE", "TENTATIVA_FRUSTRADA", "DEVOLVIDA", "EXTRAVIADA",
)


class TransportadoraApp:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.db = Database()
        self.connected = False
        self.current_user: str | None = None
        self.current_display_name: str | None = None
        self.current_role: str | None = None
        self.db_profile_enforced = False
        self.current_page = "Dashboard"
        self.nav_buttons: dict[str, tk.Button] = {}
        self.content: tk.Frame | None = None
        self.status_var = tk.StringVar(value="Desconectado")

        self.root.title("Nexo Logística | Gestão de Transportadora")
        self.root.geometry("1380x860")
        self.root.minsize(1120, 720)
        self.root.configure(bg=BG)
        self._configure_styles()
        self._build_shell()
        if Path(__file__).with_name("config.ini").exists():
            self.root.after(250, self._try_auto_connect)
        else:
            self.show_page("Conexão")

    def _configure_styles(self) -> None:
        style = ttk.Style()
        try:
            style.theme_use("clam")
        except tk.TclError:
            pass
        style.configure("Treeview", background=WHITE, fieldbackground=WHITE, foreground=TEXT,
                        rowheight=31, borderwidth=0, font=("Segoe UI", 9))
        style.configure("Treeview.Heading", background="#EAF0F8", foreground=NAVY,
                        font=("Segoe UI", 9, "bold"), padding=(9, 9), relief="flat")
        style.map("Treeview", background=[("selected", "#DCE8FA")], foreground=[("selected", NAVY)])
        style.configure("TCombobox", padding=7, font=("Segoe UI", 10))
        style.configure("TEntry", padding=7, font=("Segoe UI", 10))
        style.configure("TNotebook", background=BG, borderwidth=0)
        style.configure("TNotebook.Tab", background="#E8EDF5", foreground=NAVY,
                        padding=(15, 9), font=("Segoe UI", 9, "bold"))
        style.map("TNotebook.Tab", background=[("selected", WHITE)])

    def _build_shell(self) -> None:
        shell = tk.Frame(self.root, bg=BG)
        shell.pack(fill="both", expand=True)
        self.sidebar = tk.Frame(shell, bg=NAVY, width=238)
        self.sidebar.pack(side="left", fill="y")
        self.sidebar.pack_propagate(False)
        brand = tk.Frame(self.sidebar, bg=NAVY, padx=20, pady=23)
        brand.pack(fill="x")
        tk.Label(brand, text="NEXO", font=("Segoe UI", 22, "bold"), fg=WHITE, bg=NAVY).pack(anchor="w")
        tk.Label(brand, text="LOGÍSTICA  •  GESTÃO", font=("Segoe UI", 8, "bold"), fg="#AFC0DD", bg=NAVY).pack(anchor="w", pady=(2, 0))
        tk.Frame(self.sidebar, bg="#344766", height=1).pack(fill="x", padx=16, pady=(0, 14))

        nav_items = [
            ("Dashboard", "▦", "Visão geral"),
            ("Clientes", "♙", "Cadastro de clientes"),
            ("Encomendas", "▣", "Remessas e volumes"),
            ("Rastreamento", "⌖", "Histórico de status"),
            ("Entregas", "✓", "Tentativas e ocorrências"),
            ("Frota e rotas", "▤", "Veículos e expedições"),
            ("Relatórios", "▥", "Indicadores operacionais"),
            ("Consultas avançadas", "⌕", "Filtros e agregações"),
            ("Serviços adicionais", "+", "Catálogo de serviços"),
            ("Segurança e testes", "⚒", "Acesso, transações e auditoria"),
        ]
        for page, glyph, subtitle in nav_items:
            btn = tk.Button(self.sidebar, text=f"  {glyph}    {page}", anchor="w", padx=16, pady=12,
                            bg=NAVY, fg="#D8E2F1", activebackground=NAVY_2, activeforeground=WHITE,
                            relief="flat", borderwidth=0, font=("Segoe UI", 10, "bold"), cursor="hand2",
                            command=lambda p=page: self.show_page(p))
            btn.pack(fill="x", padx=10, pady=2)
            self.nav_buttons[page] = btn
        tk.Frame(self.sidebar, bg="#344766", height=1).pack(fill="x", padx=16, pady=(18, 13))
        connection_btn = tk.Button(self.sidebar, text="  ⚙    Conexão MySQL", anchor="w", padx=16, pady=12,
                                   bg=NAVY, fg="#D8E2F1", activebackground=NAVY_2, activeforeground=WHITE,
                                   relief="flat", borderwidth=0, font=("Segoe UI", 10, "bold"), cursor="hand2",
                                   command=lambda: self.show_page("Conexão"))
        connection_btn.pack(fill="x", padx=10, pady=2)
        tk.Label(self.sidebar, text="PROJETO ACADÊMICO\nMySQL 8+  •  Python", justify="left",
                 font=("Segoe UI", 8), fg="#94A7C6", bg=NAVY).pack(side="bottom", anchor="w", padx=22, pady=20)

        main = tk.Frame(shell, bg=BG)
        main.pack(side="left", fill="both", expand=True)
        header = tk.Frame(main, bg=WHITE, height=68, padx=28)
        header.pack(fill="x")
        header.pack_propagate(False)
        tk.Label(header, text="CENTRAL DE OPERAÇÕES", bg=WHITE, fg=MUTED,
                 font=("Segoe UI", 9, "bold")).pack(side="left", pady=22)
        self.connection_badge = tk.Label(header, textvariable=self.status_var, bg="#FCE7C1", fg="#8B5E12",
                                         padx=12, pady=6, font=("Segoe UI", 9, "bold"))
        self.connection_badge.pack(side="right", pady=16)
        tk.Frame(main, bg=BORDER, height=1).pack(fill="x")
        self.page_host = tk.Frame(main, bg=BG)
        self.page_host.pack(fill="both", expand=True)

    def _try_auto_connect(self) -> None:
        try:
            self.db.test_connection()
            self.connected = True
            self.status_var.set(f"Conectado  •  {self.db.settings['database']}")
            self.connection_badge.configure(bg="#D7F3E5", fg=GREEN)
            self._open_login_dialog()
        except Exception:
            self.connected = False
            self.status_var.set("Falha na conexão")
            self.connection_badge.configure(bg="#FDE2E2", fg=RED)
            self.show_page("Conexão")

    def show_page(self, page: str) -> None:
        if self.current_role == "CONSULTA" and page not in ("Relatórios", "Rastreamento", "Conexão"):
            messagebox.showinfo("Perfil de consulta", "Seu perfil tem acesso apenas aos relatórios consolidados e à configuração de conexão.")
            page = "Relatórios"
        self.current_page = page
        for name, button in self.nav_buttons.items():
            active = name == page
            button.configure(bg=NAVY_2 if active else NAVY, fg=WHITE if active else "#D8E2F1")
        for child in self.page_host.winfo_children():
            child.destroy()
        self.content = tk.Frame(self.page_host, bg=BG, padx=28, pady=25)
        self.content.pack(fill="both", expand=True)
        builders = {
            "Dashboard": self.page_dashboard,
            "Clientes": self.page_clients,
            "Encomendas": self.page_orders,
            "Rastreamento": self.page_tracking,
            "Entregas": self.page_deliveries,
            "Frota e rotas": self.page_fleet,
            "Relatórios": self.page_reports,
            "Consultas avançadas": self.page_advanced_queries,
            "Serviços adicionais": self.page_services,
            "Segurança e testes": self.page_security_tests,
            "Conexão": self.page_connection,
        }
        builders.get(page, self.page_dashboard)()

    def page_heading(self, title: str, subtitle: str) -> tk.Frame:
        assert self.content is not None
        block = tk.Frame(self.content, bg=BG)
        block.pack(fill="x", pady=(0, 20))
        tk.Label(block, text=title, bg=BG, fg=NAVY, font=("Segoe UI", 22, "bold")).pack(anchor="w")
        tk.Label(block, text=subtitle, bg=BG, fg=MUTED, font=("Segoe UI", 10)).pack(anchor="w", pady=(5, 0))
        return block

    def card(self, parent: tk.Widget, title: str, value: str, note: str, accent: str = ORANGE) -> tk.Frame:
        frame = tk.Frame(parent, bg=WHITE, highlightbackground=BORDER, highlightthickness=1, padx=18, pady=17)
        tk.Frame(frame, bg=accent, width=4).pack(side="left", fill="y", padx=(0, 15))
        inner = tk.Frame(frame, bg=WHITE)
        inner.pack(side="left", fill="both", expand=True)
        tk.Label(inner, text=title.upper(), bg=WHITE, fg=MUTED, font=("Segoe UI", 8, "bold")).pack(anchor="w")
        tk.Label(inner, text=value, bg=WHITE, fg=NAVY, font=("Segoe UI", 23, "bold")).pack(anchor="w", pady=(5, 2))
        tk.Label(inner, text=note, bg=WHITE, fg=MUTED, font=("Segoe UI", 9)).pack(anchor="w")
        return frame

    def action_button(self, parent: tk.Widget, text: str, command, primary: bool = True) -> tk.Button:
        return tk.Button(parent, text=text, command=command, bg=ORANGE if primary else WHITE,
                         fg=NAVY if primary else NAVY_2, activebackground="#E8A008" if primary else "#EDF2F8",
                         activeforeground=NAVY, relief="flat", bd=0, padx=14, pady=9,
                         font=("Segoe UI", 9, "bold"), cursor="hand2")

    def _need_connection(self) -> bool:
        if self.connected and self.current_user:
            return True
        messagebox.showwarning("Acesso necessário", "Conecte ao MySQL e entre com um usuário da aplicação.")
        self.show_page("Conexão")
        return False

    def _require_write(self) -> bool:
        if not self._need_connection():
            return False
        if self.current_role == "CONSULTA":
            messagebox.showwarning("Permissão insuficiente", "Seu perfil permite consultas, mas não permite alterar dados.")
            return False
        return True

    def _require_admin(self) -> bool:
        if not self._need_connection():
            return False
        if self.current_role != "ADMINISTRADOR":
            messagebox.showwarning("Permissão insuficiente", "Somente o perfil ADMINISTRADOR pode gerenciar usuários.")
            return False
        return True

    @staticmethod
    def _friendly_db_message(exc: Exception) -> str:
        errno = getattr(exc, "errno", None)
        message = str(getattr(exc, "msg", "") or exc)
        if errno == 1062:
            return "Já existe um registro com esse identificador único. Confira CPF/CNPJ, código de rastreio, placa ou nome de usuário."
        if errno == 1451:
            return "Este registro está relacionado a outros dados e não pode ser removido. Remova ou desvincule os registros dependentes antes."
        if errno == 1452:
            return "Um dos registros relacionados não existe. Atualize a tela e selecione novamente os dados vinculados."
        if errno == 3819 or "check constraint" in message.lower() or "constraint" in message.lower():
            return "A operação viola uma regra de integridade do banco. Revise os campos e os valores permitidos."
        if errno == 1048:
            return "Um campo obrigatório não foi preenchido."
        if errno == 1142 or errno == 1044:
            return "A conta MySQL conectada não tem permissão para executar essa operação. Verifique o papel atribuído à conta e os privilégios com SHOW GRANTS."
        if errno == 1146:
            return "Uma tabela necessária não existe. Execute os scripts SQL na ordem descrita no README."
        if errno == 1049:
            return "O banco informado não existe. Confira o nome e execute os scripts de criação antes de conectar."
        if errno == 1045:
            return "O MySQL recusou a autenticação. Confira usuário, senha e permissões da conta."
        if errno in (2002, 2003, 2006, 2013):
            return "Não foi possível manter a conexão com o MySQL. Confira se o serviço está iniciado, o host e a porta, e tente novamente."
        if errno == 1644:
            return "A operação viola uma regra de negócio definida no banco. Revise os dados relacionados e tente novamente."
        if errno == 1213:
            return "A operação entrou em conflito com outra transação e foi desfeita. Tente novamente."
        if errno == 1205:
            return "A operação aguardou um bloqueio por tempo excessivo e foi cancelada. Tente novamente."
        return "Não foi possível concluir a operação por um erro inesperado do banco. Verifique os dados e a conexão; se persistir, peça ao administrador para conferir o log do MySQL."

    def _show_db_error(self, title: str, exc: Exception, parent: tk.Misc | None = None) -> None:
        messagebox.showerror(title, self._friendly_db_message(exc), parent=parent or self.root)

    def _selected_row(self, tree: ttk.Treeview | None) -> dict[str, Any] | None:
        if tree is None or not tree.selection():
            messagebox.showwarning("Seleção necessária", "Selecione um registro na tabela primeiro.")
            return None
        try:
            index = int(tree.selection()[0])
            rows = getattr(tree, "_row_data", [])
            return rows[index]
        except (ValueError, IndexError, TypeError):
            messagebox.showwarning("Seleção inválida", "Atualize a tabela e selecione o registro novamente.")
            return None

    def _safe_fetch(self, sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
        try:
            return self.db.fetch_all(sql, params)
        except Exception as exc:
            self._show_db_error("Erro ao consultar o banco", exc)
            return []

    def _table(self, parent: tk.Widget, columns: list[tuple[str, str, int]], rows: list[dict[str, Any]],
               height: int = 12) -> ttk.Treeview:
        holder = tk.Frame(parent, bg=WHITE, highlightbackground=BORDER, highlightthickness=1)
        holder.pack(fill="both", expand=True)
        names = [col[0] for col in columns]
        tree = ttk.Treeview(holder, columns=names, show="headings", height=height)
        for key, label, width in columns:
            tree.heading(key, text=label)
            tree.column(key, width=width, minwidth=65, anchor="w", stretch=True)
        yscroll = ttk.Scrollbar(holder, orient="vertical", command=tree.yview)
        xscroll = ttk.Scrollbar(holder, orient="horizontal", command=tree.xview)
        tree.configure(yscrollcommand=yscroll.set, xscrollcommand=xscroll.set)
        tree.grid(row=0, column=0, sticky="nsew")
        yscroll.grid(row=0, column=1, sticky="ns")
        xscroll.grid(row=1, column=0, sticky="ew")
        holder.grid_rowconfigure(0, weight=1)
        holder.grid_columnconfigure(0, weight=1)
        tree._row_data = rows  # permite recuperar os IDs completos do registro selecionado
        for index, row in enumerate(rows):
            values = [self._display_value(row.get(key)) for key in names]
            tree.insert("", "end", iid=str(index), values=values, tags=("odd" if index % 2 else "even",))
        tree.tag_configure("odd", background="#F8FAFD")
        tree.tag_configure("even", background=WHITE)
        return tree

    @staticmethod
    def _display_value(value: Any) -> str:
        if value is None:
            return "—"
        if isinstance(value, datetime):
            return value.strftime("%d/%m/%Y %H:%M")
        if isinstance(value, date):
            return value.strftime("%d/%m/%Y")
        if isinstance(value, float):
            return f"{value:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
        return str(value)

    def _table_from_result(self, parent: tk.Widget, rows: list[dict[str, Any]], height: int = 12) -> ttk.Treeview | None:
        if not rows:
            tk.Label(parent, text="Nenhum registro encontrado para esta consulta.", bg=WHITE, fg=MUTED,
                     font=("Segoe UI", 10), padx=20, pady=26).pack(fill="x")
            return None
        cols = []
        for key in rows[0].keys():
            cols.append((key, key.replace("_", " ").title(), 150))
        return self._table(parent, cols, rows, height=height)

    def page_dashboard(self) -> None:
        self.page_heading("Visão geral", "Acompanhe o fluxo logístico em um só lugar.")
        if not self.connected:
            panel = tk.Frame(self.content, bg=WHITE, padx=28, pady=28, highlightbackground=BORDER, highlightthickness=1)
            panel.pack(fill="x")
            tk.Label(panel, text="Conecte o sistema ao MySQL", bg=WHITE, fg=NAVY,
                     font=("Segoe UI", 16, "bold")).pack(anchor="w")
            tk.Label(panel, text="Depois da conexão, os indicadores serão carregados diretamente do banco db_transportadora.",
                     bg=WHITE, fg=MUTED, font=("Segoe UI", 10)).pack(anchor="w", pady=(8, 16))
            self.action_button(panel, "Configurar conexão", lambda: self.show_page("Conexão")).pack(anchor="w")
            return
        stats_sql = [
            ("Clientes", "SELECT COUNT(*) AS total FROM cliente", "Cadastros de remetentes", "#3B82F6"),
            ("Encomendas", "SELECT COUNT(*) AS total FROM encomenda", "Remessas registradas", ORANGE),
            ("Expedições ativas", "SELECT COUNT(*) AS total FROM expedicao WHERE status_expedicao IN ('PLANEJADA','EM_CARREGAMENTO','EM_TRANSITO')", "Planejadas ou em andamento", "#8B5CF6"),
            ("Tentativas sem sucesso", "SELECT COUNT(*) AS total FROM tentativa_entrega WHERE resultado = 'INSUCESSO'", "Precisam de acompanhamento", RED),
        ]
        cards = tk.Frame(self.content, bg=BG)
        cards.pack(fill="x", pady=(0, 23))
        for i, (title, sql, note, accent) in enumerate(stats_sql):
            rows = self._safe_fetch(sql)
            value = str(rows[0]["total"]) if rows else "—"
            widget = self.card(cards, title, value, note, accent)
            widget.grid(row=0, column=i, sticky="nsew", padx=(0 if i == 0 else 8, 8 if i < 3 else 0))
            cards.grid_columnconfigure(i, weight=1, uniform="cards")
        section = tk.Frame(self.content, bg=BG)
        section.pack(fill="both", expand=True)
        top = tk.Frame(section, bg=BG)
        top.pack(fill="x", pady=(0, 10))
        tk.Label(top, text="Encomendas recentes", bg=BG, fg=NAVY, font=("Segoe UI", 13, "bold")).pack(side="left")
        self.action_button(top, "Ver encomendas", lambda: self.show_page("Encomendas"), primary=False).pack(side="right")
        rows = self._safe_fetch(self._orders_sql() + " ORDER BY e.id_encomenda DESC LIMIT 8")
        self._table(section, [("codigo_rastreio", "Código de rastreio", 160), ("cliente", "Cliente remetente", 220),
                              ("data_postagem", "Postagem", 120), ("status_atual", "Status atual", 190),
                              ("destino", "Destino", 200)], rows, height=8)

    @staticmethod
    def _orders_sql() -> str:
        return """SELECT e.id_encomenda, e.id_cliente, e.id_endereco_origem, e.id_endereco_destino,
                         e.codigo_rastreio,
                         COALESCE(pf.nome, pj.razao_social, CONCAT('Cliente #', c.id_cliente)) AS cliente,
                         e.data_postagem,
                         COALESCE(v.status_atual, 'SEM_HISTORICO') AS status_atual,
                         CONCAT(cd.nome, ' - ', cd.uf) AS destino
                  FROM encomenda e
                  JOIN cliente c ON c.id_cliente = e.id_cliente
                  LEFT JOIN cliente_pf pf ON pf.id_cliente = c.id_cliente
                  LEFT JOIN cliente_pj pj ON pj.id_cliente = c.id_cliente
                  LEFT JOIN vw_encomenda_status_atual v ON v.id_encomenda = e.id_encomenda
                  LEFT JOIN endereco ed ON ed.id_endereco = e.id_endereco_destino
                  LEFT JOIN cidade cd ON cd.id_cidade = ed.id_cidade"""

    def page_clients(self) -> None:
        self.page_heading("Clientes", "Consulte e cadastre pessoas físicas e jurídicas.")
        controls = tk.Frame(self.content, bg=BG)
        controls.pack(fill="x", pady=(0, 13))
        search = ttk.Entry(controls, width=43)
        search.pack(side="left", ipady=3)
        search.insert(0, "Nome, CPF/CNPJ, e-mail ou ID")
        search.bind("<FocusIn>", lambda _e: search.delete(0, "end") if search.get() == "Nome, CPF/CNPJ, e-mail ou ID" else None)
        self.action_button(controls, "Buscar", lambda: load_rows(), primary=False).pack(side="left", padx=(8, 0))
        self.action_button(controls, "Editar selecionado", self.edit_selected_client, primary=False).pack(side="left", padx=(8, 0))
        self.action_button(controls, "Excluir selecionado", self.delete_selected_client, primary=False).pack(side="left", padx=(8, 0))
        self.action_button(controls, "+ Novo cliente", self.open_client_form).pack(side="right")
        table_host = tk.Frame(self.content, bg=BG)
        table_host.pack(fill="both", expand=True)

        def load_rows() -> None:
            for child in table_host.winfo_children():
                child.destroy()
            if not self._need_connection():
                return
            term = search.get().strip()
            params: tuple[Any, ...] = ()
            where = ""
            if term and term != "Nome, CPF/CNPJ, e-mail ou ID":
                where = "WHERE pf.nome LIKE %s OR pj.razao_social LIKE %s OR pf.cpf LIKE %s OR pj.cnpj LIKE %s OR c.email LIKE %s OR c.telefone LIKE %s OR CAST(c.id_cliente AS CHAR) LIKE %s"
                like = f"%{term}%"
                params = (like, like, like, like, like, like, like)
            sql = f"""SELECT c.id_cliente,
                       c.tipo_cliente,
                       COALESCE(pf.nome, pj.razao_social) AS nome,
                       COALESCE(pf.cpf, pj.cnpj) AS documento,
                       c.telefone, c.email, c.data_cadastro
                    FROM cliente c
                    LEFT JOIN cliente_pf pf ON pf.id_cliente = c.id_cliente
                    LEFT JOIN cliente_pj pj ON pj.id_cliente = c.id_cliente
                    {where}
                    ORDER BY c.id_cliente DESC LIMIT 500"""
            rows = self._safe_fetch(sql, params)
            self.client_tree = self._table(table_host, [("id_cliente", "ID", 65), ("tipo_cliente", "Tipo", 70),
                                     ("nome", "Nome / razão social", 240), ("documento", "CPF / CNPJ", 150),
                                     ("telefone", "Telefone", 140), ("email", "E-mail", 230),
                                     ("data_cadastro", "Cadastro", 125)], rows, height=14)
        search.bind("<Return>", lambda _e: load_rows())
        load_rows()

    def open_client_form(self) -> None:
        if not self._require_write():
            return
        win = tk.Toplevel(self.root)
        win.title("Novo cliente")
        win.geometry("520x590")
        win.configure(bg=WHITE)
        win.transient(self.root)
        win.grab_set()
        tk.Label(win, text="Cadastrar cliente", bg=WHITE, fg=NAVY, font=("Segoe UI", 18, "bold")).pack(anchor="w", padx=26, pady=(24, 4))
        tk.Label(win, text="Os dados comuns e os dados PF/PJ serão gravados em tabelas relacionadas.", bg=WHITE, fg=MUTED,
                 font=("Segoe UI", 9), wraplength=450, justify="left").pack(anchor="w", padx=26, pady=(0, 16))
        form = tk.Frame(win, bg=WHITE, padx=26)
        form.pack(fill="both", expand=True)
        fields: dict[str, tk.Widget] = {}

        def field(label: str, key: str, value: str = "") -> None:
            tk.Label(form, text=label, bg=WHITE, fg=TEXT, font=("Segoe UI", 9, "bold")).pack(anchor="w", pady=(8, 4))
            entry = ttk.Entry(form)
            entry.pack(fill="x")
            if value:
                entry.insert(0, value)
            fields[key] = entry

        tk.Label(form, text="Tipo de cliente", bg=WHITE, fg=TEXT, font=("Segoe UI", 9, "bold")).pack(anchor="w", pady=(2, 4))
        kind = ttk.Combobox(form, values=("PF - Pessoa Física", "PJ - Pessoa Jurídica"), state="readonly")
        kind.current(0)
        kind.pack(fill="x")
        fields["tipo"] = kind
        field("Nome completo", "nome")
        field("CPF (somente números)", "documento")
        field("Telefone (opcional)", "telefone")
        field("E-mail (opcional)", "email")
        labels = [child for child in form.winfo_children() if isinstance(child, tk.Label)]

        def update_labels(_event=None) -> None:
            labels[1].configure(text="Nome completo" if kind.current() == 0 else "Razão social")
            labels[2].configure(text="CPF (somente números)" if kind.current() == 0 else "CNPJ (somente números)")
        kind.bind("<<ComboboxSelected>>", update_labels)

        def save() -> None:
            tipo = "PF" if kind.current() == 0 else "PJ"
            nome = fields["nome"].get().strip()
            doc = re.sub(r"\D", "", fields["documento"].get())
            telefone = fields["telefone"].get().strip() or None
            email = fields["email"].get().strip() or None
            expected = 11 if tipo == "PF" else 14
            if not nome:
                messagebox.showwarning("Validação", "Preencha o nome ou a razão social.", parent=win); return
            if len(doc) != expected:
                messagebox.showwarning("Validação", f"Informe {expected} dígitos no documento.", parent=win); return
            if email and not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
                messagebox.showwarning("Validação", "O formato do e-mail parece inválido.", parent=win); return
            try:
                with self.db.transaction(actor=self.current_user or "sistema") as conn:
                    cur = conn.cursor()
                    cur.execute("INSERT INTO cliente (tipo_cliente, telefone, email, data_cadastro) VALUES (%s, %s, %s, %s)",
                                (tipo, telefone, email, date.today()))
                    client_id = cur.lastrowid
                    if tipo == "PF":
                        cur.execute("INSERT INTO cliente_pf (id_cliente, nome, cpf) VALUES (%s, %s, %s)", (client_id, nome, doc))
                    else:
                        cur.execute("INSERT INTO cliente_pj (id_cliente, razao_social, nome_fantasia, cnpj) VALUES (%s, %s, %s, %s)",
                                    (client_id, nome, None, doc))
                    cur.close()
                messagebox.showinfo("Sucesso", f"Cliente #{client_id} cadastrado.", parent=win)
                win.destroy(); self.show_page("Clientes")
            except Exception as exc:
                self._show_db_error("Não foi possível cadastrar o cliente", exc, win)
        self.action_button(win, "Salvar cliente", save).pack(fill="x", padx=26, pady=20)

    def page_orders(self) -> None:
        self.page_heading("Encomendas", "Gerencie remessas, volumes e o início do rastreamento.")
        controls = tk.Frame(self.content, bg=BG)
        controls.pack(fill="x", pady=(0, 13))
        search = ttk.Entry(controls, width=43)
        search.pack(side="left", ipady=3)
        search.insert(0, "Pesquisar código de rastreio")
        search.bind("<FocusIn>", lambda _e: search.delete(0, "end") if search.get() == "Pesquisar código de rastreio" else None)
        self.action_button(controls, "Buscar", lambda: load_rows(), primary=False).pack(side="left", padx=(8, 0))
        self.action_button(controls, "Editar selecionada", self.edit_selected_order, primary=False).pack(side="left", padx=(8, 0))
        self.action_button(controls, "Excluir selecionada", self.delete_selected_order, primary=False).pack(side="left", padx=(8, 0))
        self.action_button(controls, "+ Nova encomenda", self.open_order_form).pack(side="right")
        host = tk.Frame(self.content, bg=BG); host.pack(fill="both", expand=True)

        def load_rows() -> None:
            for child in host.winfo_children(): child.destroy()
            if not self._need_connection(): return
            term = search.get().strip()
            sql = self._orders_sql()
            params: tuple[Any, ...] = ()
            if term and term != "Pesquisar código de rastreio":
                sql += " WHERE e.codigo_rastreio LIKE %s"
                params = (f"%{term}%",)
            sql += " ORDER BY e.id_encomenda DESC LIMIT 500"
            rows = self._safe_fetch(sql, params)
            self.order_tree = self._table(host, [("codigo_rastreio", "Código de rastreio", 180), ("cliente", "Cliente", 220),
                               ("data_postagem", "Postagem", 115), ("status_atual", "Status atual", 195),
                               ("destino", "Cidade destino", 190)], rows, height=14)
        search.bind("<Return>", lambda _e: load_rows())
        load_rows()

    def open_order_form(self) -> None:
        if not self._require_write(): return
        clients = self._safe_fetch("""SELECT c.id_cliente, c.tipo_cliente, COALESCE(pf.nome,pj.razao_social) AS nome
                                      FROM cliente c LEFT JOIN cliente_pf pf ON pf.id_cliente=c.id_cliente
                                      LEFT JOIN cliente_pj pj ON pj.id_cliente=c.id_cliente ORDER BY nome""")
        addresses = self._safe_fetch("""SELECT e.id_endereco, CONCAT(e.id_endereco, ' | ', e.logradouro, ', ', e.numero,
                                       ' - ', e.bairro, ' / ', cid.nome, '-', cid.uf) AS rotulo
                                       FROM endereco e JOIN cidade cid ON cid.id_cidade=e.id_cidade
                                       ORDER BY cid.nome, e.logradouro""")
        centers = self._safe_fetch("SELECT id_centro, nome FROM centro_distribuicao ORDER BY nome")
        if not clients or len(addresses) < 2 or not centers:
            messagebox.showwarning("Cadastros necessários", "Para criar uma encomenda, o banco precisa ter pelo menos um cliente, dois endereços diferentes e um centro de distribuição.")
            return
        win = tk.Toplevel(self.root); win.title("Nova encomenda"); win.geometry("650x800"); win.configure(bg=WHITE); win.transient(self.root); win.grab_set()
        canvas = tk.Canvas(win, bg=WHITE, highlightthickness=0)
        scrollbar = ttk.Scrollbar(win, orient="vertical", command=canvas.yview)
        scroll_frame = tk.Frame(canvas, bg=WHITE, padx=28, pady=22)
        scroll_frame.bind("<Configure>", lambda _e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=scroll_frame, anchor="nw", width=610)
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.pack(side="left", fill="both", expand=True); scrollbar.pack(side="right", fill="y")
        tk.Label(scroll_frame, text="Registrar encomenda", bg=WHITE, fg=NAVY, font=("Segoe UI", 18, "bold")).pack(anchor="w")
        tk.Label(scroll_frame, text="O cadastro cria o volume 1 e o status inicial REGISTRADA.", bg=WHITE, fg=MUTED, font=("Segoe UI", 9)).pack(anchor="w", pady=(5, 12))
        widgets: dict[str, Any] = {}

        def label(text: str) -> None: tk.Label(scroll_frame, text=text, bg=WHITE, fg=TEXT, font=("Segoe UI", 9, "bold")).pack(anchor="w", pady=(9, 4))
        def entry(label_text: str, key: str, default: str = "") -> None:
            label(label_text); w = ttk.Entry(scroll_frame); w.pack(fill="x")
            if default: w.insert(0, default)
            widgets[key] = w
        def combo(label_text: str, key: str, options: list[str]) -> None:
            label(label_text); w = ttk.Combobox(scroll_frame, values=options, state="readonly"); w.pack(fill="x")
            if options: w.current(0)
            widgets[key] = w

        entry("Código de rastreio", "codigo")
        combo("Cliente remetente", "cliente", [f"{c['id_cliente']} | {'PF' if c['tipo_cliente']=='PF' else 'PJ'} - {c['nome']}" for c in clients])
        entry("Data de postagem (AAAA-MM-DD)", "data", date.today().isoformat())
        entry("Valor declarado (opcional)", "valor", "")
        combo("Endereço de origem", "origem", [a["rotulo"] for a in addresses])
        combo("Endereço de destino", "destino", [a["rotulo"] for a in addresses])
        combo("Centro de distribuição responsável pelo status inicial", "centro", [f"{c['id_centro']} | {c['nome']}" for c in centers])
        tk.Label(scroll_frame, text="Dados do volume 1", bg=WHITE, fg=NAVY, font=("Segoe UI", 12, "bold")).pack(anchor="w", pady=(19, 0))
        entry("Peso em kg", "peso", "1.000")
        entry("Altura em cm", "altura", "10")
        entry("Largura em cm", "largura", "10")
        entry("Comprimento em cm", "comprimento", "10")
        entry("Descrição do conteúdo (opcional)", "descricao", "")

        def id_from_combo(text: str) -> int:
            return int(text.split("|", 1)[0].strip())
        def save() -> None:
            code = widgets["codigo"].get().strip()
            if not code:
                messagebox.showwarning("Validação", "Informe o código de rastreio.", parent=win); return
            if widgets["origem"].get() == widgets["destino"].get():
                messagebox.showwarning("Validação", "Origem e destino devem ser diferentes.", parent=win); return
            try:
                posted = datetime.strptime(widgets["data"].get().strip(), "%Y-%m-%d").date()
                value_raw = widgets["valor"].get().strip().replace(",", ".")
                declared = float(value_raw) if value_raw else None
                if declared is not None and declared < 0: raise ValueError("O valor declarado não pode ser negativo.")
                weight, height, width, length = [float(widgets[k].get().strip().replace(",", ".")) for k in ("peso", "altura", "largura", "comprimento")]
                if min(weight, height, width, length) <= 0: raise ValueError("Peso e dimensões devem ser maiores que zero.")
                client_id = id_from_combo(widgets["cliente"].get())
                origin_id = id_from_combo(widgets["origem"].get()); dest_id = id_from_combo(widgets["destino"].get())
                center_id = id_from_combo(widgets["centro"].get())
                with self.db.transaction(actor=self.current_user or "sistema") as conn:
                    cur = conn.cursor()
                    cur.execute("INSERT INTO encomenda (codigo_rastreio,data_postagem,valor_declarado,id_cliente,id_endereco_origem,id_endereco_destino) VALUES (%s,%s,%s,%s,%s,%s)",
                                (code, posted, declared, client_id, origin_id, dest_id))
                    order_id = cur.lastrowid
                    cur.execute("INSERT INTO volume_encomenda (id_encomenda,num_volume,peso,altura,largura,comprimento,descricao_conteudo) VALUES (%s,1,%s,%s,%s,%s,%s)",
                                (order_id, weight, height, width, length, widgets["descricao"].get().strip() or None))
                    cur.execute("INSERT INTO historico_status_encomenda (status,data_hora,observacao,id_encomenda,id_centro) VALUES (%s,%s,%s,%s,%s)",
                                ("REGISTRADA", datetime.now().replace(microsecond=0), "Encomenda cadastrada pela interface", order_id, center_id))
                    cur.close()
                messagebox.showinfo("Sucesso", f"Encomenda {code} cadastrada com status REGISTRADA.", parent=win)
                win.destroy(); self.show_page("Encomendas")
            except ValueError as exc:
                messagebox.showwarning("Validação", str(exc), parent=win)
            except Exception as exc:
                self._show_db_error("Não foi possível cadastrar a encomenda", exc, win)
        self.action_button(scroll_frame, "Salvar encomenda", save).pack(fill="x", pady=22)

    def edit_selected_client(self) -> None:
        if not self._require_write(): return
        selected = self._selected_row(getattr(self, "client_tree", None))
        if not selected: return
        row = self.db.fetch_one("""SELECT c.id_cliente,c.tipo_cliente,c.telefone,c.email,
                                      pf.nome,pf.cpf,pj.razao_social,pj.nome_fantasia,pj.cnpj
                                   FROM cliente c LEFT JOIN cliente_pf pf ON pf.id_cliente=c.id_cliente
                                   LEFT JOIN cliente_pj pj ON pj.id_cliente=c.id_cliente
                                   WHERE c.id_cliente=%s""", (selected["id_cliente"],))
        if not row:
            messagebox.showwarning("Registro não encontrado", "O cliente foi removido. Atualize a lista."); return
        win = tk.Toplevel(self.root); win.title("Editar cliente"); win.geometry("500x560"); win.configure(bg=WHITE); win.transient(self.root); win.grab_set()
        tk.Label(win, text=f"Editar cliente #{row['id_cliente']}", bg=WHITE, fg=NAVY, font=("Segoe UI", 17, "bold")).pack(anchor="w", padx=24, pady=(22, 4))
        tk.Label(win, text=f"Tipo fixo: {'Pessoa Física' if row['tipo_cliente']=='PF' else 'Pessoa Jurídica'}", bg=WHITE, fg=MUTED).pack(anchor="w", padx=24, pady=(0, 12))
        form = tk.Frame(win, bg=WHITE, padx=24); form.pack(fill="both", expand=True)
        widgets: dict[str, ttk.Entry] = {}
        values = {"nome": row["nome"] if row["tipo_cliente"] == "PF" else row["razao_social"],
                  "documento": row["cpf"] if row["tipo_cliente"] == "PF" else row["cnpj"],
                  "telefone": row["telefone"] or "", "email": row["email"] or ""}
        specs = [("Nome completo" if row["tipo_cliente"] == "PF" else "Razão social", "nome"),
                 ("CPF (11 dígitos)" if row["tipo_cliente"] == "PF" else "CNPJ (14 dígitos)", "documento"),
                 ("Telefone (opcional)", "telefone"), ("E-mail (opcional)", "email")]
        for label_text, key in specs:
            tk.Label(form, text=label_text, bg=WHITE, fg=TEXT, font=("Segoe UI", 9, "bold")).pack(anchor="w", pady=(8, 4))
            ent = ttk.Entry(form); ent.pack(fill="x"); ent.insert(0, str(values[key])); widgets[key] = ent
        def save() -> None:
            name = widgets["nome"].get().strip(); doc = re.sub(r"\D", "", widgets["documento"].get())
            phone = widgets["telefone"].get().strip() or None; email = widgets["email"].get().strip() or None
            expected = 11 if row["tipo_cliente"] == "PF" else 14
            if not name: messagebox.showwarning("Validação", "Informe o nome/razão social.", parent=win); return
            if len(doc) != expected: messagebox.showwarning("Validação", f"O documento deve conter {expected} dígitos.", parent=win); return
            if email and not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
                messagebox.showwarning("Validação", "Informe um e-mail válido.", parent=win); return
            try:
                with self.db.transaction(actor=self.current_user or "sistema") as conn:
                    cur = conn.cursor()
                    cur.execute("UPDATE cliente SET telefone=%s,email=%s WHERE id_cliente=%s", (phone, email, row["id_cliente"]))
                    if row["tipo_cliente"] == "PF":
                        cur.execute("UPDATE cliente_pf SET nome=%s,cpf=%s WHERE id_cliente=%s", (name, doc, row["id_cliente"]))
                    else:
                        cur.execute("UPDATE cliente_pj SET razao_social=%s,cnpj=%s WHERE id_cliente=%s", (name, doc, row["id_cliente"]))
                    cur.close()
                win.destroy(); self.show_page("Clientes")
                messagebox.showinfo("Sucesso", "Cliente atualizado. A alteração da tabela CLIENTE foi registrada na auditoria.")
            except Exception as exc: self._show_db_error("Não foi possível atualizar o cliente", exc, win)
        self.action_button(win, "Salvar alterações", save).pack(fill="x", padx=24, pady=20)

    def delete_selected_client(self) -> None:
        if not self._require_write(): return
        row = self._selected_row(getattr(self, "client_tree", None))
        if not row: return
        if not messagebox.askyesno("Confirmar exclusão", f"Excluir o cliente #{row['id_cliente']} — {row['nome']}?\n\nSe ele possuir encomendas vinculadas, o banco impedirá a exclusão."):
            return
        try:
            with self.db.transaction(actor=self.current_user or "sistema") as conn:
                cur = conn.cursor(); cur.execute("DELETE FROM cliente WHERE id_cliente=%s", (row["id_cliente"],)); cur.close()
            self.show_page("Clientes"); messagebox.showinfo("Sucesso", "Cliente excluído.")
        except Exception as exc: self._show_db_error("Não foi possível excluir o cliente", exc)

    def edit_selected_order(self) -> None:
        if not self._require_write(): return
        selected = self._selected_row(getattr(self, "order_tree", None))
        if not selected: return
        order = self.db.fetch_one("SELECT * FROM encomenda WHERE id_encomenda=%s", (selected["id_encomenda"],))
        if not order: messagebox.showwarning("Registro não encontrado", "A encomenda foi removida. Atualize a lista."); return
        clients = self._safe_fetch("""SELECT c.id_cliente,COALESCE(pf.nome,pj.razao_social) AS nome
                                    FROM cliente c LEFT JOIN cliente_pf pf ON pf.id_cliente=c.id_cliente
                                    LEFT JOIN cliente_pj pj ON pj.id_cliente=c.id_cliente ORDER BY nome""")
        addresses = self._safe_fetch("""SELECT e.id_endereco, CONCAT(e.logradouro, ', ', e.numero, ' - ', cid.nome, '/', cid.uf) AS rotulo
                                      FROM endereco e JOIN cidade cid ON cid.id_cidade=e.id_cidade ORDER BY cid.nome,e.logradouro""")
        if not clients or len(addresses) < 2: messagebox.showwarning("Cadastros necessários", "São necessários clientes e endereços cadastrados."); return
        win=tk.Toplevel(self.root); win.title("Editar encomenda"); win.geometry("610x650"); win.configure(bg=WHITE); win.transient(self.root); win.grab_set()
        frame=tk.Frame(win,bg=WHITE,padx=24,pady=20); frame.pack(fill="both",expand=True)
        tk.Label(frame,text=f"Editar encomenda #{order['id_encomenda']}",bg=WHITE,fg=NAVY,font=("Segoe UI",17,"bold")).pack(anchor="w")
        fields: dict[str, Any] = {}
        def ent(label: str, key: str, value: Any) -> None:
            tk.Label(frame,text=label,bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(9,4))
            w=ttk.Entry(frame); w.pack(fill="x"); w.insert(0,"" if value is None else str(value)); fields[key]=w
        def combo(label: str, key: str, opts: list[str], current_id: int) -> None:
            tk.Label(frame,text=label,bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(9,4))
            w=ttk.Combobox(frame,values=opts,state="readonly"); w.pack(fill="x")
            for i,opt in enumerate(opts):
                if int(opt.split("|",1)[0].strip()) == int(current_id): w.current(i); break
            fields[key]=w
        ent("Código de rastreio","codigo",order["codigo_rastreio"])
        ent("Data de postagem (AAAA-MM-DD)","data",order["data_postagem"])
        ent("Valor declarado (opcional)","valor",order["valor_declarado"])
        combo("Cliente", "cliente", [f"{c['id_cliente']} | {c['nome']}" for c in clients], order["id_cliente"])
        combo("Endereço de origem", "origem", [f"{a['id_endereco']} | {a['rotulo']}" for a in addresses], order["id_endereco_origem"])
        combo("Endereço de destino", "destino", [f"{a['id_endereco']} | {a['rotulo']}" for a in addresses], order["id_endereco_destino"])
        def save() -> None:
            code=fields["codigo"].get().strip()
            if not code: messagebox.showwarning("Validação","Informe o código de rastreio.",parent=win); return
            try:
                posted=datetime.strptime(fields["data"].get().strip(),"%Y-%m-%d").date()
                val=fields["valor"].get().strip().replace(",","."); declared=Decimal(val) if val else None
                if declared is not None and declared < 0: raise ValueError("O valor declarado não pode ser negativo.")
                ids={k:int(fields[k].get().split("|",1)[0].strip()) for k in ("cliente","origem","destino")}
                if ids["origem"] == ids["destino"]: raise ValueError("Origem e destino devem ser diferentes.")
                with self.db.transaction(actor=self.current_user or "sistema") as conn:
                    cur=conn.cursor()
                    cur.execute("""UPDATE encomenda SET codigo_rastreio=%s,data_postagem=%s,valor_declarado=%s,
                                  id_cliente=%s,id_endereco_origem=%s,id_endereco_destino=%s WHERE id_encomenda=%s""",
                                (code,posted,declared,ids["cliente"],ids["origem"],ids["destino"],order["id_encomenda"]))
                    cur.close()
                win.destroy(); self.show_page("Encomendas"); messagebox.showinfo("Sucesso","Encomenda atualizada e alteração auditada.")
            except (ValueError, InvalidOperation) as exc: messagebox.showwarning("Validação",str(exc),parent=win)
            except Exception as exc: self._show_db_error("Não foi possível atualizar a encomenda",exc,win)
        self.action_button(frame,"Salvar alterações",save).pack(fill="x",pady=20)

    def delete_selected_order(self) -> None:
        if not self._require_write(): return
        row=self._selected_row(getattr(self,"order_tree",None))
        if not row: return
        if not messagebox.askyesno("Excluir encomenda?", f"Excluir a encomenda {row['codigo_rastreio']}?\n\nATENÇÃO: volumes, histórico, ocorrências, tentativas e vínculos podem ser removidos em cascata. A operação não pode ser desfeita."):
            return
        try:
            with self.db.transaction(actor=self.current_user or "sistema") as conn:
                cur=conn.cursor(); cur.execute("DELETE FROM encomenda WHERE id_encomenda=%s",(row["id_encomenda"],)); cur.close()
            self.show_page("Encomendas"); messagebox.showinfo("Sucesso","Encomenda excluída.")
        except Exception as exc: self._show_db_error("Não foi possível excluir a encomenda",exc)

    def page_services(self) -> None:
        self.page_heading("Serviços adicionais", "CRUD completo do catálogo de serviços associados às encomendas.")
        controls=tk.Frame(self.content,bg=BG); controls.pack(fill="x",pady=(0,13))
        self.action_button(controls,"Novo serviço",lambda: self._open_service_form()).pack(side="left")
        self.action_button(controls,"Editar selecionado",self._edit_service,primary=False).pack(side="left",padx=8)
        self.action_button(controls,"Excluir selecionado",self._delete_service,primary=False).pack(side="left")
        host=tk.Frame(self.content,bg=BG); host.pack(fill="both",expand=True)
        rows=self._safe_fetch("SELECT id_servico,nome,descricao,valor_referencia,ativo FROM servico_adicional ORDER BY nome") if self.connected and self.current_user else []
        self.service_tree=self._table(host,[("id_servico","ID",60),("nome","Serviço",220),("descricao","Descrição",380),("valor_referencia","Valor referência",150),("ativo","Ativo (1/0)",100)],rows,height=15)

    def _open_service_form(self, existing: dict[str, Any] | None = None) -> None:
        if not self._require_write(): return
        win=tk.Toplevel(self.root); win.title("Editar serviço" if existing else "Novo serviço"); win.geometry("480x430"); win.configure(bg=WHITE); win.transient(self.root); win.grab_set()
        frame=tk.Frame(win,bg=WHITE,padx=24,pady=22); frame.pack(fill="both",expand=True)
        tk.Label(frame,text="Dados do serviço adicional",bg=WHITE,fg=NAVY,font=("Segoe UI",16,"bold")).pack(anchor="w")
        fields={}
        for label,key,value in [("Nome","nome",(existing or {}).get("nome","")),("Descrição","descricao",(existing or {}).get("descricao","") or ""),("Valor de referência","valor",(existing or {}).get("valor_referencia","0.00"))]:
            tk.Label(frame,text=label,bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(12,4)); w=ttk.Entry(frame); w.pack(fill="x"); w.insert(0,str(value)); fields[key]=w
        tk.Label(frame,text="Situação",bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(12,4))
        active=ttk.Combobox(frame,values=["Ativo","Inativo"],state="readonly"); active.current(0 if int((existing or {}).get("ativo",1)) else 1); active.pack(fill="x")
        def save() -> None:
            name=fields["nome"].get().strip(); desc=fields["descricao"].get().strip() or None
            try:
                value=Decimal(fields["valor"].get().strip().replace(",","."))
                if not name: raise ValueError("Informe o nome do serviço.")
                if value < 0: raise ValueError("O valor não pode ser negativo.")
                with self.db.transaction(actor=self.current_user or "sistema") as conn:
                    cur=conn.cursor()
                    if existing:
                        cur.execute("UPDATE servico_adicional SET nome=%s,descricao=%s,valor_referencia=%s,ativo=%s WHERE id_servico=%s",(name,desc,value,1 if active.current()==0 else 0,existing["id_servico"]))
                    else:
                        cur.execute("INSERT INTO servico_adicional (nome,descricao,valor_referencia,ativo) VALUES (%s,%s,%s,%s)",(name,desc,value,1 if active.current()==0 else 0))
                    cur.close()
                win.destroy(); self.show_page("Serviços adicionais")
            except (ValueError,InvalidOperation) as exc: messagebox.showwarning("Validação",str(exc),parent=win)
            except Exception as exc: self._show_db_error("Não foi possível salvar o serviço",exc,win)
        self.action_button(frame,"Salvar",save).pack(fill="x",pady=20)

    def _edit_service(self) -> None:
        if not self._require_write(): return
        row=self._selected_row(getattr(self,"service_tree",None))
        if row: self._open_service_form(row)

    def _delete_service(self) -> None:
        if not self._require_write(): return
        row=self._selected_row(getattr(self,"service_tree",None))
        if not row: return
        if not messagebox.askyesno("Excluir serviço",f"Excluir o serviço '{row['nome']}'? Serviços já contratados impedirão a exclusão por chave estrangeira."): return
        try:
            with self.db.transaction(actor=self.current_user or "sistema") as conn:
                cur=conn.cursor();cur.execute("DELETE FROM servico_adicional WHERE id_servico=%s",(row["id_servico"],));cur.close()
            self.show_page("Serviços adicionais")
        except Exception as exc: self._show_db_error("Não foi possível excluir o serviço",exc)

    def _incident_form(self, existing: dict[str, Any] | None = None) -> None:
        if not self._require_write(): return
        orders=self._safe_fetch("SELECT id_encomenda,codigo_rastreio FROM encomenda ORDER BY id_encomenda DESC LIMIT 1000")
        if not orders: messagebox.showwarning("Encomendas necessárias","Cadastre uma encomenda antes de registrar ocorrência."); return
        win=tk.Toplevel(self.root); win.title("Editar ocorrência" if existing else "Nova ocorrência"); win.geometry("560x560");win.configure(bg=WHITE);win.transient(self.root);win.grab_set()
        frame=tk.Frame(win,bg=WHITE,padx=24,pady=20);frame.pack(fill="both",expand=True)
        tk.Label(frame,text="Ocorrência operacional",bg=WHITE,fg=NAVY,font=("Segoe UI",17,"bold")).pack(anchor="w")
        fields={}
        def combo(label,key,options,index=0):
            tk.Label(frame,text=label,bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(10,4));w=ttk.Combobox(frame,values=options,state="readonly");w.pack(fill="x");
            if options: w.current(max(0,min(index,len(options)-1)))
            fields[key]=w
        def entry(label,key,value):
            tk.Label(frame,text=label,bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(10,4));w=ttk.Entry(frame);w.pack(fill="x");w.insert(0,str(value or ""));fields[key]=w
        order_options=[f"{o['id_encomenda']} | {o['codigo_rastreio']}" for o in orders]
        order_index=0
        if existing:
            for i,opt in enumerate(order_options):
                if opt.startswith(f"{existing['id_encomenda']} |"): order_index=i;break
        combo("Encomenda","encomenda",order_options,order_index)
        types=["AVARIA","ATRASO","EXTRAVIO","ENDERECO_NAO_LOCALIZADO","RECUSA_DESTINATARIO","VEICULO_INDISPONIVEL","OUTRA"]
        situations=["ABERTA","EM_TRATAMENTO","RESOLVIDA","CANCELADA"]
        combo("Tipo","tipo",types,types.index(existing["tipo"]) if existing else 0)
        entry("Data e hora (AAAA-MM-DD HH:MM:SS)","data",existing.get("data_hora",datetime.now().replace(microsecond=0).strftime("%Y-%m-%d %H:%M:%S")) if existing else datetime.now().replace(microsecond=0).strftime("%Y-%m-%d %H:%M:%S"))
        combo("Situação","situacao",situations,situations.index(existing["situacao"]) if existing else 0)
        entry("Descrição","descricao",existing.get("descricao","") if existing else "")
        def save():
            desc=fields["descricao"].get().strip()
            if not desc: messagebox.showwarning("Validação","A descrição é obrigatória.",parent=win);return
            try:
                moment=datetime.strptime(fields["data"].get().strip(),"%Y-%m-%d %H:%M:%S")
                order_id=int(fields["encomenda"].get().split("|",1)[0].strip())
                with self.db.transaction(actor=self.current_user or "sistema") as conn:
                    cur=conn.cursor()
                    if existing:
                        cur.execute("UPDATE ocorrencia SET tipo=%s,data_hora=%s,descricao=%s,situacao=%s,id_encomenda=%s WHERE id_ocorrencia=%s",(fields["tipo"].get(),moment,desc,fields["situacao"].get(),order_id,existing["id_ocorrencia"]))
                    else:
                        cur.execute("INSERT INTO ocorrencia (tipo,data_hora,descricao,situacao,id_encomenda) VALUES (%s,%s,%s,%s,%s)",(fields["tipo"].get(),moment,desc,fields["situacao"].get(),order_id))
                    cur.close()
                win.destroy();self.show_page("Entregas")
            except ValueError as exc: messagebox.showwarning("Validação",f"Verifique a data e hora no formato AAAA-MM-DD HH:MM:SS. {exc}",parent=win)
            except Exception as exc: self._show_db_error("Não foi possível salvar a ocorrência",exc,win)
        self.action_button(frame,"Salvar ocorrência",save).pack(fill="x",pady=20)

    def edit_selected_incident(self) -> None:
        if not self._require_write(): return
        row=self._selected_row(getattr(self,"incident_tree",None))
        if row: self._incident_form(row)

    def delete_selected_incident(self) -> None:
        if not self._require_write(): return
        row=self._selected_row(getattr(self,"incident_tree",None))
        if not row: return
        if not messagebox.askyesno("Excluir ocorrência",f"Excluir ocorrência #{row['id_ocorrencia']}? A exclusão será definitiva."): return
        try:
            with self.db.transaction(actor=self.current_user or "sistema") as conn:
                cur=conn.cursor();cur.execute("DELETE FROM ocorrencia WHERE id_ocorrencia=%s",(row["id_ocorrencia"],));cur.close()
            self.show_page("Entregas")
        except Exception as exc: self._show_db_error("Não foi possível excluir a ocorrência",exc)

    def page_advanced_queries(self) -> None:
        self.page_heading("Consultas avançadas", "Duas consultas parametrizadas com junções e agregações, exigidas pela Etapa 2.")
        if not self._need_connection(): return
        nb=ttk.Notebook(self.content);nb.pack(fill="both",expand=True)
        tab1=tk.Frame(nb,bg=BG,padx=12,pady=12);tab2=tk.Frame(nb,bg=BG,padx=12,pady=12)
        nb.add(tab1,text="Desempenho de motoristas");nb.add(tab2,text="Encomendas por status/cidade")
        # Consulta 1
        top=tk.Frame(tab1,bg=WHITE,padx=16,pady=14,highlightbackground=BORDER,highlightthickness=1);top.pack(fill="x",pady=(0,12))
        drivers=self._safe_fetch("SELECT m.id_funcionario,f.nome FROM motorista m JOIN funcionario f ON f.id_funcionario=m.id_funcionario ORDER BY f.nome")
        tk.Label(top,text="Data inicial",bg=WHITE,fg=TEXT).grid(row=0,column=0,sticky="w"); start=ttk.Entry(top,width=15);start.grid(row=1,column=0,padx=(0,10),pady=5);start.insert(0,date.today().replace(month=1, day=1).isoformat())
        tk.Label(top,text="Data final",bg=WHITE,fg=TEXT).grid(row=0,column=1,sticky="w"); end=ttk.Entry(top,width=15);end.grid(row=1,column=1,padx=(0,10),pady=5);end.insert(0,date.today().isoformat())
        tk.Label(top,text="Motorista",bg=WHITE,fg=TEXT).grid(row=0,column=2,sticky="w")
        opts=["Todos"]+[f"{d['id_funcionario']} | {d['nome']}" for d in drivers];driver=ttk.Combobox(top,values=opts,state="readonly",width=28);driver.current(0);driver.grid(row=1,column=2,padx=(0,10),pady=5)
        result1=tk.Frame(tab1,bg=BG);result1.pack(fill="both",expand=True)
        def run_driver_query():
            for child in result1.winfo_children():child.destroy()
            try:
                d1=datetime.strptime(start.get().strip(),"%Y-%m-%d").date();d2=datetime.strptime(end.get().strip(),"%Y-%m-%d").date()
                if d1>d2: raise ValueError("A data inicial deve ser anterior à data final.")
                driver_id=None if driver.current()==0 else int(driver.get().split("|",1)[0].strip())
                sql="""SELECT f.id_funcionario AS id_motorista,f.nome AS motorista,
                         COUNT(t.id_tentativa) AS total_tentativas,
                         SUM(CASE WHEN t.resultado='SUCESSO' THEN 1 ELSE 0 END) AS sucessos,
                         SUM(CASE WHEN t.resultado='INSUCESSO' THEN 1 ELSE 0 END) AS insucessos,
                         ROUND(100.0*SUM(CASE WHEN t.resultado='SUCESSO' THEN 1 ELSE 0 END)/NULLIF(COUNT(t.id_tentativa),0),2) AS taxa_sucesso_pct
                       FROM motorista m JOIN funcionario f ON f.id_funcionario=m.id_funcionario
                       LEFT JOIN tentativa_entrega t ON t.id_funcionario_motorista=m.id_funcionario
                         AND t.data_hora >= %s AND t.data_hora < DATE_ADD(%s, INTERVAL 1 DAY)
                       WHERE (%s IS NULL OR m.id_funcionario=%s)
                       GROUP BY f.id_funcionario,f.nome ORDER BY taxa_sucesso_pct DESC,motorista"""
                rows=self._safe_fetch(sql,(d1,d2,driver_id,driver_id));self._table_from_result(result1,rows,height=12)
            except ValueError as exc: messagebox.showwarning("Filtros inválidos",str(exc))
        self.action_button(top,"Executar consulta",run_driver_query).grid(row=1,column=3,padx=4)
        run_driver_query()
        # Consulta 2
        top2=tk.Frame(tab2,bg=WHITE,padx=16,pady=14,highlightbackground=BORDER,highlightthickness=1);top2.pack(fill="x",pady=(0,12))
        tk.Label(top2,text="Data inicial",bg=WHITE,fg=TEXT).grid(row=0,column=0,sticky="w");s2=ttk.Entry(top2,width=15);s2.grid(row=1,column=0,padx=(0,10),pady=5);s2.insert(0,date.today().replace(month=1, day=1).isoformat())
        tk.Label(top2,text="Data final",bg=WHITE,fg=TEXT).grid(row=0,column=1,sticky="w");e2=ttk.Entry(top2,width=15);e2.grid(row=1,column=1,padx=(0,10),pady=5);e2.insert(0,date.today().isoformat())
        status_opts=["TODOS"]+list(STATUS_ENCOMENDA)+["SEM_HISTORICO"]
        tk.Label(top2,text="Status",bg=WHITE,fg=TEXT).grid(row=0,column=2,sticky="w");status=ttk.Combobox(top2,values=status_opts,state="readonly",width=24);status.current(0);status.grid(row=1,column=2,padx=(0,10),pady=5)
        tk.Label(top2,text="Cidade destino (opcional)",bg=WHITE,fg=TEXT).grid(row=0,column=3,sticky="w");city=ttk.Entry(top2,width=22);city.grid(row=1,column=3,padx=(0,10),pady=5)
        result2=tk.Frame(tab2,bg=BG);result2.pack(fill="both",expand=True)
        def run_order_query():
            for child in result2.winfo_children():child.destroy()
            try:
                d1=datetime.strptime(s2.get().strip(),"%Y-%m-%d").date();d2=datetime.strptime(e2.get().strip(),"%Y-%m-%d").date()
                if d1>d2:raise ValueError("A data inicial deve ser anterior à data final.")
                st=status.get();ct=city.get().strip()
                sql="""SELECT cid.nome AS cidade_destino,cid.uf AS uf_destino,
                       COALESCE(v.status_atual,'SEM_HISTORICO') AS status_atual,
                       COUNT(DISTINCT e.id_encomenda) AS total_encomendas,
                       COUNT(DISTINCT o.id_ocorrencia) AS total_ocorrencias
                       FROM encomenda e JOIN endereco ed ON ed.id_endereco=e.id_endereco_destino
                       JOIN cidade cid ON cid.id_cidade=ed.id_cidade
                       LEFT JOIN vw_encomenda_status_atual v ON v.id_encomenda=e.id_encomenda
                       LEFT JOIN ocorrencia o ON o.id_encomenda=e.id_encomenda
                       WHERE e.data_postagem BETWEEN %s AND %s
                         AND (%s='TODOS' OR COALESCE(v.status_atual,'SEM_HISTORICO')=%s)
                         AND (%s='' OR cid.nome LIKE %s)
                       GROUP BY cid.nome,cid.uf,COALESCE(v.status_atual,'SEM_HISTORICO')
                       ORDER BY total_encomendas DESC,cidade_destino,status_atual"""
                rows=self._safe_fetch(sql,(d1,d2,st,st,ct,f"%{ct}%"));self._table_from_result(result2,rows,height=12)
            except ValueError as exc: messagebox.showwarning("Filtros inválidos",str(exc))
        self.action_button(top2,"Executar consulta",run_order_query).grid(row=1,column=4,padx=4)
        run_order_query()

    def page_security_tests(self) -> None:
        self.page_heading("Segurança, transações e auditoria", "Gerencie usuários de aplicação, teste rollback e consulte a situação de isolamento.")
        if not self._need_connection(): return
        nb=ttk.Notebook(self.content);nb.pack(fill="both",expand=True)
        users_tab=tk.Frame(nb,bg=BG,padx=12,pady=12);tx_tab=tk.Frame(nb,bg=BG,padx=12,pady=12);audit_tab=tk.Frame(nb,bg=BG,padx=12,pady=12)
        nb.add(users_tab,text="Usuários da aplicação");nb.add(tx_tab,text="Transações e concorrência");nb.add(audit_tab,text="Auditoria")
        if self.current_role == "ADMINISTRADOR":
            top=tk.Frame(users_tab,bg=BG);top.pack(fill="x",pady=(0,10))
            self.action_button(top,"Criar usuário",self._create_app_user_dialog).pack(side="left")
            self.action_button(top,"Ativar/desativar selecionado",self._toggle_app_user,primary=False).pack(side="left",padx=8)
            user_rows=self.db.list_app_users()
            self.user_tree=self._table(users_tab,[("id_usuario","ID",55),("nome_usuario","Usuário",140),("nome_exibicao","Nome",200),("perfil","Perfil",150),("ativo","Ativo",75),("data_criacao","Criado em",160),("ultimo_login","Último login",160)],user_rows,height=9)
        else:
            tk.Label(users_tab,text="Somente ADMINISTRADOR pode gerenciar usuários.",bg=BG,fg=MUTED).pack(anchor="w")
        panel=tk.Frame(tx_tab,bg=WHITE,padx=18,pady=16,highlightbackground=BORDER,highlightthickness=1);panel.pack(fill="x",pady=(0,12))
        tk.Label(panel,text="Teste controlado de ROLLBACK",bg=WHITE,fg=NAVY,font=("Segoe UI",12,"bold")).pack(anchor="w")
        tk.Label(panel,text="Cria uma encomenda de teste dentro de uma transação e provoca uma violação CHECK ao inserir um volume inválido. A transação deve ser desfeita e o código de teste não deve permanecer no banco.",bg=WHITE,fg=MUTED,wraplength=850,justify="left").pack(anchor="w",pady=(5,10))
        self.action_button(panel,"Executar teste de rollback",self._run_rollback_demo).pack(anchor="w")
        level_panel=tk.Frame(tx_tab,bg=WHITE,padx=18,pady=16,highlightbackground=BORDER,highlightthickness=1);level_panel.pack(fill="x",pady=(0,12))
        level=tk.Label(level_panel,text="Nível de isolamento ainda não consultado.",bg=WHITE,fg=TEXT);level.pack(side="left")
        self.action_button(level_panel,"Consultar isolamento",lambda:self._show_isolation(level)).pack(side="right")
        guide=tk.Frame(tx_tab,bg="#FFF7E6",padx=18,pady=15);guide.pack(fill="x")
        tk.Label(guide,text="Experimento de concorrência com duas sessões",bg="#FFF7E6",fg="#825B11",font=("Segoe UI",10,"bold")).pack(anchor="w")
        tk.Label(guide,text="Abra duas sessões no Workbench. Na sessão A, inicie uma transação e execute SELECT ... FOR UPDATE em um registro de encomenda; sem COMMIT, tente atualizar a mesma encomenda na sessão B. Registre o tempo de espera/bloqueio e o valor de @@transaction_isolation em ambas as sessões. Depois faça COMMIT ou ROLLBACK na sessão A e observe a sessão B.",bg="#FFF7E6",fg="#825B11",wraplength=880,justify="left").pack(anchor="w",pady=(5,0))
        audit_top=tk.Frame(audit_tab,bg=BG);audit_top.pack(fill="x",pady=(0,10))
        self.action_button(audit_top,"Atualizar auditoria",lambda:self._load_audit_table(audit_tab),primary=False).pack(side="left")
        self._load_audit_table(audit_tab)

    def _load_audit_table(self, parent: tk.Widget) -> None:
        for child in list(parent.winfo_children()):
            if getattr(child,"_audit_data_table",False): child.destroy()
        if self.current_role != "ADMINISTRADOR":
            note = tk.Label(parent, text="O histórico de auditoria contém informações administrativas e está restrito ao perfil ADMINISTRADOR.", bg=BG, fg=MUTED, justify="left")
            note.pack(anchor="w")
            note._audit_data_table = True
            return
        try:
            rows=self.db.fetch_all("SELECT id_auditoria,tabela_afetada,operacao,registro_id,autor,data_hora,valores_anteriores,valores_posteriores FROM auditoria_alteracao ORDER BY data_hora DESC LIMIT 300")
            tree=self._table(parent,[("id_auditoria","ID",55),("tabela_afetada","Tabela",110),("operacao","Operação",90),("registro_id","Registro",100),("autor","Autor",170),("data_hora","Data/hora",160),("valores_anteriores","Anterior (JSON)",260),("valores_posteriores","Posterior (JSON)",260)],rows,height=10)
            tree.master._audit_data_table=True
        except Exception as exc:
            tk.Label(parent,text="A auditoria ainda não está disponível. Execute sql/04_etapa2_seguranca_auditoria.sql.\n"+self._friendly_db_message(exc),bg=BG,fg=RED,justify="left").pack(anchor="w")

    def _run_rollback_demo(self) -> None:
        """Demonstra rollback com uma violação de chave primária, não CHECK.

        Duplicar (id_encomenda, num_volume) é rejeitado por uma PK em todas as
        versões suportadas do MySQL. Isso evita falsos resultados em servidores
        antigos que não aplicam CHECK constraints.
        """
        if not self._require_write():
            return

        reference = self.db.fetch_one(
            "SELECT id_cliente,id_endereco_origem,id_endereco_destino FROM encomenda LIMIT 1"
        )
        if not reference:
            reference = self.db.fetch_one(
                """SELECT c.id_cliente,
                          MIN(e.id_endereco) AS id_endereco_origem,
                          MAX(e.id_endereco) AS id_endereco_destino
                   FROM cliente c CROSS JOIN endereco e
                   GROUP BY c.id_cliente
                   HAVING MIN(e.id_endereco) < MAX(e.id_endereco)
                   LIMIT 1"""
            )
        if not reference or reference.get("id_endereco_origem") == reference.get("id_endereco_destino"):
            messagebox.showwarning(
                "Dados insuficientes",
                "O teste requer pelo menos um cliente e dois endereços diferentes."
            )
            return

        code = "ROLLBACK-TEST-" + datetime.now().strftime("%Y%m%d%H%M%S%f")
        reached_duplicate_statement = False
        failure_exc: Exception | None = None
        try:
            try:
                with self.db.transaction(actor=self.current_user or "sistema") as conn:
                    cur = conn.cursor()
                    try:
                        cur.execute(
                            """INSERT INTO encomenda
                               (codigo_rastreio,data_postagem,valor_declarado,id_cliente,
                                id_endereco_origem,id_endereco_destino)
                               VALUES (%s,%s,%s,%s,%s,%s)""",
                            (code, date.today(), 0, reference["id_cliente"],
                             reference["id_endereco_origem"], reference["id_endereco_destino"]),
                        )
                        new_id = cur.lastrowid
                        # Primeira gravação dependente: volume válido.
                        cur.execute(
                            """INSERT INTO volume_encomenda
                               (id_encomenda,num_volume,peso,altura,largura,comprimento,descricao_conteudo)
                               VALUES (%s,1,1,10,10,10,'VOLUME ROLLBACK')""",
                            (new_id,),
                        )
                        # Falha intencional: a mesma PK composta já existe.
                        reached_duplicate_statement = True
                        cur.execute(
                            """INSERT INTO volume_encomenda
                               (id_encomenda,num_volume,peso,altura,largura,comprimento,descricao_conteudo)
                               VALUES (%s,1,2,10,10,10,'VOLUME DUPLICADO PARA TESTE')""",
                            (new_id,),
                        )
                    finally:
                        cur.close()
            except Exception as exc:
                # O transaction context manager deve executar rollback antes de propagar.
                failure_exc = exc

            persisted_order = self.db.fetch_one(
                "SELECT COUNT(*) AS n FROM encomenda WHERE codigo_rastreio=%s", (code,)
            )
            persisted_volume = self.db.fetch_one(
                """SELECT COUNT(*) AS n
                   FROM volume_encomenda v
                   JOIN encomenda e ON e.id_encomenda=v.id_encomenda
                   WHERE e.codigo_rastreio=%s""",
                (code,),
            )
            errno = getattr(failure_exc, "errno", None) if failure_exc else None
            duplicate_failed = failure_exc is not None and (
                errno == 1062 or "duplicate entry" in str(failure_exc).lower()
                or "duplicate key" in str(failure_exc).lower()
            )
            order_count = int(persisted_order["n"]) if persisted_order else -1
            volume_count = int(persisted_volume["n"]) if persisted_volume else -1

            if reached_duplicate_statement and duplicate_failed and order_count == 0 and volume_count == 0:
                messagebox.showinfo(
                    "Rollback confirmado",
                    "O teste provocou uma chave duplicada após inserir a encomenda e seu primeiro volume. "
                    "A transação foi desfeita: nem a encomenda nem o volume permaneceram no banco."
                )
            else:
                if failure_exc is None:
                    detail = "O MySQL não rejeitou a inserção duplicada, o que não era esperado."
                elif not duplicate_failed:
                    detail = self._friendly_db_message(failure_exc)
                else:
                    detail = "A falha ocorreu, mas os dados ainda foram encontrados após a transação."
                messagebox.showerror(
                    "Teste de rollback não comprovado",
                    f"{detail}\n\nVerificação após a tentativa: encomendas={order_count}; volumes={volume_count}. "
                    "Confirme que todas as tabelas envolvidas usam InnoDB e que a conexão MySQL tem privilégios de escrita."
                )
        except Exception as exc:
            self._show_db_error("Não foi possível executar o teste de rollback", exc)

    def _show_isolation(self, label: tk.Label) -> None:
        try:
            row=self.db.fetch_one("SELECT @@transaction_isolation AS nivel")
            label.configure(text=f"Nível de isolamento do servidor: {row['nivel'] if row else 'desconhecido'}")
        except Exception as exc: self._show_db_error("Não foi possível consultar o isolamento",exc)

    def _create_app_user_dialog(self) -> None:
        if not self._require_admin(): return
        win=tk.Toplevel(self.root);win.title("Criar usuário da aplicação");win.geometry("470x490");win.configure(bg=WHITE);win.transient(self.root);win.grab_set()
        frame=tk.Frame(win,bg=WHITE,padx=24,pady=22);frame.pack(fill="both",expand=True)
        tk.Label(frame,text="Novo usuário",bg=WHITE,fg=NAVY,font=("Segoe UI",17,"bold")).pack(anchor="w")
        fields={}
        for label,key in [("Nome de usuário","username"),("Nome de exibição","display") ,("Senha (mínimo 10 caracteres)","password"),("Confirmar senha","confirm")]:
            tk.Label(frame,text=label,bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(12,4));w=ttk.Entry(frame,show="*" if key in ("password","confirm") else "");w.pack(fill="x");fields[key]=w
        tk.Label(frame,text="Perfil",bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(12,4))
        profile=ttk.Combobox(frame,values=["OPERADOR","CONSULTA","ADMINISTRADOR"],state="readonly");profile.current(0);profile.pack(fill="x")
        def save():
            if fields["password"].get()!=fields["confirm"].get():messagebox.showwarning("Validação","As senhas não coincidem.",parent=win);return
            try:
                self.db.create_app_user(fields["username"].get(),fields["display"].get(),fields["password"].get(),profile.get(),actor=self.current_user or "sistema")
                win.destroy();self.show_page("Segurança e testes");messagebox.showinfo("Sucesso","Usuário criado. A senha foi armazenada com hash e sal.")
            except Exception as exc:self._show_db_error("Não foi possível criar usuário",exc,win)
        self.action_button(frame,"Criar usuário",save).pack(fill="x",pady=20)

    def _toggle_app_user(self) -> None:
        if not self._require_admin():return
        row=self._selected_row(getattr(self,"user_tree",None))
        if not row:return
        if row["nome_usuario"] == self.current_user and int(row["ativo"]) == 1:
            messagebox.showwarning("Operação não permitida","Você não pode desativar o usuário conectado.");return
        try:
            self.db.set_app_user_active(int(row["id_usuario"]),not bool(row["ativo"]),actor=self.current_user or "sistema")
            self.show_page("Segurança e testes")
        except Exception as exc:self._show_db_error("Não foi possível alterar o usuário",exc)

    def _open_login_dialog(self) -> None:
        if not self.connected: return
        try:
            # Se a conta MySQL CONSULTA estiver configurada, ela valida o login da
            # aplicação com privilégios mínimos. Só a criação inicial usa a conta
            # bootstrap, que precisa conseguir inserir o primeiro administrador.
            self.db.use_authentication_connection()
            user_count=self.db.count_app_users()
            if user_count == 0:
                self.db.use_bootstrap_connection()
        except Exception as exc:
            self.connected=False;self.current_user=None
            messagebox.showerror("Configure a etapa de segurança","Não foi possível consultar usuario_aplicacao. Execute sql/04_etapa2_seguranca_auditoria.sql e confira as credenciais do perfil CONSULTA no config.ini.\n\n"+self._friendly_db_message(exc),parent=self.root)
            self.show_page("Conexão");return
        win=tk.Toplevel(self.root);win.configure(bg=WHITE);win.transient(self.root);win.grab_set()
        fields={}
        if user_count == 0:
            win.title("Configuração inicial — administrador");win.geometry("480x530")
            heading="Criar o primeiro administrador"
            intro="Nenhum usuário existe ainda. Crie a conta administradora inicial; a senha será salva com PBKDF2, hash e sal."
            labels=[("Usuário","username",False),("Nome de exibição","display",False),("Senha (mínimo 10 caracteres)","password",True),("Confirmar senha","confirm",True)]
        else:
            win.title("Login — Nexo Logística");win.geometry("440x390")
            heading="Entrar no Nexo Logística"
            intro="Informe seu usuário da aplicação. O perfil controla quais operações podem ser feitas na interface."
            labels=[("Usuário","username",False),("Senha","password",True)]
        frame=tk.Frame(win,bg=WHITE,padx=26,pady=24);frame.pack(fill="both",expand=True)
        tk.Label(frame,text=heading,bg=WHITE,fg=NAVY,font=("Segoe UI",17,"bold")).pack(anchor="w")
        tk.Label(frame,text=intro,bg=WHITE,fg=MUTED,wraplength=390,justify="left").pack(anchor="w",pady=(6,12))
        for label,key,secret in labels:
            tk.Label(frame,text=label,bg=WHITE,fg=TEXT,font=("Segoe UI",9,"bold")).pack(anchor="w",pady=(8,4));w=ttk.Entry(frame,show="*" if secret else "");w.pack(fill="x");fields[key]=w
        error=tk.Label(frame,text="",bg=WHITE,fg=RED,wraplength=390,justify="left");error.pack(anchor="w",pady=(8,0))
        def close():
            self.connected=False;self.current_user=None;self.current_display_name=None;self.current_role=None
            self.status_var.set("Login necessário");self.connection_badge.configure(bg="#FCE7C1",fg="#8B5E12")
            win.destroy();self.show_page("Conexão")
        def submit():
            try:
                if user_count == 0:
                    if fields["password"].get()!=fields["confirm"].get():error.configure(text="As senhas não coincidem.");return
                    self.db.create_app_user(fields["username"].get(),fields["display"].get(),fields["password"].get(),"ADMINISTRADOR",first_admin_only=True,actor="configuração inicial")
                    authenticated={"nome_usuario":fields["username"].get().strip(),"nome_exibicao":fields["display"].get().strip(),"perfil":"ADMINISTRADOR"}
                else:
                    authenticated=self.db.authenticate_user(fields["username"].get(),fields["password"].get())
                    if not authenticated:error.configure(text="Usuário ou senha inválidos, ou usuário desativado.");return
                # Depois da autenticação da aplicação, tenta trocar para a conta MySQL
                # dedicada ao perfil (config.ini: [mysql_administrador], [mysql_operador],
                # [mysql_consulta]). Sem essas seções, a interface avisa que o papel MySQL
                # ainda não está efetivamente isolado.
                try:
                    db_profile_enforced = self.db.use_app_profile(authenticated["perfil"])
                except Exception as profile_exc:
                    self.db.use_bootstrap_connection()
                    error.configure(text="O usuário da aplicação foi validado, mas a conta MySQL específica deste perfil não conectou. " + self._friendly_db_message(profile_exc))
                    return
                self.current_user=authenticated["nome_usuario"]
                self.current_display_name=authenticated["nome_exibicao"]
                self.current_role=authenticated["perfil"]
                self.db_profile_enforced = db_profile_enforced
                if db_profile_enforced:
                    self.status_var.set(f"{self.current_display_name} • {self.current_role} • MySQL restrito")
                    self.connection_badge.configure(bg="#D7F3E5",fg=GREEN)
                else:
                    self.status_var.set(f"{self.current_display_name} • {self.current_role} • DB geral")
                    self.connection_badge.configure(bg="#FCE7C1",fg="#8B5E12")
                win.destroy()
                self.show_page("Relatórios" if self.current_role == "CONSULTA" else "Dashboard")
                if not db_profile_enforced:
                    messagebox.showwarning(
                        "Permissões MySQL por perfil não configuradas",
                        "A interface restringe as telas pelo perfil, mas a conexão atual continua usando a conta MySQL geral. "
                        "Para demonstrar o princípio do menor privilégio no banco, configure as seções "
                        "[mysql_administrador], [mysql_operador] e [mysql_consulta] no config.ini com logins MySQL "
                        "que tenham os papéis nexo_admin, nexo_operador e nexo_consulta, respectivamente."
                    )
            except Exception as exc:error.configure(text=self._friendly_db_message(exc))
        self.action_button(frame,"Criar administrador" if user_count==0 else "Entrar",submit).pack(fill="x",pady=(16,6))
        if user_count>0:self.action_button(frame,"Voltar à conexão",close,primary=False).pack(fill="x")
        win.protocol("WM_DELETE_WINDOW",close)
        fields["username"].focus_set();fields["username"].bind("<Return>",lambda _e:submit())

    def page_tracking(self) -> None:
        self.page_heading("Rastreamento", "Consulte o status atual e a linha do tempo de uma encomenda.")
        panel = tk.Frame(self.content, bg=WHITE, padx=20, pady=18,
                         highlightbackground=BORDER, highlightthickness=1)
        panel.pack(fill="x", pady=(0, 18))
        tk.Label(panel, text="Código de rastreio", bg=WHITE, fg=TEXT,
                 font=("Segoe UI", 9, "bold")).pack(anchor="w")
        row = tk.Frame(panel, bg=WHITE)
        row.pack(fill="x", pady=(7, 0))
        code = ttk.Entry(row, width=42)
        code.pack(side="left", ipady=4)
        info = tk.Frame(self.content, bg=BG)
        info.pack(fill="both", expand=True)

        def summary_query(term: str) -> list[dict[str, Any]]:
            # O perfil CONSULTA não recebe SELECT nas tabelas pessoais de base.
            # Ele consulta somente views explicitamente limitadas pelo SQL 04.
            if self.current_role == "CONSULTA":
                return self._safe_fetch(
                    """SELECT codigo_rastreio, data_postagem, status_atual,
                              'Informações restritas' AS cliente,
                              CONCAT(cidade_destino, ' - ', uf_destino) AS destino
                       FROM vw_rastreamento_publico
                       WHERE UPPER(TRIM(codigo_rastreio)) = UPPER(%s)
                       LIMIT 1""",
                    (term,),
                )
            return self._safe_fetch(
                self._orders_sql() +
                " WHERE UPPER(TRIM(e.codigo_rastreio)) = UPPER(%s) LIMIT 1",
                (term,),
            )

        def search() -> None:
            for child in info.winfo_children():
                child.destroy()
            if not self._need_connection():
                return
            term = code.get().strip()
            if not term:
                messagebox.showwarning("Rastreamento", "Digite o código de rastreio.")
                return

            rows = summary_query(term)
            if not rows:
                # Ajuda o usuário a corrigir códigos parcialmente informados sem
                # selecionar silenciosamente uma encomenda errada.
                if self.current_role == "CONSULTA":
                    candidates = self._safe_fetch(
                        """SELECT codigo_rastreio FROM vw_rastreamento_publico
                           WHERE UPPER(codigo_rastreio) LIKE UPPER(%s)
                           ORDER BY codigo_rastreio LIMIT 8""",
                        (f"%{term}%",),
                    )
                else:
                    candidates = self._safe_fetch(
                        """SELECT codigo_rastreio FROM encomenda
                           WHERE UPPER(codigo_rastreio) LIKE UPPER(%s)
                           ORDER BY codigo_rastreio LIMIT 8""",
                        (f"%{term}%",),
                    )
                if candidates:
                    codes = "\n".join(str(item["codigo_rastreio"]) for item in candidates)
                    messagebox.showinfo(
                        "Código não exato",
                        "Não encontrei uma correspondência exata. Confira os códigos semelhantes:\n\n" + codes,
                    )
                else:
                    messagebox.showinfo(
                        "Rastreamento",
                        "Nenhuma encomenda encontrada. Confira o código. Nos dados fictícios de demonstração, "
                        "você pode testar BR100000TR, BR100001TR ou BR100002TR."
                    )
                return

            order = rows[0]
            card = tk.Frame(info, bg=WHITE, padx=22, pady=18,
                            highlightbackground=BORDER, highlightthickness=1)
            card.pack(fill="x", pady=(0, 15))
            tk.Label(card, text=order["codigo_rastreio"], bg=WHITE, fg=NAVY,
                     font=("Segoe UI", 17, "bold")).pack(anchor="w")
            tk.Label(card, text=f"Remetente: {order['cliente']}    •    Destino: {order['destino']}",
                     bg=WHITE, fg=MUTED, font=("Segoe UI", 10)).pack(anchor="w", pady=(5, 7))
            status = str(order.get("status_atual") or "SEM_HISTORICO")
            status_color = "#D7F3E5" if status == "ENTREGUE" else "#FCE7C1"
            status_text_color = GREEN if status == "ENTREGUE" else "#8B5E12"
            tk.Label(card, text=f"STATUS ATUAL  ·  {status.replace('_', ' ')}",
                     bg=status_color, fg=status_text_color, padx=12, pady=7,
                     font=("Segoe UI", 10, "bold")).pack(anchor="w")

            if self.current_role == "CONSULTA":
                history = self._safe_fetch(
                    """SELECT data_hora, status, NULL AS observacao, centro
                       FROM vw_historico_rastreamento_publico
                       WHERE UPPER(TRIM(codigo_rastreio)) = UPPER(%s)
                       ORDER BY data_hora DESC""",
                    (term,),
                )
            else:
                history = self._safe_fetch(
                    """SELECT h.data_hora, h.status, h.observacao, cd.nome AS centro
                       FROM historico_status_encomenda h
                       JOIN encomenda e ON e.id_encomenda=h.id_encomenda
                       LEFT JOIN centro_distribuicao cd ON cd.id_centro=h.id_centro
                       WHERE UPPER(TRIM(e.codigo_rastreio)) = UPPER(%s)
                       ORDER BY h.data_hora DESC, h.id_historico DESC""",
                    (term,),
                )
            tk.Label(info, text="Histórico de movimentações", bg=BG, fg=NAVY,
                     font=("Segoe UI", 13, "bold")).pack(anchor="w", pady=(0, 9))
            self._table(info, [
                ("data_hora", "Data e hora", 170), ("status", "Status", 210),
                ("centro", "Centro de distribuição", 240), ("observacao", "Observação", 340),
            ], history, height=10)

        self.action_button(row, "Rastrear", search).pack(side="left", padx=(9, 0))
        code.bind("<Return>", lambda _e: search())
        if not self.connected:
            tk.Label(info, text="Conecte-se ao banco para consultar o rastreamento.",
                     bg=BG, fg=MUTED, font=("Segoe UI", 10)).pack(anchor="w")

    def page_deliveries(self) -> None:
        self.page_heading("Entregas e ocorrências", "Acompanhe as tentativas de entrega e os problemas operacionais registrados.")
        notebook = ttk.Notebook(self.content); notebook.pack(fill="both", expand=True)
        attempts_tab = tk.Frame(notebook, bg=BG, padx=10, pady=12); incidents_tab = tk.Frame(notebook, bg=BG, padx=10, pady=12)
        notebook.add(attempts_tab, text="Tentativas de entrega"); notebook.add(incidents_tab, text="Ocorrências")
        if not self.connected:
            for tab in (attempts_tab, incidents_tab): tk.Label(tab, text="Configure a conexão MySQL para visualizar registros.", bg=BG, fg=MUTED).pack(anchor="w")
            return
        attempts = self._safe_fetch("""SELECT t.id_tentativa, e.codigo_rastreio, t.data_hora, t.resultado,
                                          t.motivo_insucesso, f.nome AS motorista, v.placa
                                   FROM tentativa_entrega t
                                   JOIN encomenda e ON e.id_encomenda=t.id_encomenda
                                   JOIN motorista m ON m.id_funcionario=t.id_funcionario_motorista
                                   JOIN funcionario f ON f.id_funcionario=m.id_funcionario
                                   JOIN veiculo v ON v.id_veiculo=t.id_veiculo
                                   ORDER BY t.data_hora DESC LIMIT 500""")
        self._table(attempts_tab, [("id_tentativa", "ID", 65), ("codigo_rastreio", "Rastreio", 155),
                                  ("data_hora", "Data / hora", 155), ("resultado", "Resultado", 115),
                                  ("motivo_insucesso", "Motivo do insucesso", 230), ("motorista", "Motorista", 190),
                                  ("placa", "Veículo", 100)], attempts, height=13)
        incident_controls = tk.Frame(incidents_tab, bg=BG)
        incident_controls.pack(fill="x", pady=(0, 10))
        self.action_button(incident_controls, "Nova ocorrência", lambda: self._incident_form()).pack(side="left")
        self.action_button(incident_controls, "Editar selecionada", self.edit_selected_incident, primary=False).pack(side="left", padx=8)
        self.action_button(incident_controls, "Excluir selecionada", self.delete_selected_incident, primary=False).pack(side="left")
        incidents = self._safe_fetch("""SELECT o.id_ocorrencia, o.id_encomenda, e.codigo_rastreio, o.tipo, o.data_hora,
                                           o.situacao, o.descricao
                                    FROM ocorrencia o JOIN encomenda e ON e.id_encomenda=o.id_encomenda
                                    ORDER BY o.data_hora DESC LIMIT 500""")
        self.incident_tree = self._table(incidents_tab, [("id_ocorrencia", "ID", 65), ("codigo_rastreio", "Rastreio", 150),
                                    ("tipo", "Tipo", 200), ("data_hora", "Data / hora", 155),
                                    ("situacao", "Situação", 135), ("descricao", "Descrição", 350)], incidents, height=13)

    def page_fleet(self) -> None:
        self.page_heading("Frota e rotas", "Consulte a disponibilidade dos veículos, as rotas e as expedições.")
        notebook = ttk.Notebook(self.content); notebook.pack(fill="both", expand=True)
        tabs = {name: tk.Frame(notebook, bg=BG, padx=10, pady=12) for name in ("Veículos", "Rotas", "Expedições", "Centros")}
        for name, tab in tabs.items(): notebook.add(tab, text=name)
        if not self.connected:
            for tab in tabs.values(): tk.Label(tab, text="Configure a conexão MySQL para visualizar os dados.", bg=BG, fg=MUTED).pack(anchor="w")
            return
        vehicle_rows = self._safe_fetch("SELECT id_veiculo, placa, modelo, capacidade_carga, categoria_cnh_exigida, situacao FROM veiculo ORDER BY placa")
        self._table(tabs["Veículos"], [("id_veiculo", "ID", 60), ("placa", "Placa", 100), ("modelo", "Modelo", 190),
                                      ("capacidade_carga", "Capacidade (kg)", 130), ("categoria_cnh_exigida", "CNH exigida", 100),
                                      ("situacao", "Situação", 145)], vehicle_rows, height=13)
        route_rows = self._safe_fetch("""SELECT r.id_rota, r.nome, r.situacao, COUNT(rc.id_cidade) AS total_cidades,
                                              COALESCE(SUM(rc.distancia_desde_anterior_km),0) AS distancia_km
                                       FROM rota r LEFT JOIN rota_cidade rc ON rc.id_rota=r.id_rota
                                       GROUP BY r.id_rota,r.nome,r.situacao ORDER BY r.nome""")
        self._table(tabs["Rotas"], [("id_rota", "ID", 60), ("nome", "Rota", 220), ("situacao", "Situação", 130),
                                    ("total_cidades", "Cidades", 100), ("distancia_km", "Distância (km)", 140)], route_rows, height=13)
        exp_rows = self._safe_fetch("""SELECT ex.id_expedicao, r.nome AS rota, v.placa, f.nome AS motorista,
                                            ex.data_hora_saida, ex.data_hora_prevista_chegada,
                                            ex.data_hora_chegada, ex.status_expedicao
                                     FROM expedicao ex JOIN rota r ON r.id_rota=ex.id_rota
                                     JOIN veiculo v ON v.id_veiculo=ex.id_veiculo
                                     JOIN motorista m ON m.id_funcionario=ex.id_funcionario_motorista
                                     JOIN funcionario f ON f.id_funcionario=m.id_funcionario
                                     ORDER BY ex.id_expedicao DESC LIMIT 500""")
        self._table(tabs["Expedições"], [("id_expedicao", "ID", 60), ("rota", "Rota", 160), ("placa", "Veículo", 90),
                                          ("motorista", "Motorista", 170), ("data_hora_saida", "Saída", 150),
                                          ("data_hora_prevista_chegada", "Previsão", 150), ("data_hora_chegada", "Chegada", 150),
                                          ("status_expedicao", "Status", 150)], exp_rows, height=13)
        center_rows = self._safe_fetch("""SELECT cd.id_centro, cd.codigo, cd.nome, e.logradouro, e.numero,
                                             cid.nome AS cidade, cid.uf
                                      FROM centro_distribuicao cd JOIN endereco e ON e.id_endereco=cd.id_endereco
                                      JOIN cidade cid ON cid.id_cidade=e.id_cidade ORDER BY cd.nome""")
        self._table(tabs["Centros"], [("id_centro", "ID", 60), ("codigo", "Código", 100), ("nome", "Centro", 200),
                                       ("logradouro", "Logradouro", 220), ("numero", "Número", 80),
                                       ("cidade", "Cidade", 150), ("uf", "UF", 60)], center_rows, height=13)

    def page_reports(self) -> None:
        self.page_heading("Relatórios", "Consultas para apoio à operação e à gestão da transportadora.")
        panel = tk.Frame(self.content, bg=WHITE, padx=18, pady=15, highlightbackground=BORDER, highlightthickness=1)
        panel.pack(fill="x", pady=(0, 15))
        tk.Label(panel, text="Relatório", bg=WHITE, fg=TEXT, font=("Segoe UI", 9, "bold")).pack(anchor="w")
        row = tk.Frame(panel, bg=WHITE); row.pack(fill="x", pady=(6, 0))
        if self.current_role == "CONSULTA":
            report_names = ["Relatório consolidado (view)", "Desempenho dos motoristas (view)"]
        else:
            report_names = ["Relatório consolidado (view)", "Encomendas por status", "Tentativas por resultado", "Veículos indisponíveis",
                            "Desempenho dos motoristas", "Desempenho dos motoristas (view)", "Receita de serviços adicionais", "Expedições por rota"]
        selected = ttk.Combobox(row, values=report_names, state="readonly", width=39); selected.current(0); selected.pack(side="left", ipady=3)
        host = tk.Frame(self.content, bg=BG); host.pack(fill="both", expand=True)

        queries = {
            "Relatório consolidado (view)": """SELECT codigo_rastreio, data_postagem, remetente,
                cidade_destino, uf_destino, status_atual, valor_declarado, total_volumes, total_ocorrencias
                FROM vw_relatorio_operacional ORDER BY data_postagem DESC LIMIT 500""",
            "Desempenho dos motoristas (view)": """SELECT id_motorista, motorista, total_tentativas, sucessos, insucessos, taxa_sucesso_pct FROM vw_desempenho_motoristas ORDER BY taxa_sucesso_pct DESC, motorista""",
            "Encomendas por status": """SELECT COALESCE(v.status_atual,'SEM_HISTORICO') AS status, COUNT(*) AS total
                                      FROM encomenda e LEFT JOIN vw_encomenda_status_atual v ON v.id_encomenda=e.id_encomenda
                                      GROUP BY status ORDER BY total DESC""",
            "Tentativas por resultado": """SELECT resultado, COUNT(*) AS total FROM tentativa_entrega
                                             GROUP BY resultado ORDER BY total DESC""",
            "Veículos indisponíveis": """SELECT placa, modelo, situacao, capacidade_carga FROM veiculo
                                           WHERE situacao IN ('MANUTENCAO','INATIVO') ORDER BY situacao, placa""",
            "Desempenho dos motoristas": """SELECT f.nome AS motorista, COUNT(t.id_tentativa) AS total_tentativas,
                    SUM(CASE WHEN t.resultado='SUCESSO' THEN 1 ELSE 0 END) AS sucessos,
                    ROUND(100.0*SUM(CASE WHEN t.resultado='SUCESSO' THEN 1 ELSE 0 END)/NULLIF(COUNT(t.id_tentativa),0),1) AS taxa_sucesso_pct
                    FROM motorista m JOIN funcionario f ON f.id_funcionario=m.id_funcionario
                    LEFT JOIN tentativa_entrega t ON t.id_funcionario_motorista=m.id_funcionario
                    GROUP BY m.id_funcionario,f.nome ORDER BY taxa_sucesso_pct DESC, motorista""",
            "Receita de serviços adicionais": """SELECT COALESCE(pf.nome,pj.razao_social) AS cliente,
                    SUM(es.valor_contratado) AS receita_servicos, COUNT(DISTINCT e.id_encomenda) AS encomendas_com_servico
                    FROM encomenda e JOIN encomenda_servico es ON es.id_encomenda=e.id_encomenda
                    JOIN cliente c ON c.id_cliente=e.id_cliente
                    LEFT JOIN cliente_pf pf ON pf.id_cliente=c.id_cliente LEFT JOIN cliente_pj pj ON pj.id_cliente=c.id_cliente
                    GROUP BY e.id_cliente,pf.nome,pj.razao_social ORDER BY receita_servicos DESC LIMIT 100""",
            "Expedições por rota": """SELECT r.nome AS rota, ex.status_expedicao, COUNT(*) AS total_expedicoes
                    FROM expedicao ex JOIN rota r ON r.id_rota=ex.id_rota
                    GROUP BY r.id_rota,r.nome,ex.status_expedicao ORDER BY r.nome, total_expedicoes DESC""",
        }

        if self.current_role == "CONSULTA":
            # O perfil de consulta recebe somente a view de rastreamento com colunas
            # minimizadas, sem nome/documento/contato do remetente nem valor declarado.
            queries["Relatório consolidado (view)"] = """SELECT codigo_rastreio, data_postagem,
                cidade_destino, uf_destino, status_atual
                FROM vw_rastreamento_publico ORDER BY data_postagem DESC LIMIT 500"""

        def run_report() -> None:
            for child in host.winfo_children(): child.destroy()
            if not self._need_connection(): return
            result = self._safe_fetch(queries[selected.get()])
            self._table_from_result(host, result, height=15)
        self.action_button(row, "Gerar relatório", run_report).pack(side="left", padx=(9, 0))
        run_report()

    def page_connection(self) -> None:
        self.page_heading("Conexão MySQL", "Configure o acesso ao servidor MySQL onde está o banco db_transportadora.")
        outer = tk.Frame(self.content, bg=BG); outer.pack(fill="both", expand=True)
        panel = tk.Frame(outer, bg=WHITE, padx=26, pady=24, highlightbackground=BORDER, highlightthickness=1)
        panel.pack(fill="x", anchor="n")
        tk.Label(panel, text="Parâmetros do servidor", bg=WHITE, fg=NAVY, font=("Segoe UI", 15, "bold")).grid(row=0, column=0, columnspan=4, sticky="w", pady=(0, 5))
        tk.Label(panel, text="O Workbench não precisa estar aberto para a aplicação conectar; o serviço do MySQL precisa estar em execução. Para limitar permissões reais por perfil, configure as seções específicas de conexão descritas no README.",
                 bg=WHITE, fg=MUTED, font=("Segoe UI", 9), wraplength=850, justify="left").grid(row=1, column=0, columnspan=4, sticky="w", pady=(0, 18))
        field_specs = [("Host", "host", 0, 0), ("Porta", "port", 0, 2), ("Banco de dados", "database", 1, 0),
                       ("Usuário", "user", 1, 2), ("Senha", "password", 2, 0)]
        entries: dict[str, ttk.Entry] = {}
        for label_text, key, row, col in field_specs:
            tk.Label(panel, text=label_text, bg=WHITE, fg=TEXT, font=("Segoe UI", 9, "bold")).grid(row=row*2+2, column=col, sticky="w", pady=(7, 4), padx=(0, 18))
            entry = ttk.Entry(panel, width=37, show="*" if key == "password" else "")
            entry.grid(row=row*2+3, column=col, sticky="ew", pady=(0, 5), padx=(0, 18))
            entry.insert(0, self.db.bootstrap_settings.get(key, ""))
            entries[key] = entry
        panel.grid_columnconfigure(0, weight=1); panel.grid_columnconfigure(2, weight=1)
        hint = tk.Label(panel, text="", bg=WHITE, fg=MUTED, font=("Segoe UI", 9), wraplength=830, justify="left")
        hint.grid(row=9, column=0, columnspan=4, sticky="w", pady=(12, 0))

        def values() -> dict[str, str]: return {key: entry.get() for key, entry in entries.items()}
        def connect() -> None:
            settings = values()
            try:
                self.db.test_connection(settings)
                self.db.save_settings(settings)
                self.connected = True
                self.status_var.set(f"Conectado  •  {settings['database']}")
                self.connection_badge.configure(bg="#D7F3E5", fg=GREEN)
                hint.configure(text="Conexão estabelecida e configuração salva localmente.", fg=GREEN)
                messagebox.showinfo("Conexão bem-sucedida", f"Conectado ao banco {settings['database']}.")
                self._open_login_dialog()
            except Exception as exc:
                self.connected = False
                self.status_var.set("Falha na conexão")
                self.connection_badge.configure(bg="#FDE2E2", fg=RED)
                hint.configure(text=self._friendly_db_message(exc), fg=RED)
                self._show_db_error("Falha na conexão", exc)
        buttons = tk.Frame(panel, bg=WHITE); buttons.grid(row=10, column=0, columnspan=4, sticky="w", pady=(20, 0))
        self.action_button(buttons, "Testar e conectar", connect).pack(side="left")
        self.action_button(buttons, "Limpar senha", lambda: entries["password"].delete(0, "end"), primary=False).pack(side="left", padx=8)
        safety = tk.Frame(outer, bg="#FFF7E6", padx=18, pady=15, highlightbackground="#F4D28D", highlightthickness=1)
        safety.pack(fill="x", pady=(16, 0))
        tk.Label(safety, text="Segurança", bg="#FFF7E6", fg="#825B11", font=("Segoe UI", 10, "bold")).pack(anchor="w")
        tk.Label(safety, text="As credenciais locais ficam no config.ini sem criptografia. Não compartilhe esse arquivo nem o envie ao Git. Configure logins MySQL separados para ADMINISTRADOR, OPERADOR e CONSULTA conforme o README; sem eles, apenas as restrições de tela da aplicação são aplicadas e a permissão SQL da conta geral continua ativa.",
                 bg="#FFF7E6", fg="#825B11", font=("Segoe UI", 9), justify="left", wraplength=900).pack(anchor="w", pady=(5, 0))


def main() -> None:
    root = tk.Tk()
    TransportadoraApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
