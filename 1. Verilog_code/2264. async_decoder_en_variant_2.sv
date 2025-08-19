//SystemVerilog
//===================================================================
// Module: async_decoder_en
// Description: Top-level module for an asynchronous 2-to-4 decoder with enable
//===================================================================
module async_decoder_en (
    input      [1:0] addr,
    input            enable,
    output     [3:0] decode_out
);
    
    wire [3:0] decoder_value;
    wire       enable_signal;
    
    // Instantiate address decoder submodule
    addr_decoder addr_decoder_inst (
        .addr_in       (addr),
        .decoded_value (decoder_value)
    );
    
    // Instantiate enable control submodule
    enable_controller enable_ctrl_inst (
        .enable_in     (enable),
        .enable_out    (enable_signal)
    );
    
    // Instantiate output generator submodule
    output_generator output_gen_inst (
        .decoded_value (decoder_value),
        .enable_signal (enable_signal),
        .decoder_out   (decode_out)
    );
    
endmodule

//===================================================================
// Module: addr_decoder
// Description: Converts 2-bit address to one-hot encoding
//===================================================================
module addr_decoder (
    input      [1:0] addr_in,
    output reg [3:0] decoded_value
);
    
    always @(*) begin
        decoded_value = 4'b0001 << addr_in;
    end
    
endmodule

//===================================================================
// Module: enable_controller
// Description: Manages the enable signal with potential for future expansion
//===================================================================
module enable_controller (
    input      enable_in,
    output     enable_out
);
    
    assign enable_out = enable_in;
    
endmodule

//===================================================================
// Module: output_generator
// Description: Generates final output based on decoder value and enable signal
//===================================================================
module output_generator #(
    parameter WIDTH = 4
)(
    input      [WIDTH-1:0] decoded_value,
    input                  enable_signal,
    output reg [WIDTH-1:0] decoder_out
);
    
    always @(*) begin
        if (enable_signal) begin
            decoder_out = decoded_value;
        end
        else begin
            decoder_out = {WIDTH{1'b0}};
        end
    end
    
endmodule