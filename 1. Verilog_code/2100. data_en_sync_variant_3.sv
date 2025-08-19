//SystemVerilog
module data_en_sync #(parameter DW=8) (
    input  wire              src_clk,
    input  wire              dst_clk,
    input  wire              rst,
    input  wire [DW-1:0]     data,
    input  wire              data_en,
    output reg  [DW-1:0]     synced_data
);

    // Stage 1: Latch data and data_en in src_clk domain
    reg [DW-1:0] data_stage1;
    reg          data_en_stage1;

    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            data_stage1     <= {DW{1'b0}};
            data_en_stage1  <= 1'b0;
        end else begin
            if (data_en) begin
                data_stage1 <= data;
            end
            data_en_stage1 <= data_en;
        end
    end

    // Stage 2: Synchronize data_en to dst_clk domain (2-stage sync)
    reg data_en_sync_stage2;
    reg data_en_sync_stage3;

    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            data_en_sync_stage2 <= 1'b0;
            data_en_sync_stage3 <= 1'b0;
        end else begin
            data_en_sync_stage2 <= data_en_stage1;
            data_en_sync_stage3 <= data_en_sync_stage2;
        end
    end

    // Stage 3: Detect rising edge of synchronized data_en (valid signal)
    reg valid_stage3;

    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= data_en_sync_stage2 & ~data_en_sync_stage3;
        end
    end

    // Stage 4: Latch data from src_clk domain to dst_clk domain via pipeline register
    reg [DW-1:0] data_stage4;
    reg          valid_stage4;

    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            data_stage4  <= {DW{1'b0}};
            valid_stage4 <= 1'b0;
        end else begin
            data_stage4  <= data_stage1;
            valid_stage4 <= valid_stage3;
        end
    end

    // Stage 5: Output register with valid signal (synced_data)
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            synced_data <= {DW{1'b0}};
        end else if (valid_stage4) begin
            synced_data <= data_stage4;
        end
    end

endmodule