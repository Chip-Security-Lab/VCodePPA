//SystemVerilog
module pl_reg_sync #(parameter W=8, parameter STAGES=3) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire valid_in,
    input wire [W-1:0] data_in,
    output wire valid_out,
    output wire [W-1:0] data_out
);
    // 定义前向重定时后的流水线寄存器和控制信号
    reg [W-1:0] data_stage [0:STAGES-1];
    reg valid_stage [0:STAGES-1];
    
    // 第一级流水线 - 直接将输入传递给第一级寄存器
    wire [W-1:0] data_stage0_next;
    wire valid_stage0_next;
    
    // 应用前向重定时策略，直接使用组合逻辑处理输入数据
    assign data_stage0_next = data_in;
    assign valid_stage0_next = valid_in;
    
    // 第一级流水线寄存器
    always @(posedge clk) begin
        if (!rst_n || !en) begin
            data_stage[0] <= {W{1'b0}};
            valid_stage[0] <= 1'b0;
        end
        else begin
            data_stage[0] <= data_stage0_next;
            valid_stage[0] <= valid_stage0_next;
        end
    end
    
    // 生成中间流水线级 - 使用相同的重定时策略
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : pipeline_stages
            // 定义下一级的组合逻辑输入
            wire [W-1:0] data_stagei_next;
            wire valid_stagei_next;
            
            // 前向重定时 - 数据从前一级到当前级
            assign data_stagei_next = data_stage[i-1];
            assign valid_stagei_next = valid_stage[i-1];
            
            // 寄存器更新逻辑
            always @(posedge clk) begin
                if (!rst_n || !en) begin
                    data_stage[i] <= {W{1'b0}};
                    valid_stage[i] <= 1'b0;
                end
                else begin
                    data_stage[i] <= data_stagei_next;
                    valid_stage[i] <= valid_stagei_next;
                end
            end
        end
    endgenerate
    
    // 输出赋值
    assign data_out = data_stage[STAGES-1];
    assign valid_out = valid_stage[STAGES-1];
    
endmodule