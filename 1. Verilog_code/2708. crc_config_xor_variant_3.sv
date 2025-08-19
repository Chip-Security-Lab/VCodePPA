//SystemVerilog
module crc_config_xor #(
    parameter WIDTH = 16,
    parameter INIT = 16'hFFFF,
    parameter FINAL_XOR = 16'h0000
)(
    input clk, en, 
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] crc,
    output [WIDTH-1:0] crc_result
);
    // Pipeline registers for critical path
    reg [WIDTH-1:0] shifted_crc;
    reg [WIDTH-1:0] xor_pattern;
    reg [WIDTH-1:0] data_reg;
    reg crc_msb;
    reg en_pipeline;
    reg [WIDTH-1:0] crc_next;
    
    // Stage 1: Register inputs and calculate initial values
    always @(posedge clk) begin
        data_reg <= data;
        en_pipeline <= en;
    end
    
    // Stage 2: Calculate XOR pattern and shifted CRC
    always @(posedge clk) begin
        crc_msb <= crc[WIDTH-1];
        shifted_crc <= crc << 1;
        xor_pattern <= crc_msb ? 16'h1021 : 16'h0000;
    end
    
    // Stage 3: Final CRC calculation
    always @(posedge clk) begin
        if (en_pipeline) begin
            crc <= shifted_crc ^ (data_reg ^ xor_pattern);
        end else begin
            crc <= INIT;
        end
    end
    
    // Final output
    assign crc_result = crc ^ FINAL_XOR;
endmodule