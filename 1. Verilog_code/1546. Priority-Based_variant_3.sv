//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module priority_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_high_pri,
    input wire high_pri_valid,
    input wire [WIDTH-1:0] data_low_pri,
    input wire low_pri_valid,
    output reg [WIDTH-1:0] shadow_out
);
    // Main data register
    reg [WIDTH-1:0] data_reg;
    
    // Internal signals for conditional inverting subtractor
    reg [WIDTH-1:0] a_operand, b_operand;
    reg subtract_mode;
    wire [WIDTH-1:0] result;
    wire cin;
    wire [WIDTH:0] sum_with_carry;
    wire [WIDTH-1:0] b_operand_inverted;
    
    // Priority encoding for input selection
    wire [1:0] pri_select;
    assign pri_select = {high_pri_valid, low_pri_valid};
    
    // Conditional inverting subtractor
    assign cin = subtract_mode;
    assign b_operand_inverted = subtract_mode ? ~b_operand : b_operand;
    assign sum_with_carry = a_operand + b_operand_inverted + cin;
    assign result = sum_with_carry[WIDTH-1:0];
    
    // Priority-based input selection with subtractor operation using case
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
            a_operand <= 0;
            b_operand <= 0;
            subtract_mode <= 0;
        end
        else begin
            case (pri_select)
                2'b10, 2'b11: begin // high_pri_valid is active (with priority)
                    a_operand <= data_high_pri;
                    b_operand <= {WIDTH{1'b0}}; // No subtraction for high priority
                    subtract_mode <= 0;
                    data_reg <= data_high_pri;
                end
                2'b01: begin // Only low_pri_valid is active
                    // Implement conditional subtraction for low priority
                    a_operand <= data_low_pri;
                    b_operand <= {WIDTH{1'b0}}; // Could be customized based on needs
                    subtract_mode <= 1; // Enable subtraction mode
                    data_reg <= result; // Use result from subtractor
                end
                default: begin // No valid inputs
                    // Maintain previous values
                    a_operand <= a_operand;
                    b_operand <= b_operand;
                    subtract_mode <= subtract_mode;
                    data_reg <= data_reg;
                end
            endcase
        end
    end
    
    // Shadow update on any valid data using case
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= 0;
        else begin
            case (|pri_select) // Check if any valid input
                1'b1: shadow_out <= data_reg;
                1'b0: shadow_out <= shadow_out;
            endcase
        end
    end
endmodule