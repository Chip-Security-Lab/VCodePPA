//SystemVerilog
module PulseFilter #(parameter TIMEOUT=8) (
    input clk, rst,
    input in_pulse,
    output reg out_pulse
);
    // Pipeline stage registers
    reg [3:0] cnt_stage1, cnt_stage2;
    reg in_pulse_stage1;
    reg pulse_detected_stage1, pulse_detected_stage2;
    reg counting_stage1, counting_stage2;
    
    // Pre-compute decrement value to reduce critical path
    wire [3:0] cnt_dec = (cnt_stage2 > 0) ? cnt_stage2 - 1'b1 : 4'b0;
    wire counting_next = (cnt_dec > 0) || in_pulse;
    
    // Stage 1: Pulse detection and counter initialization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_pulse_stage1 <= 0;
            pulse_detected_stage1 <= 0;
            counting_stage1 <= 0;
            cnt_stage1 <= 0;
        end else begin
            in_pulse_stage1 <= in_pulse;
            pulse_detected_stage1 <= in_pulse;
            counting_stage1 <= counting_next;
            cnt_stage1 <= in_pulse ? TIMEOUT : cnt_dec;
        end
    end
    
    // Stage 2: Counter processing and output generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pulse_detected_stage2 <= 0;
            counting_stage2 <= 0;
            cnt_stage2 <= 0;
            out_pulse <= 0;
        end else begin
            pulse_detected_stage2 <= pulse_detected_stage1;
            counting_stage2 <= counting_stage1;
            cnt_stage2 <= cnt_stage1;
            out_pulse <= counting_stage1;
        end
    end
endmodule