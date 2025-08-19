//SystemVerilog
module async_load_dff (
    input wire clk,
    input wire rst_n,        // 添加复位信号
    input wire load,
    input wire valid_in,     // 输入有效信号
    input wire [3:0] data,
    output wire [3:0] q,
    output wire valid_out    // 输出有效信号
);

    // 流水线第一级 - 输入寄存器
    reg [3:0] data_stage1;
    reg load_stage1;
    reg valid_stage1;
    
    // 流水线第二级 - 处理寄存器
    reg [3:0] data_stage2;
    reg load_stage2;
    reg valid_stage2;
    
    // 流水线第三级 - 输出寄存器
    reg [3:0] q_reg;
    reg valid_stage3;
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 4'b0;
            load_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (valid_in) begin
            data_stage1 <= data;
            load_stage1 <= load;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 4'b0;
            load_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            load_stage2 <= load_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 计算逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_reg <= 4'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            if (load_stage2) begin
                q_reg <= data_stage2;
            end else begin
                q_reg <= q_reg + 4'b1;
            end
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign q = q_reg;
    assign valid_out = valid_stage3;
    
endmodule