//SystemVerilog
module data_en_sync #(parameter DW=8) (
    input  wire             src_clk,
    input  wire             dst_clk,
    input  wire             rst,
    input  wire [DW-1:0]    data,
    input  wire             data_en,
    output reg  [DW-1:0]    synced_data
);

    // Internal signals
    reg [DW-1:0] data_latch;
    reg          data_en_srcclk_d;
    wire         data_en_rise;
    reg [1:0]    en_sync;

    // Detect rising edge of data_en on src_clk
    always @(posedge src_clk or posedge rst) begin
        if (rst)
            data_en_srcclk_d <= 1'b0;
        else
            data_en_srcclk_d <= data_en;
    end

    assign data_en_rise = data_en & ~data_en_srcclk_d;

    // Latch data on data_en rising edge
    always @(posedge src_clk or posedge rst) begin
        if (rst)
            data_latch <= {DW{1'b0}};
        else if (data_en_rise)
            data_latch <= data;
    end

    // Synchronizer stage 1: capture data_en pulse to dst_clk domain
    reg en_pulse_stage1;
    always @(posedge dst_clk or posedge rst) begin
        if (rst)
            en_pulse_stage1 <= 1'b0;
        else
            en_pulse_stage1 <= data_en_rise;
    end

    // Synchronizer stage 2: generate synchronized pulse
    always @(posedge dst_clk or posedge rst) begin
        if (rst)
            en_sync <= 2'b00;
        else
            en_sync <= {en_sync[0], en_pulse_stage1};
    end

    // Output data when enable pulse is detected in destination clock domain
    always @(posedge dst_clk or posedge rst) begin
        if (rst)
            synced_data <= {DW{1'b0}};
        else if (en_sync[1])
            synced_data <= data_latch;
    end

endmodule