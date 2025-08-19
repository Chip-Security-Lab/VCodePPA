//SystemVerilog
module serial_shifter(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [1:0] mode,   // 00:hold, 01:left, 10:right, 11:load
    input wire [7:0] data_in,
    input wire serial_in,
    output reg [7:0] data_out
);

// Pipeline registers and valid chain
reg [7:0] data_in_stage1;
reg serial_in_stage1;
reg [1:0] mode_stage1;
reg enable_stage1;
reg valid_stage1;

reg [7:0] data_stage2;
reg [1:0] mode_stage2;
reg serial_in_stage2;
reg enable_stage2;
reg valid_stage2;

reg [7:0] shift_result_stage3;
reg valid_stage3;
reg enable_stage3;

// Pipeline Stage 1: Register inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_stage1   <= 8'h00;
        serial_in_stage1 <= 1'b0;
        mode_stage1      <= 2'b00;
        enable_stage1    <= 1'b0;
        valid_stage1     <= 1'b0;
    end else begin
        data_in_stage1   <= data_in;
        serial_in_stage1 <= serial_in;
        mode_stage1      <= mode;
        enable_stage1    <= enable;
        valid_stage1     <= enable;
    end
end

// Pipeline Stage 2: Prepare data for shifting/loading
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage2      <= 8'h00;
        mode_stage2      <= 2'b00;
        serial_in_stage2 <= 1'b0;
        enable_stage2    <= 1'b0;
        valid_stage2     <= 1'b0;
    end else begin
        // Pass through the data from previous stage
        data_stage2      <= data_in_stage1;
        mode_stage2      <= mode_stage1;
        serial_in_stage2 <= serial_in_stage1;
        enable_stage2    <= enable_stage1;
        valid_stage2     <= valid_stage1;
    end
end

// Pipeline Stage 3: Perform shift/load operation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_result_stage3 <= 8'h00;
        valid_stage3        <= 1'b0;
        enable_stage3       <= 1'b0;
    end else begin
        case (mode_stage2)
            2'b00: shift_result_stage3 <= data_out; // hold
            2'b01: shift_result_stage3 <= {data_out[6:0], serial_in_stage2}; // left
            2'b10: shift_result_stage3 <= {serial_in_stage2, data_out[7:1]}; // right
            2'b11: shift_result_stage3 <= data_stage2; // load
            default: shift_result_stage3 <= data_out;
        endcase
        valid_stage3  <= valid_stage2;
        enable_stage3 <= enable_stage2;
    end
end

// Pipeline Output Register: data_out
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= 8'h00;
    else if (enable_stage3 && valid_stage3)
        data_out <= shift_result_stage3;
end

endmodule