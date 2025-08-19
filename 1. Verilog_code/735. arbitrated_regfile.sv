module arbitrated_regfile #(
    parameter DATA_W = 8,
    parameter ADDR_W = 2,
    parameter PRIORITY = 2  // 0-RR, 1-WR0, 2-WR1
)(
    input clk,
    input wr0_en, wr1_en, wr2_en,
    input [ADDR_W-1:0] wr_addr [0:2],
    input [DATA_W-1:0] wr_data [0:2],
    output conflict
);
reg [DATA_W-1:0] regs [0:(1<<ADDR_W)-1];
wire [2:0] requests = {wr2_en, wr1_en, wr0_en};
reg [1:0] grant;

always @(posedge clk) begin
    case(PRIORITY)
        0: grant <= (grant == 2) ? 0 : grant + 1; // Round Robin
        1: grant <= 0; // Fixed priority 0
        2: grant <= 1; // Fixed priority 1
        default: grant <= 2; // Priority 2
    endcase
    
    if (|requests) begin
        regs[wr_addr[grant]] <= wr_data[grant];
    end
end

assign conflict = ( (wr0_en & wr1_en & (wr_addr[0] == wr_addr[1])) |
                    (wr0_en & wr2_en & (wr_addr[0] == wr_addr[2])) |
                    (wr1_en & wr2_en & (wr_addr[1] == wr_addr[2])) );
endmodule