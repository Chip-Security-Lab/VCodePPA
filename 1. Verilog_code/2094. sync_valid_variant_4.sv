//SystemVerilog
module sync_valid #(parameter DW=16, STAGES=3) (
    input wire clkA,
    input wire clkB,
    input wire rst,
    input wire [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid_out
);
    reg [STAGES-1:0] valid_sync;
    wire valid_sync_all_high;

    assign valid_sync_all_high = (valid_sync == {STAGES{1'b1}});

    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            valid_sync <= {STAGES{1'b0}};
            data_out <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else if (valid_sync_all_high) begin
            valid_sync <= {valid_sync[STAGES-2:0], data_in[0]};
            data_out <= data_in;
            valid_out <= 1'b1;
        end else begin
            valid_sync <= {valid_sync[STAGES-2:0], data_in[0]};
            valid_out <= 1'b0;
            // data_out holds its value
        end
    end
endmodule