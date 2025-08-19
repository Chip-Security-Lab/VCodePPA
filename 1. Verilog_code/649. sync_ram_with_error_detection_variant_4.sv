//SystemVerilog
module sync_ram_with_error_detection #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output reg error_flag
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] next_dout;
    reg next_error_flag;
    wire [DATA_WIDTH-1:0] diff;
    wire [DATA_WIDTH:0] borrow;
    
    // Carry Lookahead Subtractor
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : sub_gen
            wire p, g;
            assign p = ~ram[addr][i] ^ dout[i];
            assign g = ~ram[addr][i] & dout[i];
            assign borrow[i+1] = g | (p & borrow[i]);
            assign diff[i] = ram[addr][i] ^ dout[i] ^ borrow[i];
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
            error_flag <= 0;
        end else begin
            dout <= next_dout;
            error_flag <= next_error_flag;
        end
    end

    always @(*) begin
        next_dout = ram[addr];
        next_error_flag = |diff;
        
        if (we) begin
            ram[addr] = din;
            next_error_flag = 0;
        end
    end
endmodule