//SystemVerilog
module fifo_parity #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input clk, wr_en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH:0] fifo [0:DEPTH-1]
);
    wire parity_bit = ^data_in;
    integer i;
    
    always @(posedge clk) begin
        if (wr_en) begin
            fifo[0] <= {parity_bit, data_in};
            i = 1;
            while (i < DEPTH) begin
                fifo[i] <= fifo[i-1];
                i = i + 1;
            end
        end
    end
endmodule