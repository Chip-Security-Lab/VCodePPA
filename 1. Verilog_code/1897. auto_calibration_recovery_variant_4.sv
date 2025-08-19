//SystemVerilog
module auto_calibration_recovery (
    input wire clk,
    input wire init_calib,
    input wire [9:0] signal_in,
    input wire [9:0] ref_level,
    output reg [9:0] calibrated_out,
    output reg calib_done
);
    reg [9:0] offset_reg;
    reg [9:0] signal_in_reg;
    reg [9:0] ref_level_reg;
    wire [9:0] offset_comb = ref_level_reg - signal_in_reg;
    wire [9:0] calibrated_comb = signal_in_reg + offset_reg;
    reg [1:0] calib_state;
    
    always @(posedge clk) begin
        signal_in_reg <= signal_in;
        ref_level_reg <= ref_level;
        
        if (init_calib) begin
            calib_state <= 2'b00;
            offset_reg <= 10'h000;
            calib_done <= 1'b0;
        end else begin
            case (calib_state)
                2'b00: begin
                    offset_reg <= offset_comb;
                    calib_state <= 2'b01;
                end
                2'b01, 2'b10: begin
                    calibrated_out <= calibrated_comb;
                    calib_state <= calib_state + 1'b1;
                    calib_done <= (calib_state == 2'b01);
                end
                default: calib_state <= 2'b00;
            endcase
        end
    end
endmodule