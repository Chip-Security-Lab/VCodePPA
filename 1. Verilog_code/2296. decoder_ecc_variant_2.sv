//SystemVerilog
// Top level module
module decoder_ecc #(
    parameter DATA_W = 4
) (
    input [DATA_W+2:0] encoded_addr, // [DATA_W+2:3]=data, [2:0]=parity bits
    output [2**DATA_W-1:0] decoded,
    output error
);

    // Internal connections
    wire [DATA_W-1:0] data;
    wire calc_parity;
    wire parity_error;

    // Extract data bits from encoded address
    data_extractor #(
        .DATA_W(DATA_W)
    ) data_ext_inst (
        .encoded_addr(encoded_addr),
        .data(data)
    );

    // Calculate parity for error detection
    parity_calculator #(
        .DATA_W(DATA_W)
    ) parity_calc_inst (
        .data(data),
        .calc_parity(calc_parity)
    );

    // Detect error in the received data
    error_detector error_det_inst (
        .calc_parity(calc_parity),
        .stored_parity(encoded_addr[0]),
        .error(parity_error)
    );

    // Generate decoded output based on data and error status
    output_decoder #(
        .DATA_W(DATA_W)
    ) out_dec_inst (
        .data(data),
        .error(parity_error),
        .decoded(decoded)
    );

    // Assign the error output
    assign error = parity_error;

endmodule

// Module to extract data bits from encoded address
module data_extractor #(
    parameter DATA_W = 4
) (
    input [DATA_W+2:0] encoded_addr,
    output [DATA_W-1:0] data
);
    
    // Extract data bits
    assign data = encoded_addr[DATA_W+2:3];
    
endmodule

// Module to calculate parity
module parity_calculator #(
    parameter DATA_W = 4
) (
    input [DATA_W-1:0] data,
    output calc_parity
);
    
    // Calculate parity using XOR reduction
    assign calc_parity = ^data;
    
endmodule

// Module to detect errors
module error_detector (
    input calc_parity,
    input stored_parity,
    output error
);
    
    // Compare calculated parity with stored parity
    wire equal_parity;
    wire not_equal_parity;
    
    assign equal_parity = ~(calc_parity ^ stored_parity);
    assign not_equal_parity = ~equal_parity;
    
    // MUX for error detection
    wire [1:0] mux_sel;
    wire [1:0] mux_out;
    
    assign mux_sel = {equal_parity, not_equal_parity};
    assign mux_out = (mux_sel == 2'b10) ? 1'b0 : 1'b1;
    
    assign error = mux_out[0];
    
endmodule

// Module to decode the output
module output_decoder #(
    parameter DATA_W = 4
) (
    input [DATA_W-1:0] data,
    input error,
    output [2**DATA_W-1:0] decoded
);
    
    // Generate shifted value based on data
    wire [2**DATA_W-1:0] shifted_value;
    assign shifted_value = (1'b1 << data);
    
    // MUX to select between zero or shifted value based on error
    wire [2**DATA_W-1:0] zero_value;
    assign zero_value = {(2**DATA_W){1'b0}};
    
    // MUX select signals
    wire error_sel;
    wire no_error_sel;
    
    assign error_sel = error;
    assign no_error_sel = ~error;
    
    // MUX implementation
    wire [1:0] decoded_sel;
    wire [2**DATA_W-1:0] decoded_mux [1:0];
    
    assign decoded_sel = {error_sel, no_error_sel};
    assign decoded_mux[0] = zero_value;
    assign decoded_mux[1] = shifted_value;
    
    // Final output assignment using explicit mux structure
    assign decoded = (decoded_sel[1]) ? decoded_mux[0] : 
                    (decoded_sel[0]) ? decoded_mux[0] : decoded_mux[1];
    
endmodule