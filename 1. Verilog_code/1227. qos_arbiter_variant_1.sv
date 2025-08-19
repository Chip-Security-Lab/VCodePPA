//SystemVerilog
module qos_arbiter #(parameter WIDTH=4, parameter SCORE_W=4) (
    input clk, rst_n,
    input [WIDTH*SCORE_W-1:0] qos_scores,
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    // Extract scores
    wire [SCORE_W-1:0] scores[0:WIDTH-1];
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_scores
            assign scores[g] = qos_scores[(g*SCORE_W+SCORE_W-1):(g*SCORE_W)];
        end
    endgenerate

    // Pipeline stage 1: Find maximum score combinatorial signals
    wire [SCORE_W-1:0] max_score_comb;
    wire [1:0] max_idx_comb;
    wire any_req_comb;
    
    // Pipeline stage 1 registers
    reg [SCORE_W-1:0] max_score_stage1;
    reg [1:0] max_idx_stage1;
    reg [WIDTH-1:0] req_i_stage1;
    reg any_req_stage1;

    // Pipeline stage 2 registers
    reg [SCORE_W-1:0] max_score;
    reg [1:0] max_idx;
    reg any_req;
    reg [WIDTH-1:0] grant_o_reg;

    // Stage 1 combinatorial logic: Find maximum score
    max_score_finder #(
        .WIDTH(WIDTH),
        .SCORE_W(SCORE_W)
    ) max_score_finder_inst (
        .scores(scores),
        .req_i(req_i),
        .max_score(max_score_comb),
        .max_idx(max_idx_comb),
        .any_req(any_req_comb)
    );

    // Grant decoder combinatorial logic
    wire [WIDTH-1:0] grant_decoded;
    grant_decoder #(
        .WIDTH(WIDTH)
    ) grant_decoder_inst (
        .max_idx(max_idx_stage1),
        .any_req(any_req_stage1),
        .grant_o(grant_decoded)
    );

    // Stage 1 sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_score_stage1 <= 0;
            max_idx_stage1 <= 0;
            req_i_stage1 <= 0;
            any_req_stage1 <= 0;
        end else begin
            max_score_stage1 <= max_score_comb;
            max_idx_stage1 <= max_idx_comb;
            req_i_stage1 <= req_i;
            any_req_stage1 <= any_req_comb;
        end
    end

    // Stage 2 sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_score <= 0;
            max_idx <= 0;
            any_req <= 0;
            grant_o_reg <= 0;
        end else begin
            max_score <= max_score_stage1;
            max_idx <= max_idx_stage1;
            any_req <= any_req_stage1;
            grant_o_reg <= grant_decoded;
        end
    end

    // Connect output
    assign grant_o = grant_o_reg;

endmodule

// Combinatorial module to find maximum score
module max_score_finder #(parameter WIDTH=4, parameter SCORE_W=4) (
    input [SCORE_W-1:0] scores[0:WIDTH-1],
    input [WIDTH-1:0] req_i,
    output reg [SCORE_W-1:0] max_score,
    output reg [1:0] max_idx,
    output any_req
);
    // Generate any_req signal
    assign any_req = |req_i;
    
    // Find maximum score logic
    always @(*) begin
        // Default values
        max_score = 0;
        max_idx = 0;
        
        // Find maximum score among requests
        if(req_i[0] && scores[0] > max_score) begin
            max_score = scores[0];
            max_idx = 2'd0;
        end
        
        if(req_i[1] && scores[1] > max_score) begin
            max_score = scores[1];
            max_idx = 2'd1;
        end
        
        if(req_i[2] && scores[2] > max_score) begin
            max_score = scores[2];
            max_idx = 2'd2;
        end
        
        if(req_i[3] && scores[3] > max_score) begin
            max_score = scores[3];
            max_idx = 2'd3;
        end
    end
endmodule

// Combinatorial module to decode grant outputs
module grant_decoder #(parameter WIDTH=4) (
    input [1:0] max_idx,
    input any_req,
    output reg [WIDTH-1:0] grant_o
);
    // Generate grant signals based on max_idx
    always @(*) begin
        case(max_idx)
            2'd0: grant_o = 4'b0001 & {4{any_req}};
            2'd1: grant_o = 4'b0010 & {4{any_req}};
            2'd2: grant_o = 4'b0100 & {4{any_req}};
            2'd3: grant_o = 4'b1000 & {4{any_req}};
            default: grant_o = 4'b0000;
        endcase
    end
endmodule