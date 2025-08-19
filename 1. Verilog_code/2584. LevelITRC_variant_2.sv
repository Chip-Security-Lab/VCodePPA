//SystemVerilog
module ChannelController #(
    parameter TIMEOUT = 8
) (
    input clk,
    input rst,
    input level_irq,
    output reg irq_active,
    output reg [$clog2(TIMEOUT):0] timeout_counter
);
    // LUT for 8-bit subtraction
    reg [7:0] sub_lut [0:255];
    reg [7:0] next_counter;
    
    // Initialize LUT
    initial begin
        for (int i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = (i > 0) ? (i - 1) : 0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            irq_active <= 0;
            timeout_counter <= 0;
        end else begin
            if (level_irq && !irq_active) begin
                irq_active <= 1;
                timeout_counter <= TIMEOUT;
            end else if (irq_active && timeout_counter > 0) begin
                timeout_counter <= sub_lut[timeout_counter];
            end else if (irq_active) begin
                irq_active <= 0;
            end
        end
    end
endmodule

module PriorityEncoder #(
    parameter CHANNELS = 4
) (
    input [CHANNELS-1:0] irq_active,
    output reg irq_valid,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);
    always @(*) begin
        irq_valid = |irq_active;
        active_channel = 0;
        for (integer i = CHANNELS-1; i >= 0; i = i - 1) begin
            if (irq_active[i]) begin
                active_channel = i;
            end
        end
    end
endmodule

module LevelITRC #(
    parameter CHANNELS = 4,
    parameter TIMEOUT = 8
) (
    input clk,
    input rst,
    input [CHANNELS-1:0] level_irq,
    output irq_valid,
    output [$clog2(CHANNELS)-1:0] active_channel
);
    wire [CHANNELS-1:0] irq_active;
    wire [$clog2(TIMEOUT):0] timeout_counter [0:CHANNELS-1];

    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin : channel_instances
            ChannelController #(
                .TIMEOUT(TIMEOUT)
            ) channel_controller (
                .clk(clk),
                .rst(rst),
                .level_irq(level_irq[i]),
                .irq_active(irq_active[i]),
                .timeout_counter(timeout_counter[i])
            );
        end
    endgenerate

    PriorityEncoder #(
        .CHANNELS(CHANNELS)
    ) priority_encoder (
        .irq_active(irq_active),
        .irq_valid(irq_valid),
        .active_channel(active_channel)
    );
endmodule