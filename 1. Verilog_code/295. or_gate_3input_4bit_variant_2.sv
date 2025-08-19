//SystemVerilog
module or_gate_3input_4bit (
    input wire clk,             // Clock signal for pipeline registers
    input wire rst_n,           // Active-low reset
    input wire [3:0] a,         // First input operand
    input wire [3:0] b,         // Second input operand
    input wire [3:0] c,         // Third input operand
    output reg [3:0] y          // Output result
);
    // Pipeline stage registers
    reg [3:0] a_reg, b_reg, c_reg;
    reg [3:0] ab_or_result;
    
    // Reset logic for a_reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
        end else begin
            a_reg <= a;
        end
    end
    
    // Reset logic for b_reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_reg <= 4'b0;
        end else begin
            b_reg <= b;
        end
    end
    
    // Reset logic for c_reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_reg <= 4'b0;
        end else begin
            c_reg <= c;
        end
    end
    
    // Second pipeline stage: Compute partial result (a OR b)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_or_result <= 4'b0;
        end else begin
            ab_or_result <= a_reg | b_reg;
        end
    end
    
    // Third pipeline stage: Compute final result (ab_or_result OR c)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 4'b0;
        end else begin
            y <= ab_or_result | c_reg;
        end
    end
    
endmodule