//SystemVerilog
// 4-bit AND gate with enable signal - Pipelined implementation with explicit multiplexer
module and_gate_4_enable (
    input wire clk,          // Clock signal
    input wire rst_n,        // Active-low reset
    input wire [3:0] a,      // 4-bit input A
    input wire [3:0] b,      // 4-bit input B
    input wire enable,       // Enable signal
    output reg [3:0] y       // 4-bit output Y
);
    // Pipeline stage 1 - Input registration
    reg [3:0] a_reg, b_reg;
    reg enable_reg;
    
    // Pipeline stage 2 - AND operation
    reg [3:0] and_result;
    wire [3:0] and_output;
    wire [3:0] zero_output;
    
    // Explicit multiplexer inputs
    assign and_output = a_reg & b_reg;
    assign zero_output = 4'b0000;
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0000;
            b_reg <= 4'b0000;
            enable_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            enable_reg <= enable;
        end
    end
    
    // Stage 2: Perform AND operation with enable using explicit multiplexer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 4'b0000;
        end else begin
            case (enable_reg)
                1'b1: and_result <= and_output;
                1'b0: and_result <= zero_output;
                default: and_result <= zero_output;
            endcase
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 4'b0000;
        end else begin
            y <= and_result;
        end
    end
endmodule