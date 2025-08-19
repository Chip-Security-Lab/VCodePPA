//SystemVerilog
module rotate_carry_pipeline #(parameter W=8) (
    input clk,
    input rst_n,
    input start,
    input dir,
    input [W-1:0] din,
    output reg [W-1:0] dout,
    output reg carry,
    output reg valid_out
);

reg [W-1:0] rotated_data_stage1;
reg carry_bit_stage1;
reg valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rotated_data_stage1 <= {W{1'b0}};
        carry_bit_stage1 <= 1'b0;
        valid_stage1 <= 1'b0;
        dout <= {W{1'b0}};
        carry <= 1'b0;
        valid_out <= 1'b0;
    end else begin
        // Stage 1: Input capture and rotate/carry logic
        if (start) begin
            if (dir) begin
                carry_bit_stage1 <= din[W-1];
                rotated_data_stage1 <= {din[W-2:0], din[W-1]};
            end else begin
                carry_bit_stage1 <= din[0];
                rotated_data_stage1 <= {din[0], din[W-1:1]};
            end
            valid_stage1 <= 1'b1;
        end else begin
            carry_bit_stage1 <= carry_bit_stage1;
            rotated_data_stage1 <= rotated_data_stage1;
            valid_stage1 <= 1'b0;
        end

        // Stage 2: Output register stage
        dout <= rotated_data_stage1;
        carry <= carry_bit_stage1;
        valid_out <= valid_stage1;
    end
end

endmodule