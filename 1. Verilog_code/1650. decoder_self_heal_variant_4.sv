//SystemVerilog
module decoder_self_heal #(MAX_ERRORS=3) (
    input clk, rst_n,
    input [7:0] addr,
    output reg select,
    output reg [1:0] err_cnt
);

reg [7:0] last_valid_addr;
reg addr_valid;
reg addr_match;
reg [7:0] addr_buf1;
reg [7:0] addr_buf2;
reg addr_valid_buf;
reg addr_match_buf;

// Buffer stage 1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_buf1 <= 0;
        addr_valid_buf <= 0;
    end else begin
        addr_buf1 <= addr;
        addr_valid_buf <= (addr[7:4] == 4'hA);
    end
end

// Buffer stage 2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_buf2 <= 0;
        addr_match_buf <= 0;
    end else begin
        addr_buf2 <= addr_buf1;
        addr_match_buf <= (addr_buf1 == last_valid_addr);
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        select <= 0;
        err_cnt <= 0;
        last_valid_addr <= 0;
    end else begin
        if(addr_valid_buf) begin
            select <= 1;
            err_cnt <= 0;
            last_valid_addr <= addr_buf1;
        end else begin
            select <= addr_match_buf;
            err_cnt <= (err_cnt == MAX_ERRORS) ? 0 : err_cnt + 1;
        end
    end
end

endmodule