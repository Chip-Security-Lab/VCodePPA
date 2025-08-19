//SystemVerilog
module sync_single_port_ram_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    // RAM array
    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

    // Pipeline stage 1: Input registers
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] din_reg;
    reg we_reg;

    // Pipeline stage 2: RAM access
    reg [DATA_WIDTH-1:0] ram_data_reg;
    reg [ADDR_WIDTH-1:0] addr_reg2;
    reg we_reg2;

    // Pipeline stage 3: Output mux
    reg [DATA_WIDTH-1:0] output_mux_reg;

    // Stage 1: Input registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_reg <= 0;
            din_reg <= 0;
            we_reg <= 0;
        end else begin
            addr_reg <= addr;
            din_reg <= din;
            we_reg <= we;
        end
    end

    // Stage 2: RAM access and write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_reg <= 0;
            addr_reg2 <= 0;
            we_reg2 <= 0;
        end else begin
            if (we_reg) begin
                ram[addr_reg] <= din_reg;
            end
            ram_data_reg <= ram[addr_reg];
            addr_reg2 <= addr_reg;
            we_reg2 <= we_reg;
        end
    end

    // Stage 3: Output selection and registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            output_mux_reg <= 0;
        end else begin
            output_mux_reg <= (we_reg2 && (addr_reg2 == addr_reg)) ? din_reg : ram_data_reg;
        end
    end

    // Output assignment
    assign dout = output_mux_reg;

endmodule