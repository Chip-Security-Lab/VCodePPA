//SystemVerilog
module barrel_shifter_sync_cl (
    input clk, rst_n, en,
    input [7:0] data_in,
    input [2:0] shift_amount,
    output reg [7:0] data_out
);
    // 内部信号定义
    reg [7:0] shift_left;
    reg [7:0] shift_right;
    reg [7:0] combined_result;
    
    // 计算左移结果
    always @(*) begin
        shift_left = data_in << shift_amount;
    end
    
    // 计算右移结果
    always @(*) begin
        shift_right = data_in >> (8 - shift_amount);
    end
    
    // 合并左移和右移结果
    always @(*) begin
        combined_result = shift_left | shift_right;
    end
    
    // 时序输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end
        else if (en) begin
            data_out <= combined_result;
        end
    end
endmodule