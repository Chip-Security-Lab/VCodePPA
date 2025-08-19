module parity_checker #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] data_in,
    input  wire             parity_in,
    input  wire             odd_parity_mode,
    output wire             error_flag
);
    wire calculated_parity;
    
    // Calculate parity based on input data
    assign calculated_parity = ^data_in ^ odd_parity_mode;
    
    // Check if calculated parity matches received parity
    assign error_flag = calculated_parity != parity_in;
endmodule