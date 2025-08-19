//SystemVerilog
module range_detector_sync(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire [7:0] lower_bound, upper_bound,
    output reg in_range
);
    reg [7:0] data_in_reg;
    reg [7:0] lower_bound_reg;
    reg [7:0] upper_bound_reg;
    wire lower_compare;
    wire upper_compare;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'b0;
            lower_bound_reg <= 8'b0;
            upper_bound_reg <= 8'b0;
        end else begin
            data_in_reg <= data_in;
            lower_bound_reg <= lower_bound;
            upper_bound_reg <= upper_bound;
        end
    end
    
    // Optimized comparison using parallel comparators
    assign lower_compare = (data_in_reg >= lower_bound_reg);
    assign upper_compare = (data_in_reg <= upper_bound_reg);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) in_range <= 1'b0;
        else in_range <= lower_compare & upper_compare;
    end
endmodule