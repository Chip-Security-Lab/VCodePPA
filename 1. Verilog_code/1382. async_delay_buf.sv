module async_delay_buf #(parameter DW=8, DEPTH=3) (
    input clk, en,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    reg [DW-1:0] buf_reg [0:DEPTH];
    integer i;
    
    always @(posedge clk) if(en) begin
        buf_reg[0] <= data_in;
        for(i=0; i<DEPTH; i=i+1)
            buf_reg[i+1] <= buf_reg[i];
    end
    assign data_out = buf_reg[DEPTH];
endmodule
