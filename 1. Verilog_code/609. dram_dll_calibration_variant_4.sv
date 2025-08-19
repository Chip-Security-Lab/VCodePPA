//SystemVerilog
module dram_dll_calibration #(
    parameter CAL_CYCLES = 128
)(
    input clk,
    input rst_n,
    input calibrate,
    output reg dll_locked
);

    // Pipeline stage 1: Counter increment
    reg [15:0] cal_counter_stage1;
    reg calibrate_stage1;
    
    // Pipeline stage 2: Comparison and lock generation
    reg [15:0] cal_counter_stage2;
    reg calibrate_stage2;
    reg dll_locked_stage2;

    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;

    // Stage 1: Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cal_counter_stage1 <= 16'd0;
            calibrate_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            cal_counter_stage1 <= calibrate ? cal_counter_stage1 + 1 : 16'd0;
            calibrate_stage1 <= calibrate;
            valid_stage1 <= calibrate;
        end
    end

    // Stage 2: Lock generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cal_counter_stage2 <= 16'd0;
            calibrate_stage2 <= 1'b0;
            dll_locked_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            cal_counter_stage2 <= cal_counter_stage1;
            calibrate_stage2 <= calibrate_stage1;
            dll_locked_stage2 <= calibrate_stage1 ? (cal_counter_stage1 == CAL_CYCLES) : 1'b0;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dll_locked <= 1'b0;
        end else begin
            dll_locked <= valid_stage2 ? dll_locked_stage2 : 1'b0;
        end
    end

endmodule