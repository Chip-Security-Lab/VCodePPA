//SystemVerilog
// Top-level SPI PHY DDR Hierarchical Module (Pipelined)
module SPI_PHY_DDR #(
    parameter DELAY_STEPS = 16
)(
    input clk,
    input rst,
    input calibration_en,
    input [3:0] delay_set,
    output delay_locked,
    // DDR interface
    input ddr_clk,
    inout [3:0] ddr_data,
    // Control interface
    input [31:0] tx_data,
    output [31:0] rx_data
);

    // Internal connections
    wire [7:0] delay_line_0;
    wire [7:0] delay_line_1;
    wire [7:0] delay_line_2;
    wire [7:0] delay_line_3;
    wire [15:0] calibration_cnt;
    wire [31:0] rx_data_internal;
    wire [3:0] training_pattern_internal;

    // Delay Control Unit
    SPI_PHY_DDR_delay_ctrl #(
        .DELAY_STEPS(DELAY_STEPS)
    ) u_delay_ctrl (
        .clk(clk),
        .rst(rst),
        .calibration_en(calibration_en),
        .delay_set(delay_set),
        .delay_line_0(delay_line_0),
        .delay_line_1(delay_line_1),
        .delay_line_2(delay_line_2),
        .delay_line_3(delay_line_3)
    );

    // DDR Data Sampling Unit (Pipelined)
    SPI_PHY_DDR_ddr_sample u_ddr_sample (
        .ddr_clk(ddr_clk),
        .rst(rst),
        .ddr_data(ddr_data),
        .rx_data_internal(rx_data_internal)
    );

    // Calibration Pattern Generator (Parameterizable)
    SPI_PHY_DDR_training_pattern u_training_pattern (
        .clk(clk),
        .rst(rst),
        .training_pattern(training_pattern_internal)
    );

    // Calibration Control Unit (Pipelined)
    SPI_PHY_DDR_calibration_ctrl u_calibration_ctrl (
        .clk(clk),
        .rst(rst),
        .calibration_en(calibration_en),
        .rx_data_internal(rx_data_internal),
        .training_pattern(training_pattern_internal),
        .calibration_cnt(calibration_cnt),
        .delay_locked(delay_locked)
    );

    // RX Data Output
    assign rx_data = rx_data_internal;

endmodule

//-----------------------------------------------------------------------------
// Delay Control Unit: Controls the delay line settings for the DDR PHY (Pipelined)
//-----------------------------------------------------------------------------
module SPI_PHY_DDR_delay_ctrl #(
    parameter DELAY_STEPS = 16
)(
    input clk,
    input rst,
    input calibration_en,
    input [3:0] delay_set,
    output reg [7:0] delay_line_0,
    output reg [7:0] delay_line_1,
    output reg [7:0] delay_line_2,
    output reg [7:0] delay_line_3
);

    reg [3:0] delay_set_stage1;
    reg calibration_en_stage1;
    reg [1:0] state_stage1;
    reg [7:0] delay_value_stage2;
    reg [7:0] delay_value_stage3;

    // Stage 1: Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_set_stage1 <= 4'b0;
            calibration_en_stage1 <= 1'b0;
            state_stage1 <= 2'b00;
        end else begin
            delay_set_stage1 <= delay_set;
            calibration_en_stage1 <= calibration_en;
            if (calibration_en)
                state_stage1 <= (delay_set == 4'b0000) ? 2'b01 :
                                (delay_set == 4'b1111) ? 2'b10 : 2'b11;
            else
                state_stage1 <= 2'b00;
        end
    end

    // Stage 2: Compute delay value
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_value_stage2 <= 8'h00;
        end else if (calibration_en_stage1) begin
            case (state_stage1)
                2'b01: delay_value_stage2 <= 8'h00;
                2'b10: delay_value_stage2 <= 8'hFF;
                2'b11: delay_value_stage2 <= {delay_set_stage1, 4'b0};
                default: delay_value_stage2 <= 8'h00;
            endcase
        end
    end

    // Stage 3: Output assignment
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_value_stage3 <= 8'h00;
            delay_line_0 <= 8'h00;
            delay_line_1 <= 8'h00;
            delay_line_2 <= 8'h00;
            delay_line_3 <= 8'h00;
        end else begin
            delay_value_stage3 <= delay_value_stage2;
            if (calibration_en_stage1) begin
                delay_line_0 <= delay_value_stage3;
                delay_line_1 <= delay_value_stage3;
                delay_line_2 <= delay_value_stage3;
                delay_line_3 <= delay_value_stage3;
            end
        end
    end

endmodule

//-----------------------------------------------------------------------------
// DDR Data Sampling Unit: Samples DDR data on both clock edges (Pipelined)
//-----------------------------------------------------------------------------
module SPI_PHY_DDR_ddr_sample (
    input ddr_clk,
    input rst,
    inout [3:0] ddr_data,
    output reg [31:0] rx_data_internal
);
    reg [3:0] ddr_data_stage1_pos;
    reg [3:0] ddr_data_stage2_pos;
    reg [3:0] ddr_data_stage1_neg;
    reg [3:0] ddr_data_stage2_neg;

    // Positive edge sampling (pipeline)
    always @(posedge ddr_clk or posedge rst) begin
        if (rst) begin
            ddr_data_stage1_pos <= 4'b0;
            ddr_data_stage2_pos <= 4'b0;
            rx_data_internal[31:24] <= 8'h00;
        end else begin
            ddr_data_stage1_pos <= ddr_data;
            ddr_data_stage2_pos <= ddr_data_stage1_pos;
            rx_data_internal[31:28] <= ddr_data_stage2_pos;
            rx_data_internal[27:24] <= ddr_data_stage1_pos;
        end
    end

    // Negative edge sampling (pipeline)
    always @(negedge ddr_clk or posedge rst) begin
        if (rst) begin
            ddr_data_stage1_neg <= 4'b0;
            ddr_data_stage2_neg <= 4'b0;
            rx_data_internal[23:16] <= 8'h00;
        end else begin
            ddr_data_stage1_neg <= ddr_data;
            ddr_data_stage2_neg <= ddr_data_stage1_neg;
            rx_data_internal[23:20] <= ddr_data_stage2_neg;
            rx_data_internal[19:16] <= ddr_data_stage1_neg;
        end
    end

    // Lower 16 bits remain zero for compatibility (unchanged)
    initial rx_data_internal = 32'h0;

endmodule

//-----------------------------------------------------------------------------
// Calibration Pattern Generator: Generates the training pattern used in calibration
//-----------------------------------------------------------------------------
module SPI_PHY_DDR_training_pattern (
    input clk,
    input rst,
    output reg [3:0] training_pattern
);
    reg [3:0] training_pattern_stage1;
    reg [3:0] training_pattern_stage2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            training_pattern_stage1 <= 4'b1010;
            training_pattern_stage2 <= 4'b1010;
            training_pattern <= 4'b1010;
        end else begin
            training_pattern_stage1 <= 4'b1010;
            training_pattern_stage2 <= training_pattern_stage1;
            training_pattern <= training_pattern_stage2;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Calibration Control Unit: Manages calibration sequence and delay lock detection (Pipelined)
//-----------------------------------------------------------------------------
module SPI_PHY_DDR_calibration_ctrl (
    input clk,
    input rst,
    input calibration_en,
    input [31:0] rx_data_internal,
    input [3:0] training_pattern,
    output reg [15:0] calibration_cnt,
    output reg delay_locked
);

    reg calibration_en_stage1;
    reg [31:0] rx_data_stage1;
    reg [3:0] training_pattern_stage1;
    reg [7:0] compare_data_stage2;
    reg [3:0] compare_pattern_stage2;
    reg match_stage3;
    reg [15:0] calibration_cnt_stage1;
    reg [15:0] calibration_cnt_stage2;

    // Stage 1: Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            calibration_en_stage1 <= 1'b0;
            rx_data_stage1 <= 32'b0;
            training_pattern_stage1 <= 4'b0;
            calibration_cnt_stage1 <= 16'h0000;
        end else begin
            calibration_en_stage1 <= calibration_en;
            rx_data_stage1 <= rx_data_internal;
            training_pattern_stage1 <= training_pattern;
            if (calibration_en)
                calibration_cnt_stage1 <= calibration_cnt + 1'b1;
            else
                calibration_cnt_stage1 <= calibration_cnt;
        end
    end

    // Stage 2: Prepare compare data
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            compare_data_stage2 <= 8'b0;
            compare_pattern_stage2 <= 4'b0;
            calibration_cnt_stage2 <= 16'h0000;
        end else begin
            compare_data_stage2 <= rx_data_stage1[7:0];
            compare_pattern_stage2 <= training_pattern_stage1;
            calibration_cnt_stage2 <= calibration_cnt_stage1;
        end
    end

    // Stage 3: Compare and update delay_locked
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            match_stage3 <= 1'b0;
            calibration_cnt <= 16'h0000;
            delay_locked <= 1'b0;
        end else begin
            match_stage3 <= (compare_data_stage2 == compare_pattern_stage2);
            calibration_cnt <= calibration_cnt_stage2;
            if (calibration_en_stage1 && calibration_cnt_stage2[15]) begin
                delay_locked <= match_stage3;
            end
        end
    end

endmodule