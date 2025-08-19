//SystemVerilog
module token_ring_arbiter #(
    parameter WIDTH = 4
) (
    input wire clk, 
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] token_stage1;
    reg [WIDTH-1:0] req_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] token_stage2;
    reg [WIDTH-1:0] req_stage2;
    reg [WIDTH-1:0] grant_stage2;
    reg valid_stage2;
    reg no_req_stage2;
    
    // 用于case语句的控制状态变量
    reg [1:0] token_update_state;
    
    // Stage 1: Capture requests and update token position
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_stage1 <= 1;
            req_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            req_stage1 <= req_i;
            valid_stage1 <= 1'b1;
            
            // 定义token更新状态
            token_update_state = {valid_stage2, no_req_stage2};
            
            // 使用case语句替代if-else级联
            case (token_update_state)
                2'b11:   token_stage1 <= {token_stage2[WIDTH-2:0], token_stage2[WIDTH-1]}; // valid and no request
                2'b10:   token_stage1 <= token_stage2; // valid but has request
                2'b0?:   token_stage1 <= token_stage1; // not valid, keep current token
                default: token_stage1 <= token_stage1; // default case
            endcase
        end
    end
    
    // Stage 2: Calculate grant and token rotation decision
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_stage2 <= 0;
            req_stage2 <= 0;
            grant_stage2 <= 0;
            valid_stage2 <= 0;
            no_req_stage2 <= 0;
        end else begin
            token_stage2 <= token_stage1;
            req_stage2 <= req_stage1;
            valid_stage2 <= valid_stage1;
            
            // Generate grant
            grant_stage2 <= token_stage1 & req_stage1;
            
            // Check if no request for current token
            no_req_stage2 <= !(|(token_stage1 & req_stage1));
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
        end else begin
            grant_o <= grant_stage2;
        end
    end
    
endmodule