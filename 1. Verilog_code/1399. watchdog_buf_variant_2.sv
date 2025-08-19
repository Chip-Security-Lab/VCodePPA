//SystemVerilog
module watchdog_buf #(parameter DW=8, TIMEOUT=1000) (
    input wire clk, rst_n,
    input wire wr_en, rd_en,
    input wire [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg error
);
    reg [DW-1:0] buf_reg;
    reg [15:0] counter;
    reg valid;
    
    // 合并所有时序逻辑到一个always块中
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            valid <= 1'b0;
            counter <= 16'h0;
            error <= 1'b0;
            buf_reg <= {DW{1'b0}};
            dout <= {DW{1'b0}};
        end
        else begin
            // 默认操作 - 保持当前状态
            
            // 优先级1: 写入操作
            if (wr_en) begin
                buf_reg <= din;
                valid <= 1'b1;
                counter <= 16'h0;
                error <= 1'b0;
            end
            // 优先级2: 读取操作
            else if (rd_en && valid) begin
                dout <= buf_reg;
                valid <= 1'b0;
                error <= 1'b0;
                counter <= 16'h0;
            end
            // 优先级3: 计数器更新和超时检测
            else if (valid) begin
                // 优化比较逻辑: 使用 < 替代多个条件检查
                if (counter < TIMEOUT - 1) begin
                    counter <= counter + 16'h1;
                end
                else begin
                    error <= 1'b1;
                    valid <= 1'b0;
                end
            end
        end
    end
endmodule