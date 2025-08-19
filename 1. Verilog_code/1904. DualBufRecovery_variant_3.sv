//SystemVerilog
module DualBufRecovery #(parameter WIDTH=8) (
    input clk, async_rst,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    // Registered input signal
    reg [WIDTH-1:0] din_reg;
    
    // Buffered copies of din_reg to distribute fanout
    reg [WIDTH-1:0] din_reg_buf1, din_reg_buf2, din_reg_buf3;
    
    // Internal buffers with combinational logic moved before them
    reg [WIDTH-1:0] buf1, buf2;
    
    // Combinational logic for output calculation
    wire [WIDTH-1:0] recovery_result;
    // Use separate buffered copies of din_reg for each term
    assign recovery_result = (din_reg_buf1 & buf1) | (din_reg_buf2 & buf2) | (buf1 & buf2);
    
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            din_reg <= 0;
            din_reg_buf1 <= 0;
            din_reg_buf2 <= 0;
            din_reg_buf3 <= 0;
            buf1 <= 0;
            buf2 <= 0;
            dout <= 0;
        end
        else begin
            din_reg <= din;
            // Create buffered copies of din_reg to distribute fanout
            din_reg_buf1 <= din_reg;
            din_reg_buf2 <= din_reg;
            din_reg_buf3 <= din_reg;
            // Use a dedicated buffer for each path
            buf1 <= din_reg_buf3;
            buf2 <= buf1;
            dout <= recovery_result;
        end
    end
endmodule