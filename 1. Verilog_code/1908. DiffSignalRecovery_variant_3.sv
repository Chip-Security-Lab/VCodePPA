//SystemVerilog
// Top-level module
module DiffSignalRecovery #(
    parameter THRESHOLD = 100
) (
    input  wire clk,
    input  wire diff_p, 
    input  wire diff_n,
    output wire recovered
);
    // Internal signals
    wire signed [15:0] diff_value;
    wire compare_result;
    
    // Instantiate submodules
    DiffCalculator diff_calc_inst (
        .clk       (clk),
        .diff_p    (diff_p),
        .diff_n    (diff_n),
        .diff_value(diff_value)
    );
    
    ThresholdComparator #(
        .THRESHOLD(THRESHOLD)
    ) threshold_comp_inst (
        .clk           (clk),
        .diff_value    (diff_value),
        .prev_recovered(recovered),
        .comp_result   (compare_result)
    );
    
    OutputRegister output_reg_inst (
        .clk           (clk),
        .compare_result(compare_result),
        .recovered     (recovered)
    );
    
endmodule

// Differential calculator submodule
module DiffCalculator (
    input  wire clk,
    input  wire diff_p,
    input  wire diff_n,
    output reg signed [15:0] diff_value
);
    // Calculate difference between differential inputs
    always @(posedge clk) begin
        diff_value <= diff_p - diff_n;
    end
endmodule

// Threshold comparator submodule
module ThresholdComparator #(
    parameter THRESHOLD = 100
) (
    input  wire clk,
    input  wire signed [15:0] diff_value,
    input  wire prev_recovered,
    output reg comp_result
);
    // Compare difference value with thresholds
    always @(posedge clk) begin
        comp_result <= (diff_value > THRESHOLD) ? 1'b1 :
                       (diff_value < -THRESHOLD) ? 1'b0 : prev_recovered;
    end
endmodule

// Output register submodule
module OutputRegister (
    input  wire clk,
    input  wire compare_result,
    output reg recovered
);
    // Register the comparison result to create output
    always @(posedge clk) begin
        recovered <= compare_result;
    end
endmodule