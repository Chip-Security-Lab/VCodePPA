//SystemVerilog
//IEEE 1364-2005 Verilog
module and_gate_3_delay (
    input  wire clk,       // System clock
    input  wire rst_n,     // Active low reset
    input  wire a,         // Input A
    input  wire b,         // Input B
    input  wire c,         // Input C
    output reg  y          // Output Y
);
    // Forward-retiming: Move registers after combinational logic
    // Compute partial results first (no input registers)
    wire a_and_b;
    wire ab_and_c;
    
    // Combinational logic before registers
    assign a_and_b = a & b;
    
    // Fanout optimization: Buffer the high fanout signal a_and_b 
    reg a_and_b_buf1, a_and_b_buf2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_and_b_buf1 <= 1'b0;
            a_and_b_buf2 <= 1'b0;
        end else begin
            a_and_b_buf1 <= a_and_b;
            a_and_b_buf2 <= a_and_b;
        end
    end
    
    // Use buffered signal for the final AND operation
    assign ab_and_c = a_and_b_buf1 & c;
    
    // Pipeline stage 1: Register partial result (A & B)
    reg a_and_b_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_and_b_reg <= 1'b0;
        end else begin
            a_and_b_reg <= a_and_b_buf2;
        end
    end
    
    // Pipeline stage 2: Register final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= ab_and_c;
        end
    end
    
endmodule