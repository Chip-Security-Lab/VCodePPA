//SystemVerilog
// SystemVerilog
// Top module instantiating the OR gate submodule with a pipelined data path
module top_or_gate_pipelined (
    input wire clk,
    input wire reset,
    input wire in_a,
    input wire in_b,
    output wire out_y
);

    // Internal signals for pipelined data path
    reg  stage1_a_reg;
    reg  stage1_b_reg;
    wire stage1_or_result;

    reg  stage2_or_result_reg;

    // Stage 1: Register inputs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stage1_a_reg <= 1'b0;
            stage1_b_reg <= 1'b0;
        end else begin
            stage1_a_reg <= in_a;
            stage1_b_reg <= in_b;
        end
    end

    // Stage 1: Combinational OR operation
    assign stage1_or_result = stage1_a_reg | stage1_b_reg;

    // Stage 2: Register the OR result
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stage2_or_result_reg <= 1'b0;
        end else begin
            stage2_or_result_reg <= stage1_or_result;
        end
    end

    // Final output
    assign out_y = stage2_or_result_reg;

endmodule