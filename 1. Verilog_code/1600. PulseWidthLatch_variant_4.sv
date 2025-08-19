//SystemVerilog
module PulseWidthLatch (
    input clk,
    input rst_n,
    input pulse,
    output reg [15:0] width_count
);

// Input sampling
reg pulse_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pulse_stage1 <= 1'b0;
    else
        pulse_stage1 <= pulse;
end

// Edge detection
reg last_pulse_stage1;
wire rising_edge_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        last_pulse_stage1 <= 1'b0;
    else
        last_pulse_stage1 <= pulse_stage1;
end
assign rising_edge_stage1 = pulse_stage1 && !last_pulse_stage1;

// Width count register
reg [15:0] width_count_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        width_count_stage1 <= 16'd0;
    else
        width_count_stage1 <= width_count;
end

// Counter logic
reg [15:0] width_count_stage2;
reg valid_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        width_count_stage2 <= 16'd0;
        valid_stage2 <= 1'b0;
    end else begin
        valid_stage2 <= 1'b1;
        if (rising_edge_stage1)
            width_count_stage2 <= 16'd0;
        else if (pulse_stage1)
            width_count_stage2 <= width_count_stage1 + 1'b1;
    end
end

// Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        width_count <= 16'd0;
    else if (valid_stage2)
        width_count <= width_count_stage2;
end

endmodule