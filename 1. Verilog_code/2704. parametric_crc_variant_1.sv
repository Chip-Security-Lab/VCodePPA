//SystemVerilog
module parametric_crc #(
    parameter WIDTH = 8,
    parameter POLY = 8'h9B,
    parameter INIT = {WIDTH{1'b1}}
)(
    input clk, en,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] crc
);

// LUT for subtraction results
reg [WIDTH-1:0] sub_lut [0:255];

// 流水线寄存器和控制信号
reg [WIDTH-1:0] stage1_data, stage2_data;
reg [WIDTH-1:0] stage1_crc, stage2_crc;
reg stage1_valid, stage2_valid;
reg stage1_msb;
reg [WIDTH-1:0] stage1_next_crc;
reg [WIDTH-1:0] stage2_result;

// Initialize LUT
integer i;
initial begin
    for(i = 0; i < 256; i = i + 1) begin
        sub_lut[i] = i ^ POLY;
    end
end

// 流水线第一级：捕获输入，生成next_crc和条件标志
always @(posedge clk) begin
    if (!en) begin
        stage1_valid <= 1'b0;
        stage1_crc <= INIT;
    end else begin
        stage1_valid <= 1'b1;
        stage1_data <= data;
        stage1_crc <= crc;
        stage1_msb <= crc[WIDTH-1];
        stage1_next_crc <= {crc[WIDTH-2:0], 1'b0};
    end
end

// 流水线第二级：计算CRC逻辑
always @(posedge clk) begin
    if (!en) begin
        stage2_valid <= 1'b0;
    end else begin
        stage2_valid <= stage1_valid;
        if (stage1_valid) begin
            if (stage1_msb) begin
                stage2_result <= sub_lut[stage1_next_crc ^ stage1_data];
            end else begin
                stage2_result <= stage1_next_crc ^ stage1_data;
            end
        end
    end
end

// 最终CRC输出
always @(posedge clk) begin
    if (!en) begin
        crc <= INIT;
    end else if (stage2_valid) begin
        crc <= stage2_result;
    end
end

endmodule