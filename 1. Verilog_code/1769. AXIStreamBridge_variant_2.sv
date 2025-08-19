//SystemVerilog
module AXIStreamBridge #(
    parameter TDATA_W = 32
)(
    input clk, rst_n,
    input [TDATA_W-1:0] tdata,
    input tvalid, tlast,
    output reg tready
);
    reg [1:0] state;
    wire state_is_idle;
    wire state_is_active;
    wire should_activate;
    wire should_deactivate;
    
    assign state_is_idle = ~|state;
    assign state_is_active = state[0];
    assign should_activate = state_is_idle & tvalid;
    assign should_deactivate = state_is_active & tlast;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            tready <= 1'b0;
            state <= 2'b00;
        end else begin
            tready <= should_activate | (state_is_active & ~should_deactivate);
            state <= {1'b0, should_activate | (state_is_active & ~should_deactivate)};
        end
    end
endmodule