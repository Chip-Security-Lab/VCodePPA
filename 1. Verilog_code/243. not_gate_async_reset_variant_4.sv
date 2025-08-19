//SystemVerilog
module not_gate_pipelined (
    input wire A,
    input wire clk,
    input wire reset,
    input wire valid_in,
    output wire Y,
    output wire valid_out
);

// Stage 1: Input buffering and valid signal propagation
reg A_stage1_reg;
reg valid_stage1_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        A_stage1_reg <= 1'b0;
        valid_stage1_reg <= 1'b0;
    end else begin
        A_stage1_reg <= A;
        valid_stage1_reg <= valid_in;
    end
end

// Stage 2: NOT operation and valid signal propagation
reg Y_stage2_reg;
reg valid_stage2_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        Y_stage2_reg <= 1'b0;
        valid_stage2_reg <= 1'b0;
    end else begin
        // Direct assignment for NOT operation, ensuring minimal logic depth
        Y_stage2_reg <= ~A_stage1_reg;
        valid_stage2_reg <= valid_stage1_reg;
    end
end

// Output
assign Y = Y_stage2_reg;
assign valid_out = valid_stage2_reg;

endmodule