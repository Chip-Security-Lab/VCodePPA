module ArbiterBridge #(
    parameter MASTERS = 4
)(
    input clk, rst_n,
    input [MASTERS-1:0] req,
    output reg [MASTERS-1:0] grant
);
    reg [1:0] priority_ptr;
    integer i;
    reg found;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 0;
            priority_ptr <= 0;
        end else begin
            found = 0;
            for (i = 0; i < MASTERS; i = i + 1) begin
                if (req[(priority_ptr+i)%MASTERS] && !found) begin
                    grant <= 1 << ((priority_ptr+i)%MASTERS);
                    priority_ptr <= (priority_ptr+i+1)%MASTERS;
                    found = 1;
                end
            end
            if (!found) grant <= 0;
        end
    end
endmodule