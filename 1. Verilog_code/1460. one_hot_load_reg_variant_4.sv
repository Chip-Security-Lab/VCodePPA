//SystemVerilog
module one_hot_load_reg (
    input logic clk, rst_n,
    input logic [23:0] data_word,
    input logic [2:0] load_select,  // One-hot encoded
    input logic req_in,             // 替换valid_in为req_in（请求信号）
    output logic req_out,           // 替换valid_out为req_out（请求信号）
    output logic [23:0] data_out,
    output logic ack_in             // 替换ready为ack_in（应答信号）
);
    // 流水线阶段寄存器 
    logic [23:0] data_word_stage1, data_word_stage2;
    logic [2:0] load_select_stage1, load_select_stage2;
    logic req_stage1, req_stage2;
    logic ack_stage2;  // 内部应答信号
    
    // 第一级流水线：寄存数据和控制信号
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_word_stage1 <= 24'h0;
            load_select_stage1 <= 3'h0;
            req_stage1 <= 1'b0;
        end
        else if (ack_in) begin  // 当收到应答时，接收新数据
            data_word_stage1 <= data_word;
            load_select_stage1 <= load_select;
            req_stage1 <= req_in;
        end
    end
    
    // 第二级流水线：解码选择信号
    logic [2:0] byte_enable;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_word_stage2 <= 24'h0;
            load_select_stage2 <= 3'h0;
            req_stage2 <= 1'b0;
            byte_enable <= 3'h0;
        end
        else if (ack_stage2 || !req_stage2) begin  // 当下一级给出应答或当前级无请求时
            data_word_stage2 <= data_word_stage1;
            load_select_stage2 <= load_select_stage1;
            req_stage2 <= req_stage1;
            
            // 解码阶段 - 生成字节使能信号
            byte_enable <= load_select_stage1;
        end
    end
    
    // 第三级流水线：执行写入操作
    logic [23:0] data_out_reg;
    logic req_out_reg;
    logic ack_out;  // 输出应答信号
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= 24'h0;
            req_out_reg <= 1'b0;
            ack_stage2 <= 1'b0;
        end
        else begin
            // 请求传递
            if (req_stage2 && !req_out_reg) begin
                req_out_reg <= 1'b1;
                ack_stage2 <= 1'b1;  // 向上一级发出应答
                
                // 基于字节使能有选择地更新输出寄存器
                if (byte_enable[0])
                    data_out_reg[7:0] <= data_word_stage2[7:0];
                if (byte_enable[1])
                    data_out_reg[15:8] <= data_word_stage2[15:8];
                if (byte_enable[2])
                    data_out_reg[23:16] <= data_word_stage2[23:16];
            end
            else if (ack_out) begin  // 当收到输出应答时
                req_out_reg <= 1'b0;
                ack_stage2 <= 1'b0;
            end
            else begin
                ack_stage2 <= 1'b0;  // 应答信号仅持续一个周期
            end
        end
    end
    
    // Req-Ack握手逻辑
    assign ack_in = !req_stage1 || ack_stage2;  // 当第一级无请求或收到第二级应答时可接收新数据
    assign req_out = req_out_reg;
    assign ack_out = 1'b1;  // 简化实现：假设下游模块总是能接收数据
    
    // 输出赋值
    assign data_out = data_out_reg;
    
endmodule