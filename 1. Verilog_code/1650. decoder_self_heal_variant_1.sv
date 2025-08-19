//SystemVerilog
module decoder_self_heal #(MAX_ERRORS=3) (
    input clk, rst_n,
    input [7:0] addr,
    output reg select,
    output reg [1:0] err_cnt
);

// Pipeline stage 1 registers
reg [7:0] addr_stage1;
reg addr_valid_stage1;

// Pipeline stage 2 registers  
reg [7:0] last_valid_addr;
reg [7:0] addr_stage2;
reg addr_valid_stage2;
reg addr_match_stage2;

// Pipeline stage 3 registers
reg select_stage3;
reg [1:0] err_cnt_stage3;

// Stage 1: Address validation
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_stage1 <= 0;
        addr_valid_stage1 <= 0;
    end else begin
        addr_stage1 <= addr;
        addr_valid_stage1 <= 1;
    end
end

// Stage 2: Address comparison and error counting
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_stage2 <= 0;
        addr_valid_stage2 <= 0;
        addr_match_stage2 <= 0;
    end else begin
        addr_stage2 <= addr_stage1;
        addr_valid_stage2 <= addr_valid_stage1;
        addr_match_stage2 <= (addr_stage1 == last_valid_addr);
    end
end

// Stage 3: Output generation
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        select <= 0;
        err_cnt <= 0;
        last_valid_addr <= 0;
        select_stage3 <= 0;
        err_cnt_stage3 <= 0;
    end else begin
        if(addr_stage2[7:4] == 4'hA) begin
            select <= 1;
            err_cnt <= 0;
            last_valid_addr <= addr_stage2;
            select_stage3 <= 1;
            err_cnt_stage3 <= 0;
        end else begin
            select <= addr_match_stage2;
            err_cnt <= (err_cnt_stage3 == MAX_ERRORS) ? 0 : err_cnt_stage3 + 1;
            select_stage3 <= addr_match_stage2;
            err_cnt_stage3 <= (err_cnt_stage3 == MAX_ERRORS) ? 0 : err_cnt_stage3 + 1;
        end
    end
end

endmodule