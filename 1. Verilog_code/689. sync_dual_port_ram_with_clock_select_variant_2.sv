//SystemVerilog
module sync_dual_port_ram_with_clock_select #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg we_a_reg, we_b_reg;
    
    // Buffer registers for high fanout signals
    reg [DATA_WIDTH-1:0] ram_data_a_buf, ram_data_b_buf;
    reg [ADDR_WIDTH-1:0] addr_a_buf, addr_b_buf;
    reg we_a_buf, we_b_buf;

    // Port A
    always @(posedge clk_a) begin
        if (rst) begin
            dout_a <= {DATA_WIDTH{1'b0}};
            addr_a_reg <= {ADDR_WIDTH{1'b0}};
            din_a_reg <= {DATA_WIDTH{1'b0}};
            we_a_reg <= 1'b0;
            ram_data_a_buf <= {DATA_WIDTH{1'b0}};
            addr_a_buf <= {ADDR_WIDTH{1'b0}};
            we_a_buf <= 1'b0;
        end else begin
            // First stage buffering
            addr_a_buf <= addr_a;
            din_a_reg <= din_a;
            we_a_buf <= we_a;
            
            // Second stage buffering
            addr_a_reg <= addr_a_buf;
            we_a_reg <= we_a_buf;
            
            if (we_a_reg) begin
                ram[addr_a_reg] <= din_a_reg;
            end
            ram_data_a_buf <= ram[addr_a_reg];
            dout_a <= ram_data_a_buf;
        end
    end

    // Port B
    always @(posedge clk_b) begin
        if (rst) begin
            dout_b <= {DATA_WIDTH{1'b0}};
            addr_b_reg <= {ADDR_WIDTH{1'b0}};
            din_b_reg <= {DATA_WIDTH{1'b0}};
            we_b_reg <= 1'b0;
            ram_data_b_buf <= {DATA_WIDTH{1'b0}};
            addr_b_buf <= {ADDR_WIDTH{1'b0}};
            we_b_buf <= 1'b0;
        end else begin
            // First stage buffering
            addr_b_buf <= addr_b;
            din_b_reg <= din_b;
            we_b_buf <= we_b;
            
            // Second stage buffering
            addr_b_reg <= addr_b_buf;
            we_b_reg <= we_b_buf;
            
            if (we_b_reg) begin
                ram[addr_b_reg] <= din_b_reg;
            end
            ram_data_b_buf <= ram[addr_b_reg];
            dout_b <= ram_data_b_buf;
        end
    end
endmodule