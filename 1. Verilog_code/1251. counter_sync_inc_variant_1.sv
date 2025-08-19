//SystemVerilog
module counter_sync_inc #(parameter WIDTH=4) (
    input clk, rst_n, en,
    output reg [WIDTH-1:0] cnt
);
    // Internal registers for retiming
    reg [WIDTH-1:0] cnt_next;
    reg en_reg, rst_n_reg;
    
    // Register input control signals 
    always @(posedge clk) begin
        rst_n_reg <= rst_n;
        en_reg <= en;
    end
    
    // Move computation before register
    always @(*) begin
        if (!rst_n_reg)
            cnt_next = {WIDTH{1'b0}};
        else if (!en_reg)
            cnt_next = cnt;
        else
            cnt_next = cnt + 1'b1;
    end
    
    // Output register
    always @(posedge clk) begin
        cnt <= cnt_next;
    end
endmodule