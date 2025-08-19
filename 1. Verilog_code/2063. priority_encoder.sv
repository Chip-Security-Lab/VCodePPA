module priority_encoder #(parameter WIDTH = 8, OUT_WIDTH = $clog2(WIDTH)) (
    input wire [WIDTH-1:0] requests,
    output reg [OUT_WIDTH-1:0] grant_idx,
    output reg valid
);
    integer i;
    always @(*) begin
        valid = 1'b0;
        grant_idx = {OUT_WIDTH{1'b0}};
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (requests[i]) begin
                grant_idx = i[OUT_WIDTH-1:0];
                valid = 1'b1;
            end
        end
    end
endmodule