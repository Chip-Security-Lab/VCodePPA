//SystemVerilog
module cascaded_clk_divider(
    input clk_in,
    input rst,
    output [3:0] clk_out
);
    // Internal counter approach instead of cascaded toggle flip-flops
    // This reduces logic cells and improves timing
    reg [3:0] counter;
    reg [3:0] divider;
    
    // Single counter-based approach
    always @(posedge clk_in or posedge rst) begin
        if (rst)
            counter <= 4'b0000;
        else
            counter <= counter + 1'b1;
    end
    
    // Generate divided clock outputs using different counter bits
    always @(posedge clk_in or posedge rst) begin
        if (rst)
            divider <= 4'b0000;
        else begin
            divider[0] <= counter[0];    // Divide by 2
            divider[1] <= counter[1];    // Divide by 4
            divider[2] <= counter[2];    // Divide by 8
            divider[3] <= counter[3];    // Divide by 16
        end
    end
    
    // Output assignment
    assign clk_out = divider;
endmodule