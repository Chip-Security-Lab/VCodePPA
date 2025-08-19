//SystemVerilog
module dual_sampler #(
    parameter DATA_WIDTH = 1  // 参数化设计，提高可配置性
) (
    input  wire                 clk,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] rise_data,
    output reg  [DATA_WIDTH-1:0] fall_data
);

    // 上升沿采样
    always @(posedge clk) begin
        rise_data <= din;
    end
    
    // 下降沿采样
    always @(negedge clk) begin
        fall_data <= din;
    end

endmodule