//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module nand2_20 (
    input  wire clk,     // Clock input for pipeline stages
    input  wire rst_n,   // Active-low reset signal
    input  wire A, B,    // Primary input signals
    output wire Y        // Output signal
);
    // Internal pipeline stage signals
    reg stage1_A, stage1_B;   // First pipeline stage registers
    reg stage2_nand_result;   // Second pipeline stage register
    wire nand_combinational;  // Combinational NAND result

    // First pipeline stage - input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
        end
    end

    // Combinational NAND logic between pipeline stages
    assign nand_combinational = ~(stage1_A & stage1_B);

    // Second pipeline stage - result registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_nand_result <= 1'b1; // Default NAND output on reset
        end else begin
            stage2_nand_result <= nand_combinational;
        end
    end

    // Final output assignment
    assign Y = stage2_nand_result;

endmodule