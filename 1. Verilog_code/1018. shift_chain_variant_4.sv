//SystemVerilog
// Top-level shift_chain_pipelined module with hierarchical pipeline structure
module shift_chain_pipelined #(parameter LEN=4, WIDTH=8) (
    input clk,
    input rst_n,
    input start,
    input [WIDTH-1:0] ser_in,
    output [WIDTH-1:0] ser_out,
    output valid_out
);

    // Internal pipeline registers and valid flags
    reg [WIDTH-1:0] data_stage [0:LEN];
    reg valid_stage [0:LEN];

    integer i;

    // Synchronous pipeline register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <= LEN; i = i + 1) begin
                data_stage[i] <= {WIDTH{1'b0}};
                valid_stage[i] <= 1'b0;
            end
        end else begin
            // Stage 0: input registration
            data_stage[0] <= ser_in;
            valid_stage[0] <= start;

            // Pipeline stages
            for (i = 1; i <= LEN; i = i + 1) begin
                data_stage[i] <= data_stage[i-1];
                valid_stage[i] <= valid_stage[i-1];
            end
        end
    end

    assign ser_out = data_stage[LEN];
    assign valid_out = valid_stage[LEN];

endmodule