//SystemVerilog
module Hier_NAND (
    input wire clk,           // Added clock for pipeline registers
    input wire rst_n,         // Added reset signal for proper initialization
    input wire [1:0] a, b,    // Input ports
    output wire [3:0] y       // Output port
);
    // Internal pipeline registers
    reg [1:0] a_reg, b_reg;   // Stage 1 input registers
    reg [1:0] nand_result;    // Stage 2 result register
    reg [3:0] y_reg;          // Output register

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 2'b00;
            b_reg <= 2'b00;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Stage 2: NAND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result <= 2'b00;
        end else begin
            nand_result <= ~(a_reg & b_reg);
        end
    end

    // Stage 3: Output formation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_reg <= 4'b0000;
        end else begin
            y_reg <= {2'b11, nand_result};
        end
    end

    // Connect register to output
    assign y = y_reg;

endmodule