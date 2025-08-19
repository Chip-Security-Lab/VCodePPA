//SystemVerilog
module crossbar_error_check #(parameter DW=8) (
    input clk, rst,
    input [7:0] parity_in,
    input [2*DW-1:0] din, // 打平的数组
    output reg [2*DW-1:0] dout, // 打平的数组
    output reg error,
    // 流水线控制信号
    input valid_in,
    output reg valid_out,
    input ready_in,
    output reg ready_out
);
    // 第一级流水线：计算校验和
    reg [2*DW-1:0] din_stage1;
    reg [7:0] parity_in_stage1;
    reg [7:0] calc_parity_stage1;
    reg valid_stage1;
    
    // 第二级流水线：比较校验和并输出
    reg [2*DW-1:0] din_stage2;
    reg [7:0] parity_in_stage2;
    reg [7:0] calc_parity_stage2;
    reg parity_match_stage2;
    reg valid_stage2;
    
    // 流水线控制逻辑
    always @(*) begin
        ready_out = valid_stage1 ? ready_in : 1'b1;
    end
    
    // 第一级流水线：计算校验和
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            din_stage1 <= 0;
            parity_in_stage1 <= 0;
            calc_parity_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (ready_out) begin
            din_stage1 <= din;
            parity_in_stage1 <= parity_in;
            calc_parity_stage1 <= ^{din[0 +: DW], din[DW +: DW]};
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：比较校验和
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            din_stage2 <= 0;
            parity_in_stage2 <= 0;
            calc_parity_stage2 <= 0;
            parity_match_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (ready_in) begin
            din_stage2 <= din_stage1;
            parity_in_stage2 <= parity_in_stage1;
            calc_parity_stage2 <= calc_parity_stage1;
            parity_match_stage2 <= (parity_in_stage1 == calc_parity_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dout <= 0;
            error <= 0;
            valid_out <= 0;
        end else if (ready_in) begin
            dout <= parity_match_stage2 ? din_stage2 : 0;
            error <= !parity_match_stage2 && valid_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule