//SystemVerilog
module HybridArbiter #(parameter HP_GROUP=2) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

    // Stage 1 signals
    reg [3:0] req_stage1;
    reg [3:0] hp_req_stage1;
    reg [3:0] lp_req_stage1;
    reg has_hp_req_stage1;

    // Stage 2 signals
    reg [3:0] hp_req_stage2;
    reg [3:0] lp_req_stage2;
    reg has_hp_req_stage2;
    reg [3:0] hp_grant_stage2;
    reg [3:0] lp_grant_stage2;
    reg [1:0] random_shift_stage2;

    // Stage 3 signals
    reg [3:0] hp_grant_stage3;
    reg [3:0] lp_grant_stage3;
    reg [1:0] random_shift_stage3;
    reg has_hp_req_stage3;

    // Stage 1: Request classification
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            req_stage1 <= 4'b0;
            hp_req_stage1 <= 4'b0;
            lp_req_stage1 <= 4'b0;
            has_hp_req_stage1 <= 1'b0;
        end else begin
            req_stage1 <= req;
            hp_req_stage1 <= req & {4{1'b1}};
            lp_req_stage1 <= req & {4{1'b0}};
            has_hp_req_stage1 <= |(req & {4{1'b1}});
        end
    end

    // Stage 2: Priority arbitration
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            hp_req_stage2 <= 4'b0;
            lp_req_stage2 <= 4'b0;
            has_hp_req_stage2 <= 1'b0;
            hp_grant_stage2 <= 4'b0;
            lp_grant_stage2 <= 4'b0;
            random_shift_stage2 <= 2'b0;
        end else begin
            hp_req_stage2 <= hp_req_stage1;
            lp_req_stage2 <= lp_req_stage1;
            has_hp_req_stage2 <= has_hp_req_stage1;
            hp_grant_stage2 <= hp_req_stage1 & -hp_req_stage1;
            lp_grant_stage2 <= lp_req_stage1;
            random_shift_stage2 <= $urandom%2;
        end
    end

    // Stage 3: Grant selection
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            hp_grant_stage3 <= 4'b0;
            lp_grant_stage3 <= 4'b0;
            random_shift_stage3 <= 2'b0;
            has_hp_req_stage3 <= 1'b0;
        end else begin
            hp_grant_stage3 <= hp_grant_stage2;
            lp_grant_stage3 <= lp_grant_stage2;
            random_shift_stage3 <= random_shift_stage2;
            has_hp_req_stage3 <= has_hp_req_stage2;
        end
    end

    // Stage 4: Final grant output
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            grant <= 4'b0;
        end else begin
            if(has_hp_req_stage3)
                grant <= hp_grant_stage3;
            else
                grant <= lp_grant_stage3 << random_shift_stage3;
        end
    end

endmodule