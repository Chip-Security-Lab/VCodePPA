//SystemVerilog
module multi_phase_clk_gen_valid_ready (
    input  wire        clk_in,
    input  wire        reset,
    input  wire        ready,     
    output reg         valid,     
    output reg         clk_0,     
    output reg         clk_90,    
    output reg         clk_180,   
    output reg         clk_270    
);

    reg  [1:0] phase_count;
    wire [3:0] clk_phase_vec;
    wire       phase_adv;

    // 预先计算下一状态是否推进，减少关键路径
    assign phase_adv = valid & ready;

    // 组合生成各相位时钟信号，平衡路径延迟
    assign clk_phase_vec = 4'b0001 << phase_count;

    // Valid-Ready握手与相位计数逻辑
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            phase_count <= 2'b00;
            valid       <= 1'b0;
        end else begin
            phase_count <= phase_adv ? (phase_count + 2'b01) : phase_count;
            valid       <= 1'b1;
        end
    end

    // 相位输出逻辑，减少条件判断链长度
    always @(*) begin
        clk_0   = clk_phase_vec[0];
        clk_90  = clk_phase_vec[1];
        clk_180 = clk_phase_vec[2];
        clk_270 = clk_phase_vec[3];
    end

endmodule