module async_rst_sync #(parameter CH=2) (
    input clk, async_rst,
    input [CH-1:0] ch_in,
    output [CH-1:0] ch_out
);
    reg [CH-1:0] sync0, sync1;
    
    always @(posedge clk or posedge async_rst) begin
        if(async_rst) begin
            sync0 <= {CH{1'b0}};
            sync1 <= {CH{1'b0}};
        end else begin
            sync0 <= ch_in;
            sync1 <= sync0;
        end
    end
    
    assign ch_out = sync1;
endmodule