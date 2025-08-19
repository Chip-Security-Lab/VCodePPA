//SystemVerilog
// 顶层模块 - 优化的算术右移实现
module arithmetic_shift_right #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_WIDTH = 5
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   data_valid_in,
    input  logic [DATA_WIDTH-1:0]  data_in,
    input  logic [SHIFT_WIDTH-1:0] shift,
    output logic                   data_valid_out,
    output logic [DATA_WIDTH-1:0]  data_out
);
    // 内部信号定义 - 流水线阶段
    logic [DATA_WIDTH-1:0]  stage1_data;
    logic [SHIFT_WIDTH-1:0] stage1_shift;
    logic                   stage1_valid;
    
    logic [DATA_WIDTH-1:0]  stage2_partial_result;
    logic                   stage2_valid;
    
    // 第一级流水线 - 输入寄存
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            stage1_data  <= '0;
            stage1_shift <= '0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_data  <= data_in;
            stage1_shift <= shift;
            stage1_valid <= data_valid_in;
        end
    end
    
    // 实例化优化的位移计算单元
    shift_computation #(
        .DATA_WIDTH(DATA_WIDTH),
        .SHIFT_WIDTH(SHIFT_WIDTH)
    ) shift_comp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_in(stage1_valid),
        .data_in(stage1_data),
        .shift_amount(stage1_shift),
        .data_valid_out(stage2_valid),
        .data_out(stage2_partial_result)
    );
    
    // 实例化输出处理单元
    output_processor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) out_proc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_in(stage2_valid),
        .shift_result(stage2_partial_result),
        .data_valid_out(data_valid_out),
        .data_out(data_out)
    );
    
endmodule

// 优化的位移计算单元
module shift_computation #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_WIDTH = 5
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   data_valid_in,
    input  logic [DATA_WIDTH-1:0]  data_in,
    input  logic [SHIFT_WIDTH-1:0] shift_amount,
    output logic                   data_valid_out,
    output logic [DATA_WIDTH-1:0]  data_out
);
    // 中间移位结果
    logic [DATA_WIDTH-1:0] shift_result;
    
    // 优化的移位逻辑 - 分割长路径
    // 实现分层移位策略，减少组合逻辑路径深度
    always_comb begin
        // 首先处理0位移的特殊情况
        if (shift_amount == '0) begin
            shift_result = data_in;
        end else begin
            // 符号位扩展
            logic sign_bit = data_in[DATA_WIDTH-1];
            logic [DATA_WIDTH-1:0] extended_sign = {DATA_WIDTH{sign_bit}};
            
            // 执行算术右移，使用分层策略
            shift_result = (data_in >> shift_amount) | 
                          (extended_sign & ~({{DATA_WIDTH{1'b1}} >> shift_amount}));
        end
    end
    
    // 寄存结果，分割组合逻辑路径
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_out <= '0;
            data_valid_out <= 1'b0;
        end else begin
            data_out <= shift_result;
            data_valid_out <= data_valid_in;
        end
    end
    
endmodule

// 优化的输出处理单元
module output_processor #(
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  data_valid_in,
    input  logic [DATA_WIDTH-1:0] shift_result,
    output logic                  data_valid_out,
    output logic [DATA_WIDTH-1:0] data_out
);
    // 可选的后处理逻辑
    logic [DATA_WIDTH-1:0] processed_result;
    
    // 简单传递数据，但保留未来扩展的可能性
    assign processed_result = shift_result;
    
    // 输出寄存器 - 切分数据路径并提供清晰的时序边界
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_out <= '0;
            data_valid_out <= 1'b0;
        end else begin
            data_out <= processed_result;
            data_valid_out <= data_valid_in;
        end
    end
    
endmodule