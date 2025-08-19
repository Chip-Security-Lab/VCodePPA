//SystemVerilog
module async_single_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire en
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] data_reg;
    reg write_en_reg;
    reg read_en_reg;
    reg [DATA_WIDTH-1:0] result;
    reg borrow;
    reg [DATA_WIDTH-1:0] temp_result;
    reg [DATA_WIDTH-1:0] temp_ram_data;

    always @* begin
        if (en) begin
            addr_reg = addr;
            data_reg = din;
            write_en_reg = we;
            read_en_reg = 1'b1;
            
            if (write_en_reg) begin
                ram[addr_reg] = data_reg;
                result = data_reg;
            end else begin
                temp_ram_data = ram[addr_reg];
                borrow = 1'b0;
                
                for (int i = 0; i < DATA_WIDTH; i = i + 1) begin
                    temp_result[i] = temp_ram_data[i] ^ borrow;
                    borrow = (~temp_ram_data[i] & borrow) | (temp_ram_data[i] & ~borrow);
                end
                
                result = temp_result;
            end
            
            dout = result;
        end else begin
            dout = {DATA_WIDTH{1'b0}};
        end
    end
endmodule