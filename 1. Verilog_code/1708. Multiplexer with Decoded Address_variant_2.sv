//SystemVerilog
module decoded_addr_mux #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data_array [0:3],
    input [1:0] addr,
    output [WIDTH-1:0] selected_data
);
    wire [3:0] decoded;
    
    // Instantiate decoder module
    addr_decoder u_decoder(
        .addr(addr),
        .decoded(decoded)
    );
    
    // Instantiate multiplexer module
    data_mux #(
        .WIDTH(WIDTH)
    ) u_mux(
        .data_array(data_array),
        .decoded(decoded),
        .selected_data(selected_data)
    );
endmodule

// Address decoder module
module addr_decoder(
    input [1:0] addr,
    output [3:0] decoded
);
    wire [1:0] addr_n;
    wire [1:0] addr_p;
    
    // Generate complementary signals
    assign addr_n[0] = ~addr[0];
    assign addr_n[1] = ~addr[1];
    assign addr_p[0] = addr[0];
    assign addr_p[1] = addr[1];
    
    // Parallel prefix decoding
    assign decoded[0] = addr_n[1] & addr_n[0];
    assign decoded[1] = addr_n[1] & addr_p[0];
    assign decoded[2] = addr_p[1] & addr_n[0];
    assign decoded[3] = addr_p[1] & addr_p[0];
endmodule

// Data multiplexer module
module data_mux #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data_array [0:3],
    input [3:0] decoded,
    output [WIDTH-1:0] selected_data
);
    // Optimized multiplexer using parallel prefix
    assign selected_data = (decoded[0] & data_array[0]) |
                          (decoded[1] & data_array[1]) |
                          (decoded[2] & data_array[2]) |
                          (decoded[3] & data_array[3]);
endmodule