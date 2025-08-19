//SystemVerilog
module error_arbiter #(WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input error_en,
    output reg [WIDTH-1:0] grant_o
);
    // Stage 1: Input registration and inversion
    reg [WIDTH-1:0] req_stage1;
    reg [WIDTH-1:0] inverted_req_stage1;
    reg error_en_stage1;
    
    // Stage 2: Two's complement calculation
    reg [WIDTH-1:0] inverted_req_stage2;
    reg [WIDTH-1:0] two_comp_stage2;
    reg error_en_stage2;
    
    // Stage 3: Grant computation
    reg [WIDTH-1:0] req_stage3;
    reg [WIDTH-1:0] normal_grant_stage3;
    reg error_en_stage3;
    
    // Pipeline Stage 1: Register inputs and perform inversion
    always @(posedge clk) begin
        if (!rst_n) begin
            req_stage1 <= {WIDTH{1'b0}};
            inverted_req_stage1 <= {WIDTH{1'b0}};
            error_en_stage1 <= 1'b0;
        end else begin
            req_stage1 <= req_i;
            inverted_req_stage1 <= ~req_i;
            error_en_stage1 <= error_en;
        end
    end
    
    // Pipeline Stage 2: Calculate two's complement
    always @(posedge clk) begin
        if (!rst_n) begin
            inverted_req_stage2 <= {WIDTH{1'b0}};
            two_comp_stage2 <= {WIDTH{1'b0}};
            error_en_stage2 <= 1'b0;
            req_stage3 <= {WIDTH{1'b0}};
        end else begin
            inverted_req_stage2 <= inverted_req_stage1;
            two_comp_stage2 <= inverted_req_stage1 + 1'b1;
            error_en_stage2 <= error_en_stage1;
            req_stage3 <= req_stage1;
        end
    end
    
    // Pipeline Stage 3: Calculate normal grant
    always @(posedge clk) begin
        if (!rst_n) begin
            normal_grant_stage3 <= {WIDTH{1'b0}};
            error_en_stage3 <= 1'b0;
        end else begin
            normal_grant_stage3 <= req_stage3 & two_comp_stage2;
            error_en_stage3 <= error_en_stage2;
        end
    end
    
    // Output stage: Select final grant output
    always @(posedge clk) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= error_en_stage3 ? {WIDTH{1'b1}} : normal_grant_stage3;
        end
    end
endmodule