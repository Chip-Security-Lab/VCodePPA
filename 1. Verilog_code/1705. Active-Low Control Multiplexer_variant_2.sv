//SystemVerilog
module active_low_mux(
    input wire clk,
    input wire rst_n,
    input [23:0] src_a,
    input [23:0] src_b,
    input sel_n,
    input en_n,
    output reg [23:0] dest
);

    // Combined selection and enable logic in single pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dest <= 24'h0;
        end else begin
            dest <= (!en_n) ? ((!sel_n) ? src_a : src_b) : 24'h0;
        end
    end

endmodule