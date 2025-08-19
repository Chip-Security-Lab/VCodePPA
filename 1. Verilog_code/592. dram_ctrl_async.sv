module dram_ctrl_async #(
    parameter BANK_ADDR_WIDTH = 3,
    parameter ROW_ADDR_WIDTH = 13,
    parameter COL_ADDR_WIDTH = 10
)(
    input clk,
    input async_req,
    output reg ack,
    inout [15:0] dram_dq
);
    // 地址多路复用控制
    reg ras_n, cas_n, we_n;
    reg [BANK_ADDR_WIDTH-1:0] bank_addr;
    
    // 组合逻辑接口控制
    always @(*) begin
        if(async_req && !ack) begin
            ras_n = 0;
            cas_n = 1;
            we_n = 1;
        end
        else begin
            ras_n = 1;
            cas_n = 1;
            we_n = 1;
        end
    end
    
    // 时序控制单元
    always @(posedge clk) begin
        ack <= async_req;
    end
endmodule
