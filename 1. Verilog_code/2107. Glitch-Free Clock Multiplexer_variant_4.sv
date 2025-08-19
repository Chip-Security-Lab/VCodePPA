//SystemVerilog
module glitch_free_clk_mux(
    input  wire clk_a,
    input  wire clk_b,
    input  wire select,   // 0 for clk_a, 1 for clk_b
    input  wire rst,
    output wire clk_out
);

    wire select_a_next;
    wire select_b_next;
    reg  select_a_reg;
    reg  select_b_reg;

    // Combinational logic for next state of select_a and select_b
    assign select_a_next = ~select & ~select_b_reg;
    assign select_b_next = select & ~select_a_reg;

    // Sequential logic for select_a_reg: latch on negedge clk_a or posedge rst
    always @(negedge clk_a or posedge rst) begin
        if (rst)
            select_a_reg <= 1'b0;
        else
            select_a_reg <= select_a_next;
    end

    // Sequential logic for select_b_reg: latch on negedge clk_b or posedge rst
    always @(negedge clk_b or posedge rst) begin
        if (rst)
            select_b_reg <= 1'b0;
        else
            select_b_reg <= select_b_next;
    end

    // Combinational logic for output clock
    assign clk_out = (clk_a & select_a_reg) | (clk_b & select_b_reg);

endmodule