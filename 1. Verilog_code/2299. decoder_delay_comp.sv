module decoder_delay_comp #(parameter STAGES=3) (
    input clk,
    input [4:0] addr,
    output [31:0] decoded
);
    reg [4:0] addr_pipe [0:STAGES-1];
    integer i;
    
    always @(posedge clk) begin
        addr_pipe[0] <= addr;
        for(i=1; i<STAGES; i=i+1)
            addr_pipe[i] <= addr_pipe[i-1];
    end
    
    assign decoded = 1'b1 << addr_pipe[STAGES-1];
endmodule