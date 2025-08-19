module dram_dll_calibration #(
    parameter CAL_CYCLES = 128
)(
    input clk,
    input calibrate,
    output reg dll_locked
);
    reg [15:0] cal_counter;
    
    always @(posedge clk) begin
        if(calibrate) begin
            cal_counter <= cal_counter + 1;
            dll_locked <= (cal_counter == CAL_CYCLES);
        end else begin
            cal_counter <= 0;
            dll_locked <= 0;
        end
    end
endmodule
