//SystemVerilog
module shadow_reg_pipeline #(parameter WIDTH=4) (
    input clk, reset, enable,
    input [WIDTH-1:0] input_data,
    output reg [WIDTH-1:0] output_data
);
    // 流水线寄存器
    reg [WIDTH-1:0] shadow_store_stage1;
    reg [WIDTH-1:0] shadow_store_stage2;
    reg [WIDTH-1:0] shadow_store_stage3;

    // 流水线控制信号
    reg enable_stage1, enable_stage2, enable_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 复位所有寄存器和控制信号
            shadow_store_stage1 <= 0;
            shadow_store_stage2 <= 0;
            shadow_store_stage3 <= 0;
            enable_stage1 <= 0;
            enable_stage2 <= 0;
            enable_stage3 <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_stage3 <= 0;
            output_data <= 0;
        end else begin
            // Stage 1: 捕获输入数据和控制信号
            if (enable) begin
                shadow_store_stage1 <= input_data;
                valid_stage1 <= 1;
            end else begin
                valid_stage1 <= 0;
            end
            enable_stage1 <= enable;

            // Stage 2: 中间流水线级
            shadow_store_stage2 <= shadow_store_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;

            // Stage 3: 最终流水线级
            shadow_store_stage3 <= shadow_store_stage2;
            enable_stage3 <= enable_stage2;
            valid_stage3 <= valid_stage2;

            // 输出阶段
            if (valid_stage3) begin
                output_data <= shadow_store_stage3;
            end
        end
    end
endmodule