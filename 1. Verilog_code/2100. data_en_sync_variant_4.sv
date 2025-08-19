//SystemVerilog
module data_en_sync #(
    parameter DW = 8
)(
    input  wire             src_clk,
    input  wire             dst_clk,
    input  wire             rst,
    input  wire [DW-1:0]    data,
    input  wire             data_en,
    output reg  [DW-1:0]    synced_data
);

    // Latch data in source clock domain when data_en is asserted
    reg [DW-1:0] data_latch;
    always @(posedge src_clk) begin
        if (data_en)
            data_latch <= data;
    end

    // Double flip-flop synchronizer for data_en into destination clock domain
    reg en_sync_ff1, en_sync_ff2;
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            en_sync_ff1 <= 1'b0;
            en_sync_ff2 <= 1'b0;
        end else begin
            en_sync_ff1 <= data_en;
            en_sync_ff2 <= en_sync_ff1;
        end
    end

    // Detect rising edge of synchronized data_en
    reg en_sync_ff2_d;
    always @(posedge dst_clk or posedge rst) begin
        if (rst)
            en_sync_ff2_d <= 1'b0;
        else
            en_sync_ff2_d <= en_sync_ff2;
    end

    wire en_pulse;
    assign en_pulse = en_sync_ff2 & ~en_sync_ff2_d;

    // Update synced_data in destination clock domain when enable pulse is detected
    always @(posedge dst_clk or posedge rst) begin
        if (rst)
            synced_data <= {DW{1'b0}};
        else if (en_pulse)
            synced_data <= data_latch;
    end

endmodule