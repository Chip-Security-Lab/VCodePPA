//SystemVerilog
module decoder_self_heal #(MAX_ERRORS=3) (
    input clk, rst_n,
    input [7:0] addr,
    output reg select,
    output reg [1:0] err_cnt
);

reg [7:0] last_valid_addr;
reg addr_match;
reg addr_valid;

// Pipeline stage 1: Address validation and matching
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_valid <= 0;
        addr_match <= 0;
    end else begin
        addr_valid <= (addr[7:4] == 4'hA);
        addr_match <= (addr == last_valid_addr);
    end
end

// Pipeline stage 2: Control logic and error counting
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        select <= 0;
        err_cnt <= 0;
        last_valid_addr <= 0;
    end else begin
        if(addr_valid) begin
            select <= 1;
            err_cnt <= 0;
            last_valid_addr <= addr;
        end else begin
            select <= addr_match;
            err_cnt <= (err_cnt == MAX_ERRORS) ? 0 : err_cnt + 1;
        end
    end
end

endmodule