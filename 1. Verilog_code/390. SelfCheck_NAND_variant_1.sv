//SystemVerilog
module SelfCheck_NAND(
    input wire clk,       // Clock input for pipelining
    input wire rst_n,     // Reset signal
    input wire a,
    input wire b,
    output reg y,
    output reg parity
);
    // Clock buffer tree for reducing fanout
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Clock buffer instantiation
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // Internal pipeline registers
    reg a_reg, b_reg;
    reg nand_result;
    
    // Stage 1: Input registration - using buffered clock
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Stage 2: NAND operation - using buffered clock
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            nand_result <= 1'b1;
        end else begin
            nand_result <= ~(a_reg & b_reg);
        end
    end
    
    // Stage 3: Output generation and parity calculation - using buffered clock
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b1;
            parity <= 1'b0;
        end else begin
            y <= nand_result;
            parity <= ^nand_result;  // Calculate parity
        end
    end

endmodule