//SystemVerilog
module shift_parity_checker_pipelined (
    input clk,
    input rst_n,
    input serial_in,
    input valid_in,
    output reg valid_out,
    output reg parity
);

// Reduced pipeline stages (from 4 to 2)
reg [7:0] shift_reg_stage1;
reg [7:0] shift_reg_stage2;

// Valid signals for each stage
reg valid_stage1;
reg valid_stage2;

// Parity calculation for each stage
reg parity_stage1;
reg parity_stage2;

// Stage 1: Shift register and parity calculation
// Combines original stages 1 & 2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg_stage1 <= 8'b0;
        valid_stage1 <= 1'b0;
        parity_stage1 <= 1'b0;
    end else begin
        shift_reg_stage1 <= {shift_reg_stage1[6:0], serial_in};
        valid_stage1 <= valid_in;
        parity_stage1 <= ^{shift_reg_stage1[6:0], serial_in};
    end
end

// Stage 2: Final parity calculation and output
// Combines original stages 3 & 4
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg_stage2 <= 8'b0;
        valid_stage2 <= 1'b0;
        parity_stage2 <= 1'b0;
        valid_out <= 1'b0;
        parity <= 1'b0;
    end else begin
        shift_reg_stage2 <= shift_reg_stage1;
        valid_stage2 <= valid_stage1;
        parity_stage2 <= parity_stage1;
        valid_out <= valid_stage2;
        parity <= parity_stage2;
    end
end

endmodule