//SystemVerilog
// Top-level module for 32-bit LCG-based RNG with hierarchical structure
module rng_lcg_4(
    input              clk,
    input              rst,
    input              en,
    output [31:0]      rand_val
);

    // Internal signal for LCG state
    wire [31:0] lcg_state_next;
    wire [31:0] lcg_state_q;

    // Instantiate LCG state register submodule
    lcg_state_reg u_lcg_state_reg (
        .clk        (clk),
        .rst        (rst),
        .en         (en),
        .next_val   (lcg_state_next),
        .state_q    (lcg_state_q)
    );

    // Instantiate LCG update logic submodule
    lcg_update #(
        .A(32'h41C64E6D),
        .C(32'h00003039)
    ) u_lcg_update (
        .current_val(lcg_state_q),
        .next_val   (lcg_state_next)
    );

    // Output assignment
    assign rand_val = lcg_state_q;

endmodule

// ------------------------------------------------------------------------
// Submodule: lcg_state_reg
// Purpose  : 32-bit register for LCG state with synchronous reset and enable
// ------------------------------------------------------------------------
module lcg_state_reg (
    input         clk,
    input         rst,
    input         en,
    input  [31:0] next_val,
    output [31:0] state_q
);

    reg [31:0] state_reg;
    reg [31:0] state_reg_next;

    // --------------------------------------------------------------------
    // Always block: State register update (sequential logic)
    // Handles updating the state register on clock edge
    // --------------------------------------------------------------------
    always @(posedge clk) begin
        state_reg <= state_reg_next;
    end

    // --------------------------------------------------------------------
    // Always block: Next state logic
    // Handles reset and enable logic for next state value
    // --------------------------------------------------------------------
    always @(*) begin
        if (rst) begin
            state_reg_next = 32'h12345678;
        end else if (en) begin
            state_reg_next = next_val;
        end else begin
            state_reg_next = state_reg;
        end
    end

    assign state_q = state_reg;
endmodule

// ------------------------------------------------------------------------
// Submodule: lcg_update
// Purpose  : Computes the next LCG value: next_val = current_val * A + C
// Parameters :
//    A - LCG multiplier
//    C - LCG increment
// ------------------------------------------------------------------------
module lcg_update #(
    parameter A = 32'h41C64E6D,
    parameter C = 32'h00003039
)(
    input  [31:0] current_val,
    output [31:0] next_val
);

    // --------------------------------------------------------------------
    // Always block: LCG calculation
    // Computes next LCG value combinationally
    // --------------------------------------------------------------------
    reg [31:0] lcg_next_val;
    always @(*) begin
        lcg_next_val = current_val * A + C;
    end

    assign next_val = lcg_next_val;

endmodule