//SystemVerilog
module binary_freq_div #(parameter WIDTH = 4) (
    input wire clk_in,
    input wire rst_n,
    output wire clk_out
);
    // 三级流水线结构划分，更均衡的计算负载
    localparam STAGE1_WIDTH = WIDTH/3;
    localparam STAGE2_WIDTH = WIDTH/3;
    localparam STAGE3_WIDTH = WIDTH - STAGE1_WIDTH - STAGE2_WIDTH;
    
    // 第一级流水线
    reg [STAGE1_WIDTH-1:0] count_stage1;
    reg stage1_carry;
    reg stage1_valid;
    
    // 第二级流水线
    reg [STAGE2_WIDTH-1:0] count_stage2;
    reg stage2_carry;
    reg stage2_valid;
    
    // 第三级流水线
    reg [STAGE3_WIDTH-1:0] count_stage3;
    reg clk_out_reg;
    reg stage3_valid;
    
    // 流水线状态控制
    reg pipeline_active;
    
    // 第一级流水线逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count_stage1 <= {STAGE1_WIDTH{1'b0}};
            stage1_carry <= 1'b0;
            stage1_valid <= 1'b0;
            pipeline_active <= 1'b0;
        end
        else begin
            pipeline_active <= 1'b1;
            count_stage1 <= count_stage1 + 1'b1;
            stage1_carry <= &count_stage1; // 当第一级全为1时产生进位
            stage1_valid <= pipeline_active;
        end
    end
    
    // 第二级流水线逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count_stage2 <= {STAGE2_WIDTH{1'b0}};
            stage2_carry <= 1'b0;
            stage2_valid <= 1'b0;
        end
        else begin
            if (stage1_valid) begin
                if (stage1_carry) begin
                    count_stage2 <= count_stage2 + 1'b1;
                    stage2_carry <= &count_stage2; // 当第二级全为1时产生进位
                end
                stage2_valid <= 1'b1;
            end
        end
    end
    
    // 第三级流水线逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count_stage3 <= {STAGE3_WIDTH{1'b0}};
            clk_out_reg <= 1'b0;
            stage3_valid <= 1'b0;
        end
        else begin
            if (stage2_valid) begin
                if (stage2_carry) begin
                    count_stage3 <= count_stage3 + 1'b1;
                    // 使用最高位作为输出时钟，提升寄存器后减少输出延迟
                    clk_out_reg <= count_stage3[STAGE3_WIDTH-1];
                end
                stage3_valid <= 1'b1;
            end
        end
    end
    
    // 输出赋值，可以直接使用寄存器输出
    assign clk_out = clk_out_reg;
    
endmodule