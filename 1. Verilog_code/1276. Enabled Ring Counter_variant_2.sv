//SystemVerilog - IEEE 1364-2005
module enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire enable,
    output wire [3:0] count
);
    // 增加流水线级数，从2级增加到4级
    reg [3:0] count_stage1;
    reg [3:0] count_stage2;
    reg [3:0] count_stage3;
    reg [3:0] count_stage4;
    
    reg enable_stage1, enable_stage2, enable_stage3, enable_stage4;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clock) begin
        if (reset) begin
            count_stage1 <= 4'b0001;
            enable_stage1 <= 1'b0;
        end else begin
            count_stage1 <= count_stage4;
            enable_stage1 <= enable;
        end
    end
    
    // 第二级流水线 - 旋转预处理
    always @(posedge clock) begin
        if (reset) begin
            count_stage2 <= 4'b0001;
            enable_stage2 <= 1'b0;
        end else begin
            count_stage2 <= count_stage1;
            enable_stage2 <= enable_stage1;
        end
    end
    
    // 第三级流水线 - 执行旋转操作
    always @(posedge clock) begin
        if (reset) begin
            count_stage3 <= 4'b0001;
            enable_stage3 <= 1'b0;
        end else if (enable_stage2) begin
            count_stage3 <= {count_stage2[2:0], count_stage2[3]};
            enable_stage3 <= enable_stage2;
        end else begin
            count_stage3 <= count_stage2;
            enable_stage3 <= enable_stage2;
        end
    end
    
    // 第四级流水线 - 输出缓冲
    always @(posedge clock) begin
        if (reset) begin
            count_stage4 <= 4'b0001;
            enable_stage4 <= 1'b0;
        end else begin
            count_stage4 <= count_stage3;
            enable_stage4 <= enable_stage3;
        end
    end
    
    // 输出赋值
    assign count = count_stage4;
    
endmodule