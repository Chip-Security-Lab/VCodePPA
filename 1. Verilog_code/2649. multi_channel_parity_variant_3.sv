//SystemVerilog
module multi_channel_parity #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8
)(
    input [CHANNELS*WIDTH-1:0] ch_data,
    output reg [CHANNELS-1:0] ch_parity
);
    integer i, j;
    
    always @(*) begin
        i = 0;
        while (i < CHANNELS) begin
            ch_parity[i] = 1'b0;
            
            j = 0;
            while (j < WIDTH) begin
                ch_parity[i] = ch_parity[i] ^ ch_data[i*WIDTH+j];
                j = j + 1;
            end
            
            i = i + 1;
        end
    end
endmodule