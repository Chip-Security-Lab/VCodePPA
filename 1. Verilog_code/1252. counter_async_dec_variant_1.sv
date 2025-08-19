//SystemVerilog
module counter_async_dec #(parameter WIDTH=4) (
    input clk, rst, en,
    output reg [WIDTH-1:0] count
);
    // Internal signal to hold the decrement operation result
    reg [WIDTH-1:0] next_count;
    
    // Pre-compute the next count value
    always @(posedge clk, posedge rst) begin
        if (rst) next_count <= {WIDTH{1'b1}} - 1;
        else if (en) next_count <= count - 1;
        else next_count <= count - 1;
    end
    
    // Register the final output
    always @(posedge clk, posedge rst) begin
        if (rst) count <= {WIDTH{1'b1}};
        else if (en) count <= next_count;
    end
endmodule