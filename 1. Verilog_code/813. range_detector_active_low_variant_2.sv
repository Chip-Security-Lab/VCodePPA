//SystemVerilog
module range_detector_active_low(
    input wire clock, reset,
    input wire [7:0] value,
    input wire [7:0] range_low, range_high,
    output reg range_valid_n
);
    wire comp_result_n;
    
    comparator_low_pipelined comp1 (
        .clock(clock),
        .reset(reset),
        .in_value(value),
        .lower_lim(range_low),
        .upper_lim(range_high),
        .out_of_range(comp_result_n)
    );
    
    always @(posedge clock) begin
        if (reset) range_valid_n <= 1'b1;
        else range_valid_n <= comp_result_n;
    end
endmodule

module comparator_low_pipelined(
    input wire clock, reset,
    input wire [7:0] in_value,
    input wire [7:0] lower_lim,
    input wire [7:0] upper_lim,
    output reg out_of_range
);
    // Split the comparison into two pipeline stages
    reg lower_compare_result;
    reg upper_compare_result;
    reg lower_compare_result_pipe;
    reg upper_compare_result_pipe;
    
    // First stage - calculate comparisons
    always @(posedge clock) begin
        if (reset) begin
            lower_compare_result <= 1'b0;
            upper_compare_result <= 1'b0;
        end else begin
            lower_compare_result <= (in_value < lower_lim);
            upper_compare_result <= (in_value > upper_lim);
        end
    end
    
    // Second stage - pipeline the comparison results
    always @(posedge clock) begin
        if (reset) begin
            lower_compare_result_pipe <= 1'b0;
            upper_compare_result_pipe <= 1'b0;
            out_of_range <= 1'b0;
        end else begin
            lower_compare_result_pipe <= lower_compare_result;
            upper_compare_result_pipe <= upper_compare_result;
            out_of_range <= lower_compare_result_pipe || upper_compare_result_pipe;
        end
    end
endmodule