//SystemVerilog
module TokenBucketArbiter #(parameter BUCKET_SIZE=16) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// Stage 1: Token Count Update
reg [7:0] token_cnt_stage1 [0:3];
reg [3:0] req_stage1;
reg tokens_available_stage1;

// Stage 2: Grant Generation
reg [7:0] token_cnt_stage2 [0:3];
reg [3:0] req_stage2;
reg [3:0] grant_stage2;

// Brent-Kung Adder signals
wire [7:0] token_cnt_plus_one [0:3];
wire [7:0] token_cnt_minus_one [0:3];

// Brent-Kung Adder implementation
genvar j;
generate
    for(j=0; j<4; j=j+1) begin : BK_ADDERS
        // Plus one adder
        wire [7:0] p_plus [0:7];
        wire [7:0] g_plus [0:7];
        wire [7:0] c_plus;
        
        // Generate and propagate signals
        assign p_plus[0] = token_cnt_stage1[j] ^ 8'b00000001;
        assign g_plus[0] = token_cnt_stage1[j] & 8'b00000001;
        
        // First level
        assign p_plus[1] = p_plus[0][1:0] & p_plus[0][3:2];
        assign g_plus[1] = (p_plus[0][3:2] & g_plus[0][1:0]) | g_plus[0][3:2];
        
        // Second level
        assign p_plus[2] = p_plus[1][1:0] & p_plus[1][3:2];
        assign g_plus[2] = (p_plus[1][3:2] & g_plus[1][1:0]) | g_plus[1][3:2];
        
        // Third level
        assign c_plus[0] = g_plus[0][0];
        assign c_plus[1] = g_plus[0][1] | (p_plus[0][1] & c_plus[0]);
        assign c_plus[2] = g_plus[1][0] | (p_plus[1][0] & c_plus[1]);
        assign c_plus[3] = g_plus[1][1] | (p_plus[1][1] & c_plus[2]);
        assign c_plus[4] = g_plus[2][0] | (p_plus[2][0] & c_plus[3]);
        assign c_plus[5] = g_plus[2][1] | (p_plus[2][1] & c_plus[4]);
        assign c_plus[6] = g_plus[2][2] | (p_plus[2][2] & c_plus[5]);
        assign c_plus[7] = g_plus[2][3] | (p_plus[2][3] & c_plus[6]);
        
        // Sum calculation
        assign token_cnt_plus_one[j] = p_plus[0] ^ {c_plus[6:0], 1'b0};
        
        // Minus one adder (using two's complement)
        wire [7:0] p_minus [0:7];
        wire [7:0] g_minus [0:7];
        wire [7:0] c_minus;
        
        // Generate and propagate signals
        assign p_minus[0] = token_cnt_stage1[j] ^ 8'b11111111;
        assign g_minus[0] = token_cnt_stage1[j] & 8'b11111111;
        
        // First level
        assign p_minus[1] = p_minus[0][1:0] & p_minus[0][3:2];
        assign g_minus[1] = (p_minus[0][3:2] & g_minus[0][1:0]) | g_minus[0][3:2];
        
        // Second level
        assign p_minus[2] = p_minus[1][1:0] & p_minus[1][3:2];
        assign g_minus[2] = (p_minus[1][3:2] & g_minus[1][1:0]) | g_minus[1][3:2];
        
        // Third level
        assign c_minus[0] = g_minus[0][0];
        assign c_minus[1] = g_minus[0][1] | (p_minus[0][1] & c_minus[0]);
        assign c_minus[2] = g_minus[1][0] | (p_minus[1][0] & c_minus[1]);
        assign c_minus[3] = g_minus[1][1] | (p_minus[1][1] & c_minus[2]);
        assign c_minus[4] = g_minus[2][0] | (p_minus[2][0] & c_minus[3]);
        assign c_minus[5] = g_minus[2][1] | (p_minus[2][1] & c_minus[4]);
        assign c_minus[6] = g_minus[2][2] | (p_minus[2][2] & c_minus[5]);
        assign c_minus[7] = g_minus[2][3] | (p_minus[2][3] & c_minus[6]);
        
        // Sum calculation
        assign token_cnt_minus_one[j] = p_minus[0] ^ {c_minus[6:0], 1'b0};
    end
endgenerate

// Stage 1: Token Count Update Logic
always @(posedge clk) begin
    if(rst) begin
        for(int i=0; i<4; i=i+1) 
            token_cnt_stage1[i] <= BUCKET_SIZE;
        req_stage1 <= 0;
        tokens_available_stage1 <= 0;
    end else begin
        for(int i=0; i<4; i=i+1) begin
            if(token_cnt_stage1[i] < BUCKET_SIZE)
                token_cnt_stage1[i] <= token_cnt_plus_one[i];
                
            if(grant_stage2[i] && token_cnt_stage1[i] > 0)
                token_cnt_stage1[i] <= token_cnt_minus_one[i];
        end
        req_stage1 <= req;
        tokens_available_stage1 <= |{token_cnt_stage1[0], token_cnt_stage1[1], token_cnt_stage1[2], token_cnt_stage1[3]};
    end
end

// Stage 2: Grant Generation Logic
always @(posedge clk) begin
    if(rst) begin
        for(int i=0; i<4; i=i+1)
            token_cnt_stage2[i] <= BUCKET_SIZE;
        req_stage2 <= 0;
        grant_stage2 <= 0;
    end else begin
        for(int i=0; i<4; i=i+1)
            token_cnt_stage2[i] <= token_cnt_stage1[i];
        req_stage2 <= req_stage1;
        grant_stage2 <= req_stage1 & {4{tokens_available_stage1}};
    end
end

// Output Stage
always @(posedge clk) begin
    if(rst)
        grant <= 0;
    else
        grant <= grant_stage2;
end

endmodule