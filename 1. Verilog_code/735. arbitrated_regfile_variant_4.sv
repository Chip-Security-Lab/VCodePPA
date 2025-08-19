//SystemVerilog
module arbitrated_regfile #(
    parameter DATA_W = 8,
    parameter ADDR_W = 2,
    parameter PRIORITY = 2
)(
    input clk,
    input wr0_en, wr1_en, wr2_en,
    input [ADDR_W-1:0] wr_addr [0:2],
    input [DATA_W-1:0] wr_data [0:2],
    output conflict
);

    // Register declarations
    reg [DATA_W-1:0] regs [0:(1<<ADDR_W)-1];
    reg [1:0] grant;
    
    // Buffer registers
    reg wr0_en_buf1, wr0_en_buf2;
    reg wr1_en_buf1, wr1_en_buf2;
    reg wr2_en_buf1, wr2_en_buf2;
    
    reg [ADDR_W-1:0] wr_addr0_buf1, wr_addr0_buf2;
    reg [ADDR_W-1:0] wr_addr1_buf1, wr_addr1_buf2;
    reg [ADDR_W-1:0] wr_addr2_buf1, wr_addr2_buf2;

    // Combinational logic
    wire [2:0] requests = {wr2_en, wr1_en, wr0_en};
    wire [2:0] requests_buf = {wr2_en_buf1, wr1_en_buf1, wr0_en_buf1};
    wire [1:0] next_grant;
    wire conflict_0_1 = wr0_en_buf2 & wr1_en_buf2 & (wr_addr0_buf2 == wr_addr1_buf2);
    wire conflict_0_2 = wr0_en_buf2 & wr2_en_buf2 & (wr_addr0_buf2 == wr_addr2_buf2);
    wire conflict_1_2 = wr1_en_buf2 & wr2_en_buf2 & (wr_addr1_buf2 == wr_addr2_buf2);

    // Grant logic - combinational
    assign next_grant = (PRIORITY == 0) ? ((grant == 2) ? 0 : grant + 1) :
                       (PRIORITY == 1) ? 0 :
                       (PRIORITY == 2) ? 1 : 2;

    // Conflict detection - combinational
    assign conflict = conflict_0_1 | conflict_0_2 | conflict_1_2;

    // Sequential logic - First stage buffer
    always @(posedge clk) begin
        wr0_en_buf1 <= wr0_en;
        wr1_en_buf1 <= wr1_en;
        wr2_en_buf1 <= wr2_en;
        wr_addr0_buf1 <= wr_addr[0];
        wr_addr1_buf1 <= wr_addr[1];
        wr_addr2_buf1 <= wr_addr[2];
    end

    // Sequential logic - Second stage buffer
    always @(posedge clk) begin
        wr0_en_buf2 <= wr0_en_buf1;
        wr1_en_buf2 <= wr1_en_buf1;
        wr2_en_buf2 <= wr2_en_buf1;
        wr_addr0_buf2 <= wr_addr0_buf1;
        wr_addr1_buf2 <= wr_addr1_buf1;
        wr_addr2_buf2 <= wr_addr2_buf1;
    end

    // Sequential logic - Grant and write
    always @(posedge clk) begin
        grant <= next_grant;
        
        if (|requests_buf) begin
            case(grant)
                0: regs[wr_addr0_buf2] <= wr_data[0];
                1: regs[wr_addr1_buf2] <= wr_data[1];
                2: regs[wr_addr2_buf2] <= wr_data[2];
            endcase
        end
    end

endmodule