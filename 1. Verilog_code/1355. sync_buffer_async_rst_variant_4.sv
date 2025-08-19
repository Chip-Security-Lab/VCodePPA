//SystemVerilog
module sync_buffer_async_rst (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire valid_in,
    output wire ready_out,
    output reg [7:0] data_out,
    output reg valid_out,
    input wire ready_in
);
    // 接口状态记录
    reg busy;
    
    // 扇出缓冲寄存器 - 为busy信号添加扇出缓冲
    reg busy_buf1, busy_buf2;
    
    // 生成ready信号
    assign ready_out = !busy_buf1;
    
    // 缓冲寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_buf1 <= 1'b0;
            busy_buf2 <= 1'b0;
        end else begin
            busy_buf1 <= busy;
            busy_buf2 <= busy;
        end
    end
    
    // 数据传输和握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            valid_out <= 1'b0;
            busy <= 1'b0;
        end else if (valid_in && !busy_buf2) begin
            // 数据传输逻辑
            data_out <= data_in;
            valid_out <= 1'b1;
            busy <= 1'b1;
        end else if (valid_out && ready_in) begin
            // 完成传输后的握手处理
            valid_out <= 1'b0;
            busy <= 1'b0;
        end
    end
endmodule