module pingpong_buf #(parameter DW=16) (
    input clk, switch,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] buf1, buf2;
    reg sel;
    
    always @(posedge clk) begin
        if(switch) begin
            dout <= sel ? buf1 : buf2;
            sel <= !sel;
        end else begin
            if(sel) buf2 <= din;
            else buf1 <= din;
        end
    end
endmodule
