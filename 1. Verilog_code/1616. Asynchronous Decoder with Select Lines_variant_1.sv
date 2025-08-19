//SystemVerilog
// Top level module
module async_sel_decoder (
    input [1:0] sel,
    input enable,
    output [3:0] out_bus
);

    // Internal signals
    wire [3:0] decoded_value;
    wire [3:0] enabled_output;

    // Decoder submodule
    decoder_2to4 decoder_inst (
        .sel(sel),
        .decoded(decoded_value)
    );

    // Enable control submodule  
    enable_control enable_inst (
        .enable(enable),
        .decoded_in(decoded_value),
        .enabled_out(enabled_output)
    );

    // Output assignment
    assign out_bus = enabled_output;

endmodule

// 2-to-4 decoder submodule
module decoder_2to4 (
    input [1:0] sel,
    output reg [3:0] decoded
);
    always @(*) begin
        case (sel)
            2'b00: decoded = 4'b0001;
            2'b01: decoded = 4'b0010;
            2'b10: decoded = 4'b0100;
            2'b11: decoded = 4'b1000;
        endcase
    end
endmodule

// Enable control submodule
module enable_control (
    input enable,
    input [3:0] decoded_in,
    output reg [3:0] enabled_out
);
    always @(*) begin
        if (enable)
            enabled_out = decoded_in;
        else
            enabled_out = 4'b0000;
    end
endmodule