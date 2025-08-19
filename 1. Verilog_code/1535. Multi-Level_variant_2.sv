//SystemVerilog
// IEEE 1364-2005 Verilog标准
module multi_shadow_reg #(
    parameter WIDTH = 8,
    parameter LEVELS = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    input wire [1:0] shadow_select,
    output wire [WIDTH-1:0] shadow_out
);
    // Main register
    reg [WIDTH-1:0] main_reg;
    // Multiple shadow registers
    reg [WIDTH-1:0] shadow_reg [0:LEVELS-1];
    
    // Main register update - 独立always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else
            main_reg <= data_in;
    end
    
    // 第一级shadow register更新 - 拆分为独立always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_reg[0] <= 0;
        else if (capture)
            shadow_reg[0] <= main_reg;
    end
    
    // 生成中间shadow registers - 每个级别一个独立always块
    genvar g;
    generate
        for (g = 1; g < LEVELS; g = g + 1) begin : shadow_reg_gen
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    shadow_reg[g] <= 0;
                else if (capture)
                    shadow_reg[g] <= shadow_reg[g-1];
            end
        end
    endgenerate
    
    // Output selection
    assign shadow_out = shadow_reg[shadow_select];
endmodule