//SystemVerilog
module RangeDetector_AddrConfig #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input [ADDR_WIDTH-1:0] addr,
    output reg out_of_range
);

reg [DATA_WIDTH-1:0] lower_bounds [2**ADDR_WIDTH-1:0];
reg [DATA_WIDTH-1:0] upper_bounds [2**ADDR_WIDTH-1:0];

// 寄存输入数据和地址 - 将寄存器前移
reg [DATA_WIDTH-1:0] data_in_r;
reg [ADDR_WIDTH-1:0] addr_r;

// 第一级流水线 - 仅寄存输入数据
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_r <= {DATA_WIDTH{1'b0}};
        addr_r <= {ADDR_WIDTH{1'b0}};
    end
    else begin
        data_in_r <= data_in;
        addr_r <= addr;
    end
end

// 比较逻辑的结果 - 不再提前寄存比较结果
wire lower_comp_result;
wire upper_comp_result;

// 比较逻辑现在直接使用寄存后的输入信号
assign lower_comp_result = (data_in_r < lower_bounds[addr_r]);
assign upper_comp_result = (data_in_r > upper_bounds[addr_r]);

// 第二级流水线 - 寄存比较结果
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_of_range <= 1'b0;
    end
    else begin
        out_of_range <= lower_comp_result || upper_comp_result;
    end
end

endmodule