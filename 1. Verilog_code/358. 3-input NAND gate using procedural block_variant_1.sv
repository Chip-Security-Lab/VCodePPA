//SystemVerilog
module nand3_3 (
    input  wire clk,     // Clock for pipelined implementation
    input  wire rst_n,   // Reset signal for proper initialization
    input  wire A,
    input  wire B, 
    input  wire C, 
    output wire Y
);
    // Pipeline stage signals
    reg stage1_a_n;       // First pipeline stage for A
    reg stage1_b_n;       // First pipeline stage for B
    reg stage2_c_n;       // Second pipeline stage for C
    reg stage3_result;    // Final pipeline stage for result
    
    // First pipeline stage for input A
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a_n <= 1'b1;
        end else begin
            stage1_a_n <= ~A;
        end
    end
    
    // First pipeline stage for input B
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_b_n <= 1'b1;
        end else begin
            stage1_b_n <= ~B;
        end
    end
    
    // Second pipeline stage for input C
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_c_n <= 1'b1;
        end else begin
            stage2_c_n <= ~C;
        end
    end
    
    // Combinational logic for intermediate signals
    wire nand_intermediate;
    assign nand_intermediate = stage1_a_n | stage1_b_n | stage2_c_n;
    
    // Final pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_result <= 1'b1;
        end else begin
            stage3_result <= nand_intermediate;
        end
    end
    
    // Output assignment
    assign Y = stage3_result;
    
endmodule