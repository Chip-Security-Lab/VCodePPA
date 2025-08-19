module Axi2ApbBridge #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32
)(
    input clk, rst_n,
    // AXI Lite接口
    input awvalid, wvalid,
    output reg awready, wready,
    input [ADDR_W-1:0] awaddr,
    input [DATA_W-1:0] wdata,
    // APB接口
    output reg psel, penable,
    output reg pwrite,
    output reg [ADDR_W-1:0] paddr,
    output reg [DATA_W-1:0] pwdata
);
    // 定义状态常量
    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;
    reg [1:0] state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            {awready, wready} <= 2'b11;
            psel <= 0;
            penable <= 0;
            pwrite <= 0;
            paddr <= 0;
            pwdata <= 0;
        end else begin
            case(state)
                IDLE: if (awvalid && wvalid) begin
                    paddr <= awaddr;
                    pwdata <= wdata;
                    pwrite <= 1;
                    state <= SETUP;
                    {awready, wready} <= 2'b00;
                end
                SETUP: begin
                    psel <= 1;
                    state <= ACCESS;
                end
                ACCESS: begin
                    penable <= 1;
                    if (penable) begin
                        psel <= 0;
                        penable <= 0;
                        {awready, wready} <= 2'b11;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule