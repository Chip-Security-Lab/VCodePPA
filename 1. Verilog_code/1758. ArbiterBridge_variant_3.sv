//SystemVerilog
module ArbiterBridge_Pipeline #(
    parameter MASTERS = 4
)(
    input clk, rst_n,
    input [MASTERS-1:0] req,
    output reg [MASTERS-1:0] grant
);

    // Internal signals
    reg [MASTERS-1:0] grant_stage1;
    reg [1:0] priority_ptr_stage1;
    reg found_stage1;
    reg [1:0] priority_ptr_stage2;
    reg found_stage2;
    integer i;

    // Combined always block for all stages
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 0;
            grant_stage1 <= 0;
            priority_ptr_stage1 <= 0;
            found_stage1 <= 0;
            priority_ptr_stage2 <= 0;
            found_stage2 <= 0;
        end else begin
            // Stage 1: Request handling and priority calculation
            found_stage1 = 0;
            for (i = 0; i < MASTERS; i = i + 1) begin
                if (req[(priority_ptr_stage1+i)%MASTERS] && !found_stage1) begin
                    grant_stage1 <= 1 << ((priority_ptr_stage1+i)%MASTERS);
                    priority_ptr_stage1 <= (priority_ptr_stage1+i+1)%MASTERS;
                    found_stage1 = 1;
                end
            end
            if (!found_stage1) grant_stage1 <= 0;

            // Stage 2: Grant output and final priority pointer update
            grant <= grant_stage1;
            priority_ptr_stage2 <= priority_ptr_stage1;
            found_stage2 <= found_stage1;
        end
    end

endmodule