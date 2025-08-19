//SystemVerilog
module ChecksumMux #(parameter DW=8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [3:0][DW-1:0]    din,
    input  wire [1:0]            sel,
    input  wire                  in_valid,
    output reg  [DW+3:0]         out,
    output reg                   out_valid
);

// Stage 1: Latch select and validity
reg [1:0] sel_stage1;
reg       valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sel_stage1   <= 2'b00;
        valid_stage1 <= 1'b0;
    end else begin
        sel_stage1   <= sel;
        valid_stage1 <= in_valid;
    end
end

// Stage 2: Balanced data selection
reg [DW-1:0] data_stage2;
reg [1:0]    sel_stage2;
reg          valid_stage2;

wire [DW-1:0] din_sel_0_1 = (sel_stage1[0] == 1'b0) ? din[0] : din[1];
wire [DW-1:0] din_sel_2_3 = (sel_stage1[0] == 1'b0) ? din[2] : din[3];
wire [DW-1:0] din_mux     = (sel_stage1[1] == 1'b0) ? din_sel_0_1 : din_sel_2_3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage2  <= {DW{1'b0}};
        sel_stage2   <= 2'b00;
        valid_stage2 <= 1'b0;
    end else begin
        data_stage2  <= din_mux;
        sel_stage2   <= sel_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Data split for parity calculation (balanced)
reg [DW/2-1:0] data_lower_stage3;
reg [DW/2-1:0] data_upper_stage3;
reg [1:0]      sel_stage3;
reg            valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_lower_stage3 <= {(DW/2){1'b0}};
        data_upper_stage3 <= {(DW/2){1'b0}};
        sel_stage3        <= 2'b00;
        valid_stage3      <= 1'b0;
    end else begin
        data_lower_stage3 <= data_stage2[DW/2-1:0];
        data_upper_stage3 <= data_stage2[DW-1:DW/2];
        sel_stage3        <= sel_stage2;
        valid_stage3      <= valid_stage2;
    end
end

// Stage 4: Parity calculation and data combine (balanced)
reg parity_stage4;
reg [DW-1:0] data_stage4;
reg [1:0]    sel_stage4;
reg          valid_stage4;

// Precompute partial parities for lower and upper halves
wire parity_lower = ^data_lower_stage3;
wire parity_upper = ^data_upper_stage3;
wire parity_full  = parity_lower ^ parity_upper;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_stage4 <= 1'b0;
        data_stage4   <= {DW{1'b0}};
        sel_stage4    <= 2'b00;
        valid_stage4  <= 1'b0;
    end else begin
        parity_stage4 <= parity_full;
        data_stage4   <= {data_upper_stage3, data_lower_stage3};
        sel_stage4    <= sel_stage3;
        valid_stage4  <= valid_stage3;
    end
end

// Stage 5: Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out       <= {(DW+4){1'b0}};
        out_valid <= 1'b0;
    end else begin
        out       <= {parity_stage4, data_stage4, sel_stage4};
        out_valid <= valid_stage4;
    end
end

endmodule