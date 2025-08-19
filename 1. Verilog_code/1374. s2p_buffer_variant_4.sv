//SystemVerilog
module s2p_buffer (
    input wire clk,
    input wire serial_in,
    input wire shift,
    input wire clear,
    output reg [7:0] parallel_out
);
    reg serial_in_reg;
    
    always @(posedge clk) begin
        serial_in_reg <= serial_in;
    end
    
    always @(posedge clk) begin
        if (clear)
            parallel_out <= 8'b0;
        else if (shift)
            parallel_out <= {parallel_out[6:0], serial_in_reg};
    end
endmodule