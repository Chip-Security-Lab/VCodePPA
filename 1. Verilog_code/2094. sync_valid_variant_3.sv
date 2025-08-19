//SystemVerilog
module sync_valid_pipeline #(parameter DW=16, STAGES=3) (
    input wire                  clkA,
    input wire                  clkB,
    input wire                  rst,
    input wire  [DW-1:0]        data_in,
    output wire [DW-1:0]        data_out,
    output wire                 valid_out
);

    // Stage 1: Capture incoming data and valid
    reg [DW-1:0]                data_stage1;
    reg                         valid_stage1;

    // Stage 2: Synchronizer shift register for valid signal
    reg [STAGES-1:0]            valid_sync_stage2;
    reg [DW-1:0]                data_stage2;

    // Stage 3: Output stage
    reg [DW-1:0]                data_stage3;
    reg                         valid_stage3;

    // Pipeline flush logic
    wire                        pipeline_flush;
    assign pipeline_flush = rst;

    // Stage 1: Latch input data and valid
    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            data_stage1    <= {DW{1'b0}};
            valid_stage1   <= 1'b0;
        end else begin
            data_stage1    <= data_in;
            valid_stage1   <= 1'b1; // Assume data_in is always valid
        end
    end

    // Stage 2: Synchronize the valid signal and register data
    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            valid_sync_stage2 <= {STAGES{1'b0}};
            data_stage2       <= {DW{1'b0}};
        end else begin
            valid_sync_stage2 <= {valid_sync_stage2[STAGES-2:0], valid_stage1};
            data_stage2       <= data_stage1;
        end
    end

    // Stage 3: Output valid data when synchronizer chain is full
    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            data_stage3    <= {DW{1'b0}};
            valid_stage3   <= 1'b0;
        end else begin
            if (&valid_sync_stage2) begin
                data_stage3  <= data_stage2;
                valid_stage3 <= 1'b1;
            end else begin
                data_stage3  <= {DW{1'b0}};
                valid_stage3 <= 1'b0;
            end
        end
    end

    assign data_out  = data_stage3;
    assign valid_out = valid_stage3;

endmodule