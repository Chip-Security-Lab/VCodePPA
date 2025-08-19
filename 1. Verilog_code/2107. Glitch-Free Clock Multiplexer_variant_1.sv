//SystemVerilog
// Top-level glitch-free clock multiplexer with hierarchical structure

module glitch_free_clk_mux(
    input         clk_a,
    input         clk_b,
    input         select,   // 0 for clk_a, 1 for clk_b
    input         rst,
    output        clk_out
);

    // Internal signals for select state
    wire          select_a;
    wire          select_b;

    // Select logic for clk_a domain
    select_a_logic u_select_a_logic (
        .clk_a      (clk_a),
        .rst        (rst),
        .select     (select),
        .select_b   (select_b),
        .select_a   (select_a)
    );

    // Select logic for clk_b domain
    select_b_logic u_select_b_logic (
        .clk_b      (clk_b),
        .rst        (rst),
        .select     (select),
        .select_a   (select_a),
        .select_b   (select_b)
    );

    // Clock output multiplexer logic
    clk_mux_logic u_clk_mux_logic (
        .clk_a      (clk_a),
        .clk_b      (clk_b),
        .select_a   (select_a),
        .select_b   (select_b),
        .clk_out    (clk_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Module: select_a_logic
// Purpose: Generates select_a in clk_a domain ensuring glitch-free operation
// -----------------------------------------------------------------------------
module select_a_logic(
    input      clk_a,
    input      rst,
    input      select,
    input      select_b,
    output reg select_a
);
    always @(negedge clk_a or posedge rst) begin
        if (rst)
            select_a <= 1'b0;
        else
            select_a <= ~(select | select_b);
    end
endmodule

// -----------------------------------------------------------------------------
// Module: select_b_logic
// Purpose: Generates select_b in clk_b domain ensuring glitch-free operation
// -----------------------------------------------------------------------------
module select_b_logic(
    input      clk_b,
    input      rst,
    input      select,
    input      select_a,
    output reg select_b
);
    always @(negedge clk_b or posedge rst) begin
        if (rst)
            select_b <= 1'b0;
        else
            select_b <= select & ~select_a;
    end
endmodule

// -----------------------------------------------------------------------------
// Module: clk_mux_logic
// Purpose: Performs glitch-free clock multiplexing based on select signals
// -----------------------------------------------------------------------------
module clk_mux_logic(
    input      clk_a,
    input      clk_b,
    input      select_a,
    input      select_b,
    output     clk_out
);
    assign clk_out = (clk_a & select_a) | (clk_b & select_b);
endmodule