//SystemVerilog
module SPI_PHY_DDR #(
    parameter DELAY_STEPS = 16
)(
    input clk, rst,
    input calibration_en,
    input [3:0] delay_set,
    output reg delay_locked,
    // DDR interface
    input ddr_clk,
    inout [3:0] ddr_data,
    // Control interface
    input [31:0] tx_data,
    output [31:0] rx_data
);

// Delay line control moved after combination logic (forward register retiming)
reg [7:0] delay_line_next [0:3];
reg [7:0] delay_line [0:3];

reg [3:0] training_pattern;
reg [15:0] calibration_cnt;
reg [31:0] rx_data_internal;
reg [31:0] rx_data_internal_next;

reg calibration_cnt_enable;
reg delay_locked_next;

// Initialize registers
initial begin
    delay_locked = 0;
    calibration_cnt = 0;
    training_pattern = 4'b1010;
    rx_data_internal = 0;
end

// Combinational logic for delay line setup (forward retiming)
always @* begin
    delay_line_next[0] = delay_line[0];
    delay_line_next[1] = delay_line[1];
    delay_line_next[2] = delay_line[2];
    delay_line_next[3] = delay_line[3];
    if(rst) begin
        delay_line_next[0] = 8'h00;
        delay_line_next[1] = 8'h00;
        delay_line_next[2] = 8'h00;
        delay_line_next[3] = 8'h00;
    end else if(calibration_en) begin
        case(delay_set)
        0: begin
            delay_line_next[0] = 8'h00;
            delay_line_next[1] = 8'h00;
            delay_line_next[2] = 8'h00;
            delay_line_next[3] = 8'h00;
        end
        15: begin
            delay_line_next[0] = 8'hFF;
            delay_line_next[1] = 8'hFF;
            delay_line_next[2] = 8'hFF;
            delay_line_next[3] = 8'hFF;
        end
        default: begin
            delay_line_next[0] = {delay_set, 4'b0};
            delay_line_next[1] = {delay_set, 4'b0};
            delay_line_next[2] = {delay_set, 4'b0};
            delay_line_next[3] = {delay_set, 4'b0};
        end
        endcase
    end
end

// Delay unit control registers (after combinational logic)
always @(posedge clk) begin
    delay_line[0] <= delay_line_next[0];
    delay_line[1] <= delay_line_next[1];
    delay_line[2] <= delay_line_next[2];
    delay_line[3] <= delay_line_next[3];
end

// DDR sampling logic
always @(posedge ddr_clk) begin
    rx_data_internal[31:24] <= ddr_data;
end

always @(negedge ddr_clk) begin
    rx_data_internal[23:16] <= ddr_data;
end

assign rx_data = rx_data_internal;

// Calibration combinational logic (forward retiming)
always @* begin
    calibration_cnt_enable = 1'b0;
    delay_locked_next = delay_locked;
    rx_data_internal_next = rx_data_internal;
    if(rst) begin
        calibration_cnt_enable = 1'b0;
        delay_locked_next = 1'b0;
    end else if(calibration_en) begin
        calibration_cnt_enable = 1'b1;
        if(calibration_cnt[15]) begin
            delay_locked_next = (rx_data_internal[7:0] == training_pattern);
        end
    end
end

// Calibration state machine registers (after combinational logic)
always @(posedge clk) begin
    if(rst) begin
        calibration_cnt <= 16'h0000;
        delay_locked <= 1'b0;
    end else begin
        if(calibration_cnt_enable)
            calibration_cnt <= calibration_cnt + 1'b1;
        delay_locked <= delay_locked_next;
    end
end

endmodule