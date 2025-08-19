//SystemVerilog
// IEEE 1364-2005 Verilog标准
module selective_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] bit_mask,
    input wire update,
    output reg [WIDTH-1:0] shadow_out
);
    // Main data register
    reg [WIDTH-1:0] data_reg;
    
    // 流水线寄存器
    reg [WIDTH-1:0] masked_data_reg;
    reg [WIDTH-1:0] preserved_shadow_reg;
    reg update_pipe;
    
    // 第一阶段：更新主寄存器和计算掩码数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {WIDTH{1'b0}};
            masked_data_reg <= {WIDTH{1'b0}};
            preserved_shadow_reg <= {WIDTH{1'b0}};
            update_pipe <= 1'b0;
        end
        else begin
            data_reg <= data_in;
            masked_data_reg <= data_reg & bit_mask;
            preserved_shadow_reg <= shadow_out & ~bit_mask;
            update_pipe <= update;
        end
    end
    
    // 第二阶段：更新影子寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_out <= {WIDTH{1'b0}};
        end 
        else if (update_pipe) begin
            shadow_out <= masked_data_reg | preserved_shadow_reg;
        end
    end
    
endmodule