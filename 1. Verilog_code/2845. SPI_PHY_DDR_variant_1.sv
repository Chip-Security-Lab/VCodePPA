//SystemVerilog
module SPI_PHY_DDR #(
    parameter DELAY_STEPS = 16
)(
    input wire clk, 
    input wire rst,
    input wire calibration_en,
    input wire [3:0] delay_set,
    output reg delay_locked,
    // DDR interface
    input wire ddr_clk,
    inout wire [3:0] ddr_data,
    // Control interface
    input wire [31:0] tx_data,
    output wire [31:0] rx_data
);

// Internal registers
reg [7:0] delay_line_reg [0:3];
reg [3:0] training_pattern_reg;
reg [15:0] calibration_cnt_reg;
reg [31:0] rx_data_internal_reg;

// Buffered (high fanout) signals
reg [3:0] delay_set_buf1, delay_set_buf2;
reg [7:0] delay_line_buf1 [0:3], delay_line_buf2 [0:3];
reg [15:0] calibration_cnt_buf1, calibration_cnt_buf2;
reg [31:0] rx_data_internal_buf1, rx_data_internal_buf2;
reg [3:0] training_pattern_buf1;
reg [3:0] h00_buf1, h00_buf2;

// h00 signal is referenced as 8'h00 in delay_line logic, buffer 4'b0000 as h00 for code clarity
wire [3:0] h00 = 4'b0000;

// Register initializations
initial begin
    delay_locked = 1'b0;
    calibration_cnt_reg = 16'h0000;
    training_pattern_reg = 4'b1010;
    rx_data_internal_reg = 32'h00000000;
end

// Buffering delay_set for fanout reduction
always @(posedge clk) begin
    delay_set_buf1 <= delay_set;
    delay_set_buf2 <= delay_set_buf1;
    h00_buf1 <= h00;
    h00_buf2 <= h00_buf1;
end

// Buffering calibration_cnt for fanout reduction
always @(posedge clk) begin
    calibration_cnt_buf1 <= calibration_cnt_reg;
    calibration_cnt_buf2 <= calibration_cnt_buf1;
end

// Buffering rx_data_internal for fanout reduction
always @(posedge clk) begin
    rx_data_internal_buf1 <= rx_data_internal_reg;
    rx_data_internal_buf2 <= rx_data_internal_buf1;
end

// Buffering delay_line for fanout reduction
genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : delay_line_buffering
        always @(posedge clk) begin
            delay_line_buf1[i] <= delay_line_reg[i];
            delay_line_buf2[i] <= delay_line_buf1[i];
        end
    end
endgenerate

// Buffering training_pattern for potential high fanout
always @(posedge clk) begin
    training_pattern_buf1 <= training_pattern_reg;
end

// Delay line reset logic
always @(posedge clk) begin
    if (rst) begin
        delay_line_reg[0] <= 8'h00;
        delay_line_reg[1] <= 8'h00;
        delay_line_reg[2] <= 8'h00;
        delay_line_reg[3] <= 8'h00;
    end
end

// Delay line calibration logic with buffered delay_set
always @(posedge clk) begin
    if (!rst && calibration_en) begin
        case(delay_set_buf2)
            4'd0: begin
                delay_line_reg[0] <= {h00_buf2, 4'b0000};
                delay_line_reg[1] <= {h00_buf2, 4'b0000};
                delay_line_reg[2] <= {h00_buf2, 4'b0000};
                delay_line_reg[3] <= {h00_buf2, 4'b0000};
            end
            4'd15: begin
                delay_line_reg[0] <= 8'hFF;
                delay_line_reg[1] <= 8'hFF;
                delay_line_reg[2] <= 8'hFF;
                delay_line_reg[3] <= 8'hFF;
            end
            default: begin
                delay_line_reg[0] <= {delay_set_buf2, 4'b0000};
                delay_line_reg[1] <= {delay_set_buf2, 4'b0000};
                delay_line_reg[2] <= {delay_set_buf2, 4'b0000};
                delay_line_reg[3] <= {delay_set_buf2, 4'b0000};
            end
        endcase
    end
end

// DDR data capture on rising edge, buffer output
always @(posedge ddr_clk) begin
    rx_data_internal_reg[31:24] <= ddr_data;
end

// DDR data capture on falling edge, buffer output
always @(negedge ddr_clk) begin
    rx_data_internal_reg[23:16] <= ddr_data;
end

// Calibration counter logic, buffer output
always @(posedge clk) begin
    if (rst) begin
        calibration_cnt_reg <= 16'h0000;
    end else if (calibration_en) begin
        calibration_cnt_reg <= calibration_cnt_reg + 1'b1;
    end
end

// Delay locked logic with buffered calibration_cnt and rx_data_internal
always @(posedge clk) begin
    if (rst) begin
        delay_locked <= 1'b0;
    end else if (calibration_en && calibration_cnt_buf2[15]) begin
        delay_locked <= (rx_data_internal_buf2[7:0] == training_pattern_buf1);
    end
end

assign rx_data = rx_data_internal_buf2;

endmodule