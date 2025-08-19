//SystemVerilog
// Top-level module
module activelow_demux (
    input wire data_in,                  // Input data (active high)
    input wire [1:0] addr,               // Address selection
    output wire [3:0] out_n              // Active-low outputs
);
    // Internal connections
    wire [3:0] decoded_signal;
    
    // Instantiate decoder submodule
    addr_decoder decoder_inst (
        .data_valid(data_in),
        .address(addr),
        .decoded_bus(decoded_signal)
    );
    
    // Instantiate output inverter submodule
    output_inverter inverter_inst (
        .in_bus(decoded_signal),
        .out_bus_n(out_n)
    );
    
endmodule

// Decoder submodule - handles address decoding and data validation
module addr_decoder (
    input wire data_valid,               // Data valid signal (active high)
    input wire [1:0] address,            // Address input
    output reg [3:0] decoded_bus         // Decoded output bus (active high)
);
    // One-hot encoding based on address
    always @(*) begin
        decoded_bus = 4'b0000;
        if (data_valid) begin
            case (address)
                2'b00: decoded_bus = 4'b0001;
                2'b01: decoded_bus = 4'b0010;
                2'b10: decoded_bus = 4'b0100;
                2'b11: decoded_bus = 4'b1000;
                default: decoded_bus = 4'b0000;
            endcase
        end
    end
endmodule

// Output inverter submodule - converts active high to active low signals
module output_inverter (
    input wire [3:0] in_bus,             // Input bus (active high)
    output wire [3:0] out_bus_n          // Output bus (active low)
);
    // Invert all signals
    assign out_bus_n = ~in_bus;
endmodule