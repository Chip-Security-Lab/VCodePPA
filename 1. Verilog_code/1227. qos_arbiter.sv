module qos_arbiter #(parameter WIDTH=4, parameter SCORE_W=4) (
    input clk, rst_n,
    input [WIDTH*SCORE_W-1:0] qos_scores,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [SCORE_W-1:0] max_score;
    reg [1:0] max_idx;
    
    // Extract scores
    wire [SCORE_W-1:0] scores[0:WIDTH-1];
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_scores
            assign scores[g] = qos_scores[(g*SCORE_W+SCORE_W-1):(g*SCORE_W)];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
            max_score <= 0;
            max_idx <= 0;
        end else begin
            max_score <= 0;
            max_idx <= 0;
            
            // Find maximum score among requests
            if(req_i[0] && scores[0] > max_score) begin
                max_score <= scores[0];
                max_idx <= 2'd0;
            end
            
            if(req_i[1] && scores[1] > max_score) begin
                max_score <= scores[1];
                max_idx <= 2'd1;
            end
            
            if(req_i[2] && scores[2] > max_score) begin
                max_score <= scores[2];
                max_idx <= 2'd2;
            end
            
            if(req_i[3] && scores[3] > max_score) begin
                max_score <= scores[3];
                max_idx <= 2'd3;
            end
            
            // Set grant using pre-computed values
            case(max_idx)
                2'd0: grant_o <= 4'b0001 & {4{|req_i}};
                2'd1: grant_o <= 4'b0010 & {4{|req_i}};
                2'd2: grant_o <= 4'b0100 & {4{|req_i}};
                2'd3: grant_o <= 4'b1000 & {4{|req_i}};
            endcase
        end
    end
endmodule