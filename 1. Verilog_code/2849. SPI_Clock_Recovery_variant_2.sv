//SystemVerilog
module SPI_Clock_Recovery #(
    parameter OVERSAMPLE = 8
)(
    input  wire        async_clk,
    input  wire        sdi,
    input  wire        rst_n,
    output reg         recovered_clk,
    output reg  [7:0]  data_out
);

// Stage 1: Sampling input
reg [2:0] sample_window_stage1;
reg       valid_stage1;

// Stage 2: Edge Detection
reg       edge_detected_stage2;
reg [2:0] sample_window_stage2;
reg       valid_stage2;

// Stage 3: Digital PLL (Edge Counting and Clock Recovery)
reg [3:0] edge_cnt_stage3;
reg       recovered_clk_stage3;
reg       edge_detected_stage3;
reg [2:0] sample_window_stage3;
reg       valid_stage3;

// Stage 4: Shift Register (Data Recovery)
reg [7:0] shift_reg_stage4;
reg       recovered_clk_stage4;
reg [2:0] sample_window_stage4;
reg       valid_stage4;

// Stage 5: Output Register (moved backward)
reg [7:0] data_out_stage5;
reg       valid_stage5;

// Output pipeline registers (moved backward)
reg [7:0] data_out_pipeline;
reg       valid_pipeline;

// Pipeline registers and valid propagation with retimed output registers

// Retimed output pipeline registers (inserted before output assignment)
always @(posedge async_clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out_pipeline <= 8'h00;
        valid_pipeline    <= 1'b0;
    end else begin
        data_out_pipeline <= shift_reg_stage4;
        valid_pipeline    <= valid_stage4;
    end
end

// Stage 1: Sampling input
always @(posedge async_clk or negedge rst_n) begin
    if (!rst_n) begin
        sample_window_stage1    <= 3'b000;
        valid_stage1            <= 1'b0;
    end else begin
        sample_window_stage1    <= {sample_window_stage1[1:0], sdi};
        valid_stage1            <= 1'b1;
    end
end

// Stage 2: Edge Detection
always @(posedge async_clk or negedge rst_n) begin
    if (!rst_n) begin
        sample_window_stage2    <= 3'b000;
        edge_detected_stage2    <= 1'b0;
        valid_stage2            <= 1'b0;
    end else begin
        sample_window_stage2    <= sample_window_stage1;
        edge_detected_stage2    <= sample_window_stage1[2] ^ sample_window_stage1[1];
        valid_stage2            <= valid_stage1;
    end
end

// Stage 3: Digital PLL (Edge Counting and Clock Recovery)
always @(posedge async_clk or negedge rst_n) begin
    if (!rst_n) begin
        edge_cnt_stage3         <= 4'h0;
        recovered_clk_stage3    <= 1'b0;
        edge_detected_stage3    <= 1'b0;
        sample_window_stage3    <= 3'b000;
        valid_stage3            <= 1'b0;
    end else begin
        edge_detected_stage3    <= edge_detected_stage2;
        sample_window_stage3    <= sample_window_stage2;
        valid_stage3            <= valid_stage2;
        if (edge_detected_stage2) begin
            edge_cnt_stage3      <= OVERSAMPLE / 2;
            recovered_clk_stage3 <= 1'b0;
        end else if (edge_cnt_stage3 == OVERSAMPLE-1) begin
            recovered_clk_stage3 <= 1'b1;
            edge_cnt_stage3      <= 4'h0;
        end else begin
            edge_cnt_stage3      <= edge_cnt_stage3 + 1'b1;
            recovered_clk_stage3 <= (edge_cnt_stage3 < OVERSAMPLE/2);
        end
    end
end

// Stage 4: Shift Register (Data Recovery)
always @(posedge async_clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg_stage4        <= 8'h00;
        recovered_clk_stage4    <= 1'b0;
        sample_window_stage4    <= 3'b000;
        valid_stage4            <= 1'b0;
    end else begin
        recovered_clk_stage4    <= recovered_clk_stage3;
        sample_window_stage4    <= sample_window_stage3;
        valid_stage4            <= valid_stage3;
        if (recovered_clk_stage3) begin
            shift_reg_stage4    <= {shift_reg_stage4[6:0], sample_window_stage3[2]};
        end
    end
end

// Stage 5: Output Register (removed, replaced by data_out_pipeline)

// Output assignments (registers moved backward)
always @(posedge async_clk or negedge rst_n) begin
    if (!rst_n) begin
        recovered_clk           <= 1'b0;
        data_out                <= 8'h00;
    end else begin
        recovered_clk           <= recovered_clk_stage3;
        data_out                <= data_out_pipeline;
    end
end

endmodule