//SystemVerilog
module and_gate_generate (
    input  wire clk,      // System clock
    input  wire rst_n,    // Active low reset
    input  wire a,        // Input A
    input  wire b,        // Input B
    output wire y         // Output Y
);
    // Pipeline stage signals
    reg a_reg, b_reg;     // Stage 1 registers
    reg and_result;       // Stage 2 register
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Stage 2: AND operation and result registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 1'b0;
        end else begin
            and_result <= a_reg & b_reg;
        end
    end
    
    // Output assignment
    assign y = and_result;
    
endmodule