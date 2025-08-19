//SystemVerilog
module parity_checker #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] data_in,
    input  wire             parity_in,
    input  wire             odd_parity_mode,
    output wire             error_flag
);

    // Optimized parity calculation using tree reduction
    wire [1:0] stage1;
    wire [1:0] stage2;
    
    // First stage: parallel XOR operations
    assign stage1[0] = ^data_in[3:0];
    assign stage1[1] = ^data_in[7:4];
    
    // Second stage: combine results
    assign stage2[0] = stage1[0] ^ stage1[1];
    assign stage2[1] = stage2[0] ^ odd_parity_mode;
    
    // Error detection using direct comparison
    assign error_flag = stage2[1] ^ parity_in;

endmodule