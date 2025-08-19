//SystemVerilog
module ITRC_DoubleBuffer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] raw_status,
    output wire [WIDTH-1:0] stable_status
);

    // 数据通路寄存器
    reg [WIDTH-1:0] first_stage_reg;
    reg [WIDTH-1:0] second_stage_reg;
    
    // 同步逻辑 - 扁平化结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            first_stage_reg <= {WIDTH{1'b0}};
            second_stage_reg <= {WIDTH{1'b0}};
        end else begin
            first_stage_reg <= raw_status;
            second_stage_reg <= first_stage_reg;
        end
    end
    
    // 输出赋值
    assign stable_status = second_stage_reg;

endmodule