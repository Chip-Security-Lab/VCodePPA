//SystemVerilog
module counter_bcd (
    input wire clk,
    input wire rst,
    input wire en,
    output reg [3:0] bcd,
    output reg carry
);
    // 组合逻辑部分
    wire is_max_count;
    
    // 组合逻辑：判断是否达到最大计数
    assign is_max_count = (bcd == 4'd9);
    
    // 寄存器更新逻辑 - 后向寄存器重定时
    always @(posedge clk) begin
        if (rst) begin
            bcd <= 4'd0;
            carry <= 1'b0;
        end else if (en) begin
            // 使用if-else结构替代条件运算符
            if (is_max_count) begin
                bcd <= 4'd0;
                carry <= 1'b1;
            end else begin
                bcd <= bcd + 4'd1;
                carry <= 1'b0;
            end
        end else begin
            // 维持状态
            carry <= 1'b0;
        end
    end
    
endmodule