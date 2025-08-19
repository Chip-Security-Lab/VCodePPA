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
    
    // 使用借位减法器算法实现减一操作（用于RR计算）
    reg [2:0] counter;
    wire [2:0] counter_minus_one;
    wire [2:0] borrow;

    // 组合逻辑部分
    assign borrow[0] = counter[0] ? 0 : 1;
    assign borrow[1] = (counter[1] & ~borrow[0]) ? 0 : 1;
    assign borrow[2] = (counter[2] & ~borrow[1]) ? 0 : 1;

    assign counter_minus_one[0] = counter[0] ? 0 : 1;
    assign counter_minus_one[1] = counter[1] ^ borrow[0];
    assign counter_minus_one[2] = counter[2] ^ borrow[1];

    assign conflict = ( (wr0_en & wr1_en & (wr_addr[0] == wr_addr[1])) |
                        (wr0_en & wr2_en & (wr_addr[0] == wr_addr[2])) |
                        (wr1_en & wr2_en & (wr_addr[1] == wr_addr[2])) );

    // 时序逻辑部分
    always @(posedge clk) begin
        if (PRIORITY == 0) begin
            // Round Robin using borrow subtractor
            counter <= (counter == 3'b010) ? 3'b000 : counter + 1'b1;
            grant <= counter[1:0];
        end else if (PRIORITY == 1) begin
            grant <= 2'b00; // Fixed priority 0
        end else if (PRIORITY == 2) begin
            grant <= 2'b01; // Fixed priority 1
        end else begin
            grant <= 2'b10; // Priority 2
        end
        
        if (|requests) begin
            regs[wr_addr[grant]] <= wr_data[grant];
        end
    end
endmodule