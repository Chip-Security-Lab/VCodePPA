//SystemVerilog
module conditional_buffer (
    input wire clk,
    input wire rst_n,           // 添加复位信号以符合标准设计实践
    input wire [7:0] data_in,
    input wire [7:0] threshold,
    input wire valid_in,        // 替代compare_en，表示输入数据有效
    output wire ready_out,      // 添加ready信号，表示模块准备好接收数据
    output reg [7:0] data_out,
    output reg valid_out        // 表示输出数据有效
);

    // 内部状态定义
    reg busy;
    
    // 指示模块是否准备好接收新数据
    assign ready_out = !busy;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            valid_out <= 1'b0;
            busy <= 1'b0;
        end else begin
            // 当输入有效且模块准备好接收数据时处理数据
            if (valid_in && ready_out) begin
                if (data_in > threshold) begin
                    data_out <= data_in;
                    valid_out <= 1'b1;
                    busy <= 1'b1;
                end
            end
            
            // 当下游接收数据后清除有效标志
            if (valid_out) begin
                valid_out <= 1'b0;
                busy <= 1'b0;
            end
        end
    end
endmodule