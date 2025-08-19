module AXIStreamBridge #(
    parameter TDATA_W = 32
)(
    input clk, rst_n,
    input [TDATA_W-1:0] tdata,
    input tvalid, tlast,
    output reg tready
);
    reg [1:0] state;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            tready <= 0;
            state <= 0;
        end else case(state)
            0: if (tvalid) begin
                tready <= 1;
                state <= 1;
            end
            1: if (tlast) begin
                tready <= 0;
                state <= 0;
            end
        endcase
    end
endmodule