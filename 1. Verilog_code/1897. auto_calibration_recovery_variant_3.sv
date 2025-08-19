//SystemVerilog
module auto_calibration_recovery (
    input wire clk,
    input wire init_calib,
    input wire [9:0] signal_in,
    input wire [9:0] ref_level,
    output reg [9:0] calibrated_out,
    output reg calib_done
);
    reg [9:0] offset_stage1, offset_stage2, offset_stage3;
    reg [9:0] signal_in_stage1, signal_in_stage2;
    reg [9:0] ref_level_stage1;
    reg [1:0] calib_state_stage1, calib_state_stage2;
    reg [9:0] calibrated_out_pre;
    reg calib_done_pre;
    
    always @(posedge clk) begin
        // Pipeline stage 1
        if (init_calib) begin
            calib_state_stage1 <= 2'b00;
            offset_stage1 <= 10'h000;
            calib_done_pre <= 1'b0;
        end else begin
            signal_in_stage1 <= signal_in;
            ref_level_stage1 <= ref_level;
            calib_state_stage1 <= calib_state_stage1;
            
            case (calib_state_stage1)
                2'b00: begin // Measure reference
                    offset_stage1 <= ref_level - signal_in;
                    calib_state_stage1 <= 2'b01;
                end
                default: calib_state_stage1 <= calib_state_stage1;
            endcase
        end
        
        // Pipeline stage 2
        signal_in_stage2 <= signal_in_stage1;
        offset_stage2 <= offset_stage1;
        calib_state_stage2 <= calib_state_stage1;
        
        // Pre-compute calibrated output
        calibrated_out_pre <= signal_in_stage1 + offset_stage1;
        
        // Pre-compute calib_done
        case (calib_state_stage1)
            2'b10: calib_done_pre <= 1'b1;
            default: calib_done_pre <= 1'b0;
        endcase
        
        // Pipeline stage 3 (output)
        calibrated_out <= calibrated_out_pre;
        calib_done <= calib_done_pre;
    end
endmodule