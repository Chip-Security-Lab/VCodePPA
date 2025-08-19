//SystemVerilog
module counter_onehot #(parameter BITS=4) (
    input wire clk,
    input wire rst,
    input wire enable,  // 流水线启动控制信号
    output reg [BITS-1:0] state,
    output reg valid_out  // 输出有效信号
);

    // 流水线阶段寄存器
    reg [BITS-1:0] state_stage1;
    reg [BITS-1:0] state_stage2;
    
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;

    // 第一阶段：生成下一状态
    always @(posedge clk) begin
        if (rst) begin
            state_stage1 <= 1;
            valid_stage1 <= 0;
        end
        else begin
            if (enable) begin
                state_stage1 <= {state[BITS-2:0], state[BITS-1]};
                valid_stage1 <= 1;
            end
            else begin
                valid_stage1 <= 0;
            end
        end
    end

    // 第二阶段：中间处理
    always @(posedge clk) begin
        if (rst) begin
            state_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 输出阶段
    always @(posedge clk) begin
        if (rst) begin
            state <= 1;
            valid_out <= 0;
        end
        else begin
            state <= state_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule