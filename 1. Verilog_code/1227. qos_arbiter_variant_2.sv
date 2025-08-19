//SystemVerilog
module qos_arbiter #(
    parameter WIDTH = 4,
    parameter SCORE_W = 4
) (
    input clk, rst_n,
    input [WIDTH*SCORE_W-1:0] qos_scores,
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    // Internal signals
    wire [SCORE_W-1:0] scores[0:WIDTH-1];
    wire [WIDTH-1:0] req_buf2;
    wire [SCORE_W-1:0] scores_buf[0:WIDTH-1];
    wire [1:0] max_idx;
    wire [SCORE_W-1:0] max_score;

    // Score extraction module
    score_extractor #(
        .WIDTH(WIDTH),
        .SCORE_W(SCORE_W)
    ) u_score_extractor (
        .qos_scores(qos_scores),
        .scores(scores)
    );

    // Input buffering module
    input_buffer #(
        .WIDTH(WIDTH),
        .SCORE_W(SCORE_W)
    ) u_input_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .req_i(req_i),
        .scores(scores),
        .req_buf2(req_buf2),
        .scores_buf(scores_buf)
    );

    // Score comparison module
    max_score_finder #(
        .WIDTH(WIDTH),
        .SCORE_W(SCORE_W)
    ) u_max_score_finder (
        .clk(clk),
        .rst_n(rst_n),
        .req_buf2(req_buf2),
        .scores_buf(scores_buf),
        .max_score(max_score),
        .max_idx(max_idx)
    );

    // Grant generation module
    grant_generator #(
        .WIDTH(WIDTH)
    ) u_grant_generator (
        .clk(clk),
        .rst_n(rst_n),
        .max_idx(max_idx),
        .req_buf2(req_buf2),
        .grant_o(grant_o)
    );
endmodule

// Score extraction module
module score_extractor #(
    parameter WIDTH = 4,
    parameter SCORE_W = 4
) (
    input [WIDTH*SCORE_W-1:0] qos_scores,
    output [SCORE_W-1:0] scores[0:WIDTH-1]
);
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_scores
            assign scores[g] = qos_scores[(g*SCORE_W+SCORE_W-1):(g*SCORE_W)];
        end
    endgenerate
endmodule

// Input buffering module
module input_buffer #(
    parameter WIDTH = 4,
    parameter SCORE_W = 4
) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [SCORE_W-1:0] scores[0:WIDTH-1],
    output reg [WIDTH-1:0] req_buf2,
    output reg [SCORE_W-1:0] scores_buf[0:WIDTH-1]
);
    reg [WIDTH-1:0] req_buf1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_buf1 <= 0;
            req_buf2 <= 0;
            for (integer i=0; i<WIDTH; i=i+1) begin
                scores_buf[i] <= 0;
            end
        end else begin
            req_buf1 <= req_i;
            req_buf2 <= req_buf1;
            for (integer i=0; i<WIDTH; i=i+1) begin
                scores_buf[i] <= scores[i];
            end
        end
    end
endmodule

// Maximum score finder module
module max_score_finder #(
    parameter WIDTH = 4,
    parameter SCORE_W = 4
) (
    input clk, rst_n,
    input [WIDTH-1:0] req_buf2,
    input [SCORE_W-1:0] scores_buf[0:WIDTH-1],
    output reg [SCORE_W-1:0] max_score,
    output reg [1:0] max_idx
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_score <= 0;
            max_idx <= 0;
        end else begin
            max_score <= 0;
            max_idx <= 0;
            
            // Find maximum score among requests using buffered signals
            if(req_buf2[0] && scores_buf[0] > max_score) begin
                max_score <= scores_buf[0];
                max_idx <= 2'd0;
            end
            
            if(req_buf2[1] && scores_buf[1] > max_score) begin
                max_score <= scores_buf[1];
                max_idx <= 2'd1;
            end
            
            if(req_buf2[2] && scores_buf[2] > max_score) begin
                max_score <= scores_buf[2];
                max_idx <= 2'd2;
            end
            
            if(req_buf2[3] && scores_buf[3] > max_score) begin
                max_score <= scores_buf[3];
                max_idx <= 2'd3;
            end
        end
    end
endmodule

// Grant generation module
module grant_generator #(
    parameter WIDTH = 4
) (
    input clk, rst_n,
    input [1:0] max_idx,
    input [WIDTH-1:0] req_buf2,
    output reg [WIDTH-1:0] grant_o
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
        end else begin
            // Set grant using pre-computed values
            case(max_idx)
                2'd0: grant_o <= 4'b0001 & {4{|req_buf2}};
                2'd1: grant_o <= 4'b0010 & {4{|req_buf2}};
                2'd2: grant_o <= 4'b0100 & {4{|req_buf2}};
                2'd3: grant_o <= 4'b1000 & {4{|req_buf2}};
            endcase
        end
    end
endmodule