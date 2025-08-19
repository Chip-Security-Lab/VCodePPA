//SystemVerilog
//IEEE 1364-2005 Verilog
module cdc_buffer #(parameter DW=8) (
    input wire src_clk, dst_clk,
    input wire src_rst_n, dst_rst_n,  // 添加复位信号
    input wire src_valid,             // 源域有效信号
    output wire src_ready,            // 源域就绪信号
    input wire [DW-1:0] din,          // 输入数据
    output wire dst_valid,            // 目标域有效信号
    input wire dst_ready,             // 目标域就绪信号
    output wire [DW-1:0] dout         // 输出数据
);
    // 源域流水线寄存器和控制信号
    reg [DW-1:0] src_data_stage1;
    reg src_valid_stage1;
    reg src_handshake_complete;
    wire src_transfer;
    
    // 目标域流水线寄存器和控制信号
    reg [DW-1:0] meta_data_stage1, dst_data_stage1, dst_data_stage2;
    reg meta_valid_stage1, dst_valid_stage1, dst_valid_stage2;
    wire dst_transfer;
    
    // 握手信号生成
    assign src_transfer = src_valid && src_ready;
    assign dst_transfer = dst_valid && dst_ready;
    assign src_ready = !src_valid_stage1 || src_handshake_complete;
    assign dst_valid = dst_valid_stage2;
    assign dout = dst_data_stage2;
    
    // 源域流水线逻辑
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_data_stage1 <= {DW{1'b0}};
            src_valid_stage1 <= 1'b0;
            src_handshake_complete <= 1'b0;
        end else begin
            // 第一级流水线：捕获输入数据
            if (src_transfer) begin
                src_data_stage1 <= din;
                src_valid_stage1 <= 1'b1;
                src_handshake_complete <= 1'b0;
            end else if (meta_valid_stage1) begin
                // 当目标域确认接收数据后，清除源有效标志
                src_valid_stage1 <= 1'b0;
                src_handshake_complete <= 1'b1;
            end
        end
    end
    
    // CDC: 将源域信号同步到目标域
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            meta_data_stage1 <= {DW{1'b0}};
            meta_valid_stage1 <= 1'b0;
            dst_data_stage1 <= {DW{1'b0}};
            dst_valid_stage1 <= 1'b0;
        end else begin
            // 元稳态寄存器捕获源域信号
            meta_data_stage1 <= src_data_stage1;
            meta_valid_stage1 <= src_valid_stage1;
            
            // 第一级目标域流水线
            dst_data_stage1 <= meta_data_stage1;
            dst_valid_stage1 <= meta_valid_stage1;
        end
    end
    
    // 目标域输出流水线阶段
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_data_stage2 <= {DW{1'b0}};
            dst_valid_stage2 <= 1'b0;
        end else if (!dst_valid_stage2 || dst_ready) begin
            // 只有当输出级就绪或空闲时才更新
            dst_data_stage2 <= dst_data_stage1;
            dst_valid_stage2 <= dst_valid_stage1;
        end
    end
    
endmodule