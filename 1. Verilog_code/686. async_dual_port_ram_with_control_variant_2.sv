//SystemVerilog
module async_dual_port_ram_with_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire control_signal_a, control_signal_b
);

    // Memory array
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Control signals
    wire write_enable_a = control_signal_a & we_a;
    wire write_enable_b = control_signal_b & we_b;
    
    // Pipeline registers
    reg [DATA_WIDTH-1:0] lut_data_a, lut_data_b;
    reg [DATA_WIDTH-1:0] write_data_a, write_data_b;
    reg [ADDR_WIDTH-1:0] write_addr_a, write_addr_b;
    reg write_valid_a, write_valid_b;
    
    // LUT for data transformation
    reg [DATA_WIDTH-1:0] lut_sub [0:255];
    
    // Initialize LUT
    initial begin
        for (int i = 0; i < 256; i = i + 1) begin
            lut_sub[i] = i;
        end
    end
    
    // Stage 1: LUT lookup
    always @* begin
        lut_data_a = lut_sub[din_a];
        lut_data_b = lut_sub[din_b];
    end
    
    // Stage 2: Write control
    always @* begin
        write_data_a = write_enable_a ? lut_data_a : ram[addr_a];
        write_data_b = write_enable_b ? lut_data_b : ram[addr_b];
        write_addr_a = addr_a;
        write_addr_b = addr_b;
        write_valid_a = write_enable_a;
        write_valid_b = write_enable_b;
    end
    
    // Stage 3: Memory write
    always @* begin
        if (write_valid_a) begin
            ram[write_addr_a] = write_data_a;
        end
        if (write_valid_b) begin
            ram[write_addr_b] = write_data_b;
        end
    end
    
    // Stage 4: Memory read
    always @* begin
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
    end

endmodule