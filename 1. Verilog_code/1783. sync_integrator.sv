module sync_integrator #(
    parameter DATA_W = 16,
    parameter ACC_W = 24
)(
    input clk, rst, clear_acc,
    input [DATA_W-1:0] in_data,
    output reg [ACC_W-1:0] out_data
);
    // Integrator with leak factor (15/16)
    always @(posedge clk) begin
        if (rst | clear_acc) begin
            out_data <= 0;
        end else begin
            // Leaky integrator: y[n] = x[n] + a*y[n-1]
            out_data <= in_data + ((out_data * 15) >> 4);
        end
    end
endmodule