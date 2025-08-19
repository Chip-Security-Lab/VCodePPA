//SystemVerilog
module PulseFilter #(parameter TIMEOUT=8) (
    input clk, rst,
    input in_pulse,
    output reg out_pulse
);
    // Stage 1: Detect pulse and manage counter
    reg [3:0] cnt_stage1;
    reg pulse_detected_stage1;
    
    // Stage 2: Process counter and generate output
    reg [3:0] cnt_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Input detection and counter management
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage1 <= 4'b0;
            pulse_detected_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if (in_pulse) begin
                cnt_stage1 <= TIMEOUT;
                pulse_detected_stage1 <= 1'b1;
            end else begin
                if (cnt_stage2 > 0) begin
                    cnt_stage1 <= cnt_stage2 - 1'b1;
                end else begin
                    cnt_stage1 <= 4'b0;
                end
                
                if (cnt_stage2 != 0) begin
                    pulse_detected_stage1 <= 1'b1;
                end else begin
                    pulse_detected_stage1 <= 1'b0;
                end
            end
        end
    end
    
    // Stage 2: Output generation and counter propagation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage2 <= 4'b0;
            out_pulse <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                cnt_stage2 <= cnt_stage1;
                out_pulse <= pulse_detected_stage1;
            end
        end
    end
endmodule