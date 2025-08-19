//SystemVerilog
module auto_calibration_recovery (
    input wire clk,
    input wire reset_n,
    input wire init_calib,
    input wire [9:0] signal_in,
    input wire [9:0] ref_level,
    output wire [9:0] calibrated_out,
    output wire calib_done
);

    // Pipeline stage 0 registers
    reg [9:0] signal_in_stage0;
    reg [9:0] ref_level_stage0;
    reg init_calib_stage0;
    reg valid_stage0;

    // Pipeline stage 1 registers
    reg [9:0] offset_stage1;
    reg [9:0] signal_in_stage1;
    reg valid_stage1;

    // Pipeline stage 2 registers
    reg [9:0] calibrated_out_stage2;
    reg calib_done_stage2;
    reg valid_stage2;

    // Pipeline control
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_stage0 <= 1'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // Stage 0: Input sampling
            signal_in_stage0 <= signal_in;
            ref_level_stage0 <= ref_level;
            init_calib_stage0 <= init_calib;
            valid_stage0 <= ~init_calib;

            // Stage 1: Offset calculation
            case ({init_calib_stage0, valid_stage0})
                2'b00: begin
                    valid_stage1 <= 1'b0;
                end
                2'b01: begin
                    offset_stage1 <= ref_level_stage0 - signal_in_stage0;
                    signal_in_stage1 <= signal_in_stage0;
                    valid_stage1 <= valid_stage0;
                end
                default: begin
                    valid_stage1 <= 1'b0;
                end
            endcase

            // Stage 2: Calibration and output
            case ({init_calib_stage0, valid_stage1})
                2'b00: begin
                    valid_stage2 <= 1'b0;
                end
                2'b01: begin
                    calibrated_out_stage2 <= signal_in_stage1 + offset_stage1;
                    calib_done_stage2 <= 1'b1;
                    valid_stage2 <= valid_stage1;
                end
                default: begin
                    valid_stage2 <= 1'b0;
                end
            endcase
        end
    end

    // Output assignments
    assign calibrated_out = calibrated_out_stage2;
    assign calib_done = calib_done_stage2;

endmodule