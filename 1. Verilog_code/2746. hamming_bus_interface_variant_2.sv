//SystemVerilog
module hamming_bus_interface(
    input clk, rst, cs, we,
    input [3:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata,
    output reg ready
);
    // 编码数据寄存器
    reg [6:0] encoded;
    reg [3:0] status;
    
    // 流水线寄存器，用于切分关键路径
    reg [3:0] wdata_pipeline;
    reg [3:0] parity_temp;
    reg we_pipeline, cs_pipeline;
    reg [3:0] addr_pipeline;
    
    // 第一级流水线 - 捕获输入
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_pipeline <= 4'b0;
            we_pipeline <= 1'b0;
            cs_pipeline <= 1'b0;
            addr_pipeline <= 4'b0;
        end else begin
            wdata_pipeline <= wdata[3:0]; // 只捕获需要的数据位
            we_pipeline <= we;
            cs_pipeline <= cs;
            addr_pipeline <= addr;
        end
    end
    
    // 第二级流水线 - 计算奇偶校验位
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            parity_temp <= 4'b0;
        end else if (cs_pipeline && we_pipeline && addr_pipeline == 4'h0) begin
            // 预计算奇偶校验
            parity_temp[0] <= wdata_pipeline[0] ^ wdata_pipeline[1] ^ wdata_pipeline[3]; // 位0的奇偶
            parity_temp[1] <= wdata_pipeline[0] ^ wdata_pipeline[2] ^ wdata_pipeline[3]; // 位1的奇偶
            parity_temp[2] <= wdata_pipeline[1] ^ wdata_pipeline[2] ^ wdata_pipeline[3]; // 位3的奇偶
            parity_temp[3] <= 1'b1; // 标记完成
        end
    end
    
    // 主逻辑 - 最终输出阶段
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            status <= 4'b0;
            rdata <= 8'b0;
            ready <= 1'b0;
        end else begin
            if (cs_pipeline) begin
                ready <= 1'b1;
                if (we_pipeline) begin
                    case (addr_pipeline)
                        4'h0: begin // 输入数据
                            // 使用流水线化的奇偶校验位
                            encoded[0] <= parity_temp[0];
                            encoded[1] <= parity_temp[1];
                            encoded[2] <= wdata_pipeline[0];
                            encoded[3] <= parity_temp[2];
                            encoded[4] <= wdata_pipeline[1];
                            encoded[5] <= wdata_pipeline[2];
                            encoded[6] <= wdata_pipeline[3];
                            status[0] <= parity_temp[3]; // 编码完成
                        end
                        4'h4: status <= wdata_pipeline[3:0]; // 控制寄存器
                    endcase
                end else begin
                    case (addr_pipeline)
                        4'h0: rdata <= {1'b0, encoded}; // 读取编码数据
                        4'h4: rdata <= {4'b0, status};  // 读取状态
                    endcase
                end
            end else if (!cs) begin
                ready <= 1'b0;
            end
        end
    end
endmodule