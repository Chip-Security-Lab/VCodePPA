module multichannel_buffer (
    input wire clk,
    input wire [3:0] channel_select,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [7:0] data_out
);
    reg [7:0] channels [0:15];
    
    always @(posedge clk) begin
        if (write_en)
            channels[channel_select] <= data_in;
        data_out <= channels[channel_select];
    end
endmodule