//SystemVerilog
module range_detector_with_enable(
    input wire clk, rst, enable,
    input wire [15:0] data_input,
    input wire [15:0] range_min, range_max,
    output reg range_detect_flag
);
    wire comp_out;
    
    comparator_module_optimized comp1(
        .clk(clk),
        .rst(rst),
        .data(data_input),
        .lower(range_min),
        .upper(range_max),
        .in_range(comp_out)
    );
    
    always @(posedge clk) begin
        if (rst)
            range_detect_flag <= 1'b0;
        else if (enable)
            range_detect_flag <= comp_out;
    end
endmodule

module comparator_module_optimized(
    input wire clk, rst,
    input wire [15:0] data,
    input wire [15:0] lower,
    input wire [15:0] upper,
    output reg in_range
);
    // Optimized single-cycle range check
    wire in_range_comb;
    reg [1:0] range_check;
    
    // Parallel comparison for better timing
    assign in_range_comb = (data >= lower) && (data <= upper);
    
    // Two-stage pipelining with reduced logic
    always @(posedge clk) begin
        if (rst) begin
            range_check <= 2'b00;
            in_range <= 1'b0;
        end
        else begin
            // First pipeline stage: capture range check result
            range_check[0] <= in_range_comb;
            // Second pipeline stage: propagate to output
            range_check[1] <= range_check[0];
            in_range <= range_check[1];
        end
    end
endmodule