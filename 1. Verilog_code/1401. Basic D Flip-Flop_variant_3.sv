//SystemVerilog
// Top module - D触发器流水线顶层模块
module d_flip_flop (
    input  wire clk,
    input  wire rst_n,        // 复位信号
    input  wire valid_in,     // 输入有效信号
    input  wire d,            // 数据输入
    output wire q,            // 数据输出
    output wire valid_out     // 输出有效信号
);
    // 流水线阶段信号
    wire data_stage1;         // 第一级流水线数据
    reg  valid_stage1;        // 第一级流水线有效信号
    
    reg  data_stage2;         // 第二级流水线数据
    reg  valid_stage2;        // 第二级流水线有效信号
    
    // 实例化流水线第一级输入处理单元
    dff_input_stage input_stage (
        .d_in(d),
        .d_out(data_stage1)
    );
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2  <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2  <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 实例化流水线第三级存储单元
    dff_storage_element storage_element (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage2),
        .data_in(data_stage2),
        .q_out(q),
        .valid_out(valid_out)
    );
    
endmodule

// 流水线第一级输入处理子模块
module dff_input_stage (
    input  wire d_in,
    output wire d_out
);
    // 输入处理逻辑
    assign d_out = d_in;
    
endmodule

// 流水线第三级存储单元子模块
module dff_storage_element (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input  wire data_in,
    output reg  q_out,
    output reg  valid_out
);
    // 输出寄存器和有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_out     <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            q_out     <= data_in;
            valid_out <= valid_in;
        end
    end
    
endmodule