//SystemVerilog
//IEEE 1364-2005
module qos_arbiter #(parameter WIDTH=4, parameter SCORE_W=4) (
    input clk, rst_n,
    input [WIDTH*SCORE_W-1:0] qos_scores,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // 提取分数
    wire [SCORE_W-1:0] scores[0:WIDTH-1];
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_scores
            assign scores[g] = qos_scores[(g*SCORE_W+SCORE_W-1):(g*SCORE_W)];
        end
    endgenerate

    // 组合逻辑：计算最高分数和对应索引
    wire [SCORE_W-1:0] comb_max_score;
    wire [1:0] comb_max_idx;
    wire any_req;
    
    // 求有效请求标志
    assign any_req = |req_i;
    
    // 实例化组合逻辑模块
    max_score_finder #(
        .WIDTH(WIDTH),
        .SCORE_W(SCORE_W)
    ) max_finder (
        .req_i(req_i),
        .scores(scores),
        .max_score(comb_max_score),
        .max_idx(comb_max_idx)
    );
    
    // 组合逻辑：根据最大索引生成grant信号
    wire [WIDTH-1:0] comb_grant;
    grant_decoder grant_dec (
        .max_idx(comb_max_idx),
        .any_req(any_req),
        .grant(comb_grant)
    );
    
    // 时序逻辑：寄存grant输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= comb_grant;
        end
    end
endmodule

// 组合逻辑模块：寻找最高分数
module max_score_finder #(parameter WIDTH=4, parameter SCORE_W=4) (
    input [WIDTH-1:0] req_i,
    input [SCORE_W-1:0] scores[0:WIDTH-1],
    output reg [SCORE_W-1:0] max_score,
    output reg [1:0] max_idx
);
    integer i;
    
    always @(*) begin
        max_score = {SCORE_W{1'b0}};
        max_idx = 2'd0;
        
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (req_i[i] && (scores[i] > max_score)) begin
                max_score = scores[i];
                max_idx = i[1:0];
            end
        end
    end
endmodule

// 组合逻辑模块：将索引解码为grant信号
module grant_decoder (
    input [1:0] max_idx,
    input any_req,
    output reg [3:0] grant
);
    always @(*) begin
        case(max_idx)
            2'd0: grant = 4'b0001 & {4{any_req}};
            2'd1: grant = 4'b0010 & {4{any_req}};
            2'd2: grant = 4'b0100 & {4{any_req}};
            2'd3: grant = 4'b1000 & {4{any_req}};
            default: grant = 4'b0000;
        endcase
    end
endmodule