//SystemVerilog
module AsyncLatch #(parameter WIDTH=8) (
    input en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    // Control logic module
    control_logic #(
        .WIDTH(WIDTH)
    ) ctrl_inst (
        .en(en),
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule

module control_logic #(parameter WIDTH=8) (
    input en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    // Control logic implementation
    always @* begin
        if(en) begin
            data_out = data_in;
        end
    end

endmodule

module subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);

    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] temp_diff;
    
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for(i=0; i<WIDTH; i=i+1) begin: sub_loop
            assign temp_diff[i] = a[i] ^ b[i] ^ borrow[i];
            assign borrow[i+1] = (~a[i] & b[i]) | ((~a[i] | b[i]) & borrow[i]);
        end
    endgenerate
    
    assign diff = temp_diff;

endmodule