//SystemVerilog
module crc8_generator #(
    parameter POLY = 8'h07 // CRC-8 polynomial x^8 + x^2 + x + 1
)(
    input              clk,
    input              rst,
    input              enable,
    input              data_in,
    input              init,     // Initialization signal
    output     [7:0]   crc_out,
    output             valid_out
);

    // Stage 1: Compute feedback and shift (move registers after combinational logic)
    wire        feedback_stage1_w;
    wire [7:0]  crc_shifted_stage1_w;
    wire [7:0]  crc_reg_stage1_w;
    wire        valid_stage1_w;
    reg  [7:0]  crc_reg_stage2;
    reg         feedback_stage2;
    reg         valid_stage2;
    reg  [7:0]  crc_shifted_stage2;

    // Stage 2: Conditional XOR with POLY (register after combinational logic)
    reg  [7:0]  crc_reg_stage3;
    reg         valid_stage3;

    // Output register
    reg  [7:0]  crc_reg_out;
    reg         valid_out_reg;

    // Combinational logic for Stage 1 (replaces previous input-side registers)
    assign crc_reg_stage1_w     = crc_reg_out;
    assign feedback_stage1_w    = crc_reg_out[7] ^ data_in;
    assign crc_shifted_stage1_w = {crc_reg_out[6:0], 1'b0};
    assign valid_stage1_w       = enable;

    // Pipeline Stage 2: Register feedback and shifted CRC after combinational logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_shifted_stage2  <= 8'h00;
            feedback_stage2     <= 1'b0;
            valid_stage2        <= 1'b0;
        end else if (init) begin
            crc_shifted_stage2  <= 8'h00;
            feedback_stage2     <= 1'b0;
            valid_stage2        <= 1'b0;
        end else if (valid_stage1_w) begin
            feedback_stage2     <= feedback_stage1_w;
            crc_shifted_stage2  <= crc_shifted_stage1_w;
            valid_stage2        <= 1'b1;
        end else begin
            valid_stage2        <= 1'b0;
        end
    end

    // Pipeline Stage 3: Conditionally XOR with POLY
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_reg_stage3  <= 8'h00;
            valid_stage3    <= 1'b0;
        end else if (init) begin
            crc_reg_stage3  <= 8'h00;
            valid_stage3    <= 1'b0;
        end else if (valid_stage2) begin
            if (feedback_stage2)
                crc_reg_stage3 <= crc_shifted_stage2 ^ POLY;
            else
                crc_reg_stage3 <= crc_shifted_stage2;
            valid_stage3    <= 1'b1;
        end else begin
            valid_stage3    <= 1'b0;
        end
    end

    // Output Register: Hold the current CRC value
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_reg_out     <= 8'h00;
            valid_out_reg   <= 1'b0;
        end else if (init) begin
            crc_reg_out     <= 8'h00;
            valid_out_reg   <= 1'b0;
        end else if (valid_stage3) begin
            crc_reg_out     <= crc_reg_stage3;
            valid_out_reg   <= 1'b1;
        end else begin
            valid_out_reg   <= 1'b0;
        end
    end

    assign crc_out   = crc_reg_out;
    assign valid_out = valid_out_reg;

endmodule