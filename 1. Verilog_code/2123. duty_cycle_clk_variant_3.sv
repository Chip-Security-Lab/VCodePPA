//SystemVerilog
// Top level module
module duty_cycle_clk #(
    parameter HIGH_CYCLE = 2,
    parameter TOTAL_CYCLE = 4
)(
    input  wire clk,
    input  wire rstb,
    output wire clk_out
);
    // Internal connections
    wire valid_s1_to_s2;
    wire [7:0] counter_s1_to_s2;
    wire valid_s2_to_s3;
    wire comparison_result_to_s3;

    // Instantiate counter management module (Stage 1)
    counter_stage #(
        .TOTAL_CYCLE(TOTAL_CYCLE)
    ) counter_inst (
        .clk              (clk),
        .rstb             (rstb),
        .counter_out      (counter_s1_to_s2),
        .valid_out        (valid_s1_to_s2)
    );

    // Instantiate comparison module (Stage 2)
    comparison_stage #(
        .HIGH_CYCLE(HIGH_CYCLE)
    ) comparator_inst (
        .clk              (clk),
        .rstb             (rstb),
        .counter_in       (counter_s1_to_s2),
        .valid_in         (valid_s1_to_s2),
        .comparison_out   (comparison_result_to_s3),
        .valid_out        (valid_s2_to_s3)
    );

    // Instantiate output stage module (Stage 3)
    output_stage output_inst (
        .clk              (clk),
        .rstb             (rstb),
        .comparison_in    (comparison_result_to_s3),
        .valid_in         (valid_s2_to_s3),
        .clk_out          (clk_out)
    );
endmodule

// Stage 1: Counter management module
module counter_stage #(
    parameter TOTAL_CYCLE = 4
)(
    input  wire clk,
    input  wire rstb,
    output reg  [7:0] counter_out,
    output reg  valid_out
);
    reg [7:0] next_counter;
    
    // Calculate next counter value
    always @(*) begin
        if (counter_out >= TOTAL_CYCLE - 1)
            next_counter = 8'd0;
        else
            next_counter = counter_out + 1'b1;
    end
    
    // Counter and valid registers
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            counter_out <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            counter_out <= next_counter;
            valid_out <= 1'b1;
        end
    end
endmodule

// Stage 2: Comparison logic module
module comparison_stage #(
    parameter HIGH_CYCLE = 2
)(
    input  wire clk,
    input  wire rstb,
    input  wire [7:0] counter_in,
    input  wire valid_in,
    output reg  comparison_out,
    output reg  valid_out
);
    reg [7:0] counter_stage2;
    
    // Pipeline stage 2 registers
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            counter_stage2 <= 8'd0;
            valid_out <= 1'b0;
            comparison_out <= 1'b0;
        end else begin
            counter_stage2 <= counter_in;
            valid_out <= valid_in;
            comparison_out <= (counter_in < HIGH_CYCLE) ? 1'b1 : 1'b0;
        end
    end
endmodule

// Stage 3: Output generation module
module output_stage (
    input  wire clk,
    input  wire rstb,
    input  wire comparison_in,
    input  wire valid_in,
    output reg  clk_out
);
    // Output register
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            clk_out <= 1'b0;
        end else if (valid_in) begin
            clk_out <= comparison_in;
        end
    end
endmodule