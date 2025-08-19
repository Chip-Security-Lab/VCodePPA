//SystemVerilog
//IEEE 1364-2005 Verilog
module Conditional_AND(
    input sel,
    input [7:0] op_a, op_b,
    output reg [7:0] res
);
    reg [7:0] shift_reg;
    reg [7:0] acc_reg;
    reg [3:0] bit_count;
    reg [7:0] and_result;
    
    always @(*) begin
        // Initialize accumulators and counters
        shift_reg = op_b;
        acc_reg = 8'h00;
        bit_count = 4'h0;
        
        // Implement AND operation using shift-and-add
        for (bit_count = 0; bit_count < 8; bit_count = bit_count + 1) begin
            if (op_a[bit_count]) begin
                acc_reg = acc_reg | (shift_reg & {8{1'b1}});
            end
            shift_reg = shift_reg << 1;
        end
        
        and_result = acc_reg;
        
        // Apply selection condition
        res = sel ? and_result : 8'hFF;
    end
endmodule