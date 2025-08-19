//SystemVerilog - IEEE 1364-2005
module token_ring_arbiter #(WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] req_stage1;
    reg [WIDTH-1:0] token_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] req_stage2;
    reg [WIDTH-1:0] token_stage2;
    reg req_match_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [WIDTH-1:0] next_token_stage3;
    reg [WIDTH-1:0] next_grant_stage3;
    reg valid_stage3;
    
    // Intermediate combinational signals
    wire [WIDTH-1:0] next_token;
    wire [WIDTH-1:0] next_grant;
    wire req_match;
    
    // Stage 1: Register inputs and initialize pipeline
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage1 <= {WIDTH{1'b0}};
            token_stage1 <= {{WIDTH-1{1'b0}}, 1'b1}; // Initialize with token at position 0
            valid_stage1 <= 1'b0;
        end else begin
            req_stage1 <= req_i;
            token_stage1 <= (valid_stage3) ? next_token_stage3 : token_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Check token and request match
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage2 <= {WIDTH{1'b0}};
            token_stage2 <= {WIDTH{1'b0}};
            req_match_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            req_stage2 <= req_stage1;
            token_stage2 <= token_stage1;
            req_match_stage2 <= |(token_stage1 & req_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Calculate next token and grant values
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            next_token_stage3 <= {WIDTH{1'b0}};
            next_grant_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            next_token_stage3 <= req_match_stage2 ? token_stage2 : {token_stage2[WIDTH-2:0], token_stage2[WIDTH-1]};
            next_grant_stage3 <= req_match_stage2 ? (token_stage2 & req_stage2) : 
                               ({token_stage2[WIDTH-2:0], token_stage2[WIDTH-1]} & req_stage2);
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output stage: Update grant output
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else if(valid_stage3) begin
            grant_o <= next_grant_stage3;
        end
    end
endmodule