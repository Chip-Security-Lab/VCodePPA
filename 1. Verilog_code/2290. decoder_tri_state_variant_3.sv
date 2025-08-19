//SystemVerilog
// Top-level module
module decoder_tri_state (
    input oe,
    input [2:0] addr,
    output [7:0] bus
);
    // Internal signals
    wire [7:0] decoded_data;
    
    // Instantiate the decoder submodule
    decoder_logic u_decoder_logic (
        .addr(addr),
        .decoded_data(decoded_data)
    );
    
    // Instantiate the output buffer submodule
    tri_state_buffer u_tri_state_buffer (
        .oe(oe),
        .data_in(decoded_data),
        .data_out(bus)
    );
    
endmodule

// Decoder logic submodule
module decoder_logic (
    input [2:0] addr,
    output reg [7:0] decoded_data
);
    // Decode the address to one-hot encoding using always block
    always @(*) begin
        decoded_data = 8'h00;
        if (addr == 3'b000) decoded_data = 8'h01;
        else if (addr == 3'b001) decoded_data = 8'h02;
        else if (addr == 3'b010) decoded_data = 8'h04;
        else if (addr == 3'b011) decoded_data = 8'h08;
        else if (addr == 3'b100) decoded_data = 8'h10;
        else if (addr == 3'b101) decoded_data = 8'h20;
        else if (addr == 3'b110) decoded_data = 8'h40;
        else if (addr == 3'b111) decoded_data = 8'h80;
    end
endmodule

// Tri-state buffer submodule
module tri_state_buffer (
    input oe,
    input [7:0] data_in,
    output reg [7:0] data_out
);
    // Apply output enable to control the tri-state output using always block
    always @(*) begin
        if (oe) begin
            data_out = data_in;
        end
        else begin
            data_out = 8'hZZ;
        end
    end
endmodule