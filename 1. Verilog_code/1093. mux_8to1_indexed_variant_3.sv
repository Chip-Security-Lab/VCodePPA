//SystemVerilog
module mux_8to1_indexed (
    input wire        clk,             // Clock for pipelining
    input wire        rst_n,           // Active-low synchronous reset
    input wire [7:0]  inputs,          // 8 data inputs
    input wire [2:0]  selector,        // 3-bit selector
    output wire       out              // Output
);

// -----------------------------------------------------------------------------
// Stage 1: Combinational One-Hot Selector and Masked Input Generation
// -----------------------------------------------------------------------------
wire [7:0] select_onehot_comb;
wire [7:0] masked_inputs_comb;

assign select_onehot_comb = 8'b00000001 << selector;
assign masked_inputs_comb = inputs & select_onehot_comb;

// -----------------------------------------------------------------------------
// Stage 2: Register Masked Inputs
// -----------------------------------------------------------------------------
reg [7:0] masked_inputs_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        masked_inputs_stage2 <= 8'b0;
    end else begin
        masked_inputs_stage2 <= masked_inputs_comb;
    end
end

// -----------------------------------------------------------------------------
// Stage 3: Register Priority Encoder Output
// -----------------------------------------------------------------------------
reg out_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_stage3 <= 1'b0;
    end else begin
        out_stage3 <= |masked_inputs_stage2;
    end
end

assign out = out_stage3;

endmodule