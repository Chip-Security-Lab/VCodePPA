//SystemVerilog
// Top level module
module activelow_demux (
    input  wire       data_in,    // Input data (active high)
    input  wire [1:0] addr,       // Address selection
    output wire [3:0] out_n       // Active-low outputs
);
    // Internal signals
    wire [3:0] one_hot_out;
    
    // Instantiate address decoder module
    addr_decoder decoder_inst (
        .data_in     (data_in),
        .addr        (addr),
        .one_hot_out (one_hot_out)
    );
    
    // Instantiate output inverter module
    output_inverter inverter_inst (
        .in  (one_hot_out),
        .out (out_n)
    );
    
endmodule

// Address decoder submodule
// Converts address to one-hot encoding
module addr_decoder (
    input  wire       data_in,
    input  wire [1:0] addr,
    output reg  [3:0] one_hot_out
);
    // Generate one-hot encoded output based on address
    always @(*) begin
        if (data_in) begin
            case (addr)
                2'b00:    one_hot_out = 4'b0001;
                2'b01:    one_hot_out = 4'b0010;
                2'b10:    one_hot_out = 4'b0100;
                2'b11:    one_hot_out = 4'b1000;
                default:  one_hot_out = 4'b0000;
            endcase
        end else begin
            one_hot_out = 4'b0000;
        end
    end
endmodule

// Output inverter submodule
// Converts active-high to active-low signals
module output_inverter (
    input  wire [3:0] in,
    output wire [3:0] out
);
    // Invert each bit to convert from active-high to active-low
    assign out = ~in;
endmodule