//SystemVerilog
module self_checking_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_index,
    output reg valid,
    output reg error
);
    // 流水线寄存器声明
    reg [WIDTH-1:0] data_in_stage1;
    reg valid_stage1;
    reg [WIDTH-1:0] data_in_stage2;
    reg valid_stage2;
    reg [$clog2(WIDTH)-1:0] priority_idx_stage2;
    reg [$clog2(WIDTH)-1:0] priority_idx_stage3;
    reg valid_stage3;
    reg [WIDTH-1:0] priority_mask_stage3;
    reg [WIDTH-1:0] priority_mask_stage4;
    reg [$clog2(WIDTH)-1:0] priority_idx_stage4;
    reg valid_stage4;
    
    // 阶段1: 数据输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1 <= |data_in;
        end
    end
    
    // 阶段2: 数据传递和优先级预计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= 0;
            valid_stage2 <= 0;
            priority_idx_stage2 <= 0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            valid_stage2 <= valid_stage1;
            priority_idx_stage2 <= 0;
            for (integer i = WIDTH-1; i >= WIDTH/2; i = i - 1)
                if (data_in_stage1[i]) 
                    priority_idx_stage2 <= i[$clog2(WIDTH)-1:0];
        end
    end
    
    // 阶段3: 优先级计算完成和掩码生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_idx_stage3 <= 0;
            valid_stage3 <= 0;
            priority_mask_stage3 <= 0;
        end else begin
            priority_idx_stage3 <= priority_idx_stage2;
            for (integer i = WIDTH/2-1; i >= 0; i = i - 1)
                if (data_in_stage2[i]) 
                    priority_idx_stage3 <= i[$clog2(WIDTH)-1:0];
            valid_stage3 <= valid_stage2;
            priority_mask_stage3 <= 0;
            priority_mask_stage3[priority_idx_stage3] <= valid_stage3;
        end
    end
    
    // 阶段4: 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask_stage4 <= 0;
            priority_idx_stage4 <= 0;
            valid_stage4 <= 0;
        end else begin
            priority_mask_stage4 <= priority_mask_stage3;
            priority_idx_stage4 <= priority_idx_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 阶段5: 最终输出和错误检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_index <= 0;
            valid <= 0;
            error <= 0;
        end else begin
            priority_index <= priority_idx_stage4;
            valid <= valid_stage4;
            error <= valid_stage4 && ~(|data_in_stage2[priority_idx_stage4]);
        end
    end
endmodule