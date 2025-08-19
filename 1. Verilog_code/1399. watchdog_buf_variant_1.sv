//SystemVerilog
module watchdog_buf #(parameter DW=8, TIMEOUT=1000) (
    input clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg error
);
    reg [DW-1:0] buf_reg;
    reg [15:0] counter;
    reg valid;
    
    // 寄存输入信号，减少输入到第一级寄存器的路径延迟
    reg wr_en_reg, rd_en_reg;
    reg [DW-1:0] din_reg;
    
    // 中间组合逻辑信号
    wire timeout_reached = (counter >= TIMEOUT-1);
    wire counter_inc = valid & ~timeout_reached;
    
    // 重定时：前向寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_en_reg <= 1'b0;
            rd_en_reg <= 1'b0;
            din_reg <= {DW{1'b0}};
        end
        else begin
            wr_en_reg <= wr_en;
            rd_en_reg <= rd_en;
            din_reg <= din;
        end
    end
    
    // 主状态控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid <= 1'b0;
            counter <= 16'd0;
            error <= 1'b0;
            buf_reg <= {DW{1'b0}};
            dout <= {DW{1'b0}};
        end
        else begin
            // 默认条件
            error <= error & valid & ~wr_en_reg & ~rd_en_reg;
            
            // 写入操作处理
            if(wr_en_reg) begin
                buf_reg <= din_reg;
                valid <= 1'b1;
                counter <= 16'd0;
                error <= 1'b0;
            end
            // 读取操作处理
            else if(rd_en_reg && valid) begin
                dout <= buf_reg;
                valid <= 1'b0;
                error <= 1'b0;
                counter <= 16'd0;
            end
            // 超时计数和检测处理
            else if(valid) begin
                // 分离counter增加和超时检查的逻辑
                counter <= counter_inc ? counter + 1'b1 : counter;
                
                // 超时检测
                if(timeout_reached) begin
                    error <= 1'b1;
                    valid <= 1'b0;
                end
            end
        end
    end
endmodule