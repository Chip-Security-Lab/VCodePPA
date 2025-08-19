module shadow_reg_ring #(parameter DW=8, DEPTH=4) (
    input clk, shift,
    input [DW-1:0] new_data,
    output [DW-1:0] oldest_data
);
    reg [DW-1:0] ring_reg [0:DEPTH-1];
    integer wr_ptr;
    
    initial wr_ptr = 0;
    always @(posedge clk) begin
        if(shift) begin
            ring_reg[wr_ptr] <= new_data;
            wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
        end
    end
    assign oldest_data = ring_reg[(wr_ptr+1)%DEPTH];
endmodule