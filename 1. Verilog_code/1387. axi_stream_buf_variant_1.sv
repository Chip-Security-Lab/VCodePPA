//SystemVerilog
module axi_stream_buf #(parameter DW=64) (
    input clk, rst_n,
    input tvalid_in, tready_out,
    output tvalid_out, tready_in,
    input [DW-1:0] tdata_in,
    output [DW-1:0] tdata_out
);
    reg [DW-1:0] buf_data;
    reg buf_valid;
    reg [DW-1:0] input_data;
    reg input_valid;
    
    // 输入侧寄存器逻辑 - 使用case结构
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            input_data <= {DW{1'b0}};
            input_valid <= 1'b0;
        end
        else begin
            // 根据输入握手和缓冲状态的组合进行case分类
            case({tvalid_in && tready_in, ~buf_valid || tready_out})
                2'b10, 2'b11: begin // 输入有效且可接收
                    input_data <= tdata_in;
                    input_valid <= 1'b1;
                end
                2'b01: begin // 缓冲区已准备好但无新输入
                    input_valid <= 1'b0;
                end
                2'b00: begin // 保持当前状态
                    input_data <= input_data;
                    input_valid <= input_valid;
                end
            endcase
        end
    end
    
    // 输出缓冲逻辑 - 使用case结构
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            buf_valid <= 1'b0;
            buf_data <= {DW{1'b0}};
        end
        else begin
            // 根据输入有效性、缓冲状态和输出就绪进行case分类
            case({input_valid && (~buf_valid || tready_out), tready_out && buf_valid})
                2'b10, 2'b11: begin // 输入数据需要加载到缓冲区
                    buf_data <= input_data;
                    buf_valid <= 1'b1;
                end
                2'b01: begin // 输出读取完成，清空缓冲区
                    buf_valid <= 1'b0;
                end
                2'b00: begin // 保持当前状态
                    buf_data <= buf_data;
                    buf_valid <= buf_valid;
                end
            endcase
        end
    end
    
    // 信号分配 - 保持不变
    assign tready_in = ~input_valid || (~buf_valid || tready_out);
    assign tvalid_out = buf_valid;
    assign tdata_out = buf_data;
    
endmodule