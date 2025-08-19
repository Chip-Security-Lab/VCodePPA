//SystemVerilog
module SPI_PHY_DDR #(
    parameter DELAY_STEPS = 16
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         calibration_en,
    input  wire [3:0]   delay_set,
    output wire         delay_locked,
    // DDR interface
    input  wire         ddr_clk,
    inout  wire [3:0]   ddr_data,
    // Control interface
    input  wire [31:0]  tx_data,
    output wire [31:0]  rx_data
);

    // -------------------------
    // Stage 1: Delay Unit Control
    // -------------------------
    wire [7:0] delay_line_stage1 [0:3];
    wire [3:0] training_pattern_stage1;
    wire [15:0] calibration_cnt_stage1;
    wire        calibration_en_stage1;
    wire [3:0]  delay_set_stage1;
    wire        rst_stage1;
    wire        valid_stage1;

    DelayUnitControl #(
        .WIDTH(4)
    ) u_delay_unit_control (
        .clk(clk),
        .rst(rst),
        .calibration_en(calibration_en),
        .delay_set(delay_set),
        .delay_line(delay_line_stage1),
        .training_pattern(training_pattern_stage1),
        .calibration_cnt(calibration_cnt_stage1),
        .calibration_en_out(calibration_en_stage1),
        .delay_set_out(delay_set_stage1),
        .rst_out(rst_stage1),
        .valid_out(valid_stage1)
    );

    // -------------------------
    // Stage 2: DDR Sampling and Pipeline Register
    // -------------------------
    wire [7:0] delay_line_stage2 [0:3];
    wire [3:0] training_pattern_stage2;
    wire [15:0] calibration_cnt_stage2;
    wire        calibration_en_stage2;
    wire        rst_stage2;
    wire        valid_stage2;
    wire [31:0] rx_data_internal_stage2;

    PipelineRegister #(
        .DELAY_WIDTH(8),
        .NUM_DELAYS(4),
        .TRAIN_WIDTH(4),
        .CAL_CNT_WIDTH(16),
        .VALID_WIDTH(1),
        .DATA_WIDTH(32)
    ) u_pipeline_reg_stage2 (
        .clk(clk),
        .rst_in(rst_stage1),
        .valid_in(valid_stage1),
        .delay_line_in(delay_line_stage1),
        .training_pattern_in(training_pattern_stage1),
        .calibration_cnt_in(calibration_cnt_stage1),
        .calibration_en_in(calibration_en_stage1),
        .rst_out(rst_stage2),
        .valid_out(valid_stage2),
        .delay_line_out(delay_line_stage2),
        .training_pattern_out(training_pattern_stage2),
        .calibration_cnt_out(calibration_cnt_stage2),
        .calibration_en_out(calibration_en_stage2),
        .data_in(rx_data_internal_ddr),
        .data_out(rx_data_internal_stage2)
    );

    // DDR sampling logic
    wire [31:0] rx_data_internal_ddr;

    DDRSampler #(
        .WIDTH(4)
    ) u_ddr_sampler (
        .ddr_clk(ddr_clk),
        .ddr_data(ddr_data),
        .rx_data_ddr(rx_data_internal_ddr)
    );

    // -------------------------
    // Stage 3: Calibration State Machine & Output
    // -------------------------
    wire [3:0]  training_pattern_stage3;
    wire [15:0] calibration_cnt_stage3;
    wire        calibration_en_stage3;
    wire        rst_stage3;
    wire        delay_locked_stage3;
    wire        valid_stage3;
    wire [31:0] rx_data_internal_stage3;

    PipelineRegister #(
        .DELAY_WIDTH(8),
        .NUM_DELAYS(0),
        .TRAIN_WIDTH(4),
        .CAL_CNT_WIDTH(16),
        .VALID_WIDTH(1),
        .DATA_WIDTH(32)
    ) u_pipeline_reg_stage3 (
        .clk(clk),
        .rst_in(rst_stage2),
        .valid_in(valid_stage2),
        .delay_line_in(), // No delay line needed for this stage
        .training_pattern_in(training_pattern_stage2),
        .calibration_cnt_in(calibration_cnt_stage2),
        .calibration_en_in(calibration_en_stage2),
        .rst_out(rst_stage3),
        .valid_out(valid_stage3),
        .delay_line_out(), // No delay line output
        .training_pattern_out(training_pattern_stage3),
        .calibration_cnt_out(calibration_cnt_stage3),
        .calibration_en_out(calibration_en_stage3),
        .data_in(rx_data_internal_stage2),
        .data_out(rx_data_internal_stage3)
    );

    CalibrationLogic #(
        .TRAIN_WIDTH(4),
        .CAL_CNT_WIDTH(16),
        .DATA_WIDTH(32)
    ) u_calibration_logic (
        .clk(clk),
        .rst(rst_stage3),
        .valid(valid_stage3),
        .training_pattern(training_pattern_stage3),
        .calibration_cnt(calibration_cnt_stage3),
        .calibration_en(calibration_en_stage3),
        .rx_data_internal(rx_data_internal_stage3),
        .delay_locked(delay_locked_stage3)
    );

    assign rx_data = rx_data_internal_stage3;
    assign delay_locked = delay_locked_stage3;

endmodule

// --------------------------------------------------
// Delay Unit Control Module
// --------------------------------------------------
module DelayUnitControl #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             calibration_en,
    input  wire [WIDTH-1:0] delay_set,
    output reg  [7:0]       delay_line [0:WIDTH-1],
    output reg  [WIDTH-1:0] training_pattern,
    output reg  [15:0]      calibration_cnt,
    output reg              calibration_en_out,
    output reg  [WIDTH-1:0] delay_set_out,
    output reg              rst_out,
    output reg              valid_out
);

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for(i=0;i<WIDTH;i=i+1)
                delay_line[i] <= 8'h00;
            training_pattern <= 4'b1010;
            calibration_cnt  <= 16'h0000;
            calibration_en_out <= 1'b0;
            delay_set_out      <= {WIDTH{1'b0}};
            rst_out            <= 1'b1;
        end else begin
            rst_out            <= 1'b0;
            calibration_en_out <= calibration_en;
            delay_set_out      <= delay_set;
            training_pattern   <= 4'b1010;
            if(calibration_en) begin
                case(delay_set)
                    4'd0: begin
                        for(i=0;i<WIDTH;i=i+1)
                            delay_line[i] <= 8'h00;
                    end
                    4'd15: begin
                        for(i=0;i<WIDTH;i=i+1)
                            delay_line[i] <= 8'hFF;
                    end
                    default: begin
                        for(i=0;i<WIDTH;i=i+1)
                            delay_line[i] <= {delay_set, 4'b0};
                    end
                endcase
            end
            if(calibration_en) begin
                calibration_cnt <= calibration_cnt + 1'b1;
            end else begin
                calibration_cnt <= 16'h0000;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) 
            valid_out <= 1'b0;
        else
            valid_out <= 1'b1;
    end

endmodule

// --------------------------------------------------
// Pipeline Register Module (Generic)
// --------------------------------------------------
module PipelineRegister #(
    parameter DELAY_WIDTH = 8,
    parameter NUM_DELAYS  = 4,
    parameter TRAIN_WIDTH = 4,
    parameter CAL_CNT_WIDTH = 16,
    parameter VALID_WIDTH = 1,
    parameter DATA_WIDTH  = 32
)(
    input  wire                      clk,
    input  wire                      rst_in,
    input  wire                      valid_in,
    input  wire [DELAY_WIDTH-1:0]    delay_line_in [0:NUM_DELAYS-1],
    input  wire [TRAIN_WIDTH-1:0]    training_pattern_in,
    input  wire [CAL_CNT_WIDTH-1:0]  calibration_cnt_in,
    input  wire                      calibration_en_in,
    output reg                       rst_out,
    output reg                       valid_out,
    output reg  [DELAY_WIDTH-1:0]    delay_line_out [0:NUM_DELAYS-1],
    output reg  [TRAIN_WIDTH-1:0]    training_pattern_out,
    output reg  [CAL_CNT_WIDTH-1:0]  calibration_cnt_out,
    output reg                       calibration_en_out,
    input  wire [DATA_WIDTH-1:0]     data_in,
    output reg  [DATA_WIDTH-1:0]     data_out
);

    integer i;

    always @(posedge clk) begin
        if (rst_in) begin
            for(i=0;i<NUM_DELAYS;i=i+1)
                delay_line_out[i] <= {DELAY_WIDTH{1'b0}};
            training_pattern_out   <= {TRAIN_WIDTH{1'b0}};
            calibration_cnt_out    <= {CAL_CNT_WIDTH{1'b0}};
            calibration_en_out     <= 1'b0;
            rst_out                <= 1'b1;
            valid_out              <= 1'b0;
            data_out               <= {DATA_WIDTH{1'b0}};
        end else if (valid_in) begin
            for(i=0;i<NUM_DELAYS;i=i+1)
                delay_line_out[i] <= delay_line_in[i];
            training_pattern_out   <= training_pattern_in;
            calibration_cnt_out    <= calibration_cnt_in;
            calibration_en_out     <= calibration_en_in;
            rst_out                <= rst_in;
            valid_out              <= valid_in;
            data_out               <= data_in;
        end
    end

endmodule

// --------------------------------------------------
// DDR Sampler Module
// --------------------------------------------------
module DDRSampler #(
    parameter WIDTH = 4
)(
    input  wire         ddr_clk,
    inout  wire [WIDTH-1:0] ddr_data,
    output reg  [31:0]  rx_data_ddr
);

    always @(posedge ddr_clk) begin
        rx_data_ddr[31:24] <= ddr_data;
    end

    always @(negedge ddr_clk) begin
        rx_data_ddr[23:16] <= ddr_data;
    end

    // The rest of rx_data_ddr[15:0] are left as zeros (or can be expanded as needed).

endmodule

// --------------------------------------------------
// Calibration Logic Module
// --------------------------------------------------
module CalibrationLogic #(
    parameter TRAIN_WIDTH = 4,
    parameter CAL_CNT_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     valid,
    input  wire [TRAIN_WIDTH-1:0]   training_pattern,
    input  wire [CAL_CNT_WIDTH-1:0] calibration_cnt,
    input  wire                     calibration_en,
    input  wire [DATA_WIDTH-1:0]    rx_data_internal,
    output reg                      delay_locked
);

    always @(posedge clk) begin
        if (rst) begin
            delay_locked <= 1'b0;
        end else if (valid) begin
            if(calibration_en) begin
                if(calibration_cnt[CAL_CNT_WIDTH-1]) begin
                    delay_locked <= (rx_data_internal[7:0] == training_pattern);
                end else begin
                    delay_locked <= 1'b0;
                end
            end else begin
                delay_locked <= 1'b0;
            end
        end
    end

endmodule