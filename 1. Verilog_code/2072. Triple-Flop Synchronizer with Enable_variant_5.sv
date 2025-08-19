//SystemVerilog
module triple_flop_sync #(
    parameter DW = 16
)(
    input wire                   dest_clock,
    input wire                   reset,
    input wire                   enable,
    input wire [DW-1:0]          async_data,
    output reg [DW-1:0]          sync_data
);

    // Increased pipeline depth: 5-stage synchronizer
    reg [DW-1:0] async_data_stage1;
    reg [DW-1:0] async_data_stage2;
    reg [DW-1:0] async_data_stage3;
    reg [DW-1:0] async_data_stage4;
    reg [DW-1:0] async_data_stage5;

    // 8-bit LUT-based subtractor instance
    wire [7:0] lut_sub_a;
    wire [7:0] lut_sub_b;
    wire [7:0] lut_sub_diff;

    assign lut_sub_a = async_data[7:0];
    assign lut_sub_b = async_data_stage1[7:0];

    lut8_subtractor u_lut8_subtractor (
        .a(lut_sub_a),
        .b(lut_sub_b),
        .diff(lut_sub_diff)
    );

    always @(posedge dest_clock) begin
        if (reset) begin
            async_data_stage1 <= {DW{1'b0}};
            async_data_stage2 <= {DW{1'b0}};
            async_data_stage3 <= {DW{1'b0}};
            async_data_stage4 <= {DW{1'b0}};
            async_data_stage5 <= {DW{1'b0}};
            sync_data         <= {DW{1'b0}};
        end else if (enable) begin
            // Use LUT-based subtractor for lower 8 bits, pass through upper bits
            async_data_stage1[7:0]   <= lut_sub_diff;
            async_data_stage1[DW-1:8] <= async_data[DW-1:8];
            async_data_stage2 <= async_data_stage1;
            async_data_stage3 <= async_data_stage2;
            async_data_stage4 <= async_data_stage3;
            async_data_stage5 <= async_data_stage4;
            sync_data         <= async_data_stage5;
        end
    end

endmodule

// 8-bit LUT-based subtractor
module lut8_subtractor (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] diff
);
    reg [7:0] lut_sub_table [0:65535];
    wire [15:0] lut_addr;

    assign lut_addr = {a, b};

    initial begin : init_lut
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut_sub_table[{i[7:0], j[7:0]}] = i - j;
            end
        end
    end

    always @(*) begin
        diff = lut_sub_table[lut_addr];
    end
endmodule