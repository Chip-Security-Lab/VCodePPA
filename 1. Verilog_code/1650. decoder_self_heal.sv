module decoder_self_heal #(MAX_ERRORS=3) (
    input clk, rst_n,
    input [7:0] addr,
    output reg select,
    output reg [1:0] err_cnt
);
reg [7:0] last_valid_addr;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        select <= 0;
        err_cnt <= 0;
        last_valid_addr <= 0;
    end else begin
        if(addr[7:4] == 4'hA) begin
            select <= 1;
            err_cnt <= 0;
            last_valid_addr <= addr;
        end else begin
            select <= (addr == last_valid_addr);  // 错误恢复机制
            err_cnt <= (err_cnt == MAX_ERRORS) ? 0 : err_cnt + 1;
        end
    end
end
endmodule