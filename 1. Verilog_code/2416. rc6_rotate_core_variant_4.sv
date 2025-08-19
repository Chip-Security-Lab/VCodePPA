//SystemVerilog
module rc6_rotate_core (
    input clk, en,
    input [31:0] a_in, b_in,
    output reg [31:0] data_out
);
    // Only take the 5 least significant bits as rotation amount (0-31)
    wire [4:0] rot_offset;
    wire [31:0] rotated_data;
    wire [31:0] combined_result;
    
    // Constants
    localparam [31:0] GOLDEN_RATIO = 32'h9E3779B9;
    
    // Instantiate combinational logic module
    rc6_rotate_combinational rotate_comb (
        .a_in(a_in),
        .rot_offset(rot_offset),
        .golden_ratio(GOLDEN_RATIO),
        .rotated_data(rotated_data),
        .combined_result(combined_result)
    );
    
    // Extract rotation offset from input b
    assign rot_offset = b_in[4:0];
    
    // Sequential logic - purely register updates
    always @(posedge clk) begin
        if (en) begin
            data_out <= combined_result;
        end
    end
endmodule

// Separate combinational logic module
module rc6_rotate_combinational (
    input [31:0] a_in,
    input [4:0] rot_offset,
    input [31:0] golden_ratio,
    output [31:0] rotated_data,
    output [31:0] combined_result
);
    // Optimized barrel shifter for rotation
    assign rotated_data = (rot_offset == 5'd0) ? a_in :
                         ((a_in << rot_offset) | (a_in >> (32 - rot_offset)));
    
    // Addition operation
    assign combined_result = rotated_data + golden_ratio;
endmodule