//SystemVerilog
module cascaded_clk_divider(
    input clk_in,
    input rst,
    output [3:0] clk_out
);
    reg [3:0] divider;
    reg [3:0] divider_next;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst)
            divider[0] <= 1'b0;
        else
            divider[0] <= ~divider[0];
    end
    
    always @* begin
        divider_next = divider;
    end
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            divider[3:1] <= 3'b000;
        end
        else begin
            if (divider[0] == 1'b1 && divider_next[0] == 1'b0)
                divider[1] <= ~divider[1];
                
            if (divider[1] == 1'b1 && divider_next[1] == 1'b0 && 
                divider[0] == 1'b1 && divider_next[0] == 1'b0)
                divider[2] <= ~divider[2];
                
            if (divider[2] == 1'b1 && divider_next[2] == 1'b0 && 
                divider[1] == 1'b1 && divider_next[1] == 1'b0 && 
                divider[0] == 1'b1 && divider_next[0] == 1'b0)
                divider[3] <= ~divider[3];
        end
    end
    
    assign clk_out = divider;
endmodule