//SystemVerilog
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
reg [1:0] next_grant;

// Priority selection logic
always @(*) begin
    case(PRIORITY)
        0: next_grant = (grant == 2) ? 0 : grant + 1; // Round Robin
        1: next_grant = 0; // Fixed priority 0
        2: next_grant = 1; // Fixed priority 1
        default: next_grant = 2; // Priority 2
    endcase
end

// Register update logic
always @(posedge clk) begin
    grant <= next_grant;
    
    if (|requests) begin
        regs[wr_addr[grant]] <= wr_data[grant];
    end
end

// Conflict detection logic
wire conflict_01 = wr0_en & wr1_en & (wr_addr[0] == wr_addr[1]);
wire conflict_02 = wr0_en & wr2_en & (wr_addr[0] == wr_addr[2]);
wire conflict_12 = wr1_en & wr2_en & (wr_addr[1] == wr_addr[2]);

assign conflict = conflict_01 | conflict_02 | conflict_12;

endmodule