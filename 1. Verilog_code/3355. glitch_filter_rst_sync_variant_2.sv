//SystemVerilog
module glitch_filter_rst_sync (
    input  wire clk,
    input  wire async_rst_n,
    output wire filtered_rst_n
);
    // 第一级流水线寄存器
    reg [1:0] shift_reg_stage1;
    reg       valid_stage1;
    
    // 第二级流水线寄存器
    reg [3:0] shift_reg_stage2;
    reg       valid_stage2;
    
    // 第三级流水线寄存器 - 输出阶段
    reg       filtered_stage3;
    reg       valid_stage3;
    
    // 第一级流水线 - 采样异步复位信号
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end
        else begin
            shift_reg_stage1 <= {shift_reg_stage1[0], 1'b1};
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线 - 拓展移位寄存器
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            shift_reg_stage2 <= {shift_reg_stage2[1:0], shift_reg_stage1};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 决策逻辑
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            filtered_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else if (valid_stage2) begin
            case (shift_reg_stage2)
                4'b1111: filtered_stage3 <= 1'b1;
                4'b0000: filtered_stage3 <= 1'b0;
                default: filtered_stage3 <= filtered_stage3;
            endcase
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign filtered_rst_n = filtered_stage3;
endmodule