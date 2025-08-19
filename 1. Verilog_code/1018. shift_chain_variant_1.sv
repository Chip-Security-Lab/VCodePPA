//SystemVerilog
`timescale 1ns/1ps
module shift_chain #(
    parameter LEN=4,
    parameter WIDTH=8
)(
    input wire                      clk,
    input wire                      rst_n,
    input wire                      ser_in_valid,
    input wire [WIDTH-1:0]          ser_in,
    output wire                     ser_out_valid,
    output wire [WIDTH-1:0]         ser_out
);

// Pipeline registers for data and valid signal
reg [WIDTH-1:0] shift_data_stage   [0:LEN-1];
reg             valid_stage        [0:LEN-1];

integer stage_idx;

// Pipeline data movement
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (stage_idx = 0; stage_idx < LEN; stage_idx = stage_idx + 1) begin
            shift_data_stage[stage_idx] <= {WIDTH{1'b0}};
            valid_stage[stage_idx]      <= 1'b0;
        end
    end else begin
        // Stage 0: input stage
        shift_data_stage[0] <= ser_in;
        valid_stage[0]      <= ser_in_valid;

        // Propagate through pipeline
        for (stage_idx = 1; stage_idx < LEN; stage_idx = stage_idx + 1) begin
            shift_data_stage[stage_idx] <= shift_data_stage[stage_idx-1];
            valid_stage[stage_idx]      <= valid_stage[stage_idx-1];
        end
    end
end

assign ser_out      = shift_data_stage[LEN-1];
assign ser_out_valid= valid_stage[LEN-1];

endmodule