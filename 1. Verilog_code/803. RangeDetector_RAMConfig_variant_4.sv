//SystemVerilog
module RangeDetector_RAMConfig #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    input [DATA_WIDTH-1:0] data_in,
    output reg out_flag
);

    reg [DATA_WIDTH-1:0] threshold_ram [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] low_reg;
    reg [DATA_WIDTH-1:0] high_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;
    
    wire [DATA_WIDTH-1:0] inverted_data_in;
    wire [DATA_WIDTH-1:0] low_minus_data;
    wire [DATA_WIDTH-1:0] data_minus_high;
    wire low_compare_flag, high_compare_flag;

    // Register inputs
    always @(posedge clk) begin
        low_reg <= threshold_ram[0];
        high_reg <= threshold_ram[1];
        data_in_reg <= data_in;
    end

    // RAM write
    always @(posedge clk) begin
        if(wr_en) threshold_ram[wr_addr] <= wr_data;
    end

    // Comparison logic
    assign inverted_data_in = ~data_in_reg + 1'b1;
    assign low_minus_data = low_reg + inverted_data_in;
    assign data_minus_high = data_in_reg + (~high_reg + 1'b1);
    
    assign low_compare_flag = ~low_minus_data[DATA_WIDTH-1];
    assign high_compare_flag = ~data_minus_high[DATA_WIDTH-1];

    // Register output
    always @(posedge clk) begin
        out_flag <= low_compare_flag && high_compare_flag;
    end

endmodule