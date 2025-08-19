//SystemVerilog
module demux_async_reset (
    input wire clk,                      // Clock signal
    input wire rst_n,                    // Active-low async reset
    input wire data,                     // Input data
    input wire [2:0] channel,            // Channel selection
    output reg [7:0] out_channels        // Output channels
);

    reg data_reg;
    reg [2:0] channel_reg;
    integer i;

    // Input registers moved after input pins to optimize timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 1'b0;
            channel_reg <= 3'b0;
        end else begin
            data_reg <= data;
            channel_reg <= channel;
        end
    end

    // Output demux logic now uses registered inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_channels <= 8'b0;
        else
            for (i = 0; i < 8; i = i + 1)
                out_channels[i] <= (i == channel_reg) ? data_reg : 1'b0;
    end

endmodule