//SystemVerilog
/* IEEE 1364-2005 Verilog */
module selective_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] bit_mask,
    input wire update,
    input wire valid_in,
    output wire valid_out,
    output reg [WIDTH-1:0] shadow_out
);
    // 流水线阶段寄存器和控制信号
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] bit_mask_stage1;
    reg update_stage1;
    reg valid_stage1;
    
    reg [WIDTH-1:0] data_stage2;
    reg [WIDTH-1:0] bit_mask_stage2;
    reg update_stage2;
    reg valid_stage2;
    
    reg [WIDTH-1:0] shadow_reg;
    
    // 优化的选择性掩码信号
    wire [WIDTH-1:0] masked_data;
    wire [WIDTH-1:0] preserved_shadow;
    wire [WIDTH-1:0] next_shadow;
    
    // 第一级流水线：数据采集
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            bit_mask_stage1 <= {WIDTH{1'b0}};
            update_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            bit_mask_stage1 <= bit_mask;
            update_stage1 <= update;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            bit_mask_stage2 <= {WIDTH{1'b0}};
            update_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            bit_mask_stage2 <= bit_mask_stage1;
            update_stage2 <= update_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 优化的掩码操作 - 直接使用按位操作替代借位减法器
    assign masked_data = data_stage2 & bit_mask_stage2;
    assign preserved_shadow = shadow_reg & (~bit_mask_stage2);
    assign next_shadow = masked_data | preserved_shadow;
    
    // 第三级流水线：选择性更新shadow寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_reg <= {WIDTH{1'b0}};
            shadow_out <= {WIDTH{1'b0}};
        end else begin
            if (valid_stage2 && update_stage2) begin
                shadow_reg <= next_shadow;
            end
            shadow_out <= shadow_reg;
        end
    end
    
    // 输出有效信号
    reg valid_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
        end
    end
    
    assign valid_out = valid_stage3;
    
endmodule