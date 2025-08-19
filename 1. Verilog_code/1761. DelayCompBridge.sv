module DelayCompBridge #(
    parameter DELAY_CYC = 3
)(
    input clk, rst_n,
    input [31:0] data_in,
    output [31:0] data_out
);
    reg [31:0] delay_chain [0:DELAY_CYC-1];
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DELAY_CYC; i = i + 1) 
                delay_chain[i] <= 0;
        end else begin
            delay_chain[0] <= data_in;
            for (i = 1; i < DELAY_CYC; i = i + 1)
                delay_chain[i] <= delay_chain[i-1];
        end
    end
    assign data_out = delay_chain[DELAY_CYC-1];
endmodule