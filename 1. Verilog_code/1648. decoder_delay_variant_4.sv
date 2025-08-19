//SystemVerilog
module decoder_delay #(parameter STAGES=2) (
    input wire clk,
    input wire addr_valid,
    input wire [7:0] addr,
    output wire select
);

// Pipeline registers
reg [STAGES-1:0] valid_pipe;
reg [7:0] addr_pipe [0:STAGES-1];

// Pipeline stage 0
always @(posedge clk) begin
    valid_pipe[0] <= addr_valid;
    addr_pipe[0] <= addr;
end

// Pipeline stages 1 to STAGES-1
genvar i;
generate
    for(i=1; i<STAGES; i=i+1) begin : pipe_stages
        always @(posedge clk) begin
            valid_pipe[i] <= valid_pipe[i-1];
            addr_pipe[i] <= addr_pipe[i-1];
        end
    end
endgenerate

// Optimized output decode logic
// Using a more efficient comparison approach
wire [7:0] target_addr = 8'hA5;
wire addr_match = (addr_pipe[STAGES-1] == target_addr);
assign select = addr_match && valid_pipe[STAGES-1];

endmodule