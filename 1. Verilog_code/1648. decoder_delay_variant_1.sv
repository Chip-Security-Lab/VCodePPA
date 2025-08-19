//SystemVerilog
module decoder_delay #(parameter STAGES=2) (
    input clk,
    input addr_valid,
    input [7:0] addr,
    output wire select
);

reg [STAGES-1:0] valid_chain;
reg [7:0] addr_chain [0:STAGES-1];
reg [7:0] lut_result;
reg [7:0] addr_delayed;
reg valid_delayed;
reg [7:0] sub_result;
reg [7:0] sub_result_inv;
reg sub_borrow;

// Pipeline stage 1: Register inputs
always @(posedge clk) begin
    addr_delayed <= addr;
    valid_delayed <= addr_valid;
end

// Pipeline stage 2: Address chain and conditional inversion
always @(posedge clk) begin
    addr_chain[0] <= addr_delayed;
    for(int i=1; i<STAGES; i=i+1)
        addr_chain[i] <= addr_chain[i-1];
    
    // Conditional inversion subtraction
    sub_result_inv <= ~addr_chain[STAGES-1];
    sub_borrow <= 1'b1;
    sub_result <= sub_result_inv + 8'h5B; // 0xA5 inverted and +1
end

// Pipeline stage 3: Final comparison
always @(posedge clk) begin
    valid_chain <= {valid_chain[STAGES-2:0], valid_delayed};
    lut_result <= sub_result;
end

// Parallel comparison logic
wire [7:0] result_compare = lut_result;
wire valid_check = valid_chain[STAGES-1];
assign select = ~(|result_compare) & valid_check;

endmodule