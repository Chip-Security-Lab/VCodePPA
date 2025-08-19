module clock_multiplier(
    input ref_clk,
    input resetn,
    output reg out_clk
);
    reg [1:0] count;
    reg int_clk;
    
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count <= 2'd0;
            int_clk <= 1'b0;
        end else begin
            count <= count + 1'b1;
            if (count == 2'd1 || count == 2'd3)
                int_clk <= ~int_clk;
        end
    end
    
    always @(posedge int_clk or negedge resetn)
        if (!resetn) out_clk <= 1'b0;
        else out_clk <= ~out_clk;
endmodule