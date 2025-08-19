//SystemVerilog
module loadable_div #(parameter W=8) (
    input clk, load, 
    input [W-1:0] div_val,
    output reg clk_out
);
    reg [W-1:0] cnt;
    reg cnt_is_zero;
    
    // Conditional inverse subtractor implementation
    reg sub_result_carry;
    reg [W-1:0] sub_result;
    
    always @(*) begin
        // Conditional inverse subtraction algorithm
        // For subtraction: cnt - 1
        // We invert the subtrahend (1) and add 1 to create 2's complement
        {sub_result_carry, sub_result} = {1'b0, cnt} + {1'b0, {W{1'b1}}} + 1'b1;
    end
    
    always @(posedge clk) begin
        if(load) begin
            cnt <= div_val;
            cnt_is_zero <= (div_val == 0);
        end else if(cnt_is_zero) begin
            cnt <= div_val;
            cnt_is_zero <= (div_val == 0);
        end else begin
            cnt <= sub_result;
            cnt_is_zero <= (cnt == 1);
        end
    end
    
    always @(posedge clk) begin
        if(load) begin
            clk_out <= 1'b1;
        end else begin
            clk_out <= ~cnt_is_zero;
        end
    end
endmodule