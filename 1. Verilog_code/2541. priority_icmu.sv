module priority_icmu #(parameter INT_WIDTH = 8, CTX_WIDTH = 32) (
    input wire clk, rst_n,
    input wire [INT_WIDTH-1:0] int_req,
    input wire [CTX_WIDTH-1:0] current_ctx,
    output reg [INT_WIDTH-1:0] int_ack,
    output reg [CTX_WIDTH-1:0] saved_ctx,
    output reg [2:0] int_id,
    output reg active
);
    reg [INT_WIDTH-1:0] int_mask;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_ack <= 0; saved_ctx <= 0; int_id <= 0; active <= 0; int_mask <= 0;
        end else begin
            if (|int_req & ~active) begin
                int_id <= get_priority(int_req & ~int_mask);
                saved_ctx <= current_ctx;
                int_ack <= (1 << int_id);
                active <= 1;
            end
        end
    end
    function [2:0] get_priority;
        input [INT_WIDTH-1:0] req;
        integer i; begin get_priority = 0;
            for (i = 0; i < INT_WIDTH; i = i+1)
                if (req[i]) get_priority = i;
        end
    endfunction
endmodule