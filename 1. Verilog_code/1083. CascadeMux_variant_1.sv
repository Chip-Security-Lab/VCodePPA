//SystemVerilog

module CascadeMux #(
    parameter DW = 8
)(
    input                  clk,
    input                  rst_n,
    input      [1:0]       sel1,
    input      [1:0]       sel2,
    input      [3:0][DW-1:0] stage1,
    input      [3:0][DW-1:0] stage2,
    output reg [DW-1:0]    data_out
);

// Pipeline Stage 1: Input Selection
reg  [DW-1:0] stage1_data_p1;
reg  [DW-1:0] stage2_data_p1;
reg  [1:0]    sel1_p1;
reg  [1:0]    sel2_p1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage1_data_p1 <= {DW{1'b0}};
        stage2_data_p1 <= {DW{1'b0}};
        sel1_p1        <= 2'b00;
        sel2_p1        <= 2'b00;
    end else begin
        stage1_data_p1 <= stage1[sel1];
        stage2_data_p1 <= stage2[sel2];
        sel1_p1        <= sel1;
        sel2_p1        <= sel2;
    end
end

// Pipeline Stage 2: Subtraction (lower 4 bits)
wire [3:0] sub_result_p2;
reg  [DW-1:0] stage1_data_p2;
reg  [DW-1:0] stage2_data_p2;
reg  [1:0]    sel1_p2;

LUTSub4 lut_subtractor_inst (
    .a (stage1_data_p1[3:0]),
    .b (stage2_data_p1[3:0]),
    .diff (sub_result_p2)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage1_data_p2 <= {DW{1'b0}};
        stage2_data_p2 <= {DW{1'b0}};
        sel1_p2        <= 2'b00;
    end else begin
        stage1_data_p2 <= stage1_data_p1;
        stage2_data_p2 <= stage2_data_p1;
        sel1_p2        <= sel1_p1;
    end
end

// Pipeline Stage 3: Output Selection
wire [DW-1:0] subtract_p3;
reg  [DW-1:0] stage2_data_p3;
reg  [1:0]    sel1_p3;

assign subtract_p3 = { {(DW-4){1'b0}}, sub_result_p2 };

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage2_data_p3 <= {DW{1'b0}};
        sel1_p3        <= 2'b00;
        data_out       <= {DW{1'b0}};
    end else begin
        stage2_data_p3 <= stage2_data_p2;
        sel1_p3        <= sel1_p2;
        // Output selection based on sel1[0]
        if (sel1_p3[0])
            data_out <= stage2_data_p3;
        else
            data_out <= subtract_p3;
    end
end

endmodule

// 4-bit LUT-based Subtractor Module
module LUTSub4 (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] diff
);

reg [3:0] lut_diff [0:15][0:15];

integer i, j;
initial begin
    for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
            lut_diff[i][j] = i - j;
        end
    end
end

assign diff = lut_diff[a][b];

endmodule