//SystemVerilog
module group_shifter(
    input clk,
    input reset,
    input [31:0] data_in,
    input [1:0] group_count,      // Number of 4-bit groups to shift
    input dir,                    // 1:left, 0:right
    output reg [31:0] data_out
);
    wire [4:0] bit_shift_amt;
    assign bit_shift_amt = {group_count, 2'b00};  // Multiply by 4

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 32'h0;
        end else begin
            case (dir)
                1'b1: data_out <= data_in << bit_shift_amt;
                1'b0: data_out <= data_in >> bit_shift_amt;
                default: data_out <= 32'h0;
            endcase
        end
    end
endmodule