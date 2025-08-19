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

// 先行借位减法器实现
function [2:0] subtractor_3bit;
    input [2:0] a;
    input [2:0] b;
    reg [2:0] difference;
    reg [2:0] borrow;
    begin
        // 生成借位信号
        borrow[0] = (a[0] < b[0]);
        borrow[1] = (a[1] < b[1]) || ((a[1] == b[1]) && borrow[0]);
        borrow[2] = (a[2] < b[2]) || ((a[2] == b[2]) && borrow[1]);
        
        // 计算差值
        difference[0] = a[0] ^ b[0];
        difference[1] = a[1] ^ b[1] ^ borrow[0];
        difference[2] = a[2] ^ b[2] ^ borrow[1];
        
        subtractor_3bit = difference;
    end
endfunction

always @(posedge clk) begin
    case(PRIORITY)
        0: grant <= (grant == 2) ? 0 : grant + 1; // Round Robin
        1: grant <= 0; // Fixed priority 0
        2: grant <= 1; // Fixed priority 1
        default: grant <= 2; // Priority 2
    endcase
    
    if (|requests) begin
        // 使用先行借位减法器实现减法操作
        regs[wr_addr[grant]] <= subtractor_3bit(wr_data[grant][2:0], 3'b001); // 执行 data - 1 操作
    end
end

assign conflict = ( (wr0_en & wr1_en & (wr_addr[0] == wr_addr[1])) |
                    (wr0_en & wr2_en & (wr_addr[0] == wr_addr[2])) |
                    (wr1_en & wr2_en & (wr_addr[1] == wr_addr[2])) );
endmodule