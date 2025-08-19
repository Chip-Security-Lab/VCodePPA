//SystemVerilog
// Top-level module: Hierarchical Galois LFSR RNG with pipelined structure
module galois_lfsr_rng (
    input  wire        clock,
    input  wire        reset,
    input  wire        enable,
    output reg  [7:0]  rand_data
);

    // Internal pipeline signals
    wire [7:0] lfsr_stage1_out;
    wire [7:0] lfsr_next_state;

    // Stage 1: Pipeline register for current rand_data
    lfsr_stage1_reg u_lfsr_stage1_reg (
        .clk        (clock),
        .rst        (reset),
        .en         (enable),
        .din        (rand_data),
        .dout       (lfsr_stage1_out)
    );

    // Stage 2: LFSR next state combinational logic
    lfsr_next_state_logic u_lfsr_next_state_logic (
        .lfsr_in    (lfsr_stage1_out),
        .lfsr_out   (lfsr_next_state)
    );

    // Stage 3: Output register for pipeline result
    always @(posedge clock) begin
        if (reset)
            rand_data <= 8'h1;
        else if (enable)
            rand_data <= lfsr_next_state;
    end

endmodule

// -----------------------------------------------------------------------------
// lfsr_stage1_reg: Pipeline register for LFSR current value
// -----------------------------------------------------------------------------
module lfsr_stage1_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire [7:0]  din,
    output reg  [7:0]  dout
);
    always @(posedge clk) begin
        if (rst)
            dout <= 8'h1;
        else if (en)
            dout <= din;
    end
endmodule

// -----------------------------------------------------------------------------
// lfsr_next_state_logic: Computes next LFSR value using Galois feedback
// -----------------------------------------------------------------------------
module lfsr_next_state_logic (
    input  wire [7:0]  lfsr_in,
    output wire [7:0]  lfsr_out
);
    // Galois LFSR next state logic
    assign lfsr_out[0] = lfsr_in[7];
    assign lfsr_out[1] = lfsr_in[0];
    assign lfsr_out[2] = lfsr_in[1] ^ lfsr_in[7];
    assign lfsr_out[3] = lfsr_in[2] ^ lfsr_in[7];
    assign lfsr_out[4] = lfsr_in[3];
    assign lfsr_out[5] = lfsr_in[4] ^ lfsr_in[7];
    assign lfsr_out[6] = lfsr_in[5];
    assign lfsr_out[7] = lfsr_in[6];
endmodule