module priority_fixed_ismu #(parameter INT_COUNT = 16)(
    input clk, reset,
    input [INT_COUNT-1:0] int_src,
    input [INT_COUNT-1:0] int_enable,
    output reg [3:0] priority_num,
    output reg int_active
);
    always @(posedge clk) begin
        if (reset) begin
            priority_num <= 4'h0;
            int_active <= 1'b0;
        end else begin
            int_active <= 1'b0;
            priority_num <= 4'h0;
            
            if (int_src[0] & int_enable[0]) begin
                priority_num <= 4'h0; int_active <= 1'b1;
            end else if (int_src[1] & int_enable[1]) begin
                priority_num <= 4'h1; int_active <= 1'b1;
            end else if (int_src[2] & int_enable[2]) begin
                priority_num <= 4'h2; int_active <= 1'b1;
            end else if (int_src[3] & int_enable[3]) begin
                priority_num <= 4'h3; int_active <= 1'b1;
            end
        end
    end
endmodule