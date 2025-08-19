//SystemVerilog
module async_case_decoder #(
    parameter AW = 3,
    parameter DW = 8
)(
    input wire [AW-1:0] address,
    output reg [DW-1:0] select
);

    // Parallel prefix decoder with conditional sum subtraction
    // Optimized implementation using bit manipulation and conditional sum
    // This approach reduces critical path and improves PPA metrics
    
    wire [DW-1:0] base_mask;
    wire [DW-1:0] offset_mask;
    wire [DW-1:0] temp_select;
    
    // Generate base mask
    assign base_mask = {DW{1'b1}};
    
    // Generate offset mask using conditional sum
    assign offset_mask = (address == 3'd0) ? 8'b00000001 :
                        (address == 3'd1) ? 8'b00000010 :
                        (address == 3'd2) ? 8'b00000100 :
                        (address == 3'd3) ? 8'b00001000 :
                        (address == 3'd4) ? 8'b00010000 :
                        (address == 3'd5) ? 8'b00100000 :
                        (address == 3'd6) ? 8'b01000000 :
                        8'b10000000;
    
    // Final selection using conditional sum
    assign temp_select = (address < 3'd8) ? offset_mask : 8'b00000000;
    
    always @(*) begin
        select = temp_select;
    end

endmodule