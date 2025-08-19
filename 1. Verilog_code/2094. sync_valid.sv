module sync_valid #(parameter DW=16, STAGES=3) (
    input clkA, clkB, rst,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid_out
);
    reg [STAGES-1:0] valid_sync;
    always @(posedge clkB or posedge rst) begin
        if(rst) {valid_sync, data_out} <= 0;
        else begin
            valid_sync <= {valid_sync[STAGES-2:0], data_in[0]};
            if(&valid_sync) data_out <= data_in;
            valid_out <= &valid_sync;
        end
    end
endmodule