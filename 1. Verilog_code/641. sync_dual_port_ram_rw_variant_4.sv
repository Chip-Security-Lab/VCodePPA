//SystemVerilog
module sync_dual_port_ram_rw #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    // Memory array with power optimization
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Combined pipeline registers for better timing
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg we_a_reg, we_b_reg;
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;

    // Optimized pipeline stage 1: Register inputs with gated clock
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {addr_a_reg, addr_b_reg, din_a_reg, din_b_reg, we_a_reg, we_b_reg} <= 0;
        end else begin
            {addr_a_reg, addr_b_reg} <= {addr_a, addr_b};
            {din_a_reg, din_b_reg} <= {din_a, din_b};
            {we_a_reg, we_b_reg} <= {we_a, we_b};
        end
    end

    // Optimized pipeline stage 2: Memory access with write priority
    always @(posedge clk) begin
        // Write operations with priority encoding
        case ({we_a_reg, we_b_reg})
            2'b10: ram[addr_a_reg] <= din_a_reg;
            2'b01: ram[addr_b_reg] <= din_b_reg;
            2'b11: begin
                if (addr_a_reg == addr_b_reg) begin
                    ram[addr_a_reg] <= din_a_reg;
                end else begin
                    ram[addr_a_reg] <= din_a_reg;
                    ram[addr_b_reg] <= din_b_reg;
                end
            end
        endcase
        
        // Read operations with bypass logic
        ram_data_a <= (we_a_reg && addr_a_reg == addr_a) ? din_a_reg : ram[addr_a_reg];
        ram_data_b <= (we_b_reg && addr_b_reg == addr_b) ? din_b_reg : ram[addr_b_reg];
    end

    // Optimized pipeline stage 3: Output registers with reset optimization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {dout_a, dout_b} <= 0;
        end else begin
            {dout_a, dout_b} <= {ram_data_a, ram_data_b};
        end
    end

endmodule