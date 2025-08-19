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
            for (i=1; i<DEPTH; i=i+1)
                fifo[i] <= fifo[i-1];
        end
    end
endmodule