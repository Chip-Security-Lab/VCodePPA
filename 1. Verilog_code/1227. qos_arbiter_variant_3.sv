//SystemVerilog
module qos_arbiter #(parameter WIDTH=4, parameter SCORE_W=4) (
    input clk, rst_n,
    input [WIDTH*SCORE_W-1:0] qos_scores,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // Extract scores
    wire [SCORE_W-1:0] scores[0:WIDTH-1];
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_scores
            assign scores[g] = qos_scores[(g*SCORE_W+SCORE_W-1):(g*SCORE_W)];
        end
    endgenerate

    // Pipeline stage 1: Find the maximum score and index
    reg [SCORE_W-1:0] max_score_stage1;
    reg [1:0] max_idx_stage1;
    reg req_valid_stage1;
    
    // Pipeline stage 2: Register to carry forward values
    reg [SCORE_W-1:0] max_score_stage2;
    reg [1:0] max_idx_stage2;
    reg req_valid_stage2;
    
    // 先行借位减法器信号
    wire [1:0] borrow_out_01, borrow_out_02, borrow_out_12, borrow_out_03, borrow_out_13, borrow_out_23;
    wire [1:0] diff_01, diff_02, diff_12, diff_03, diff_13, diff_23;
    
    // 实现2位先行借位减法器逻辑
    // 生成借位信号 (使用先行借位方式)
    assign borrow_out_01[0] = (scores[0][0] < scores[1][0]) ? 1'b1 : 1'b0;
    assign borrow_out_01[1] = (scores[0][1] < scores[1][1]) ? 1'b1 : 
                             ((scores[0][1] == scores[1][1]) && borrow_out_01[0]) ? 1'b1 : 1'b0;
    
    assign borrow_out_02[0] = (scores[0][0] < scores[2][0]) ? 1'b1 : 1'b0;
    assign borrow_out_02[1] = (scores[0][1] < scores[2][1]) ? 1'b1 : 
                             ((scores[0][1] == scores[2][1]) && borrow_out_02[0]) ? 1'b1 : 1'b0;
    
    assign borrow_out_12[0] = (scores[1][0] < scores[2][0]) ? 1'b1 : 1'b0;
    assign borrow_out_12[1] = (scores[1][1] < scores[2][1]) ? 1'b1 : 
                             ((scores[1][1] == scores[2][1]) && borrow_out_12[0]) ? 1'b1 : 1'b0;
    
    assign borrow_out_03[0] = (scores[0][0] < scores[3][0]) ? 1'b1 : 1'b0;
    assign borrow_out_03[1] = (scores[0][1] < scores[3][1]) ? 1'b1 : 
                             ((scores[0][1] == scores[3][1]) && borrow_out_03[0]) ? 1'b1 : 1'b0;
    
    assign borrow_out_13[0] = (scores[1][0] < scores[3][0]) ? 1'b1 : 1'b0;
    assign borrow_out_13[1] = (scores[1][1] < scores[3][1]) ? 1'b1 : 
                             ((scores[1][1] == scores[3][1]) && borrow_out_13[0]) ? 1'b1 : 1'b0;
    
    assign borrow_out_23[0] = (scores[2][0] < scores[3][0]) ? 1'b1 : 1'b0;
    assign borrow_out_23[1] = (scores[2][1] < scores[3][1]) ? 1'b1 : 
                             ((scores[2][1] == scores[3][1]) && borrow_out_23[0]) ? 1'b1 : 1'b0;

    // Stage 1: Calculate maximum score among valid requests
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_score_stage1 <= 0;
            max_idx_stage1 <= 0;
            req_valid_stage1 <= 0;
        end else begin
            // Initialize with default values
            max_score_stage1 <= 0;
            max_idx_stage1 <= 0;
            req_valid_stage1 <= |req_i;
            
            // 使用先行借位减法器结果进行比较
            if (req_i[0]) begin
                max_score_stage1 <= scores[0];
                max_idx_stage1 <= 2'd0;
            end
            
            if (req_i[1]) begin
                if (req_i[0]) begin
                    // 使用借位信号判断大小
                    if (borrow_out_01[1]) begin
                        max_score_stage1 <= scores[1];
                        max_idx_stage1 <= 2'd1;
                    end
                end else begin
                    max_score_stage1 <= scores[1];
                    max_idx_stage1 <= 2'd1;
                end
            end
            
            if (req_i[2]) begin
                if (req_i[0] && !borrow_out_02[1]) begin
                    // scores[0] >= scores[2]，保持当前最大值
                end else if (req_i[1] && !borrow_out_12[1]) begin
                    // scores[1] >= scores[2]，保持当前最大值
                end else begin
                    max_score_stage1 <= scores[2];
                    max_idx_stage1 <= 2'd2;
                end
            end
            
            if (req_i[3]) begin
                if (req_i[0] && !borrow_out_03[1]) begin
                    // scores[0] >= scores[3]，保持当前最大值
                end else if (req_i[1] && !borrow_out_13[1]) begin
                    // scores[1] >= scores[3]，保持当前最大值
                end else if (req_i[2] && !borrow_out_23[1]) begin
                    // scores[2] >= scores[3]，保持当前最大值
                end else begin
                    max_score_stage1 <= scores[3];
                    max_idx_stage1 <= 2'd3;
                end
            end
        end
    end

    // Stage 2: Register values from stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_score_stage2 <= 0;
            max_idx_stage2 <= 0;
            req_valid_stage2 <= 0;
        end else begin
            max_score_stage2 <= max_score_stage1;
            max_idx_stage2 <= max_idx_stage1;
            req_valid_stage2 <= req_valid_stage1;
        end
    end

    // Stage 3: Set grant output based on registered maximum index
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
        end else begin
            case(max_idx_stage2)
                2'd0: grant_o <= 4'b0001 & {4{req_valid_stage2}};
                2'd1: grant_o <= 4'b0010 & {4{req_valid_stage2}};
                2'd2: grant_o <= 4'b0100 & {4{req_valid_stage2}};
                2'd3: grant_o <= 4'b1000 & {4{req_valid_stage2}};
                default: grant_o <= 4'b0000;
            endcase
        end
    end
endmodule