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
    output reg conflict
);
    reg [DATA_W-1:0] regs [0:(1<<ADDR_W)-1];
    wire [2:0] requests = {wr2_en, wr1_en, wr0_en};
    reg [1:0] grant;
    reg [1:0] grant_d1;

    // 冲突检测的中间结果寄存器
    reg conflict_01, conflict_02, conflict_12;
    reg wr0_en_d1, wr1_en_d1, wr2_en_d1;
    reg [ADDR_W-1:0] wr_addr_d1 [0:2];
    reg [DATA_W-1:0] wr_data_d1 [0:2];
    reg requests_valid_d1;

    // 冲突检测
    always @(posedge clk) begin
        conflict_01 <= wr0_en & wr1_en & (wr_addr[0] == wr_addr[1]);
        conflict_02 <= wr0_en & wr2_en & (wr_addr[0] == wr_addr[2]);
        conflict_12 <= wr1_en & wr2_en & (wr_addr[1] == wr_addr[2]);
    end

    // 优先级控制与grant计算
    always @(posedge clk) begin
        case(PRIORITY)
            0: grant <= (grant == 2) ? 0 : grant + 1; // Round Robin
            1: grant <= 0; // Fixed priority 0
            2: grant <= 1; // Fixed priority 1
            default: grant <= 2; // Priority 2
        endcase
    end

    // 存储输入信号以在下一阶段使用
    always @(posedge clk) begin
        wr0_en_d1 <= wr0_en;
        wr1_en_d1 <= wr1_en;
        wr2_en_d1 <= wr2_en;
        wr_addr_d1[0] <= wr_addr[0];
        wr_addr_d1[1] <= wr_addr[1];
        wr_addr_d1[2] <= wr_addr[2];
        wr_data_d1[0] <= wr_data[0];
        wr_data_d1[1] <= wr_data[1];
        wr_data_d1[2] <= wr_data[2];
        requests_valid_d1 <= |requests;
        grant_d1 <= grant;
    end

    // 写入操作和冲突输出
    always @(posedge clk) begin
        conflict <= conflict_01 | conflict_02 | conflict_12;
        if (requests_valid_d1) begin
            regs[wr_addr_d1[grant_d1]] <= wr_data_d1[grant_d1];
        end
    end
endmodule