//SystemVerilog
module wave7_ramp_up #(
    parameter WIDTH = 8,
    parameter STEP  = 2,
    parameter PIPELINE_STAGES = 3  // 添加流水线级数参数
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             data_valid_in,  // 输入有效信号
    output wire             data_ready_in,  // 输入就绪信号
    output wire [WIDTH-1:0] wave_out,
    output wire             data_valid_out  // 输出有效信号
);
    // 流水线寄存器
    reg [WIDTH-1:0] wave_stage1, wave_stage2, wave_stage3;
    reg             valid_stage1, valid_stage2, valid_stage3;
    
    // 计算中间值 - 分散计算负载
    wire [WIDTH-1:0] wave_step1 = wave_stage3 + (STEP/3);
    wire [WIDTH-1:0] wave_step2 = wave_stage1 + (STEP/3);
    wire [WIDTH-1:0] wave_step3 = wave_stage2 + (STEP - 2*(STEP/3));
    
    // 流水线控制逻辑 - 永远准备接收数据
    assign data_ready_in = 1'b1;
    
    // 流水线第一级
    always @(posedge clk) begin
        if (rst) begin
            wave_stage1 <= 0;
            valid_stage1 <= 1'b0;
        end
        else begin
            if (data_ready_in) begin
                wave_stage1 <= wave_step1;
                valid_stage1 <= data_valid_in;
            end
        end
    end
    
    // 流水线第二级
    always @(posedge clk) begin
        if (rst) begin
            wave_stage2 <= 0;
            valid_stage2 <= 1'b0;
        end
        else begin
            wave_stage2 <= wave_step2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线第三级
    always @(posedge clk) begin
        if (rst) begin
            wave_stage3 <= 0;
            valid_stage3 <= 1'b0;
        end
        else begin
            wave_stage3 <= wave_step3;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign wave_out = wave_stage3;
    assign data_valid_out = valid_stage3;
    
endmodule