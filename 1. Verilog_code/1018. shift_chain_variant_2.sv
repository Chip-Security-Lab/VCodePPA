//SystemVerilog
module shift_chain_pipelined #(
    parameter LEN = 4,
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input                   valid_in,
    input  [WIDTH-1:0]      ser_in,
    output                  valid_out,
    output [WIDTH-1:0]      ser_out
);

wire [WIDTH-1:0]  chain_stage_wire [0:LEN-1];
wire              valid_stage_wire [0:LEN-1];

reg  [WIDTH-1:0]  chain_stage_reg  [0:LEN-1];
reg               valid_stage_reg  [0:LEN-1];

integer stage_idx;

// Stage 0: Combinational assignment for input
assign chain_stage_wire[0] = ser_in;
assign valid_stage_wire[0] = valid_in;

// Pipeline Stages: Registers after combinational logic
generate
    genvar stage;
    for (stage = 1; stage < LEN; stage = stage + 1) begin : forward_pipeline
        assign chain_stage_wire[stage] = chain_stage_reg[stage-1];
        assign valid_stage_wire[stage]  = valid_stage_reg[stage-1];
    end
endgenerate

// Registering after combinational logic (forward retiming)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (stage_idx = 0; stage_idx < LEN; stage_idx = stage_idx + 1) begin
            chain_stage_reg[stage_idx] <= {WIDTH{1'b0}};
            valid_stage_reg[stage_idx] <= 1'b0;
        end
    end else begin
        chain_stage_reg[0] <= chain_stage_wire[0];
        valid_stage_reg[0] <= valid_stage_wire[0];
        for (stage_idx = 1; stage_idx < LEN; stage_idx = stage_idx + 1) begin
            chain_stage_reg[stage_idx] <= chain_stage_wire[stage_idx];
            valid_stage_reg[stage_idx] <= valid_stage_wire[stage_idx];
        end
    end
end

assign ser_out  = chain_stage_reg[LEN-1];
assign valid_out = valid_stage_reg[LEN-1];

endmodule