//SystemVerilog
module sync_single_port_ram_with_byte_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire [DATA_WIDTH/8-1:0] byte_en,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    integer i;
    
    wire [DATA_WIDTH-1:0] carry_propagate;
    wire [DATA_WIDTH-1:0] carry_generate;
    wire [DATA_WIDTH-1:0] carry_in;
    wire [DATA_WIDTH-1:0] sum_out;
    
    genvar j;
    generate
        for (j = 0; j < DATA_WIDTH; j = j + 1) begin : carry_logic
            assign carry_propagate[j] = ram[addr][j] ^ din[j];
            assign carry_generate[j] = ram[addr][j] & din[j];
        end
    endgenerate
    
    assign carry_in[0] = 1'b0;
    generate
        for (j = 1; j < DATA_WIDTH; j = j + 1) begin : carry_chain
            assign carry_in[j] = carry_generate[j-1] | (carry_propagate[j-1] & carry_in[j-1]);
        end
    endgenerate
    
    generate
        for (j = 0; j < DATA_WIDTH; j = j + 1) begin : sum_logic
            assign sum_out[j] = carry_propagate[j] ^ carry_in[j];
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (we) begin
            i = 0;
            while (i < DATA_WIDTH / 8) begin
                if (byte_en[i]) begin
                    ram[addr][i*8 +: 8] <= sum_out[i*8 +: 8];
                end
                i = i + 1;
            end
        end
        dout <= ram[addr];
    end
endmodule