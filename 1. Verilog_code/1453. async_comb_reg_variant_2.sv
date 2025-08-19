//SystemVerilog
// 顶层模块
module async_comb_reg (
    input wire        clk,           // 时钟信号
    input wire        rst_n,         // 复位信号
    input wire [7:0]  parallel_data, // 输入数据
    input wire        load_signal,   // 加载控制信号
    output wire [7:0] reg_output     // 寄存器输出
);
    // 内部连接信号
    wire [7:0] data_stage1;
    wire       load_stage1;
    wire [7:0] data_stage2;
    
    // 第一级流水线模块实例化
    pipeline_stage1 u_stage1 (
        .clk          (clk),
        .rst_n        (rst_n),
        .parallel_data(parallel_data),
        .load_signal  (load_signal),
        .data_stage1  (data_stage1),
        .load_stage1  (load_stage1)
    );
    
    // 第二级流水线模块实例化
    pipeline_stage2 u_stage2 (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_stage1  (data_stage1),
        .load_stage1  (load_stage1),
        .data_stage2  (data_stage2)
    );
    
    // 输出寄存器模块实例化
    output_register u_output_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_stage2  (data_stage2),
        .reg_output   (reg_output)
    );
    
endmodule

// 第一级流水线模块
module pipeline_stage1 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  parallel_data,
    input  wire        load_signal,
    output reg  [7:0]  data_stage1,
    output reg         load_stage1
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            data_stage1 <= 8'h00;
            load_stage1 <= 1'b0;
        end
        else begin
            // 第一级流水线寄存器更新
            data_stage1 <= parallel_data;
            load_stage1 <= load_signal;
        end
    end
    
endmodule

// 第二级流水线模块
module pipeline_stage2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_stage1,
    input  wire        load_stage1,
    output reg  [7:0]  data_stage2
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            data_stage2 <= 8'h00;
        end
        else begin
            // 第二级流水线寄存器更新 - 基于加载信号的条件更新
            data_stage2 <= load_stage1 ? data_stage1 : data_stage2;
        end
    end
    
endmodule

// 输出寄存器模块
module output_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_stage2,
    output reg  [7:0]  reg_output
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            reg_output <= 8'h00;
        end
        else begin
            // 输出寄存器更新
            reg_output <= data_stage2;
        end
    end
    
endmodule