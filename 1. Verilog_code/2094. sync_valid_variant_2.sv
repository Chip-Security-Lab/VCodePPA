//SystemVerilog
module sync_valid #(parameter DW=16, STAGES=3) (
    input clkA,
    input clkB,
    input rst,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid_out
);
    reg [STAGES-1:0] valid_sync;
    reg [DW-1:0]     data_in_reg;
    reg [DW-1:0]     data_in_pipe;
    reg              valid_sync_and;
    reg              valid_sync_and_reg;

    // Pipeline stage 1: register data_in to break long path
    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            data_in_reg <= {DW{1'b0}};
        end else begin
            data_in_reg <= data_in;
        end
    end

    // Pipeline stage 2: sync valid and register intermediate data
    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            valid_sync        <= {STAGES{1'b0}};
            data_in_pipe      <= {DW{1'b0}};
            valid_sync_and    <= 1'b0;
        end else begin
            valid_sync        <= {valid_sync[STAGES-2:0], data_in[0]};
            data_in_pipe      <= data_in_reg;
            valid_sync_and    <= &valid_sync;
        end
    end

    // Pipeline stage 3: register outputs
    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            data_out           <= {DW{1'b0}};
            valid_out          <= 1'b0;
            valid_sync_and_reg <= 1'b0;
        end else begin
            valid_sync_and_reg <= valid_sync_and;
            data_out           <= valid_sync_and ? data_in_pipe : data_out;
            valid_out          <= valid_sync_and_reg;
        end
    end

endmodule