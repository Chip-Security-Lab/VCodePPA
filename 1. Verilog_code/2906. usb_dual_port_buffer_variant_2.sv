//SystemVerilog
module usb_dual_port_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
)(
    // Port A - USB Interface
    input wire clk_a,
    input wire en_a,
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] data_a_in,
    output reg [DATA_WIDTH-1:0] data_a_out,
    // Port B - System Interface
    input wire clk_b,
    input wire en_b,
    input wire we_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire [DATA_WIDTH-1:0] data_b_in,
    output reg [DATA_WIDTH-1:0] data_b_out
);
    // Memory array
    reg [DATA_WIDTH-1:0] ram [(1<<ADDR_WIDTH)-1:0];
    
    // Port A operation - consolidated always block
    always @(posedge clk_a) begin
        if (en_a) begin
            if (we_a) begin
                ram[addr_a] <= data_a_in;
            end
            data_a_out <= we_a ? data_a_in : ram[addr_a];
        end
    end
    
    // Port B operation - consolidated always block
    always @(posedge clk_b) begin
        if (en_b) begin
            if (we_b) begin
                ram[addr_b] <= data_b_in;
            end
            data_b_out <= we_b ? data_b_in : ram[addr_b];
        end
    end
endmodule