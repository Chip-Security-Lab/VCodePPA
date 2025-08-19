//SystemVerilog
module RangeDetector_MultiChannel #(
    parameter WIDTH = 8,
    parameter CHANNELS = 4
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] thresholds [CHANNELS*2-1:0],
    input [$clog2(CHANNELS)-1:0] ch_sel,
    output reg out_flag
);

    // Pipeline registers
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH-1:0] lower_threshold_reg;
    reg [WIDTH-1:0] upper_threshold_reg;
    reg range_valid_reg;

    // Threshold selection and comparison logic
    wire [WIDTH-1:0] lower_threshold;
    wire [WIDTH-1:0] upper_threshold;
    wire range_valid;

    ThresholdSelector #(
        .WIDTH(WIDTH),
        .CHANNELS(CHANNELS)
    ) threshold_selector (
        .thresholds(thresholds),
        .ch_sel(ch_sel),
        .lower_threshold(lower_threshold),
        .upper_threshold(upper_threshold)
    );

    RangeComparator #(
        .WIDTH(WIDTH)
    ) range_comparator (
        .data_in(data_in_reg),
        .lower_threshold(lower_threshold_reg),
        .upper_threshold(upper_threshold_reg),
        .range_valid(range_valid)
    );

    // Pipeline stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {WIDTH{1'b0}};
            lower_threshold_reg <= {WIDTH{1'b0}};
            upper_threshold_reg <= {WIDTH{1'b0}};
        end else begin
            data_in_reg <= data_in;
            lower_threshold_reg <= lower_threshold;
            upper_threshold_reg <= upper_threshold;
        end
    end

    // Pipeline stage 2: Register comparison result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_valid_reg <= 1'b0;
        end else begin
            range_valid_reg <= range_valid;
        end
    end

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_flag <= 1'b0;
        end else begin
            out_flag <= range_valid_reg;
        end
    end

endmodule

module ThresholdSelector #(
    parameter WIDTH = 8,
    parameter CHANNELS = 4
)(
    input [WIDTH-1:0] thresholds [CHANNELS*2-1:0],
    input [$clog2(CHANNELS)-1:0] ch_sel,
    output reg [WIDTH-1:0] lower_threshold,
    output reg [WIDTH-1:0] upper_threshold
);

    always @(*) begin
        lower_threshold = thresholds[ch_sel*2];
        upper_threshold = thresholds[ch_sel*2+1];
    end

endmodule

module RangeComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower_threshold,
    input [WIDTH-1:0] upper_threshold,
    output reg range_valid
);

    always @(*) begin
        range_valid = (data_in >= lower_threshold) && 
                     (data_in <= upper_threshold);
    end

endmodule