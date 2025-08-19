//SystemVerilog
module counter_shift_load #(parameter WIDTH=8) (
    input clk, load, shift,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] cnt
);
    reg [WIDTH-1:0] next_value;
    wire [WIDTH-1:0] sub_result;
    
    // 使用二进制补码减法算法实现减法
    assign sub_result = cnt + {(WIDTH){1'b1}} + 1'b1; // cnt + ~1 + 1 = cnt - 1
    
    always @(*) begin
        if (load) begin
            next_value = data;
        end
        else if (shift) begin
            next_value = {cnt[WIDTH-2:0], cnt[WIDTH-1]}; // 循环移位逻辑
        end
        else begin
            next_value = sub_result; // 使用补码减法结果
        end
    end
    
    always @(posedge clk) begin
        cnt <= next_value;
    end
endmodule