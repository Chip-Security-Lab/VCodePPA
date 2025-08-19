//SystemVerilog
module sync_decoder_with_reset #(
    parameter ADDR_BITS = 2,
    parameter OUT_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_BITS-1:0] addr,
    output reg [OUT_BITS-1:0] decode
);

    // Pipeline stage 1: Address register
    reg [ADDR_BITS-1:0] addr_reg;
    
    // Pipeline stage 2: Shift operation
    reg [OUT_BITS-1:0] shift_result;
    
    // Pipeline stage 3: Final output
    reg [OUT_BITS-1:0] decode_reg;

    // Stage 1: Register input address
    always @(posedge clk) begin
        if (rst) begin
            addr_reg <= 0;
        end else begin
            addr_reg <= addr;
        end
    end

    // Stage 2: Perform shift operation
    always @(posedge clk) begin
        if (rst) begin
            shift_result <= 0;
        end else begin
            shift_result <= (1 << addr_reg);
        end
    end

    // Stage 3: Register final output
    always @(posedge clk) begin
        if (rst) begin
            decode_reg <= 0;
        end else begin
            decode_reg <= shift_result;
        end
    end

    // Output assignment
    assign decode = decode_reg;

endmodule