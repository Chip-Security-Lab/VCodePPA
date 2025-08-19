//SystemVerilog
module var_duty_pwm_clk #(
    parameter PERIOD = 16
)(
    input clk_in,
    input rst,
    input [3:0] duty,  // 0-15 (0%-93.75%)
    output reg clk_out
);
    reg [$clog2(PERIOD)-1:0] counter;
    reg [$clog2(PERIOD)-1:0] counter_next;
    reg [3:0] duty_reg;
    reg compare_result;
    
    // LUT-based comparison signals
    reg [15:0] comparison_lut;
    reg lut_result;
    
    // Initialize LUT - will be synthesized as constants
    initial begin
        comparison_lut = 16'b0000000000000000;
    end
    
    // Pipeline stage 1: Calculate next counter value and register duty
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 0;
            duty_reg <= 0;
            counter_next <= 1; // Pre-calculate next value
        end else begin
            counter <= counter_next;
            duty_reg <= duty;
            counter_next <= (counter_next < PERIOD-1) ? counter_next + 1 : 0;
        end
    end
    
    // LUT-based comparison logic
    always @(*) begin
        case (duty_reg)
            4'b0000: comparison_lut = 16'b0000000000000000;
            4'b0001: comparison_lut = 16'b0000000000000001;
            4'b0010: comparison_lut = 16'b0000000000000011;
            4'b0011: comparison_lut = 16'b0000000000000111;
            4'b0100: comparison_lut = 16'b0000000000001111;
            4'b0101: comparison_lut = 16'b0000000000011111;
            4'b0110: comparison_lut = 16'b0000000000111111;
            4'b0111: comparison_lut = 16'b0000000001111111;
            4'b1000: comparison_lut = 16'b0000000011111111;
            4'b1001: comparison_lut = 16'b0000000111111111;
            4'b1010: comparison_lut = 16'b0000001111111111;
            4'b1011: comparison_lut = 16'b0000011111111111;
            4'b1100: comparison_lut = 16'b0000111111111111;
            4'b1101: comparison_lut = 16'b0001111111111111;
            4'b1110: comparison_lut = 16'b0011111111111111;
            4'b1111: comparison_lut = 16'b0111111111111111;
            default: comparison_lut = 16'b0000000000000000;
        endcase
        
        lut_result = comparison_lut[counter[$clog2(PERIOD)-1:0]];
    end
    
    // Pipeline stage 2: Use LUT result and generate output
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            compare_result <= 0;
            clk_out <= 0;
        end else begin
            compare_result <= lut_result;
            clk_out <= compare_result;
        end
    end
endmodule