//SystemVerilog
module priority_encoder #(parameter WIDTH = 8, OUT_WIDTH = (WIDTH <= 2) ? 1 : 
                         (WIDTH <= 4) ? 2 : 
                         (WIDTH <= 8) ? 3 : 
                         (WIDTH <= 16) ? 4 : 
                         (WIDTH <= 32) ? 5 : 
                         (WIDTH <= 64) ? 6 : 
                         (WIDTH <= 128) ? 7 : 8) (
    input wire [WIDTH-1:0] requests,
    output reg [OUT_WIDTH-1:0] grant_idx,
    output reg valid
);

    integer i;
    reg [OUT_WIDTH-1:0] temp_idx;
    reg found;

    always @(*) begin
        valid = (requests != {WIDTH{1'b0}});
        temp_idx = {OUT_WIDTH{1'b0}};
        found = 1'b0;
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (!found && requests[i]) begin
                temp_idx = i[OUT_WIDTH-1:0];
                found = 1'b1;
            end
        end
        grant_idx = temp_idx;
    end

endmodule