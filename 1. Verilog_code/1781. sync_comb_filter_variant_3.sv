//SystemVerilog
module sync_comb_filter #(
    parameter W = 12,
    parameter DELAY = 8
)(
    input clk, rst_n, enable,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    // 优化1: 将延迟线使用二维寄存器数组表示，有助于综合工具更好地映射到物理存储资源
    reg [W-1:0] delay_line [0:DELAY-1];
    
    // 优化2: 提前计算最终延迟线索引，避免每个周期重复计算
    localparam FINAL_DELAY_INDEX = DELAY-1;
    
    // 优化3: 使用generate语句来处理不同延迟值的情况
    generate
        genvar j;
        if (DELAY == 1) begin : single_delay
            always @(posedge clk) begin
                if (!rst_n) begin
                    delay_line[0] <= {W{1'b0}};
                    dout <= {W{1'b0}};
                end else if (enable) begin
                    delay_line[0] <= din;
                    dout <= din - delay_line[0];
                end
            end
        end else begin : multi_delay
            integer i;
            always @(posedge clk) begin
                if (!rst_n) begin
                    for (i = 0; i < DELAY; i = i + 1)
                        delay_line[i] <= {W{1'b0}};
                    dout <= {W{1'b0}};
                end else if (enable) begin
                    // 优化4: 采用单独赋值方式以避免潜在的综合问题
                    delay_line[0] <= din;
                    for (i = 1; i < DELAY; i = i + 1)
                        delay_line[i] <= delay_line[i-1];
                    
                    // 优化5: 使用直接索引而非计算索引，有助于减少关键路径延迟
                    dout <= din - delay_line[FINAL_DELAY_INDEX];
                end
            end
        end
    endgenerate
endmodule