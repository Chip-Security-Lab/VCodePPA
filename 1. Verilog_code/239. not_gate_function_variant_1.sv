//SystemVerilog
module not_gate_function_pipelined (
    input wire clk,
    input wire rst_n,
    input wire A_in,
    input wire valid_in,
    output wire Y_out,
    output wire valid_out
);

    // Internal signals for pipeline stages
    reg A_stage1_reg;
    reg valid_stage1_reg;

    wire Y_stage2_comb;
    reg Y_stage2_reg;
    reg valid_stage2_reg;

    // Stage 1: Input register
    // Registers the input and its validity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_stage1_reg <= 1'b0;
            valid_stage1_reg <= 1'b0;
        end else begin
            A_stage1_reg <= A_in;
            valid_stage1_reg <= valid_in;
        end
    end

    // Stage 2: Combinational logic (NOT operation)
    // Operates on the registered input from stage 1
    assign Y_stage2_comb = ~A_stage1_reg;

    // Stage 3: Output register
    // Registers the result from stage 2 and its validity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_stage2_reg <= 1'b0;
            valid_stage2_reg <= 1'b0;
        end else begin
            Y_stage2_reg <= Y_stage2_comb;
            valid_stage2_reg <= valid_stage1_reg; // Propagate validity
        end
    end

    // Assign the final registered output and validity
    assign Y_out = Y_stage2_reg;
    assign valid_out = valid_stage2_reg;

endmodule