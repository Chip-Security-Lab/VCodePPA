//SystemVerilog
module AXIStreamBridge #(
    parameter TDATA_W = 32
)(
    input clk, rst_n,
    input [TDATA_W-1:0] tdata,
    input tvalid, tlast,
    output reg tready
);
    localparam IDLE = 2'b00;
    localparam ACTIVE = 2'b01;
    
    reg [1:0] state;
    reg [1:0] state_next;
    reg tready_next;
    
    // 组合逻辑
    always @(*) begin
        if (!rst_n) begin
            state_next = IDLE;
            tready_next = 1'b0;
        end else begin
            state_next = (state == IDLE && tvalid) ? ACTIVE :
                        (state == ACTIVE && tlast) ? IDLE : state;
            tready_next = (state_next == ACTIVE) && !tlast;
        end
    end
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tready <= 1'b0;
        end else begin
            state <= state_next;
            tready <= tready_next;
        end
    end
endmodule