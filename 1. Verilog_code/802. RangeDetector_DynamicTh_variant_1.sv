//SystemVerilog
module RangeDetector_DynamicTh #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input wr_en,
    input [WIDTH-1:0] new_low,
    input [WIDTH-1:0] new_high,
    input [WIDTH-1:0] data_in,
    input data_valid,
    output wire out_valid,
    output wire out_flag
);
    // Threshold registers
    reg [WIDTH-1:0] current_low, current_high;
    
    // 前向寄存器重定时：将原来的Stage 1中的数据寄存直接移至组合逻辑后面
    wire [WIDTH-1:0] data_for_compare;
    wire valid_for_compare;
    
    // 组合逻辑比较结果
    wire low_comp_result;
    wire high_comp_result;
    
    // Stage 2 registers
    reg low_comp_result_stage2;
    reg high_comp_result_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg result_stage3;
    reg valid_stage3;
    
    // 直接将输入数据传递给组合逻辑
    assign data_for_compare = data_in;
    assign valid_for_compare = data_valid;
    
    // 组合逻辑比较
    assign low_comp_result = (data_for_compare >= current_low);
    assign high_comp_result = (data_for_compare <= current_high);
    
    // Threshold update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_low <= {WIDTH{1'b0}};
            current_high <= {WIDTH{1'b1}};
        end else if (wr_en) begin
            current_low <= new_low;
            current_high <= new_high;
        end
    end
    
    // Stage 2: 存储组合逻辑比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_comp_result_stage2 <= 1'b0;
            high_comp_result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            low_comp_result_stage2 <= low_comp_result;
            high_comp_result_stage2 <= high_comp_result;
            valid_stage2 <= valid_for_compare;
        end
    end
    
    // Stage 3: Combine comparison results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            result_stage3 <= low_comp_result_stage2 && high_comp_result_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    assign out_flag = result_stage3;
    assign out_valid = valid_stage3;
    
endmodule