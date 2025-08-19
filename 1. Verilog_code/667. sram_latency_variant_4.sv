//SystemVerilog
module sram_latency #(
    parameter DW = 8,
    parameter AW = 4,
    parameter LATENCY = 3
)(
    input clk,
    input ce,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

// Memory array
reg [DW-1:0] mem [0:(1<<AW)-1];

// Pipeline registers with enable
reg [DW-1:0] pipe_reg [0:LATENCY-1];
reg [LATENCY-1:0] pipe_valid;

// Memory read data
wire [DW-1:0] mem_rd_data;

// Memory write logic
always @(posedge clk) begin
    if (ce && we) begin
        mem[addr] <= din;
    end
end

// Memory read logic
assign mem_rd_data = mem[addr];

// Pipeline stage 0 with valid bit
always @(posedge clk) begin
    if (ce) begin
        pipe_reg[0] <= mem_rd_data;
        pipe_valid[0] <= 1'b1;
    end else begin
        pipe_valid[0] <= 1'b0;
    end
end

// Pipeline stages 1 to LATENCY-1 with valid bits
genvar i;
generate
    for (i=1; i<LATENCY; i=i+1) begin : pipe_stages
        always @(posedge clk) begin
            if (ce) begin
                pipe_reg[i] <= pipe_reg[i-1];
                pipe_valid[i] <= pipe_valid[i-1];
            end else begin
                pipe_valid[i] <= 1'b0;
            end
        end
    end
endgenerate

// Output assignment with valid check
assign dout = pipe_valid[LATENCY-1] ? pipe_reg[LATENCY-1] : {DW{1'b0}};

endmodule