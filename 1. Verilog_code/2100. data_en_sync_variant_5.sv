//SystemVerilog
module data_en_sync #(parameter DW=8) (
    input  wire              src_clk,
    input  wire              dst_clk,
    input  wire              rst,
    input  wire [DW-1:0]     data,
    input  wire              data_en,
    output reg  [DW-1:0]     synced_data
);

    reg                      en_src_reg;
    reg                      en_sync_dst_ff [1:0];
    reg [DW-1:0]             data_latch;

    // Capture data and data_en on src_clk
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            data_latch  <= {DW{1'b0}};
            en_src_reg  <= 1'b0;
        end else if (data_en) begin
            data_latch  <= data;
            en_src_reg  <= 1'b1;
        end else begin
            en_src_reg  <= 1'b0;
        end
    end

    // Efficient 2-stage synchronizer for en_src_reg to dst_clk domain
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            en_sync_dst_ff[0] <= 1'b0;
            en_sync_dst_ff[1] <= 1'b0;
        end else begin
            en_sync_dst_ff[0] <= en_src_reg;
            en_sync_dst_ff[1] <= en_sync_dst_ff[0];
        end
    end

    // Rising edge detection for en_src_reg in dst_clk domain
    wire en_sync_rising = (en_sync_dst_ff[0] & ~en_sync_dst_ff[1]);

    // Synchronized data transfer
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            synced_data <= {DW{1'b0}};
        end else if (en_sync_rising) begin
            synced_data <= data_latch;
        end
    end

endmodule