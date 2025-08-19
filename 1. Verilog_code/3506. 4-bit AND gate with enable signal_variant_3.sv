//SystemVerilog
// 4-bit AND gate with enable signal and optimized pipelined structure
module and_gate_4_enable (
    input wire clk,          // Clock signal
    input wire rst_n,        // Active-low reset
    input wire [3:0] a,      // 4-bit input A
    input wire [3:0] b,      // 4-bit input B
    input wire enable,       // Enable signal
    output reg [3:0] y       // 4-bit output Y (registered)
);
    // Internal signals - combinational logic moved before registers
    wire [3:0] and_result_wire;
    wire [3:0] enable_result_wire;
    
    // Combinational logic moved before registers
    assign and_result_wire = a & b;
    assign enable_result_wire = enable ? and_result_wire : 4'b0000;
    
    // Pipeline stage 1: Register after combinational logic
    reg [3:0] stage1_result;
    
    // Pipeline stage 2: Second pipeline register
    reg [3:0] stage2_result;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_result <= 4'b0000;
        end else begin
            stage1_result <= enable_result_wire;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 4'b0000;
        end else begin
            stage2_result <= stage1_result;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 4'b0000;
        end else begin
            y <= stage2_result;
        end
    end
endmodule