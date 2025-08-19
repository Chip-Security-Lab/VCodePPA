//SystemVerilog
module delay_ff #(
    parameter STAGES = 4,              // 流水线级数
    parameter ENABLE_RESET = 1,        // 可配置的复位功能
    parameter RESET_ACTIVE_LOW = 0,    // 复位极性配置（0=高电平有效，1=低电平有效）
    parameter USE_LUT = 1              // 启用查找表辅助实现
) (
    input wire clk,                    // 时钟输入
    input wire d,                      // 数据输入
    input wire rst,                    // 复位信号
    output wire q                      // 数据输出
);

    // 声明流水线寄存器
    reg [STAGES-1:0] pipeline_stages;
    
    // 查找表实现的初始状态
    reg [STAGES-1:0] lut_states [0:1];
    
    // 初始化查找表
    initial begin
        lut_states[0] = {STAGES{1'b0}}; // 复位状态
        lut_states[1] = {STAGES{1'b0}}; // 正常状态的初始值
    end
    
    // 主时序逻辑
    generate
        if (ENABLE_RESET) begin: reset_gen
            wire rst_signal = RESET_ACTIVE_LOW ? ~rst : rst;
            
            if (USE_LUT) begin: lut_impl
                reg [STAGES-1:0] next_state;
                
                // 查找表辅助实现
                always @(*) begin
                    next_state = {pipeline_stages[STAGES-2:0], d};
                end
                
                always @(posedge clk or posedge rst_signal) begin
                    if (rst_signal) begin
                        pipeline_stages <= lut_states[0]; // 使用查找表复位状态
                    end else begin
                        pipeline_stages <= next_state;
                    end
                end
            end else begin: standard_impl
                always @(posedge clk or posedge rst_signal) begin
                    if (rst_signal) begin
                        pipeline_stages <= {STAGES{1'b0}};
                    end else begin
                        pipeline_stages <= {pipeline_stages[STAGES-2:0], d};
                    end
                end
            end
        end else begin: no_reset_gen
            if (USE_LUT) begin: lut_impl
                reg [STAGES-1:0] next_state;
                
                // 查找表辅助实现
                always @(*) begin
                    next_state = {pipeline_stages[STAGES-2:0], d};
                end
                
                always @(posedge clk) begin
                    pipeline_stages <= next_state;
                end
            end else begin: standard_impl
                always @(posedge clk) begin
                    pipeline_stages <= {pipeline_stages[STAGES-2:0], d};
                end
            end
        end
    endgenerate
    
    // 数据输出赋值
    assign q = pipeline_stages[STAGES-1];

endmodule