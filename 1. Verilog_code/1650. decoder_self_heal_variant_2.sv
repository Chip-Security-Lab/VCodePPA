//SystemVerilog
module decoder_self_heal #(MAX_ERRORS=3) (
    input clk, rst_n,
    input [7:0] addr,
    output reg select,
    output reg [1:0] err_cnt
);

// Pipeline stage 1: Address validation
reg [7:0] addr_reg;
reg addr_in_range_reg;
wire addr_in_range = (addr[7:4] == 4'hA);

// Pipeline stage 2: Address comparison and error counting
reg [7:0] last_valid_addr;
wire addr_match = (addr_reg == last_valid_addr);
reg [1:0] err_cnt_next;

// Pipeline stage 1 logic
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_reg <= 8'h00;
        addr_in_range_reg <= 1'b0;
    end else begin
        addr_reg <= addr;
        addr_in_range_reg <= addr_in_range;
    end
end

// Pipeline stage 2 logic
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        select <= 1'b0;
        err_cnt <= 2'b00;
        last_valid_addr <= 8'h00;
    end else begin
        if(addr_in_range_reg) begin
            select <= 1'b1;
            err_cnt <= 2'b00;
            last_valid_addr <= addr_reg;
        end else begin
            select <= addr_match;
            err_cnt <= (err_cnt == MAX_ERRORS) ? 2'b00 : err_cnt + 1'b1;
        end
    end
end

endmodule