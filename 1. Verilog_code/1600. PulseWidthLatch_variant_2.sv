//SystemVerilog
module PulseWidthLatch (
    input clk,
    input rst_n,
    input pulse,
    output reg [15:0] width_count,
    output reg valid
);

// Pipeline stages
reg [15:0] width_count_stage1;
reg [15:0] width_count_stage2;
reg pulse_stage1;
reg pulse_stage2;
reg last_pulse_stage1;
reg last_pulse_stage2;
reg valid_stage1;
reg valid_stage2;

// Stage 1: Pulse detection and initial counting
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pulse_stage1 <= 1'b0;
        last_pulse_stage1 <= 1'b0;
        width_count_stage1 <= 16'd0;
        valid_stage1 <= 1'b0;
    end else begin
        pulse_stage1 <= pulse;
        last_pulse_stage1 <= pulse_stage1;
        
        case ({pulse, last_pulse_stage1})
            2'b10: begin
                width_count_stage1 <= 16'd0;
                valid_stage1 <= 1'b1;
            end
            2'b11: begin
                width_count_stage1 <= width_count_stage1 + 16'd1;
                valid_stage1 <= 1'b1;
            end
            default: begin
                valid_stage1 <= 1'b0;
            end
        endcase
    end
end

// Stage 2: Intermediate processing
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pulse_stage2 <= 1'b0;
        last_pulse_stage2 <= 1'b0;
        width_count_stage2 <= 16'd0;
        valid_stage2 <= 1'b0;
    end else begin
        pulse_stage2 <= pulse_stage1;
        last_pulse_stage2 <= last_pulse_stage1;
        width_count_stage2 <= width_count_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Final output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        width_count <= 16'd0;
        valid <= 1'b0;
    end else begin
        width_count <= width_count_stage2;
        valid <= valid_stage2;
    end
end

endmodule