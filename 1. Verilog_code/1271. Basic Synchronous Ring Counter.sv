module basic_ring_counter #(parameter WIDTH = 4)(
    input wire clk,
    output reg [WIDTH-1:0] count
);
    initial count = {{(WIDTH-1){1'b0}}, 1'b1}; // Initialize with one-hot encoding
    
    always @(posedge clk) begin
        count <= {count[WIDTH-2:0], count[WIDTH-1]}; // Rotate the bits
    end
endmodule