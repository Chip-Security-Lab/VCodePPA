//SystemVerilog
module wave13_half_rect_sine #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    reg [ADDR_WIDTH-1:0] addr;
    wire [DATA_WIDTH-1:0] diff;
    wire is_negative;
    
    // 直接计算差值和符号
    // 使用更简单的比较运算替代复杂的减法器
    assign is_negative = addr < {1'b1, {(ADDR_WIDTH-1){1'b0}}};
    
    // 简化的差值计算
    assign diff = is_negative ? {DATA_WIDTH{1'b0}} : 
                              {1'b0, addr, {(DATA_WIDTH-ADDR_WIDTH-1){1'b0}}} - 
                              {1'b1, {(DATA_WIDTH-1){1'b0}}};
    
    always @(posedge clk) begin
        if(rst) begin
            addr <= 0;
            wave_out <= 0;
        end
        else begin
            addr <= addr + 1;
            // 直接使用计算好的diff值
            wave_out <= diff;
        end
    end
endmodule