//SystemVerilog
module ITRC_SoftAck #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input [WIDTH-1:0] ack_mask,
    output reg [WIDTH-1:0] pending
);

    wire [WIDTH-1:0] next_pending;
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] temp_result;
    
    // Borrow subtractor implementation
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_loop
            assign temp_result[i] = (pending[i] | int_src[i]) ^ ack_mask[i] ^ borrow[i];
            assign borrow[i+1] = ((pending[i] | int_src[i]) & ~ack_mask[i]) | 
                               ((pending[i] | int_src[i]) & borrow[i]) | 
                               (~ack_mask[i] & borrow[i]);
        end
    endgenerate
    
    assign next_pending = temp_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            pending <= {WIDTH{1'b0}};
        else 
            pending <= next_pending;
    end
endmodule