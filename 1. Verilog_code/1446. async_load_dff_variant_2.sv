//SystemVerilog
module async_load_dff (
    input clk, load,
    input [3:0] data,
    output reg [3:0] q
);
    reg [3:0] next_q;
    
    always @(*) begin
        if (load)
            next_q = data;
        else
            next_q = q + 1;
    end
    
    always @(posedge clk or posedge load) begin
        if (load)
            q <= data;
        else
            q <= next_q;
    end
endmodule