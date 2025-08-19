//SystemVerilog
module decoder_delay #(parameter STAGES=4) (
    input clk,
    input addr_valid,
    input [7:0] addr,
    output wire select
);

reg [STAGES-1:0] valid_chain;
reg [7:0] addr_chain [0:STAGES-1];
reg [1:0] addr_match [0:STAGES-1];
integer i;

always @(posedge clk) begin
    // Stage 1: Input registration
    valid_chain[0] <= addr_valid;
    addr_chain[0] <= addr;
    
    if (addr == 8'hA5) begin
        addr_match[0] <= 2'b01;
    end else begin
        addr_match[0] <= 2'b00;
    end

    // Stage 2: First pipeline stage
    valid_chain[1] <= valid_chain[0];
    addr_chain[1] <= addr_chain[0];
    addr_match[1] <= addr_match[0];

    // Stage 3: Second pipeline stage
    valid_chain[2] <= valid_chain[1];
    addr_chain[2] <= addr_chain[1];
    addr_match[2] <= addr_match[1];

    // Stage 4: Final pipeline stage
    valid_chain[3] <= valid_chain[2];
    addr_chain[3] <= addr_chain[2];
    addr_match[3] <= addr_match[2];
end

assign select = (addr_match[STAGES-1] == 2'b01) && valid_chain[STAGES-1];
endmodule