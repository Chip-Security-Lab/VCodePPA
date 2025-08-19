//SystemVerilog
module recursive_shifter #(parameter N=16) (
    input logic [N-1:0] data,
    input logic [$clog2(N)-1:0] shift,
    input logic clk,     // 添加时钟信号以支持流水线
    input logic rst_n,   // 添加复位信号
    output logic [N-1:0] result
);
    localparam LOG2_N = $clog2(N);
    
    // 分段实现的数据通路 - 采用流水线结构
    logic [N-1:0] pipeline_data [0:LOG2_N];
    logic [$clog2(N)-1:0] pipeline_shift [0:LOG2_N-1];
    
    // 流水线第一级 - 输入寄存器
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_data[0] <= '0;
            pipeline_shift[0] <= '0;
        end else begin
            pipeline_data[0] <= data;
            pipeline_shift[0] <= shift;
        end
    end
    
    // 生成流水线阶段
    genvar k;
    generate
        for (k = 0; k < LOG2_N; k = k + 1) begin: shift_stages
            // 每个阶段的移位逻辑
            logic [N-1:0] shifted_data;
            
            // 移位操作 - 根据不同级别执行不同的移位
            always_comb begin
                if (pipeline_shift[k][0]) begin
                    case (k)
                        0: shifted_data = {pipeline_data[k][N-2:0], pipeline_data[k][N-1]};
                        1: shifted_data = {pipeline_data[k][N-3:0], pipeline_data[k][N-1:N-2]};
                        2: shifted_data = {pipeline_data[k][N-5:0], pipeline_data[k][N-1:N-4]};
                        3: shifted_data = {pipeline_data[k][N-9:0], pipeline_data[k][N-1:N-8]};
                        default: shifted_data = {pipeline_data[k][N-(1<<k)-1:0], pipeline_data[k][N-1:N-(1<<k)]};
                    endcase
                end else begin
                    shifted_data = pipeline_data[k];
                end
            end
            
            // 流水线寄存器
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipeline_data[k+1] <= '0;
                    if (k < LOG2_N-1) begin
                        pipeline_shift[k+1] <= '0;
                    end
                end else begin
                    pipeline_data[k+1] <= shifted_data;
                    if (k < LOG2_N-1) begin
                        pipeline_shift[k+1] <= pipeline_shift[k] >> 1; // 右移移位控制信号
                    end
                end
            end
        end
    endgenerate
    
    // 最终输出结果
    assign result = pipeline_data[LOG2_N];
    
    // 增加参数配置接口，可调整流水线深度（如果需要）
    // 这部分只是注释，实际上通过改变顶层模块参数来配置
    
    // 性能评估:
    // - 延迟: LOG2_N + 1 个时钟周期
    // - 吞吐量: 每周期1个结果
    // - 关键路径: 每阶段只有一个移位操作，复杂度降低
    
endmodule