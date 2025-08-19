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
    
    // Direct use of input signals
    wire [ADDR_WIDTH-1:0] addr_a_wire;
    wire en_a_wire;
    wire we_a_wire;
    wire [DATA_WIDTH-1:0] data_a_in_wire;
    
    wire [ADDR_WIDTH-1:0] addr_b_wire;
    wire en_b_wire;
    wire we_b_wire;
    wire [DATA_WIDTH-1:0] data_b_in_wire;
    
    // Direct connection to inputs (no input registration)
    assign addr_a_wire = addr_a;
    assign en_a_wire = en_a;
    assign we_a_wire = we_a;
    assign data_a_in_wire = data_a_in;
    
    assign addr_b_wire = addr_b;
    assign en_b_wire = en_b;
    assign we_b_wire = we_b;
    assign data_b_in_wire = data_b_in;
    
    // Intermediate signals for memory access
    reg [DATA_WIDTH-1:0] ram_read_a;
    reg [DATA_WIDTH-1:0] ram_read_b;
    
    // Port A memory access logic (combinational)
    always @(*) begin
        ram_read_a = ram[addr_a_wire];
    end
    
    // Port B memory access logic (combinational)
    always @(*) begin
        ram_read_b = ram[addr_b_wire];
    end
    
    // Port A operation with register moved after combinational logic
    always @(posedge clk_a) begin
        if (en_a_wire) begin
            if (we_a_wire)
                ram[addr_a_wire] <= data_a_in_wire;
            data_a_out <= ram_read_a;
        end
    end
    
    // Port B operation with register moved after combinational logic
    always @(posedge clk_b) begin
        if (en_b_wire) begin
            if (we_b_wire)
                ram[addr_b_wire] <= data_b_in_wire;
            data_b_out <= ram_read_b;
        end
    end
endmodule