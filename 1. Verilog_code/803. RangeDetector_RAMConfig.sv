module RangeDetector_RAMConfig #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    input [DATA_WIDTH-1:0] data_in,
    output out_flag
);
reg [DATA_WIDTH-1:0] threshold_ram [2**ADDR_WIDTH-1:0];
wire [DATA_WIDTH-1:0] low = threshold_ram[0];
wire [DATA_WIDTH-1:0] high = threshold_ram[1];

always @(posedge clk) begin
    if(wr_en) threshold_ram[wr_addr] <= wr_data;
end

assign out_flag = (data_in >= low) && (data_in <= high);
endmodule