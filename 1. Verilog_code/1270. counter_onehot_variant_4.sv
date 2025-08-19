//SystemVerilog
module counter_onehot #(parameter BITS=4) (
    input wire clk,
    input wire rst,
    input wire enable,
    output reg [BITS-1:0] state,
    output reg valid_out
);
    // 流水线寄存器
    reg [BITS-1:0] state_stage1;
    reg [BITS-1:0] state_stage2;
    reg valid_stage1, valid_stage2;
    
    // 第一级：状态更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            state_stage1 <= 1;
        end
        else if (enable) begin
            state_stage1 <= {state[BITS-2:0], state[BITS-1]};
        end
    end
    
    // 第一级：有效标志更新
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 0;
        end
        else if (enable) begin
            valid_stage1 <= 1;
        end
        else begin
            valid_stage1 <= 0;
        end
    end
    
    // 第二级：状态传递
    always @(posedge clk) begin
        if (rst) begin
            state_stage2 <= 0;
        end
        else begin
            state_stage2 <= state_stage1;
        end
    end
    
    // 第二级：有效标志传递
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 0;
        end
        else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级：最终状态输出
    always @(posedge clk) begin
        if (rst) begin
            state <= 1;
        end
        else begin
            state <= state_stage2;
        end
    end
    
    // 第三级：最终有效标志输出
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 0;
        end
        else begin
            valid_out <= valid_stage2;
        end
    end
    
endmodule