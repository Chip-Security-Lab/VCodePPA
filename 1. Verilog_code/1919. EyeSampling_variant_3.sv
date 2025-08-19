//SystemVerilog
module EyeSampling #(
    parameter SAMPLE_OFFSET = 3
) (
    input  wire clk,
    input  wire rst_n,
    input  wire serial_in,
    input  wire valid_in,
    output reg  recovered_bit,
    output reg  valid_out
);

    // Stage 1: Shift register operation
    reg [7:0] shift_reg_stage1;
    reg       valid_stage1;
    reg       serial_in_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 8'b0;
            valid_stage1     <= 1'b0;
            serial_in_stage1 <= 1'b0;
        end else begin
            if (valid_in) begin
                shift_reg_stage1 <= {shift_reg_stage1[6:0], serial_in};
                valid_stage1     <= 1'b1;
                serial_in_stage1 <= serial_in;
            end else begin
                valid_stage1     <= 1'b0;
            end
        end
    end

    // Stage 2: Sample output and propagate valid
    reg [7:0] shift_reg_stage2;
    reg       valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 8'b0;
            valid_stage2     <= 1'b0;
        end else begin
            shift_reg_stage2 <= shift_reg_stage1;
            valid_stage2     <= valid_stage1;
        end
    end

    // Stage 3: Output recovered bit and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_bit <= 1'b0;
            valid_out     <= 1'b0;
        end else begin
            recovered_bit <= shift_reg_stage2[SAMPLE_OFFSET];
            valid_out     <= valid_stage2;
        end
    end

endmodule