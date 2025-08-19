//SystemVerilog
// 顶层模块 - 流水线版本
module xor_cond_operator(
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream输入接口
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream输出接口
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);
    // 内部信号
    reg [7:0] a_reg_stage1, b_reg_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [7:0] xor_result_stage3;
    
    // 流水线握手信号
    wire stage1_ready;
    wire stage2_ready;
    wire stage3_ready;
    
    // 第三阶段准备接收新数据的条件
    assign stage3_ready = !valid_stage3 || m_axis_tready;
    
    // 第二阶段准备接收新数据的条件
    assign stage2_ready = !valid_stage2 || (valid_stage2 && stage3_ready);
    
    // 第一阶段准备接收新数据的条件
    assign stage1_ready = !valid_stage1 || (valid_stage1 && stage2_ready);
    
    // 输入接口握手信号
    assign s_axis_tready = stage1_ready;
    
    // 输出接口握手信号
    assign m_axis_tvalid = valid_stage3;
    assign m_axis_tdata = xor_result_stage3;
    
    // 第一级流水线 - 接收第一个输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            if (s_axis_tvalid && s_axis_tready) begin
                a_reg_stage1 <= s_axis_tdata;
                valid_stage1 <= 1'b1;
            end
            else if (valid_stage1 && stage2_ready) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线 - 接收第二个输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_reg_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            if (valid_stage1 && stage2_ready) begin
                b_reg_stage2 <= s_axis_tdata;
                valid_stage2 <= valid_stage1 && s_axis_tvalid;
            end
            else if (valid_stage2 && stage3_ready) begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // XOR运算的中间结果
    wire [3:0] lower_nibble_result;
    wire [3:0] upper_nibble_result;
    
    // 实例化4位XOR子模块处理低4位
    xor_nibble lower_xor(
        .a_in(a_reg_stage1[3:0]),
        .b_in(b_reg_stage2[3:0]),
        .y_out(lower_nibble_result)
    );
    
    // 实例化4位XOR子模块处理高4位
    xor_nibble upper_xor(
        .a_in(a_reg_stage1[7:4]),
        .b_in(b_reg_stage2[7:4]),
        .y_out(upper_nibble_result)
    );
    
    // 第三级流水线 - 存储计算结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            if (valid_stage2 && stage3_ready) begin
                xor_result_stage3 <= {upper_nibble_result, lower_nibble_result};
                valid_stage3 <= 1'b1;
            end
            else if (valid_stage3 && m_axis_tready) begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
endmodule

// 4位XOR子模块
module xor_nibble(
    input [3:0] a_in,
    input [3:0] b_in,
    output [3:0] y_out
);
    // 使用位宽参数化的XOR位模块处理每一位
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : xor_bit_gen
            xor_bit single_bit_xor(
                .a_bit(a_in[i]),
                .b_bit(b_in[i]),
                .y_bit(y_out[i])
            );
        end
    endgenerate
endmodule

// 单比特XOR基本模块
module xor_bit(
    input a_bit,
    input b_bit,
    output y_bit
);
    // 实现单个位的XOR操作
    assign y_bit = a_bit ^ b_bit;
endmodule