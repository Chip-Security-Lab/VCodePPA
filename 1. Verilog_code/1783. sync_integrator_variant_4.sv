//SystemVerilog
module sync_integrator #(
    parameter DATA_W = 16,
    parameter ACC_W = 24
)(
    input clk, rst, clear_acc,
    input [DATA_W-1:0] in_data,
    output reg [ACC_W-1:0] out_data
);

    reg [ACC_W-1:0] acc_mult;
    reg [ACC_W-1:0] acc_shift;
    reg [ACC_W-1:0] acc_sum;

    always @(posedge clk) begin
        if (rst || clear_acc) begin
            out_data <= 0;
        end else begin
            acc_mult <= out_data * 15;
            acc_shift <= acc_mult >> 4;
            acc_sum <= in_data + acc_shift;
            out_data <= acc_sum;
        end
    end

endmodule