//SystemVerilog
module RegBypassBridge #(
    parameter WIDTH = 32,
    parameter PIPELINE_STAGES = 3  // 流水线级数
)(
    input clk, rst_n,
    input [WIDTH-1:0] reg_in,
    output reg [WIDTH-1:0] reg_out,
    input bypass_en,
    input valid_in,           // 输入数据有效信号
    output reg valid_out,     // 输出数据有效信号
    input ready_in,           // 下游模块就绪信号
    output reg ready_out      // 上游模块就绪信号
);
    // 流水线寄存器
    reg [WIDTH-1:0] data_stage1, data_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg bypass_stage1, bypass_stage2;
    
    // 流水线就绪信号传播
    wire ready_stage2, ready_stage3;
    assign ready_stage3 = ready_in;
    assign ready_stage2 = !valid_stage2 || ready_stage3;
    assign ready_out = !valid_stage1 || ready_stage2;
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            bypass_stage1 <= 1'b0;
        end else if (ready_out) begin
            data_stage1 <= reg_in;
            valid_stage1 <= valid_in;
            bypass_stage1 <= bypass_en;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            bypass_stage2 <= 1'b0;
        end else if (ready_stage2) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            bypass_stage2 <= bypass_stage1;
        end
    end
    
    // 最终输出级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (ready_stage3) begin
            if (bypass_stage2)
                reg_out <= data_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule