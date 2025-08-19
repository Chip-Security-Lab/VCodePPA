//SystemVerilog
module RangeDetector_APB #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input psel, penable, pwrite,
    input [ADDR_WIDTH-1:0] paddr,
    input [WIDTH-1:0] pwdata,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] prdata,
    output reg out_range
);
    reg [WIDTH-1:0] lower_threshold, upper_threshold;
    reg below_lower, above_upper;
    wire apb_write = psel && penable && pwrite;
    wire [0:0] threshold_sel = paddr[0];
    
    // Register update logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            lower_threshold <= 0;
            upper_threshold <= {WIDTH{1'b1}};
        end
        else if(apb_write) begin
            if(threshold_sel)
                upper_threshold <= pwdata;
            else
                lower_threshold <= pwdata;
        end
    end
    
    // Pre-compute comparison results
    always @(posedge clk) begin
        below_lower <= data_in < lower_threshold;
        above_upper <= data_in > upper_threshold;
    end
    
    // Output logic with balanced delay paths
    always @(posedge clk) begin
        out_range <= below_lower || above_upper;
        prdata <= threshold_sel ? upper_threshold : lower_threshold;
    end
endmodule