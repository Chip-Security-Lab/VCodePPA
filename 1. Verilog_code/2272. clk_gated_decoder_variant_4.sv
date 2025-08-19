//SystemVerilog
module clk_gated_decoder(
    input wire clk,
    input wire [2:0] addr,
    input wire enable,
    output wire [7:0] select
);
    // Internal connections
    wire [2:0] registered_addr;
    wire registered_enable;
    wire [7:0] decoded_value;
    
    // Input registration submodule
    input_register input_reg_inst (
        .clk(clk),
        .addr_in(addr),
        .enable_in(enable),
        .addr_out(registered_addr),
        .enable_out(registered_enable)
    );
    
    // Decoder submodule
    address_decoder decoder_inst (
        .addr(registered_addr),
        .decoded_out(decoded_value)
    );
    
    // Output register with enable control
    output_register output_reg_inst (
        .clk(clk),
        .enable(registered_enable),
        .data_in(decoded_value),
        .data_out(select)
    );
endmodule

module input_register (
    input wire clk,
    input wire [2:0] addr_in,
    input wire enable_in,
    output reg [2:0] addr_out,
    output reg enable_out
);
    // Register inputs
    always @(posedge clk) begin
        addr_out <= addr_in;
        enable_out <= enable_in;
    end
endmodule

module address_decoder (
    input wire [2:0] addr,
    output wire [7:0] decoded_out
);
    // Pure combinational one-hot decoder
    assign decoded_out = (8'b00000001 << addr);
endmodule

module output_register (
    input wire clk,
    input wire enable,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    // Registered output with enable
    always @(posedge clk) begin
        if (enable)
            data_out <= data_in;
    end
endmodule