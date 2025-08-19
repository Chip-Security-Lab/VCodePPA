module lfsr_waveform(
    input i_clk,
    input i_rst,
    input i_enable,
    output [7:0] o_random
);
    reg [15:0] lfsr;
    wire feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    
    always @(posedge i_clk) begin
        if (i_rst)
            lfsr <= 16'hACE1;
        else if (i_enable)
            lfsr <= {lfsr[14:0], feedback};
    end
    
    assign o_random = lfsr[7:0];
endmodule