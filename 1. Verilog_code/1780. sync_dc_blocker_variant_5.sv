//SystemVerilog
module sync_dc_blocker #(
    parameter WIDTH = 16
)(
    input clk, reset,
    input [WIDTH-1:0] signal_in,
    input valid_in,
    output reg valid_out,
    output reg [WIDTH-1:0] signal_out
);
    // 流水线寄存器声明
    reg [WIDTH-1:0] prev_in_stage1, prev_out_stage1;
    reg [WIDTH-1:0] sub_result_stage1;
    reg [WIDTH-1:0] mul_result_stage2;
    reg [WIDTH-1:0] add_result_stage3;
    reg [WIDTH-1:0] signal_in_stage1, signal_in_stage2, signal_in_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线：计算减法 signal_in - prev_in
    always @(posedge clk) begin
        if (reset) begin
            prev_in_stage1 <= 0;
            prev_out_stage1 <= 0;
            sub_result_stage1 <= 0;
            signal_in_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            if (valid_in) begin
                prev_in_stage1 <= signal_in;
                signal_in_stage1 <= signal_in;
                sub_result_stage1 <= signal_in - prev_in_stage1;
                prev_out_stage1 <= prev_out_stage1;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线：计算乘法 (prev_out * 7) >> 3
    always @(posedge clk) begin
        if (reset) begin
            mul_result_stage2 <= 0;
            signal_in_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            if (valid_stage1) begin
                mul_result_stage2 <= (prev_out_stage1 * 7) >> 3;
                signal_in_stage2 <= signal_in_stage1;
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 第三级流水线：计算加法 sub_result + mul_result
    always @(posedge clk) begin
        if (reset) begin
            add_result_stage3 <= 0;
            signal_in_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            if (valid_stage2) begin
                add_result_stage3 <= sub_result_stage1 + mul_result_stage2;
                signal_in_stage3 <= signal_in_stage2;
                valid_stage3 <= valid_stage2;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // 输出级：更新prev_out和signal_out
    always @(posedge clk) begin
        if (reset) begin
            prev_out_stage1 <= 0;
            signal_out <= 0;
            valid_out <= 0;
        end else begin
            if (valid_stage3) begin
                prev_out_stage1 <= add_result_stage3;
                signal_out <= add_result_stage3;
                valid_out <= valid_stage3;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule