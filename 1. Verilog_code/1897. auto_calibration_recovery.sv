module auto_calibration_recovery (
    input wire clk,
    input wire init_calib,
    input wire [9:0] signal_in,
    input wire [9:0] ref_level,
    output reg [9:0] calibrated_out,
    output reg calib_done
);
    reg [9:0] offset;
    reg [1:0] calib_state;
    
    always @(posedge clk) begin
        if (init_calib) begin
            calib_state <= 2'b00;
            offset <= 10'h000;
            calib_done <= 1'b0;
        end else begin
            case (calib_state)
                2'b00: begin // Measure reference
                    offset <= ref_level - signal_in;
                    calib_state <= 2'b01;
                end
                2'b01: begin // Validate calibration
                    calibrated_out <= signal_in + offset;
                    calib_state <= 2'b10;
                end
                2'b10: begin // Calibration complete
                    calibrated_out <= signal_in + offset;
                    calib_done <= 1'b1;
                end
                default: calib_state <= 2'b00;
            endcase
        end
    end
endmodule