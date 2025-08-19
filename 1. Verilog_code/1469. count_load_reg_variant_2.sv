//SystemVerilog
module count_load_reg(
    input clk, rst,
    input [7:0] load_val,
    input load, count_en,
    output reg [7:0] count,
    // 流水线控制信号
    input valid_in,
    output reg valid_out,
    input ready_in,
    output wire ready_out
);
    // 流水线寄存器定义
    reg [7:0] count_stage1, count_stage2;
    reg load_stage1, load_stage2;
    reg count_en_stage1, count_en_stage2;
    reg [7:0] load_val_stage1, load_val_stage2;
    reg valid_stage1, valid_stage2;
    
    // 流水线控制逻辑
    wire stall;
    assign stall = valid_out && !ready_in;
    assign ready_out = !stall;
    
    // 第一级流水线 - 寄存输入信号
    always @(posedge clk) begin
        if (rst) begin
            load_stage1 <= 1'b0;
            count_en_stage1 <= 1'b0;
            load_val_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end 
        else begin
            if (ready_out && valid_in) begin
                load_stage1 <= load;
                count_en_stage1 <= count_en;
                load_val_stage1 <= load_val;
                valid_stage1 <= valid_in;
            end 
            else if (!stall) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 计算下一状态的辅助线网
    wire [7:0] next_count;
    assign next_count = load_stage1 ? load_val_stage1 :
                        count_en_stage1 ? count + 1'b1 :
                        count;
    
    // 第二级流水线 - 计算逻辑
    always @(posedge clk) begin
        if (rst) begin
            load_stage2 <= 1'b0;
            count_en_stage2 <= 1'b0;
            load_val_stage2 <= 8'h00;
            count_stage1 <= 8'h00;
            valid_stage2 <= 1'b0;
        end 
        else begin
            if (!stall) begin
                load_stage2 <= load_stage1;
                count_en_stage2 <= count_en_stage1;
                load_val_stage2 <= load_val_stage1;
                count_stage1 <= next_count;
                valid_stage2 <= valid_stage1;
            end
            else begin
                // 当流水线暂停时，确保数据正确性
                count_stage1 <= forwarded_count;
            end
        end
    end
    
    // 第三级流水线 - 输出结果
    always @(posedge clk) begin
        if (rst) begin
            count <= 8'h00;
            valid_out <= 1'b0;
        end 
        else if (!stall) begin
            count <= count_stage1;
            valid_out <= valid_stage2;
        end
    end
    
    // 前递机制 - 处理数据依赖
    wire [7:0] forwarded_count;
    assign forwarded_count = load_stage2 ? load_val_stage2 :
                             count_en_stage2 ? count_stage1 + 1'b1 :
                             count_stage1;
    
endmodule