//SystemVerilog
module decoder_delay #(parameter STAGES=2) (
    input clk,
    input addr_valid,
    input [7:0] addr,
    output wire select
);

reg [STAGES-1:0] valid_chain;
reg [7:0] addr_chain [0:STAGES-1];
wire [7:0] target_addr = 8'hA5;
wire [7:0] addr_xor = addr_chain[STAGES-1] ^ target_addr;
wire addr_match = ~|addr_xor;

always @(posedge clk) begin
    valid_chain <= {valid_chain[STAGES-2:0], addr_valid};
    addr_chain[0] <= addr;
    for(int i=1; i<STAGES; i=i+1)
        addr_chain[i] <= addr_chain[i-1];
end

assign select = addr_match && valid_chain[STAGES-1];

endmodule