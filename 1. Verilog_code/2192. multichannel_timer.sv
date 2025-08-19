module multichannel_timer #(
    parameter CHANNELS = 4,
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire [CHANNELS-1:0] channel_en,
    input wire [DATA_WIDTH-1:0] timeout_values [CHANNELS-1:0],
    output reg [CHANNELS-1:0] timeout_flags,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);
    reg [DATA_WIDTH-1:0] counters [CHANNELS-1:0];
    integer i;
    
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                counters[i] <= {DATA_WIDTH{1'b0}};
                timeout_flags <= {CHANNELS{1'b0}};
            end
            active_channel <= {$clog2(CHANNELS){1'b0}};
        end else begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (channel_en[i]) begin
                    if (counters[i] >= timeout_values[i]) begin
                        counters[i] <= {DATA_WIDTH{1'b0}};
                        timeout_flags[i] <= 1'b1;
                        active_channel <= i;
                    end else begin
                        counters[i] <= counters[i] + 1'b1;
                        timeout_flags[i] <= 1'b0;
                    end
                end
            end
        end
    end
endmodule