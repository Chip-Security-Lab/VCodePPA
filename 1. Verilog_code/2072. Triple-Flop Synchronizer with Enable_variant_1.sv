//SystemVerilog
module triple_flop_sync_pipeline #(parameter DW = 16) (
    input wire                  dest_clock,
    input wire                  reset,
    input wire                  enable,
    input wire  [DW-1:0]        async_data,
    output wire [DW-1:0]        sync_data,
    output wire                 sync_valid
);

    // Stage 1 registers and valid
    reg [DW-1:0] data_stage1_reg;
    reg          valid_stage1_reg;

    // Stage 2 registers and valid
    reg [DW-1:0] data_stage2_reg;
    reg          valid_stage2_reg;

    // Stage 3 registers and valid
    reg [DW-1:0] data_stage3_reg;
    reg          valid_stage3_reg;

    // Pipeline flush logic (optional external flush signal could be added)
    wire pipeline_flush = reset;

    // Stage 1: Capture input data
    always @(posedge dest_clock) begin
        if (pipeline_flush) begin
            data_stage1_reg   <= {DW{1'b0}};
            valid_stage1_reg  <= 1'b0;
        end else if (enable) begin
            data_stage1_reg   <= async_data;
            valid_stage1_reg  <= 1'b1;
        end else begin
            valid_stage1_reg  <= 1'b0;
        end
    end

    // Stage 2: Register data from stage 1
    always @(posedge dest_clock) begin
        if (pipeline_flush) begin
            data_stage2_reg   <= {DW{1'b0}};
            valid_stage2_reg  <= 1'b0;
        end else begin
            data_stage2_reg   <= data_stage1_reg;
            valid_stage2_reg  <= valid_stage1_reg;
        end
    end

    // Stage 3: Register data from stage 2
    always @(posedge dest_clock) begin
        if (pipeline_flush) begin
            data_stage3_reg   <= {DW{1'b0}};
            valid_stage3_reg  <= 1'b0;
        end else begin
            data_stage3_reg   <= data_stage2_reg;
            valid_stage3_reg  <= valid_stage2_reg;
        end
    end

    assign sync_data  = data_stage3_reg;
    assign sync_valid = valid_stage3_reg;

endmodule