//SystemVerilog
module odd_div_clk #(
    parameter N = 5
)(
    input clk_in,
    input reset,
    output clk_div
);
    reg [2:0] posedge_counter;
    reg [2:0] negedge_counter;
    reg clk_p, clk_n;
    reg [2:0] div_value;
    
    // 使用移位减法除法器计算(N-1)/2
    function [2:0] shift_sub_divider;
        input [2:0] dividend;
        input [2:0] divisor;
        reg [2:0] quotient;
        reg [5:0] temp_dividend; // 扩展位宽以容纳移位操作
        reg [5:0] temp_divisor;
        integer i;
        begin
            quotient = 3'd0;
            temp_dividend = {3'd0, dividend};
            temp_divisor = {divisor, 3'd0};
            
            for (i = 0; i < 3; i = i + 1) begin
                temp_divisor = temp_divisor >> 1;
                if (temp_dividend >= temp_divisor) begin
                    temp_dividend = temp_dividend - temp_divisor;
                    quotient[0] = 1'b1;
                end
                quotient = quotient << 1;
            end
            
            quotient = quotient >> 1;
            shift_sub_divider = quotient;
        end
    endfunction
    
    // 初始化计算除法结果
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            div_value <= 3'd0;
        end else begin
            div_value <= shift_sub_divider(N-1, 2);
        end
    end
    
    // Posedge counter
    always @(posedge clk_in) begin
        if (reset) begin
            posedge_counter <= 3'd0;
            clk_p <= 1'b0;
        end else begin
            if (posedge_counter >= div_value) begin
                posedge_counter <= 3'd0;
                clk_p <= ~clk_p;
            end else begin
                posedge_counter <= posedge_counter + 1'b1;
            end
        end
    end
    
    // Negedge counter
    always @(negedge clk_in) begin
        if (reset) begin
            negedge_counter <= 3'd0;
            clk_n <= 1'b0;
        end else begin
            if (negedge_counter >= div_value) begin
                negedge_counter <= 3'd0;
                clk_n <= ~clk_n;
            end else begin
                negedge_counter <= negedge_counter + 1'b1;
            end
        end
    end
    
    assign clk_div = clk_p | clk_n;
endmodule