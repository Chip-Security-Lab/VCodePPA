module s2p_buffer (
    input wire clk,
    input wire serial_in,
    input wire shift,
    input wire clear,
    output reg [7:0] parallel_out
);
    always @(posedge clk) begin
        if (clear)
            parallel_out <= 8'b0;
        else if (shift)
            parallel_out <= {parallel_out[6:0], serial_in};
    end
endmodule