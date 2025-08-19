//SystemVerilog
module dram_temp_refresh #(
    parameter BASE_CYCLES = 7800,
    parameter TEMP_COEFF = 50
)(
    input clk,
    input [7:0] temperature,
    output refresh_req
);

    wire [31:0] threshold;
    wire [31:0] counter_out;
    wire refresh_pulse;

    temp_threshold_calc #(
        .BASE_CYCLES(BASE_CYCLES),
        .TEMP_COEFF(TEMP_COEFF)
    ) u_temp_threshold (
        .clk(clk),
        .temperature(temperature),
        .threshold(threshold)
    );

    refresh_counter u_counter (
        .clk(clk),
        .threshold(threshold),
        .counter_out(counter_out),
        .refresh_pulse(refresh_pulse)
    );

    refresh_req_gen u_req_gen (
        .clk(clk),
        .refresh_pulse(refresh_pulse),
        .refresh_req(refresh_req)
    );

endmodule

module temp_threshold_calc #(
    parameter BASE_CYCLES = 7800,
    parameter TEMP_COEFF = 50
)(
    input clk,
    input [7:0] temperature,
    output reg [31:0] threshold
);

    reg [7:0] temp_stage1;
    reg [31:0] temp_mult_stage1;
    reg [31:0] temp_mult_stage2;
    reg [31:0] base_cycles_stage1;

    always @(posedge clk) begin
        // Stage 1: Register inputs and start multiplication
        temp_stage1 <= temperature;
        base_cycles_stage1 <= BASE_CYCLES;
        temp_mult_stage1 <= temperature * TEMP_COEFF;

        // Stage 2: Complete multiplication and prepare addition
        temp_mult_stage2 <= temp_mult_stage1;

        // Stage 3: Final addition
        threshold <= base_cycles_stage1 + temp_mult_stage2;
    end

endmodule

module refresh_counter(
    input clk,
    input [31:0] threshold,
    output reg [31:0] counter_out,
    output reg refresh_pulse
);

    reg [31:0] counter_stage1;
    reg [31:0] counter_stage2;
    reg [31:0] threshold_stage1;
    reg [31:0] threshold_stage2;
    reg compare_result_stage1;
    reg compare_result_stage2;

    always @(posedge clk) begin
        // Stage 1: Register inputs and start comparison
        counter_stage1 <= counter_stage2;
        threshold_stage1 <= threshold;
        compare_result_stage1 <= (counter_stage2 >= threshold);

        // Stage 2: Complete comparison and prepare counter update
        counter_stage2 <= compare_result_stage2 ? 32'd0 : (counter_stage1 + 1);
        threshold_stage2 <= threshold_stage1;
        compare_result_stage2 <= compare_result_stage1;

        // Stage 3: Generate outputs
        counter_out <= counter_stage2;
        refresh_pulse <= compare_result_stage2;
    end

endmodule

module refresh_req_gen(
    input clk,
    input refresh_pulse,
    output reg refresh_req
);

    reg refresh_pulse_stage1;
    reg refresh_pulse_stage2;

    always @(posedge clk) begin
        // Two-stage pipeline for refresh request generation
        refresh_pulse_stage1 <= refresh_pulse;
        refresh_pulse_stage2 <= refresh_pulse_stage1;
        refresh_req <= refresh_pulse_stage2;
    end

endmodule