//SystemVerilog
module async_dual_port_ram_with_reset #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire rst
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] next_dout_a, next_dout_b;
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    reg [DATA_WIDTH-1:0] write_data_a, write_data_b;
    reg [DATA_WIDTH-1:0] borrow_a, borrow_b;
    reg [DATA_WIDTH-1:0] diff_a, diff_b;

    // Borrow subtractor implementation
    always @* begin
        // Port A subtraction
        borrow_a[0] = 1'b0;
        for (int i = 0; i < DATA_WIDTH; i = i + 1) begin
            diff_a[i] = ram_data_a[i] ^ write_data_a[i] ^ borrow_a[i];
            borrow_a[i+1] = (~ram_data_a[i] & write_data_a[i]) | 
                          ((~ram_data_a[i] | write_data_a[i]) & borrow_a[i]);
        end

        // Port B subtraction
        borrow_b[0] = 1'b0;
        for (int i = 0; i < DATA_WIDTH; i = i + 1) begin
            diff_b[i] = ram_data_b[i] ^ write_data_b[i] ^ borrow_b[i];
            borrow_b[i+1] = (~ram_data_b[i] & write_data_b[i]) | 
                          ((~ram_data_b[i] | write_data_b[i]) & borrow_b[i]);
        end
    end

    always @* begin
        ram_data_a = ram[addr_a];
        ram_data_b = ram[addr_b];
        write_data_a = din_a;
        write_data_b = din_b;

        if (!rst && we_a) begin
            ram[addr_a] = diff_a;
            next_dout_a = diff_a;
        end else begin
            next_dout_a = ram_data_a;
        end
        
        if (!rst && we_b) begin
            ram[addr_b] = diff_b;
            next_dout_b = diff_b;
        end else begin
            next_dout_b = ram_data_b;
        end
        
        if (rst) begin
            next_dout_a = 0;
            next_dout_b = 0;
        end
    end

    always @* begin
        dout_a = next_dout_a;
        dout_b = next_dout_b;
    end
endmodule