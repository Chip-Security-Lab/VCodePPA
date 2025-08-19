//SystemVerilog
/* IEEE 1364-2005 */
module bidir_counter #(parameter N = 8) (
    input wire clock, clear, load, up_down,
    input wire [N-1:0] data_in,
    output reg [N-1:0] count
);
    wire [N-1:0] next_count;
    
    // 优化后的加减法实现
    assign next_count = up_down ? count + 1'b1 : count - 1'b1;
    
    always @(posedge clock) begin
        if (clear)
            count <= {N{1'b0}};
        else if (load)
            count <= data_in;
        else
            count <= next_count;
    end
endmodule