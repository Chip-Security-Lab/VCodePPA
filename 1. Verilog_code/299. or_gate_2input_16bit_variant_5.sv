//SystemVerilog
// 顶层模块
module or_gate_2input_16bit (
    input wire aclk,                  // 时钟信号
    input wire aresetn,               // 复位信号，低电平有效
    
    // 输入AXI-Stream接口
    input wire [15:0] s_axis_tdata,   // 输入数据
    input wire s_axis_tvalid,         // 输入数据有效
    input wire s_axis_tlast,          // 输入数据包末尾标志
    output wire s_axis_tready,        // 输入就绪信号
    
    // 输出AXI-Stream接口
    output wire [15:0] m_axis_tdata,  // 输出数据
    output wire m_axis_tvalid,        // 输出数据有效
    output wire m_axis_tlast,         // 输出数据包末尾标志
    input wire m_axis_tready          // 输出就绪信号
);
    // 内部寄存器
    reg [15:0] a_reg, b_reg;
    reg a_valid, b_valid;
    reg data_phase;
    reg tlast_reg;
    
    // 就绪信号生成
    assign s_axis_tready = ~data_phase | (data_phase & b_valid & m_axis_tready);
    
    // 输入数据握手逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            a_reg <= 16'h0;
            b_reg <= 16'h0;
            a_valid <= 1'b0;
            b_valid <= 1'b0;
            data_phase <= 1'b0;
            tlast_reg <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (~data_phase) begin
                    // 第一个数据周期，存储a输入
                    a_reg <= s_axis_tdata;
                    a_valid <= 1'b1;
                    data_phase <= 1'b1;
                    tlast_reg <= s_axis_tlast;
                end else begin
                    // 第二个数据周期，存储b输入
                    b_reg <= s_axis_tdata;
                    b_valid <= 1'b1;
                end
            end
            
            // 完成计算后重置状态
            if (m_axis_tvalid && m_axis_tready) begin
                a_valid <= 1'b0;
                b_valid <= 1'b0;
                data_phase <= 1'b0;
            end
        end
    end
    
    // 将16位操作分为两个8位子模块
    wire [7:0] lower_result, upper_result;
    
    // 实例化低8位子模块
    or_gate_8bit or_lower (
        .a_in(a_reg[7:0]),
        .b_in(b_reg[7:0]),
        .y_out(lower_result)
    );
    
    // 实例化高8位子模块
    or_gate_8bit or_upper (
        .a_in(a_reg[15:8]),
        .b_in(b_reg[15:8]),
        .y_out(upper_result)
    );
    
    // 组合结果
    wire [15:0] result = {upper_result, lower_result};
    
    // 输出控制
    assign m_axis_tdata = result;
    assign m_axis_tvalid = a_valid & b_valid;
    assign m_axis_tlast = tlast_reg;
    
endmodule

// 8位或门子模块
module or_gate_8bit (
    input wire [7:0] a_in,
    input wire [7:0] b_in,
    output wire [7:0] y_out
);
    // 将8位操作分为两个4位子模块
    wire [3:0] lower_result, upper_result;
    
    // 实例化低4位子模块
    or_gate_4bit or_lower (
        .a_in(a_in[3:0]),
        .b_in(b_in[3:0]),
        .y_out(lower_result)
    );
    
    // 实例化高4位子模块
    or_gate_4bit or_upper (
        .a_in(a_in[7:4]),
        .b_in(b_in[7:4]),
        .y_out(upper_result)
    );
    
    // 组合结果
    assign y_out = {upper_result, lower_result};
endmodule

// 4位或门子模块
module or_gate_4bit (
    input wire [3:0] a_in,
    input wire [3:0] b_in,
    output wire [3:0] y_out
);
    // 使用参数化实例化单比特或门
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : or_bit_gen
            or_gate_1bit or_inst (
                .a_in(a_in[i]),
                .b_in(b_in[i]),
                .y_out(y_out[i])
            );
        end
    endgenerate
endmodule

// 基本1位或门子模块
module or_gate_1bit (
    input wire a_in,
    input wire b_in,
    output wire y_out
);
    // 原子操作
    assign y_out = a_in | b_in;
endmodule