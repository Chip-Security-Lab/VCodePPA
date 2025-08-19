//SystemVerilog
module triple_flop_sync_pipeline #(parameter DW = 16) (
    input wire                  dest_clock,
    input wire                  reset,
    input wire                  enable,
    input wire  [DW-1:0]        async_data,
    input wire                  valid_in,
    input wire                  flush,
    output reg  [DW-1:0]        sync_data,
    output reg                  valid_out
);

    // Stage 1 registers
    reg [DW-1:0] async_data_stage1;
    reg          valid_stage1;

    // Stage 2 registers
    reg [DW-1:0] async_data_stage2;
    reg          valid_stage2;

    // Stage 3 registers
    reg [DW-1:0] async_data_stage3;
    reg          valid_stage3;

    // Stage 1
    always @(posedge dest_clock) begin
        if (reset || flush) begin
            async_data_stage1 <= {DW{1'b0}};
            valid_stage1      <= 1'b0;
        end else if (enable) begin
            async_data_stage1 <= async_data;
            valid_stage1      <= valid_in;
        end
    end

    // Stage 2
    always @(posedge dest_clock) begin
        if (reset || flush) begin
            async_data_stage2 <= {DW{1'b0}};
            valid_stage2      <= 1'b0;
        end else if (enable) begin
            async_data_stage2 <= async_data_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Stage 3
    always @(posedge dest_clock) begin
        if (reset || flush) begin
            async_data_stage3 <= {DW{1'b0}};
            valid_stage3      <= 1'b0;
        end else if (enable) begin
            async_data_stage3 <= async_data_stage2;
            valid_stage3      <= valid_stage2;
        end
    end

    // Output stage
    always @(posedge dest_clock) begin
        if (reset || flush) begin
            sync_data  <= {DW{1'b0}};
            valid_out  <= 1'b0;
        end else if (enable) begin
            sync_data  <= async_data_stage3;
            valid_out  <= valid_stage3;
        end
    end

endmodule