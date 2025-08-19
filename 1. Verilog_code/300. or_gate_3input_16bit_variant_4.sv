//SystemVerilog
module or_gate_3input_16bit (
    input wire clk,          // Added clock for pipelining
    input wire rst_n,        // Added reset signal
    input wire [15:0] a,
    input wire [15:0] b, 
    input wire [15:0] c,
    output reg [15:0] y      // Changed to reg for registered output
);
    // Stage 1: Pipeline registers for inputs
    reg [15:0] a_reg, b_reg, c_reg;
    
    // Stage 2: Intermediate computation registers
    reg [15:0] ab_or_reg;
    
    // Input registration stage
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            a_reg <= 16'b0;
            b_reg <= 16'b0;
            c_reg <= 16'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
        end
    end
    
    // First computation stage - OR operation between a and b
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ab_or_reg <= 16'b0;
        end else begin
            ab_or_reg <= a_reg | b_reg;
        end
    end
    
    // Final computation stage - OR with c and output
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            y <= 16'b0;
        end else begin
            y <= ab_or_reg | c_reg;
        end
    end
endmodule