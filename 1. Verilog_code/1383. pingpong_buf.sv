module pingpong_buf #(parameter DW=16) (
    input clk, rst_n, switch,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    reg [DW-1:0] buf_A, buf_B;
    reg sel;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_A <= 0;
            buf_B <= 0;
            sel <= 0;
        end
        else if (switch) sel <= ~sel;
        else if (!sel) buf_A <= din;
        else buf_B <= din;
    end
    assign dout = sel ? buf_B : buf_A;
endmodule