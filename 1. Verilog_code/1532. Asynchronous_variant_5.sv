//SystemVerilog
// IEEE 1364-2005
module async_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shadow_en,
    output reg [WIDTH-1:0] shadow_out
);
    // 优化后的寄存器设计
    reg [WIDTH-1:0] shadow_reg;
    reg shadow_en_d1;
    reg [WIDTH-1:0] data_in_d1;
    
    // 输入数据寄存优化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_d1 <= {WIDTH{1'b0}};
        else
            data_in_d1 <= data_in;
    end
    
    // 控制信号寄存优化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_en_d1 <= 1'b0;
        else
            shadow_en_d1 <= shadow_en;
    end
    
    // 优化shadow寄存逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_reg <= {WIDTH{1'b0}};
        else if (shadow_en_d1)
            shadow_reg <= data_in_d1;
    end
    
    // 优化输出逻辑，减少逻辑级数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
        else
            shadow_out <= shadow_en_d1 ? data_in_d1 : shadow_reg;
    end
endmodule