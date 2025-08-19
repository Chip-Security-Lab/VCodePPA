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
    
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] selected_lower, selected_upper;
    reg range_check_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {DATA_WIDTH{1'b0}};
            addr_reg <= {ADDR_WIDTH{1'b0}};
            selected_lower <= {DATA_WIDTH{1'b0}};
            selected_upper <= {DATA_WIDTH{1'b1}};
            range_check_result <= 1'b0;
            out_of_range <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            addr_reg <= addr;
            selected_lower <= lower_bounds[addr_reg];
            selected_upper <= upper_bounds[addr_reg];
            range_check_result <= (data_in_reg >= selected_lower) && (data_in_reg <= selected_upper);
            out_of_range <= ~range_check_result;
        end
    end
endmodule